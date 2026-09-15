# MCP Permissions Settings Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Execution routing (per user's standing workflow preference):** Tasks 1-3 are backend-only Ruby changes — implement with a normal backend implementer (e.g. the `dev` agent). Task 4 is plain JS (Vuex store + API client, no `.vue` file, no styling) — also a normal implementer. **Task 5 touches `.vue` files and a route config file — it MUST be dispatched to the `ui` agent, and its output MUST go through the `design-review` skill before being considered done.** This split exists because two AI agents (this session and a separately-running Cursor session) have previously silently overwritten each other's work on this same repo/branch — see Task 5's Step 0.

**Goal:** Let an individual Chatwoot user view and control which of the 14 MCP tools their personal access token may call, via a new Profile Settings page, with real backend enforcement of that restriction.

**Architecture:** Backend: `Mcp::BaseTool` gains an `authorize_scope!` check (runs after auth, before tenancy) that rejects a tool call when the token's `scopes` column is non-empty and doesn't list that tool; `AccessToken#scopes` (already exists, `string[]`, default `[]`) is exposed and made writable through the existing Profile API. Frontend: a new route/page under Profile Settings, following the existing MFA settings page's shape (`BaseSettingsHeader` + route-level component, not a card on the main Index page), with a presentational checkbox-list component that tracks local dirty state and emits an explicit Save.

**Tech Stack:** Rails 7.1 request specs (RSpec), `fast-mcp` tool DSL, Vue 3 `<script setup>` Composition API, Vuex store, Relay design system (`components-next/relay/`), Vitest + `@vue/test-utils`.

**Spec:** `docs/superpowers/specs/2026-09-15-mcp-settings-page-design.md`

## Global Constraints

- Design system: Relay only (`components-next/relay/`) — no legacy `woot-*` components, no scoped CSS, no inline styles, Tailwind utility classes only (per repo `CLAUDE.md` and the design spec).
- Scope granularity: full per-tool permission list (14 checkboxes), not a binary read/write switch.
- When `scopes` is empty/nil, the UI must show all 14 checked — this is the literal current behavior (empty `scopes` = full access), not a new default.
- Save is an explicit button click, never auto-save per checkbox toggle.
- If `mcp_integration` is off for the account, show only a message — no checkbox list.
- Do not duplicate the access token value/copy/regenerate UI on this page — link to the existing Access Token section instead.
- `[]` stays reserved for "never scoped" (today's default for every existing token) — every save from this page writes an explicit list of tool names, even when all 14 are checked.
- Only `en.yml` / `en.json` get translation updates; other locales are community-maintained.
- Before any edit to a shared frontend file (`profile.routes.js`, `app/javascript/dashboard/store/modules/auth.js`), check for concurrent Cursor activity first (Task 4 Step 1, Task 5 Step 1).

---

## Task 1: `Mcp::BaseTool` — scope enforcement

**Files:**
- Modify: `app/tools/mcp/base_tool.rb`
- Test: `spec/requests/mcp/scope_enforcement_spec.rb` (new)

**Interfaces:**
- Consumes: existing `Mcp::BaseTool#call`, `#authenticate!`, `self.class.tool_name` (fast-mcp DSL, already set on every tool, e.g. `tool_name 'list_inboxes'`).
- Produces: `@access_token` ivar available to any tool after `authenticate!` runs; a token whose `scopes` column is non-empty and excludes a given tool's `tool_name` now gets `{ isError: true }` with message `"This access token is not permitted to use <tool_name>"` for that tool. A token with `scopes == []` is unaffected (today's default for every existing token).

- [ ] **Step 1: Write the failing request specs**

Create `spec/requests/mcp/scope_enforcement_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'MCP scope enforcement', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    account.enable_features!('mcp_integration')
    create(:inbox_member, inbox: inbox, user: agent)
  end

  context 'when the access token has an empty scopes array (the default)' do
    it 'allows a read tool call' do
      mcp_call('list_inboxes', arguments: { account_id: account.id }, token: agent.access_token.token)

      expect(mcp_result['isError']).to be false
    end

    it 'allows a write tool call' do
      mcp_call('add_private_note', arguments: { account_id: account.id, conversation_id: conversation.display_id, content: 'note' },
                                    token: agent.access_token.token)

      expect(mcp_result['isError']).to be false
    end
  end

  context 'when the access token is scoped to a specific set of tools' do
    before { agent.access_token.update!(scopes: ['list_inboxes']) }

    it 'allows a tool that is in scopes' do
      mcp_call('list_inboxes', arguments: { account_id: account.id }, token: agent.access_token.token)

      expect(mcp_result['isError']).to be false
    end

    it 'rejects a tool that is not in scopes' do
      mcp_call('add_private_note', arguments: { account_id: account.id, conversation_id: conversation.display_id, content: 'note' },
                                    token: agent.access_token.token)

      expect(mcp_result['isError']).to be true
      expect(mcp_result['content'].first['text']).to eq('This access token is not permitted to use add_private_note')
    end
  end
end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/requests/mcp/scope_enforcement_spec.rb`
Expected: the two "rejects"/scoped-allow examples FAIL (no `authorize_scope!` exists yet, so a scoped-down token still succeeds on `add_private_note`); the two empty-scopes examples PASS already (nothing changed their behavior yet).

- [ ] **Step 3: Implement `authorize_scope!`**

In `app/tools/mcp/base_tool.rb`, keep the resolved access token record and add the check, called right after `authenticate!` and before `require_account!` (scopes gate which tools exist for this token at all, independent of which account a call targets):

```ruby
module Mcp
  class BaseTool < FastMcp::Tool
    class ToolError < StandardError; end

    def call(**args)
      authenticate!
      Current.mcp = true
      authorize_scope!
      require_account!(args[:account_id]) if self.class.requires_account?

      Mcp::BaseTool.success(perform(**args))
    rescue ToolError => e
      Mcp::BaseTool.failure(e.message)
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, user: Current.user, account: Current.account).capture_exception
      Mcp::BaseTool.failure('Something went wrong')
    ensure
      Current.reset
    end

    def self.requires_account?
      true
    end

    def self.success(data)
      { content: [{ type: 'text', text: data.to_json }], isError: false }
    end

    def self.failure(message)
      { content: [{ type: 'text', text: message }], isError: true }
    end

    private

    attr_reader :current_user

    def current_account
      Current.account
    end

    def pundit_user
      { user: current_user, account: current_account, account_user: Current.account_user }
    end

    def can_access_conversation?(conversation)
      ConversationPolicy.new(pundit_user, conversation).show?
    end

    def authenticate!
      auth_header = headers['authorization']
      raise ToolError, 'Missing or invalid access token' if auth_header.blank?

      token = auth_header.delete_prefix('Bearer ')
      access_token = AccessToken.find_by(token: token)
      raise ToolError, 'Missing or invalid access token' unless access_token
      raise ToolError, 'Missing or invalid access token' unless access_token.owner.is_a?(User)

      @access_token = access_token
      @current_user = access_token.owner
      Current.user = @current_user
      # Deliberate -- a read-only auth check shouldn't run token validations or touch updated_at.
      access_token.update_column(:last_used_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    def authorize_scope!
      return if @access_token.scopes.blank?
      return if @access_token.scopes.include?(self.class.tool_name)

      raise ToolError, "This access token is not permitted to use #{self.class.tool_name}"
    end

    def require_account!(account_id)
      raise ToolError, 'account_id is required' if account_id.blank?

      account = current_user.accounts.find_by(id: account_id)
      raise ToolError, 'Account not found or not accessible' unless account
      raise ToolError, 'MCP access is not enabled for this account' unless account.feature_enabled?('mcp_integration')

      Current.account = account
      Current.account_user = account.account_users.find_by(user_id: current_user.id)
    end
  end
end
```

- [ ] **Step 4: Run the specs to verify they pass**

Run: `bundle exec rspec spec/requests/mcp/scope_enforcement_spec.rb`
Expected: 4 examples, 0 failures.

- [ ] **Step 5: Run the full MCP suite to check for regressions**

Run: `bundle exec rspec spec/requests/mcp spec/models/account_mcp_feature_spec.rb`
Expected: all passing (43 examples: the existing 42 plus this file adds 4, replacing none — if the count differs from 46, investigate before continuing).

- [ ] **Step 6: Rubocop and commit**

Run: `bundle exec rubocop -a app/tools/mcp/base_tool.rb spec/requests/mcp/scope_enforcement_spec.rb`

```bash
git add app/tools/mcp/base_tool.rb spec/requests/mcp/scope_enforcement_spec.rb
git commit -m "feat(mcp): enforce access token scopes on every tool call"
```

---

## Task 2: Expose `access_token_scopes` on the Profile API

**Files:**
- Modify: `app/views/api/v1/models/_user.json.jbuilder`
- Modify: `swagger/definitions/resource/user.yml`
- Modify (generated): `swagger/swagger.json`
- Modify: `spec/controllers/api/v1/profiles_controller_spec.rb`

**Interfaces:**
- Consumes: `AccessToken#scopes` (existing column, `string[]`, default `[]`).
- Produces: `GET /api/v1/profile` and any endpoint rendering `api/v1/models/_user` now include `access_token_scopes: string[]` in the JSON body — the frontend (Task 5) reads this field to seed the checkbox list.

- [ ] **Step 1: Write the failing request spec**

In `spec/controllers/api/v1/profiles_controller_spec.rb`, inside `describe 'GET /api/v1/profile'` → `context 'when it is an authenticated user'`, add:

```ruby
      it 'returns the access token scopes' do
        agent.access_token.update!(scopes: ['list_inboxes', 'add_label'])

        get '/api/v1/profile',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['access_token_scopes']).to eq(['list_inboxes', 'add_label'])
      end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/controllers/api/v1/profiles_controller_spec.rb -e "returns the access token scopes"`
Expected: FAIL — `json_response['access_token_scopes']` is `nil`, not the expected array.

- [ ] **Step 3: Add the field to the jbuilder view**

In `app/views/api/v1/models/_user.json.jbuilder`, add a line right after the existing `access_token` line:

```ruby
json.access_token resource.access_token.token
json.access_token_scopes resource.access_token.scopes
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `bundle exec rspec spec/controllers/api/v1/profiles_controller_spec.rb -e "returns the access token scopes"`
Expected: PASS.

- [ ] **Step 5: Update the swagger schema and regenerate `swagger.json`**

`spec/controllers/api/v1/profiles_controller_spec.rb` uses `expect(response).to conform_schema(200)` against `swagger/swagger.json`, so the schema must be updated or the *other*, unchanged specs in that file will start failing on the extra undocumented property.

In `swagger/definitions/resource/user.yml`, add a new property right after `access_token`:

```yaml
  access_token:
    type: string
  access_token_scopes:
    type: array
    items:
      type: string
    description: >-
      The list of MCP tool names this access token is scoped to call.
      An empty array means the token has unrestricted access to every tool.
```

Run: `bundle exec rake swagger:build`
Expected: "Swagger build was successful." printed, `swagger/swagger.json` modified (diff should show the new `access_token_scopes` property under the user schema, nowhere else).

- [ ] **Step 6: Run the full profile spec file to confirm no schema regressions**

Run: `bundle exec rspec spec/controllers/api/v1/profiles_controller_spec.rb`
Expected: all examples passing (existing `conform_schema(200)` checks still pass with the regenerated schema).

- [ ] **Step 7: Rubocop and commit**

```bash
git add app/views/api/v1/models/_user.json.jbuilder swagger/definitions/resource/user.yml swagger/swagger.json spec/controllers/api/v1/profiles_controller_spec.rb
git commit -m "feat(mcp): expose access_token_scopes on the profile API"
```

---

## Task 3: Persist scopes via `ProfilesController#update`

**Files:**
- Modify: `app/controllers/api/v1/profiles_controller.rb`
- Modify: `spec/controllers/api/v1/profiles_controller_spec.rb`

**Interfaces:**
- Consumes: `params[:profile][:scopes]` — an array of tool-name strings, or omitted entirely.
- Produces: `PUT /api/v1/profile` with `profile: { scopes: [...] }` persists `current_user.access_token.scopes`; omitting the `scopes` key from the request leaves existing scopes untouched (so unrelated profile edits like name/avatar never accidentally clear a user's saved scopes).

- [ ] **Step 1: Write the failing request specs**

In `spec/controllers/api/v1/profiles_controller_spec.rb`, inside `describe 'PUT /api/v1/profile'` → `context 'when it is an authenticated user'`, add:

```ruby
      it 'persists the access token scopes' do
        put '/api/v1/profile',
            params: { profile: { scopes: ['list_inboxes', 'add_label'] } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['access_token_scopes']).to eq(['list_inboxes', 'add_label'])
        expect(agent.access_token.reload.scopes).to eq(['list_inboxes', 'add_label'])
      end

      it 'does not clear existing scopes when scopes is omitted from the request' do
        agent.access_token.update!(scopes: ['list_inboxes'])

        put '/api/v1/profile',
            params: { profile: { name: 'renamed' } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(agent.access_token.reload.scopes).to eq(['list_inboxes'])
      end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/controllers/api/v1/profiles_controller_spec.rb -e "persists the access token scopes"`
Expected: FAIL — `agent.access_token.reload.scopes` stays `[]`, the param is silently ignored.

- [ ] **Step 3: Implement scope persistence**

In `app/controllers/api/v1/profiles_controller.rb`:

```ruby
class Api::V1::ProfilesController < Api::BaseController
  before_action :set_user

  def show; end

  def update
    if password_params[:password].present?
      render_could_not_create_error('Invalid current password') and return unless @user.valid_password?(password_params[:current_password])

      @user.update!(password_params.except(:current_password))
    end

    @user.assign_attributes(profile_params)
    @user.custom_attributes.merge!(custom_attributes_params)
    @user.save!

    @user.access_token.update!(scopes: scopes_params) if params[:profile].key?(:scopes)
  end

  def avatar
    @user.avatar.attachment.destroy! if @user.avatar.attached?
    @user.reload
  end

  def auto_offline
    @user.account_users.find_by!(account_id: auto_offline_params[:account_id]).update!(auto_offline: auto_offline_params[:auto_offline] || false)
  end

  def availability
    @user.account_users.find_by!(account_id: availability_params[:account_id]).update!(availability: availability_params[:availability])
  end

  def set_active_account
    @user.account_users.find_by(account_id: profile_params[:account_id]).update(active_at: Time.now.utc)
    head :ok
  end

  def resend_confirmation
    @user.send_confirmation_instructions unless @user.confirmed?
    head :ok
  end

  def reset_access_token
    @user.access_token.regenerate_token
    @user.reload
  end

  private

  def set_user
    @user = current_user
  end

  def availability_params
    params.require(:profile).permit(:account_id, :availability)
  end

  def auto_offline_params
    params.require(:profile).permit(:account_id, :auto_offline)
  end

  def profile_params
    params.require(:profile).permit(
      :email,
      :name,
      :display_name,
      :avatar,
      :message_signature,
      :account_id,
      ui_settings: {}
    )
  end

  def scopes_params
    params.require(:profile).permit(scopes: []).fetch(:scopes, [])
  end

  def custom_attributes_params
    params.require(:profile).permit(:phone_number)
  end

  def password_params
    params.require(:profile).permit(
      :current_password,
      :password,
      :password_confirmation
    )
  end
end
```

- [ ] **Step 4: Run the specs to verify they pass**

Run: `bundle exec rspec spec/controllers/api/v1/profiles_controller_spec.rb`
Expected: all examples passing, including the two new ones.

- [ ] **Step 5: Rubocop and commit**

```bash
bundle exec rubocop -a app/controllers/api/v1/profiles_controller.rb spec/controllers/api/v1/profiles_controller_spec.rb
git add app/controllers/api/v1/profiles_controller.rb spec/controllers/api/v1/profiles_controller_spec.rb
git commit -m "feat(mcp): persist access token scopes through the profile API"
```

---

## Task 4: Store action + API client method for updating scopes

Plain JS (Vuex store module + API client) — no `.vue` file, no styling. Normal implementer, not the `ui` agent. `auth.js` is a shared file other work may be touching concurrently, so check for that first.

**Files:**
- Modify: `app/javascript/dashboard/api/auth.js`
- Modify: `app/javascript/dashboard/store/modules/auth.js`
- Test: `app/javascript/dashboard/store/modules/specs/auth.spec.js` — check if this file exists first (`ls app/javascript/dashboard/store/modules/specs/`); if it doesn't, create it importing only the `actions` needed below rather than the whole module tree, matching how other single-module Vuex spec files in this codebase are structured.

**Interfaces:**
- Consumes: `Api::V1::ProfilesController#update` accepting `profile: { scopes: [...] }` and responding with the full user JSON including `access_token_scopes` (Task 3).
- Produces: `authAPI.updateAccessTokenScopes({ scopes })` → `PUT /api/v1/profile` with body `{ profile: { scopes } }`. Vuex action `updateAccessTokenScopes({ scopes })` → calls the API method, commits `SET_CURRENT_USER` with the response, returns `true` on success / `false` on failure — Task 5's component calls `store.dispatch('updateAccessTokenScopes', { scopes: [...] })`.

- [ ] **Step 1: Check for concurrent edits to `auth.js` before touching it**

Run: `git log --oneline -10` and `git log --since="30 minutes ago" --oneline --all`
If either shows commits touching `app/javascript/dashboard/store/modules/auth.js` or `app/javascript/dashboard/api/auth.js` from outside this session (e.g. a Cursor session) in the last 30 minutes, stop and flag it to the user before proceeding — do not silently overwrite.

- [ ] **Step 2: Write the failing API client test**

Check whether `app/javascript/dashboard/api/specs/auth.spec.js` exists (`ls app/javascript/dashboard/api/specs/ | grep auth`). If it does, add a test there; if not, create `app/javascript/dashboard/api/specs/auth.spec.js` following the pattern of a sibling API spec in that same `specs/` directory (read one first, e.g. `ls app/javascript/dashboard/api/specs/` and open the shortest file to copy its `axios` mocking setup). Add:

```js
describe('#updateAccessTokenScopes', () => {
  it('sends a PUT request with the scopes wrapped under profile', () => {
    axiosMock.onPut('/api/v1/profile').reply(200, { id: 1 });
    authAPI.updateAccessTokenScopes({ scopes: ['list_inboxes', 'add_label'] });
    expect(axiosMock.history.put[0].url).toBe('/api/v1/profile');
    expect(JSON.parse(axiosMock.history.put[0].data)).toEqual({
      profile: { scopes: ['list_inboxes', 'add_label'] },
    });
  });
});
```

Adjust the exact mocking helper names (`axiosMock`, `authAPI` import path) to match whatever the sibling spec file in that directory actually uses — read that file first, this is a template, not a literal copy-paste.

- [ ] **Step 3: Run the test to verify it fails**

Run: `pnpm vitest run app/javascript/dashboard/api/specs/auth.spec.js`
Expected: FAIL — `authAPI.updateAccessTokenScopes` is not a function.

- [ ] **Step 4: Implement the API client method**

In `app/javascript/dashboard/api/auth.js`, add a new method near `updateUISettings` (same JSON-body pattern — `scopes` is an array of strings, not a file, so this must NOT go through `profileUpdate`'s `FormData` path, which would serialize an array incorrectly):

```js
  updateAccessTokenScopes({ scopes }) {
    return axios.put(endPoints('profileUpdate').url, {
      profile: { scopes },
    });
  },
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `pnpm vitest run app/javascript/dashboard/api/specs/auth.spec.js`
Expected: PASS.

- [ ] **Step 6: Write the failing store action test**

In `app/javascript/dashboard/store/modules/specs/auth.spec.js` (create following the pattern of another module's spec under `app/javascript/dashboard/store/modules/specs/`, e.g. read `ls app/javascript/dashboard/store/modules/specs/` and open one that tests an async action against a mocked API import), add:

```js
describe('#updateAccessTokenScopes', () => {
  it('commits the updated user and returns true on success', async () => {
    authAPI.updateAccessTokenScopes.mockResolvedValue({
      data: { id: 1, access_token_scopes: ['list_inboxes'] },
    });
    const commit = vi.fn();

    const result = await actions.updateAccessTokenScopes(
      { commit },
      { scopes: ['list_inboxes'] }
    );

    expect(commit).toHaveBeenCalledWith(types.SET_CURRENT_USER, {
      id: 1,
      access_token_scopes: ['list_inboxes'],
    });
    expect(result).toBe(true);
  });

  it('returns false when the API call fails', async () => {
    authAPI.updateAccessTokenScopes.mockRejectedValue(new Error('failed'));
    const commit = vi.fn();

    const result = await actions.updateAccessTokenScopes(
      { commit },
      { scopes: ['list_inboxes'] }
    );

    expect(result).toBe(false);
  });
});
```

Adjust the exact mocking setup (`vi.mock('../../api/auth')` or equivalent) to match this codebase's existing convention — read a sibling store module spec first.

- [ ] **Step 7: Run the test to verify it fails**

Run: `pnpm vitest run app/javascript/dashboard/store/modules/specs/auth.spec.js`
Expected: FAIL — `actions.updateAccessTokenScopes` is undefined.

- [ ] **Step 8: Implement the store action**

In `app/javascript/dashboard/store/modules/auth.js`, add a new action near `resetAccessToken`, following its try/catch-return-boolean shape:

```js
  updateAccessTokenScopes: async ({ commit }, { scopes }) => {
    try {
      const response = await authAPI.updateAccessTokenScopes({ scopes });
      commit(types.SET_CURRENT_USER, response.data);
      return true;
    } catch (error) {
      return false;
    }
  },
```

- [ ] **Step 9: Run the tests to verify they pass**

Run: `pnpm vitest run app/javascript/dashboard/store/modules/specs/auth.spec.js app/javascript/dashboard/api/specs/auth.spec.js`
Expected: all passing.

- [ ] **Step 10: Lint and commit**

```bash
pnpm eslint:fix app/javascript/dashboard/api/auth.js app/javascript/dashboard/store/modules/auth.js
git add app/javascript/dashboard/api/auth.js app/javascript/dashboard/store/modules/auth.js app/javascript/dashboard/api/specs/auth.spec.js app/javascript/dashboard/store/modules/specs/auth.spec.js
git commit -m "feat(mcp): add store/api support for updating access token scopes"
```

---

## Task 5 (UI task — dispatch to the `ui` agent, then run `design-review`): MCP Permissions settings page

This task touches `.vue` files and a route config file. Per the user's standing workflow preference, it must be executed by the `ui` agent, and its result must go through the `design-review` skill before being marked done — do not implement this task freehand.

**Files:**
- Create: `app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissions.vue`
- Create: `app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissionsForm.vue`
- Create: `app/javascript/dashboard/routes/dashboard/settings/profile/specs/McpPermissionsForm.spec.js`
- Modify: `app/javascript/dashboard/routes/dashboard/settings/profile/profile.routes.js`
- Modify: `app/javascript/dashboard/i18n/locale/en/settings.json`

**Interfaces:**
- Consumes: `currentUser.access_token_scopes` (`string[]`, from Task 2's jbuilder change, already flowing into the Vuex `auth` module's `currentUser` state via the existing `getCurrentUser` getter and `SET_CURRENT_USER` mutation — no new getter needed). `store.dispatch('updateAccessTokenScopes', { scopes })` (Task 4, returns `true`/`false`). `useAccount()`'s `isCloudFeatureEnabled('mcp_integration')` (existing composable at `app/javascript/dashboard/composables/useAccount.js:36-39` — this is the actual exported function name; the design doc's mention of "the `isFeatureEnabledonAccount` getter" refers to the underlying raw Vuex getter that composable wraps, not the name to call from a component).
- Produces: route `profile_settings_mcp` at `/app/accounts/:accountId/profile/mcp`, reachable like the existing `profile_settings_mfa` route.

- [ ] **Step 1: Check for concurrent edits to `profile.routes.js` before touching it**

Run: `git log --oneline -10` and `git log --since="30 minutes ago" --oneline --all`
If either shows commits touching `app/javascript/dashboard/routes/dashboard/settings/profile/profile.routes.js` from outside this session in the last 30 minutes, stop and flag it to the user before proceeding.

- [ ] **Step 2: Add the `mcp` child route**

In `app/javascript/dashboard/routes/dashboard/settings/profile/profile.routes.js`, add an import and a new child route object, following the `mfa` route's shape. No `beforeEnter` redirect guard is needed — unlike MFA (a globally-configured feature with no in-page "disabled" state), this page's own body already handles "MCP is off for this account" by showing a message instead of the checkbox list, so there is nothing to redirect away from:

```js
import { frontendURL } from '../../../../helper/URLHelper';
import { parseBoolean } from '@chatwoot/utils';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import MfaSettings from './MfaSettings.vue';
import McpPermissions from './McpPermissions.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/profile'),
      name: 'profile_settings',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: SettingsWrapper,
      props: {
        hideSideMenu: true,
        fullWidth: true,
      },
      children: [
        {
          path: '',
          redirect: to => ({
            name: 'profile_settings_index',
            params: to.params,
          }),
        },
        {
          path: 'settings',
          name: 'profile_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
        },
        {
          path: 'mfa',
          name: 'profile_settings_mfa',
          component: MfaSettings,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
          beforeEnter: (to, from, next) => {
            // Check if MFA is enabled globally
            if (!parseBoolean(window.newrelayConfig?.isMfaEnabled)) {
              // Redirect to profile settings if MFA is disabled
              next({ name: 'profile_settings_index' });
            } else {
              next();
            }
          },
        },
        {
          path: 'mcp',
          name: 'profile_settings_mcp',
          component: McpPermissions,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
        },
      ],
    },
  ],
};
```

- [ ] **Step 3: Add the i18n strings**

In `app/javascript/dashboard/i18n/locale/en/settings.json`, add a new top-level `MCP_SETTINGS` key (sibling to `PROFILE_SETTINGS`, right after it closes — this page is its own route, like `MFA_SETTINGS` is for the MFA page, but kept in this file rather than a new one since it's a small addition):

```json
  "MCP_SETTINGS": {
    "TITLE": "MCP Permissions",
    "SUBTITLE": "Control which MCP tools your personal access token is allowed to call when connected to an external AI agent.",
    "DISABLED_MESSAGE": "MCP is not enabled for this account. Ask your administrator to enable it to manage tool permissions here.",
    "ACCESS_TOKEN_LINK": "Manage your access token",
    "GROUPS": {
      "READ": "Read",
      "WRITE": "Write"
    },
    "SAVE": "Save",
    "SAVE_SUCCESS": "MCP permissions updated successfully",
    "SAVE_ERROR": "Unable to update MCP permissions. Please try again",
    "TOOLS": {
      "LIST_ACCOUNTS": {
        "LABEL": "List accounts",
        "DESCRIPTION": "List the accounts this token's owner belongs to."
      },
      "LIST_CONVERSATIONS": {
        "LABEL": "List conversations",
        "DESCRIPTION": "List conversations in an inbox or account."
      },
      "GET_CONVERSATION": {
        "LABEL": "Get conversation",
        "DESCRIPTION": "Read a single conversation's details and messages."
      },
      "LIST_CONTACTS": {
        "LABEL": "List contacts",
        "DESCRIPTION": "List contacts in an account."
      },
      "GET_CONTACT": {
        "LABEL": "Get contact",
        "DESCRIPTION": "Read a single contact's details."
      },
      "LIST_INBOXES": {
        "LABEL": "List inboxes",
        "DESCRIPTION": "List the inboxes in an account."
      },
      "LIST_AGENTS": {
        "LABEL": "List agents",
        "DESCRIPTION": "List the agents in an account."
      },
      "LIST_TEAMS": {
        "LABEL": "List teams",
        "DESCRIPTION": "List the teams in an account."
      },
      "LIST_LABELS": {
        "LABEL": "List labels",
        "DESCRIPTION": "List the labels available in an account."
      },
      "ADD_PRIVATE_NOTE": {
        "LABEL": "Add private note",
        "DESCRIPTION": "Add an internal note to a conversation."
      },
      "ADD_LABEL": {
        "LABEL": "Add label",
        "DESCRIPTION": "Apply a label to a conversation."
      },
      "REMOVE_LABEL": {
        "LABEL": "Remove label",
        "DESCRIPTION": "Remove a label from a conversation."
      },
      "ASSIGN_CONVERSATION": {
        "LABEL": "Assign conversation",
        "DESCRIPTION": "Assign a conversation to an agent."
      },
      "SET_PRIORITY": {
        "LABEL": "Set priority",
        "DESCRIPTION": "Change a conversation's priority."
      }
    }
  },
```

Insert it directly after the `PROFILE_SETTINGS` block closes and before `SIDEBAR_ITEMS` begins (run `grep -n '"PROFILE_SETTINGS"\|"SIDEBAR_ITEMS"' app/javascript/dashboard/i18n/locale/en/settings.json` first to find the exact current line numbers, since earlier tasks in this plan don't touch this file but other concurrent work might have shifted them).

- [ ] **Step 4: Write the failing component spec for the presentational form**

Create `app/javascript/dashboard/routes/dashboard/settings/profile/specs/McpPermissionsForm.spec.js`:

```js
import { mount } from '@vue/test-utils';
import McpPermissionsForm from '../McpPermissionsForm.vue';

const ALL_TOOL_NAMES = [
  'list_accounts',
  'list_conversations',
  'get_conversation',
  'list_contacts',
  'get_contact',
  'list_inboxes',
  'list_agents',
  'list_teams',
  'list_labels',
  'add_private_note',
  'add_label',
  'remove_label',
  'assign_conversation',
  'set_priority',
];

describe('McpPermissionsForm.vue', () => {
  it('renders all 14 tools as checkboxes', () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: [] },
    });

    expect(wrapper.findAll('[role="checkbox"]')).toHaveLength(14);
  });

  it('shows every tool checked when initialScopes is empty', () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: [] },
    });

    const checkboxes = wrapper.findAll('[role="checkbox"]');
    checkboxes.forEach(checkbox => {
      expect(checkbox.attributes('aria-checked')).toBe('true');
    });
  });

  it('shows only the scoped tools checked when initialScopes is non-empty', () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: ['list_inboxes', 'add_label'] },
    });

    const checked = wrapper
      .findAll('[role="checkbox"][aria-checked="true"]')
      .map(node => node.attributes('data-tool-name'));

    expect(checked).toEqual(
      expect.arrayContaining(['list_inboxes', 'add_label'])
    );
    expect(checked).toHaveLength(2);
  });

  it('disables Save until a checkbox is toggled', async () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: ['list_inboxes'] },
    });

    expect(wrapper.find('button[type="button"]:last-of-type').attributes('disabled')).toBeDefined();

    await wrapper.find('[data-tool-name="add_label"]').trigger('click');

    expect(
      wrapper.findAll('button').at(-1).attributes('disabled')
    ).toBeUndefined();
  });

  it('emits save with the full explicit list of currently checked tool names', async () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: [] },
    });

    await wrapper.find('[data-tool-name="list_accounts"]').trigger('click');
    await wrapper.findAll('button').at(-1).trigger('click');

    const emitted = wrapper.emitted('save');
    expect(emitted).toHaveLength(1);
    expect(emitted[0][0].sort()).toEqual(
      ALL_TOOL_NAMES.filter(name => name !== 'list_accounts').sort()
    );
  });
});
```

- [ ] **Step 5: Run the spec to verify it fails**

Run: `pnpm vitest run app/javascript/dashboard/routes/dashboard/settings/profile/specs/McpPermissionsForm.spec.js`
Expected: FAIL — `McpPermissionsForm.vue` does not exist yet.

- [ ] **Step 6: Implement `McpPermissionsForm.vue` (presentational, no store dependency)**

Create `app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissionsForm.vue`:

```vue
<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayCheckbox, RelayButton } from 'dashboard/components-next/relay';

const TOOL_GROUPS = [
  {
    key: 'read',
    labelKey: 'MCP_SETTINGS.GROUPS.READ',
    tools: [
      { name: 'list_accounts', labelKey: 'MCP_SETTINGS.TOOLS.LIST_ACCOUNTS.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_ACCOUNTS.DESCRIPTION' },
      { name: 'list_conversations', labelKey: 'MCP_SETTINGS.TOOLS.LIST_CONVERSATIONS.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_CONVERSATIONS.DESCRIPTION' },
      { name: 'get_conversation', labelKey: 'MCP_SETTINGS.TOOLS.GET_CONVERSATION.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.GET_CONVERSATION.DESCRIPTION' },
      { name: 'list_contacts', labelKey: 'MCP_SETTINGS.TOOLS.LIST_CONTACTS.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_CONTACTS.DESCRIPTION' },
      { name: 'get_contact', labelKey: 'MCP_SETTINGS.TOOLS.GET_CONTACT.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.GET_CONTACT.DESCRIPTION' },
      { name: 'list_inboxes', labelKey: 'MCP_SETTINGS.TOOLS.LIST_INBOXES.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_INBOXES.DESCRIPTION' },
      { name: 'list_agents', labelKey: 'MCP_SETTINGS.TOOLS.LIST_AGENTS.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_AGENTS.DESCRIPTION' },
      { name: 'list_teams', labelKey: 'MCP_SETTINGS.TOOLS.LIST_TEAMS.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_TEAMS.DESCRIPTION' },
      { name: 'list_labels', labelKey: 'MCP_SETTINGS.TOOLS.LIST_LABELS.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_LABELS.DESCRIPTION' },
    ],
  },
  {
    key: 'write',
    labelKey: 'MCP_SETTINGS.GROUPS.WRITE',
    tools: [
      { name: 'add_private_note', labelKey: 'MCP_SETTINGS.TOOLS.ADD_PRIVATE_NOTE.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.ADD_PRIVATE_NOTE.DESCRIPTION' },
      { name: 'add_label', labelKey: 'MCP_SETTINGS.TOOLS.ADD_LABEL.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.ADD_LABEL.DESCRIPTION' },
      { name: 'remove_label', labelKey: 'MCP_SETTINGS.TOOLS.REMOVE_LABEL.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.REMOVE_LABEL.DESCRIPTION' },
      { name: 'assign_conversation', labelKey: 'MCP_SETTINGS.TOOLS.ASSIGN_CONVERSATION.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.ASSIGN_CONVERSATION.DESCRIPTION' },
      { name: 'set_priority', labelKey: 'MCP_SETTINGS.TOOLS.SET_PRIORITY.LABEL', descriptionKey: 'MCP_SETTINGS.TOOLS.SET_PRIORITY.DESCRIPTION' },
    ],
  },
];

const ALL_TOOL_NAMES = TOOL_GROUPS.flatMap(group =>
  group.tools.map(tool => tool.name)
);

const props = defineProps({
  initialScopes: { type: Array, default: () => [] },
});

const emit = defineEmits(['save']);

const { t } = useI18n();

const toBaseline = scopes =>
  scopes.length ? [...scopes] : [...ALL_TOOL_NAMES];

const savedTools = ref(toBaseline(props.initialScopes));
const selectedTools = ref(new Set(savedTools.value));

watch(
  () => props.initialScopes,
  newScopes => {
    savedTools.value = toBaseline(newScopes);
    selectedTools.value = new Set(savedTools.value);
  }
);

const isToolSelected = toolName => selectedTools.value.has(toolName);

const toggleTool = toolName => {
  const next = new Set(selectedTools.value);
  if (next.has(toolName)) {
    next.delete(toolName);
  } else {
    next.add(toolName);
  }
  selectedTools.value = next;
};

const isDirty = computed(() => {
  const current = [...selectedTools.value].sort();
  const saved = [...savedTools.value].sort();
  return (
    current.length !== saved.length ||
    current.some((tool, index) => tool !== saved[index])
  );
});

const handleSave = () => {
  const scopes = [...selectedTools.value];
  emit('save', scopes);
  savedTools.value = scopes;
};
</script>

<template>
  <div class="flex flex-col gap-8">
    <div
      v-for="group in TOOL_GROUPS"
      :key="group.key"
      class="flex flex-col gap-4"
    >
      <h3 class="text-sm font-semibold text-foreground">
        {{ t(group.labelKey) }}
      </h3>
      <div
        v-for="tool in group.tools"
        :key="tool.name"
        class="flex items-center justify-between gap-4"
      >
        <div class="max-w-[380px]">
          <div class="text-[13.5px] font-medium text-foreground">
            {{ t(tool.labelKey) }}
          </div>
          <p class="text-xs text-muted-foreground mt-0.5">
            {{ t(tool.descriptionKey) }}
          </p>
        </div>
        <RelayCheckbox
          :data-tool-name="tool.name"
          :model-value="isToolSelected(tool.name)"
          @update:model-value="toggleTool(tool.name)"
        />
      </div>
    </div>
    <div>
      <RelayButton type="button" :disabled="!isDirty" @click="handleSave">
        {{ t('MCP_SETTINGS.SAVE') }}
      </RelayButton>
    </div>
  </div>
</template>
```

- [ ] **Step 7: Run the spec to verify it passes**

Run: `pnpm vitest run app/javascript/dashboard/routes/dashboard/settings/profile/specs/McpPermissionsForm.spec.js`
Expected: all 5 examples passing. If the `RelayCheckbox` component doesn't forward `data-tool-name`/`aria-checked` the way the spec expects, re-check its actual rendered output (`app/javascript/dashboard/components-next/relay/checkbox/Checkbox.vue`) — it sets `:aria-checked` and `role="checkbox"` on its root `<button>`, and `defineOptions({ inheritAttrs: false })` with `v-bind="{ ...attrs, class: undefined }"` means the `data-tool-name` attribute passed from the parent does get forwarded onto that root button; if a mismatch turns up, adjust the spec's selectors to match the actual DOM rather than changing the component's public props.

- [ ] **Step 8: Build the route-level container component**

Create `app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissions.vue`:

```vue
<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import McpPermissionsForm from './McpPermissionsForm.vue';

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const { isCloudFeatureEnabled } = useAccount();

const isMcpEnabled = computed(() => isCloudFeatureEnabled('mcp_integration'));
const scopes = computed(() => currentUser.value.access_token_scopes || []);

const handleSave = async newScopes => {
  const success = await store.dispatch('updateAccessTokenScopes', {
    scopes: newScopes,
  });
  useAlert(
    success ? t('MCP_SETTINGS.SAVE_SUCCESS') : t('MCP_SETTINGS.SAVE_ERROR')
  );
};
</script>

<template>
  <div class="grid w-full">
    <BaseSettingsHeader
      :title="t('MCP_SETTINGS.TITLE')"
      :description="t('MCP_SETTINGS.SUBTITLE')"
      :back-button-label="t('PROFILE_SETTINGS.TITLE')"
    />

    <div class="mt-4 max-w-2xl">
      <p v-if="!isMcpEnabled" class="text-sm text-muted-foreground">
        {{ t('MCP_SETTINGS.DISABLED_MESSAGE') }}
      </p>
      <template v-else>
        <McpPermissionsForm :initial-scopes="scopes" @save="handleSave" />
        <router-link
          :to="{ name: 'profile_settings_index' }"
          class="mt-6 inline-block text-sm font-medium text-primary hover:underline"
        >
          {{ t('MCP_SETTINGS.ACCESS_TOKEN_LINK') }}
        </router-link>
      </template>
    </div>
  </div>
</template>
```

Before writing this file, confirm the exact import path and export names for `useMapGetter`/`useStore` (used as `from './store'` inside `useAccount.js`, i.e. `dashboard/composables/store` — verify with `grep -n "export" app/javascript/dashboard/composables/store.js` since `useAccount.js` imports them via a relative `./store`, and this new file lives one directory deeper) and for `useAlert` (used as `from 'dashboard/composables'` in `Index.vue`). If either path differs from what's written above, use the real one — this is the single most likely spot for an import-path mismatch since this file sits in a different directory than `useAccount.js`.

- [ ] **Step 9: Manually verify the route in the browser**

Start the dev server (`pnpm dev` or the project's usual `overmind start -f ./Procfile.dev`), log in, and navigate to `/app/accounts/:accountId/profile/mcp`:
- With `mcp_integration` disabled for the account (the default): confirm only the disabled message renders, no checkboxes.
- Enable `mcp_integration` for the test account via Super Admin (`/super_admin/accounts/:id/edit` → Features), reload the page: confirm 14 checkboxes render in two groups (Read: 9, Write: 5), all checked by default (empty scopes), Save is disabled until a box is toggled, and clicking Save persists (reload the page and confirm the previous selection survived).

- [ ] **Step 10: Lint and commit**

```bash
pnpm eslint:fix app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissions.vue app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissionsForm.vue app/javascript/dashboard/routes/dashboard/settings/profile/profile.routes.js
git add app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissions.vue app/javascript/dashboard/routes/dashboard/settings/profile/McpPermissionsForm.vue app/javascript/dashboard/routes/dashboard/settings/profile/specs/McpPermissionsForm.spec.js app/javascript/dashboard/routes/dashboard/settings/profile/profile.routes.js app/javascript/dashboard/i18n/locale/en/settings.json
git commit -m "feat(mcp): add MCP Permissions settings page"
```

- [ ] **Step 11: Run `design-review`**

Per the user's standing workflow preference, run the `design-review` skill against this task's output (`McpPermissions.vue`, `McpPermissionsForm.vue`) before considering Task 5 done. Address any findings, re-lint, and amend or add a follow-up commit as the skill's own output directs.

---

## Self-Review Notes

- **Spec coverage:** every section of `docs/superpowers/specs/2026-09-15-mcp-settings-page-design.md` maps to a task — `authorize_scope!` → Task 1; jbuilder/API read → Task 2; `ProfilesController#update` write → Task 3; store/API plumbing → Task 4; route, disabled-state message, grouped checkbox list, explicit Save, access-token link, Relay-only styling → Task 5. The spec's "Testing" section (backend scope spec, controller spec, frontend component spec) is covered by Tasks 1, 2/3, and 5 respectively. The spec's "Out of scope" items (account-wide toggle UI, per-account scoping, conversation/inbox-level enforcement) are correctly not represented by any task here.
- **Naming correction carried into the plan:** the design spec refers to "the existing `isFeatureEnabledonAccount` getter" — that's the raw Vuex getter name; the actual function a component calls is `useAccount()`'s `isCloudFeatureEnabled(feature)` wrapper. Task 5 is written against the real function name, with a step telling the `ui` agent to verify the exact import path against the live file rather than trust the plan's guess, since this is the one place a mismatch is most likely.
- **`BaseSettingsHeader` vs. spec's "SectionLayout":** the design spec's Frontend section names a `SectionLayout` wrapper; no such component exists in this codebase. The real pattern, confirmed by reading `MfaSettings.vue`, is `BaseSettingsHeader` from `../components/BaseSettingsHeader.vue`. Task 5 uses the real component.
- **FormData array bug avoided:** the existing `authAPI.profileUpdate` serializes params through `FormData`, which does not correctly encode an array value (`scopes`) as a Rails-parseable array. Task 4 deliberately adds a separate `updateAccessTokenScopes` API method using a plain JSON body (mirroring `updateUISettings`), not `profileUpdate`, to avoid silently sending `scopes` as a stringified comma-joined value.
