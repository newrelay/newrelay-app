# Comment-to-DM Automation (Instagram) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the backend pipeline that turns a keyword Instagram comment into a public reply + private DM, and attributes the resulting Chatwoot contact to the campaign only once they actually engage.

**Architecture:** An isolated `CommentAutomation::` namespace (models, jobs, one service) hangs off the existing Instagram webhook path. It never touches `AutomationRule`. The dedup gate is a single DB unique index — `comment_automation_message_logs(inbox_id, comment_id)` — written *before* any external API call, so a duplicate webhook can never cause a duplicate send. Attribution is one method call added to the existing `Instagram::WebhooksBaseService#find_or_create_contact`, since that's the one place a real DM reply already creates a Chatwoot contact.

**Tech Stack:** Ruby on Rails, Sidekiq/ActiveJob, PostgreSQL, Redis (`Redis::Alfred`), RSpec, HTTParty (direct Graph API calls, matching this repo's existing `Instagram::SendOnInstagramService` / `Channel::Instagram#subscribe` pattern — no new gems).

**Spec:** `docs/solution-notes/comment-to-dm-automation-prd.md` (CEO + eng reviewed) — this plan implements Phases 1–5 of that doc for **Instagram only**. TikTok, short-links, the templates table, and the retention job are explicitly deferred (see Global Constraints).

## Global Constraints

- Instagram only in this plan. TikTok reuses the exact same pattern once this ships — not built here.
- No `comment_automation_short_links` table, no templates table, no retention job in this plan — none of the code in this plan depends on them.
- No `dm_buttons` column and no button/quick-reply support — every trigger sends plain text. Add a `dm_buttons` jsonb column + button rendering only when a real trigger needs it.
- Reuse, don't rebuild: `Redis::Alfred` (`lib/redis/alfred.rb`) for rate limiting, the `pattr_initialize` convention (`attr_extras` gem, already a dependency) for service objects, the `table_name_prefix` namespacing convention from `app/models/reputation.rb`, and the raw `HTTParty.post(url, body:, query: { access_token: })` pattern from `Channel::Instagram#subscribe` / `Instagram::SendOnInstagramService#send_message` for every new Graph API call.
- `Webhooks::InstagramEventsJob` (DM/message events) is not modified in this plan — comment events get their own job so the existing mutex/ordering logic for DMs is never touched.
- Ruby via `rbenv`; run specs with `bundle exec rspec <path>`; RuboCop 150-char line limit (`bundle exec rubocop -a`) applies to every new file.
- Every new external-facing codepath logs `[comment_automation] event=... campaign_id=... trigger_id=... comment_id=...` on success/failure — this is the whole observability story for this plan, no new logging framework.

---

## File Structure

**New files:**
- `db/migrate/20260902000000_create_comment_automation_tables.rb` — 3 tables: campaigns, triggers, message_logs
- `app/models/comment_automation.rb` — namespace module, sets `table_name_prefix`
- `app/models/comment_automation/campaign.rb`
- `app/models/comment_automation/trigger.rb`
- `app/models/comment_automation/message_log.rb`
- `app/services/comment_automation/match_engine.rb` — keyword match + self-comment exclusion
- `app/jobs/comment_automation/inbound_comment_job.rb` — dedup gate + match dispatch
- `app/jobs/comment_automation/public_reply_job.rb` — rotating public reply + jitter
- `app/services/comment_automation/rate_limiter.rb` — per-inbox leaky bucket (fail-closed)
- `app/jobs/comment_automation/dm_dispatch_job.rb` — rate-limited DM send
- `spec/factories/comment_automation/campaign.rb`
- `spec/factories/comment_automation/trigger.rb`
- `spec/factories/comment_automation/message_log.rb`
- `spec/models/comment_automation/campaign_spec.rb`
- `spec/models/comment_automation/trigger_spec.rb`
- `spec/models/comment_automation/message_log_spec.rb`
- `spec/services/comment_automation/match_engine_spec.rb`
- `spec/jobs/comment_automation/inbound_comment_job_spec.rb`
- `spec/jobs/comment_automation/public_reply_job_spec.rb`
- `spec/services/comment_automation/rate_limiter_spec.rb`
- `spec/jobs/comment_automation/dm_dispatch_job_spec.rb`

**Modified files:**
- `app/models/channel/instagram.rb` — add `comments` to the webhook `subscribed_fields`
- `spec/factories/channel/channel_instagram.rb` — update the webmock stub to match
- `spec/models/channel/instagram_spec.rb` — assert the subscribe call includes `comments`
- `app/controllers/webhooks/instagram_controller.rb` — route comment-shaped entries to `CommentAutomation::InboundCommentJob`, leave DM routing untouched
- `spec/controllers/webhooks/instagram_controller_spec.rb` — new routing coverage + regression coverage for existing DM routing
- `app/services/instagram/webhooks_base_service.rb` — one new private method, called from `find_or_create_contact`
- `spec/services/instagram/message_text_spec.rb` — new file testing attribution through `Instagram::MessageText#ensure_contact`

---

### Task 1: Schema — Campaign, Trigger, MessageLog

**Files:**
- Create: `db/migrate/20260902000000_create_comment_automation_tables.rb`
- Create: `app/models/comment_automation.rb`
- Create: `app/models/comment_automation/campaign.rb`
- Create: `app/models/comment_automation/trigger.rb`
- Create: `app/models/comment_automation/message_log.rb`
- Create: `spec/factories/comment_automation/campaign.rb`
- Create: `spec/factories/comment_automation/trigger.rb`
- Create: `spec/factories/comment_automation/message_log.rb`
- Test: `spec/models/comment_automation/campaign_spec.rb`
- Test: `spec/models/comment_automation/trigger_spec.rb`
- Test: `spec/models/comment_automation/message_log_spec.rb`

**Interfaces:**
- Produces: `CommentAutomation::Campaign` (`account`, `inbox`, `name`, `post_id`, `is_active`, `triggers`), `CommentAutomation::Trigger` (`campaign`, `account`, `keyword`, `match_type` enum `exact`/`contains`, `public_replies` array, `dm_text_body`, `message_logs`), `CommentAutomation::MessageLog` (`trigger`, `account`, `inbox`, `contact` optional, `comment_id`, `commenter_id`, `status` enum `pending`/`public_replied`/`dm_sent`/`dm_failed`/`engaged`, `sent_at`) — every later task depends on these three classes and this exact enum vocabulary.

- [ ] **Step 1: Write the migration and run it**

```ruby
# db/migrate/20260902000000_create_comment_automation_tables.rb
class CreateCommentAutomationTables < ActiveRecord::Migration[7.0]
  def change
    create_table :comment_automation_campaigns do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :name, null: false
      t.string :post_id, null: false
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :comment_automation_campaigns, [:account_id, :post_id]

    create_table :comment_automation_triggers do |t|
      t.references :campaign, null: false, foreign_key: { to_table: :comment_automation_campaigns }
      t.references :account, null: false, foreign_key: true
      t.string :keyword
      t.integer :match_type, null: false, default: 0
      t.text :public_replies, array: true, null: false, default: []
      t.text :dm_text_body, null: false
      t.timestamps
    end

    create_table :comment_automation_message_logs do |t|
      t.references :trigger, null: false, foreign_key: { to_table: :comment_automation_triggers }
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :contact, foreign_key: true
      t.string :comment_id, null: false
      t.string :commenter_id, null: false
      t.integer :status, null: false, default: 0
      t.datetime :sent_at
      t.timestamps
    end
    add_index :comment_automation_message_logs, [:inbox_id, :comment_id], unique: true
  end
end
```

Run: `bundle exec rails db:migrate`
Expected: three tables created, `bundle exec rails db:migrate:status` shows the migration as `up`.

- [ ] **Step 2: Write the failing model specs**

```ruby
# spec/models/comment_automation/campaign_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::Campaign do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'is valid with account, inbox, name, and post_id' do
    campaign = described_class.new(account: account, inbox: inbox, name: 'Launch Post', post_id: '17895695668004550')
    expect(campaign).to be_valid
  end

  it 'is invalid without a post_id' do
    campaign = described_class.new(account: account, inbox: inbox, name: 'Launch Post')
    expect(campaign).not_to be_valid
    expect(campaign.errors[:post_id]).to be_present
  end

  it 'defaults is_active to true' do
    campaign = described_class.create!(account: account, inbox: inbox, name: 'Launch Post', post_id: '17895695668004550')
    expect(campaign.is_active).to be true
  end
end
```

```ruby
# spec/models/comment_automation/trigger_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::Trigger do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }

  it 'is valid with a keyword, match_type, public_replies, and dm_text_body' do
    trigger = described_class.new(
      campaign: campaign, account: account, keyword: 'price', match_type: :contains,
      public_replies: ['Thanks! Check your DMs.'], dm_text_body: 'Here is the info you asked for.'
    )
    expect(trigger).to be_valid
  end

  it 'is invalid without dm_text_body' do
    trigger = described_class.new(campaign: campaign, account: account, match_type: :contains, public_replies: ['hi'])
    expect(trigger).not_to be_valid
    expect(trigger.errors[:dm_text_body]).to be_present
  end

  it 'is invalid with an empty public_replies array' do
    trigger = described_class.new(campaign: campaign, account: account, match_type: :contains, dm_text_body: 'hi', public_replies: [])
    expect(trigger).not_to be_valid
    expect(trigger.errors[:public_replies]).to be_present
  end
end
```

```ruby
# spec/models/comment_automation/message_log_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::MessageLog do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account) }

  it 'is valid with a trigger, account, inbox, comment_id, and commenter_id' do
    log = described_class.new(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-1')
    expect(log).to be_valid
  end

  it 'defaults status to pending' do
    log = described_class.create!(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-1')
    expect(log.status).to eq 'pending'
  end

  it 'rejects a duplicate comment_id within the same inbox at the database level' do
    described_class.create!(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-1')
    duplicate = described_class.new(trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1', commenter_id: 'commenter-2')

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
```

- [ ] **Step 3: Run the specs to verify they fail**

Run: `bundle exec rspec spec/models/comment_automation/ -v`
Expected: FAIL with `uninitialized constant CommentAutomation` (no factories/models exist yet).

- [ ] **Step 4: Write the factories**

```ruby
# spec/factories/comment_automation/campaign.rb
FactoryBot.define do
  factory :comment_automation_campaign, class: 'CommentAutomation::Campaign' do
    account
    inbox
    sequence(:name) { |n| "Campaign #{n}" }
    sequence(:post_id) { |n| "post-#{n}" }
  end
end
```

```ruby
# spec/factories/comment_automation/trigger.rb
FactoryBot.define do
  factory :comment_automation_trigger, class: 'CommentAutomation::Trigger' do
    association :campaign, factory: :comment_automation_campaign
    account
    match_type { :contains }
    public_replies { ['Thanks for your comment!'] }
    dm_text_body { 'Here is the information you asked for.' }
  end
end
```

```ruby
# spec/factories/comment_automation/message_log.rb
FactoryBot.define do
  factory :comment_automation_message_log, class: 'CommentAutomation::MessageLog' do
    association :trigger, factory: :comment_automation_trigger
    account
    inbox
    sequence(:comment_id) { |n| "comment-#{n}" }
    sequence(:commenter_id) { |n| "commenter-#{n}" }
  end
end
```

- [ ] **Step 5: Write the models**

```ruby
# app/models/comment_automation.rb
module CommentAutomation
  def self.table_name_prefix
    'comment_automation_'
  end
end
```

```ruby
# app/models/comment_automation/campaign.rb
class CommentAutomation::Campaign < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  has_many :triggers, class_name: 'CommentAutomation::Trigger', foreign_key: :campaign_id, dependent: :destroy, inverse_of: :campaign

  validates :name, presence: true
  validates :post_id, presence: true
end
```

```ruby
# app/models/comment_automation/trigger.rb
class CommentAutomation::Trigger < ApplicationRecord
  belongs_to :campaign, class_name: 'CommentAutomation::Campaign'
  belongs_to :account
  has_many :message_logs, class_name: 'CommentAutomation::MessageLog', foreign_key: :trigger_id, dependent: :destroy, inverse_of: :trigger

  enum match_type: { exact: 0, contains: 1 }

  validates :dm_text_body, presence: true
  validates :public_replies, presence: true
end
```

```ruby
# app/models/comment_automation/message_log.rb
class CommentAutomation::MessageLog < ApplicationRecord
  belongs_to :trigger, class_name: 'CommentAutomation::Trigger'
  belongs_to :account
  belongs_to :inbox
  belongs_to :contact, optional: true

  enum status: { pending: 0, public_replied: 1, dm_sent: 2, dm_failed: 3, engaged: 4 }

  validates :comment_id, presence: true
  validates :commenter_id, presence: true
end
```

- [ ] **Step 6: Run the specs to verify they pass**

Run: `bundle exec rspec spec/models/comment_automation/ -v`
Expected: PASS, 9 examples, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add db/migrate/20260902000000_create_comment_automation_tables.rb db/schema.rb \
        app/models/comment_automation.rb app/models/comment_automation/ \
        spec/factories/comment_automation/ spec/models/comment_automation/
git commit -m "feat(comment-automation): add campaign, trigger, and message_log schema"
```

---

### Task 2: Instagram channel subscribes to comment webhooks

**Files:**
- Modify: `app/models/channel/instagram.rb`
- Modify: `spec/factories/channel/channel_instagram.rb`
- Modify: `spec/models/channel/instagram_spec.rb`

**Interfaces:**
- Consumes: none (standalone infra change).
- Produces: nothing new callable — this only changes which webhook fields Meta actually sends. Task 3 depends on this being done so comment events arrive at all in production, but Task 3's tests don't depend on this task's code.

- [ ] **Step 1: Write the failing spec**

Add to `spec/models/channel/instagram_spec.rb` (append inside the existing `RSpec.describe Channel::Instagram do` block, after the `it 'has a valid name'` block):

```ruby
  it 'subscribes to comment webhooks in addition to messages' do
    expect(WebMock).to have_requested(:post, "https://graph.instagram.com/v22.0/#{channel.instagram_id}/subscribed_apps")
      .with(query: { access_token: channel.access_token, subscribed_fields: %w[messages message_reactions messaging_seen comments] })
  end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/models/channel/instagram_spec.rb -e "subscribes to comment webhooks"`
Expected: FAIL — WebMock raises an unstubbed-request error, because the factory's stub still only expects the old 3-field list and the model still only sends the old 3-field list.

- [ ] **Step 3: Update the factory stub**

In `spec/factories/channel/channel_instagram.rb`, change the `subscribed_fields` array in the `before :create` stub:

```ruby
      WebMock::API.stub_request(:post, "https://graph.instagram.com/v22.0/#{channel.instagram_id}/subscribed_apps")
                  .with(query: {
                          access_token: channel.access_token,
                          subscribed_fields: %w[messages message_reactions messaging_seen comments]
                        })
                  .to_return(status: 200, body: '', headers: {})
```

- [ ] **Step 4: Update the model**

In `app/models/channel/instagram.rb`, change the `subscribed_fields` array inside `#subscribe`:

```ruby
  def subscribe
    # ref https://developers.facebook.com/docs/instagram-platform/webhooks#enable-subscriptions
    HTTParty.post(
      "https://graph.instagram.com/v22.0/#{instagram_id}/subscribed_apps",
      query: {
        subscribed_fields: %w[messages message_reactions messaging_seen comments],
        access_token: access_token
      }
    )
  rescue StandardError => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end
```

- [ ] **Step 5: Run the full Instagram channel spec suite to verify it passes with no regressions**

Run: `bundle exec rspec spec/models/channel/instagram_spec.rb`
Expected: PASS, all examples green (this also proves the factory change didn't break any of the other `let(:channel) { create(:channel_instagram) }` examples in the file).

- [ ] **Step 6: Commit**

```bash
git add app/models/channel/instagram.rb spec/factories/channel/channel_instagram.rb spec/models/channel/instagram_spec.rb
git commit -m "feat(comment-automation): subscribe Instagram channels to comment webhooks"
```

---

### Task 3: Route comment webhooks to a dedicated job

**Files:**
- Modify: `app/controllers/webhooks/instagram_controller.rb`
- Modify: `spec/controllers/webhooks/instagram_controller_spec.rb`

**Interfaces:**
- Consumes: none yet (the job it calls, `CommentAutomation::InboundCommentJob`, is stubbed in this task's tests and built for real in Task 5 — this task only needs the class name to exist as a message target, not a working implementation).
- Produces: every comment-shaped webhook entry (an `entry` hash containing a `changes` array with `field == 'comments'`) gets routed to `CommentAutomation::InboundCommentJob.perform_later(comment_entries)`. Every other entry keeps going to `Webhooks::InstagramEventsJob` exactly as before.

- [ ] **Step 1: Write the failing tests**

Add to `spec/controllers/webhooks/instagram_controller_spec.rb`, inside the existing `describe 'POST /webhooks/instagram' do` block (after the existing `dm_params`/`body` lets and their examples):

```ruby
    context 'with a comment webhook payload' do
      let(:comment_params) do
        {
          object: 'instagram',
          entry: [
            {
              id: 'ig-account-1',
              changes: [
                { field: 'comments', value: { id: 'comment-1', text: 'how much?', from: { id: 'commenter-1' }, media: { id: 'media-1' } } }
              ]
            }
          ]
        }
      end
      let(:comment_body) { comment_params.to_json }

      it 'routes comment entries to CommentAutomation::InboundCommentJob and not to Webhooks::InstagramEventsJob' do
        allow(CommentAutomation::InboundCommentJob).to receive(:perform_later)
        allow(Webhooks::InstagramEventsJob).to receive(:perform_later)

        post_instagram_webhook(comment_body, signature: signature_for(comment_body))

        expect(CommentAutomation::InboundCommentJob).to have_received(:perform_later).with(comment_params[:entry].map(&:deep_stringify_keys))
        expect(Webhooks::InstagramEventsJob).not_to have_received(:perform_later)
      end
    end

    it 'still routes a message-only payload to Webhooks::InstagramEventsJob and not to CommentAutomation::InboundCommentJob' do
      allow(Webhooks::InstagramEventsJob).to receive(:perform_later)
      allow(CommentAutomation::InboundCommentJob).to receive(:perform_later)

      post_instagram_webhook(body)

      expect(Webhooks::InstagramEventsJob).to have_received(:perform_later)
      expect(CommentAutomation::InboundCommentJob).not_to have_received(:perform_later)
    end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bundle exec rspec spec/controllers/webhooks/instagram_controller_spec.rb`
Expected: FAIL on the new comment-routing example (`CommentAutomation::InboundCommentJob` uninitialized, and/or the comment entry still gets sent to `Webhooks::InstagramEventsJob`). The regression example for message-only payloads should already PASS since it re-tests existing behavior.

- [ ] **Step 3: Implement the routing split**

Replace the `events` method and add the two private helpers in `app/controllers/webhooks/instagram_controller.rb`:

```ruby
  def events
    Rails.logger.info('Instagram webhook received events')
    if params['object'].casecmp('instagram').zero?
      entry_params = params.to_unsafe_hash[:entry]

      route_comment_entries(entry_params)
      route_message_entries(entry_params)

      render json: :ok
    else
      Rails.logger.warn("Message is not received from the instagram webhook event: #{params['object']}")
      head :unprocessable_entity
    end
  end
```

```ruby
  def route_comment_entries(entry_params)
    comment_entries = Array(entry_params).select { |entry| comment_entry?(entry.with_indifferent_access) }
    return if comment_entries.blank?

    ::CommentAutomation::InboundCommentJob.perform_later(comment_entries)
  end

  def route_message_entries(entry_params)
    message_entries = Array(entry_params).reject { |entry| comment_entry?(entry.with_indifferent_access) }
    return if message_entries.blank?

    if contains_echo_event?(message_entries)
      ::Webhooks::InstagramEventsJob.set(wait: 2.seconds).perform_later(message_entries)
    else
      ::Webhooks::InstagramEventsJob.perform_later(message_entries)
    end
  end

  def comment_entry?(entry)
    Array(entry[:changes]).any? { |change| change[:field] == 'comments' }
  end
```

Place `route_comment_entries`, `route_message_entries`, and `comment_entry?` in the `private` section, above the existing `contains_echo_event?` method (which is unchanged — it still takes an array of entries and checks each for an echo, now just receiving the pre-filtered `message_entries` instead of the raw `entry_params`).

Since `CommentAutomation::InboundCommentJob` doesn't exist as a real class until Task 5, add a minimal placeholder now so this task's tests (which stub `perform_later` and never execute the real job body) and Rails autoloading both work:

```ruby
# app/jobs/comment_automation/inbound_comment_job.rb
class CommentAutomation::InboundCommentJob < ApplicationJob
  queue_as :default

  def perform(entries); end
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bundle exec rspec spec/controllers/webhooks/instagram_controller_spec.rb`
Expected: PASS, all examples green including the pre-existing DM/verify examples.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/webhooks/instagram_controller.rb app/jobs/comment_automation/inbound_comment_job.rb \
        spec/controllers/webhooks/instagram_controller_spec.rb
git commit -m "feat(comment-automation): route comment webhooks away from the DM job"
```

---

### Task 4: Keyword match engine

**Files:**
- Create: `app/services/comment_automation/match_engine.rb`
- Test: `spec/services/comment_automation/match_engine_spec.rb`

**Interfaces:**
- Consumes: `CommentAutomation::Campaign` (Task 1) with its `triggers` association; a `comment` hash shaped `{ text: String, from: { id: String } }`.
- Produces: `CommentAutomation::MatchEngine.new(campaign:, comment:).match` → returns a `CommentAutomation::Trigger` or `nil`. Task 5 (`InboundCommentJob`) calls exactly this method.

- [ ] **Step 1: Write the failing spec**

```ruby
# spec/services/comment_automation/match_engine_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::MatchEngine do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox, post_id: 'media-1') }

  def comment(text:, from_id: 'commenter-1')
    { text: text, from: { id: from_id } }
  end

  it 'returns the trigger whose keyword is contained in the comment text' do
    trigger = create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'what is the price?')).match

    expect(result).to eq trigger
  end

  it 'returns nil when no trigger keyword matches' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'nice post!')).match

    expect(result).to be_nil
  end

  it 'requires an exact match for exact match_type triggers' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'info', match_type: :exact)

    result = described_class.new(campaign: campaign, comment: comment(text: 'send me info please')).match

    expect(result).to be_nil
  end

  it 'matches case-insensitively' do
    trigger = create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'PRICE', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'what is the price?')).match

    expect(result).to eq trigger
  end

  it 'excludes comments made by the connected account itself' do
    create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains)

    result = described_class.new(campaign: campaign, comment: comment(text: 'the price is $10', from_id: 'ig-account-1')).match

    expect(result).to be_nil
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/services/comment_automation/match_engine_spec.rb`
Expected: FAIL with `uninitialized constant CommentAutomation::MatchEngine`.

- [ ] **Step 3: Write the implementation**

```ruby
# app/services/comment_automation/match_engine.rb
class CommentAutomation::MatchEngine
  pattr_initialize [:campaign!, :comment!]

  def match
    return nil if self_comment?

    campaign.triggers.detect { |trigger| matches?(trigger) }
  end

  private

  def self_comment?
    comment.dig(:from, :id) == campaign.inbox.channel.instagram_id
  end

  def matches?(trigger)
    return true if trigger.keyword.blank?

    normalized_text = comment[:text].to_s.downcase
    normalized_keyword = trigger.keyword.to_s.downcase

    trigger.exact? ? normalized_text == normalized_keyword : normalized_text.include?(normalized_keyword)
  end
end
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `bundle exec rspec spec/services/comment_automation/match_engine_spec.rb`
Expected: PASS, 5 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/services/comment_automation/match_engine.rb spec/services/comment_automation/match_engine_spec.rb
git commit -m "feat(comment-automation): add keyword match engine"
```

---

### Task 5: Inbound comment job — the dedup gate

**Files:**
- Modify: `app/jobs/comment_automation/inbound_comment_job.rb` (replace the Task-3 placeholder body)
- Test: `spec/jobs/comment_automation/inbound_comment_job_spec.rb`

**Interfaces:**
- Consumes: `CommentAutomation::MatchEngine#match` (Task 4); `CommentAutomation::MessageLog` (Task 1); `CommentAutomation::PublicReplyJob` (built in Task 6 — reference it by name now, its real body doesn't exist until Task 6, so add the same kind of minimal placeholder this task needs).
- Produces: `CommentAutomation::InboundCommentJob.perform_later(entries)` where `entries` is the raw array of webhook entry hashes from Task 3's `comment_entries`. On a match, creates exactly one `CommentAutomation::MessageLog` row (`status: pending`) and enqueues `CommentAutomation::PublicReplyJob.perform_later(log.id)`. This is the only place in the whole feature that writes the first `message_logs` row for a comment — every dedup guarantee downstream depends on this being atomic.

- [ ] **Step 1: Add the placeholder PublicReplyJob this task needs**

```ruby
# app/jobs/comment_automation/public_reply_job.rb
class CommentAutomation::PublicReplyJob < ApplicationJob
  queue_as :default

  def perform(message_log_id); end
end
```

- [ ] **Step 2: Write the failing spec**

```ruby
# spec/jobs/comment_automation/inbound_comment_job_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::InboundCommentJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox, post_id: 'media-1') }
  let!(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account, keyword: 'price', match_type: :contains) }

  def comment_entry(comment_id: 'comment-1', text: 'how much is the price?', media_id: 'media-1')
    {
      'id' => 'ig-account-1',
      'changes' => [
        { 'field' => 'comments', 'value' => { 'id' => comment_id, 'text' => text, 'from' => { 'id' => 'commenter-1' }, 'media' => { 'id' => media_id } } }
      ]
    }
  end

  it 'creates a pending message log for a matching comment' do
    expect { described_class.perform_now([comment_entry]) }.to change(CommentAutomation::MessageLog, :count).by(1)

    log = CommentAutomation::MessageLog.last
    expect(log.trigger).to eq trigger
    expect(log.comment_id).to eq 'comment-1'
    expect(log.commenter_id).to eq 'commenter-1'
    expect(log.status).to eq 'pending'
  end

  it 'enqueues CommentAutomation::PublicReplyJob for a matching comment' do
    expect { described_class.perform_now([comment_entry]) }.to have_enqueued_job(CommentAutomation::PublicReplyJob)
  end

  it 'does nothing for a comment with no matching trigger' do
    expect { described_class.perform_now([comment_entry(text: 'nice post!')]) }.not_to change(CommentAutomation::MessageLog, :count)
  end

  it 'does nothing for a comment on a campaign the account has no active campaign for' do
    expect { described_class.perform_now([comment_entry(media_id: 'some-other-post')]) }.not_to change(CommentAutomation::MessageLog, :count)
  end

  it 'does not create a second log or enqueue a second reply for a duplicate comment_id' do
    described_class.perform_now([comment_entry])

    expect { described_class.perform_now([comment_entry]) }.not_to change(CommentAutomation::MessageLog, :count)

    allow(CommentAutomation::PublicReplyJob).to receive(:perform_later)
    described_class.perform_now([comment_entry])
    expect(CommentAutomation::PublicReplyJob).not_to have_received(:perform_later)
  end
end
```

- [ ] **Step 3: Run the spec to verify it fails**

Run: `bundle exec rspec spec/jobs/comment_automation/inbound_comment_job_spec.rb`
Expected: FAIL — the placeholder `perform` method does nothing, so every "creates/enqueues" example fails.

- [ ] **Step 4: Implement the job**

```ruby
# app/jobs/comment_automation/inbound_comment_job.rb
class CommentAutomation::InboundCommentJob < ApplicationJob
  queue_as :default

  def perform(entries)
    Array(entries).each { |entry| process_entry(entry.with_indifferent_access) }
  end

  private

  def process_entry(entry)
    channel = Channel::Instagram.find_by(instagram_id: entry[:id]) || Channel::FacebookPage.find_by(instagram_id: entry[:id])
    return if channel.blank? || channel.inbox.blank?

    Array(entry[:changes]).each do |change|
      next unless change[:field] == 'comments'

      process_comment(channel.inbox, change[:value].with_indifferent_access)
    end
  end

  def process_comment(inbox, comment)
    return if comment[:id].blank?

    campaign = CommentAutomation::Campaign.find_by(account_id: inbox.account_id, post_id: comment.dig(:media, :id), is_active: true)
    return if campaign.blank?

    trigger = CommentAutomation::MatchEngine.new(campaign: campaign, comment: comment).match
    return if trigger.blank?

    log = create_log(trigger, inbox, comment)
    return if log.blank?

    Rails.logger.info("[comment_automation] event=matched campaign_id=#{campaign.id} trigger_id=#{trigger.id} comment_id=#{comment[:id]}")
    CommentAutomation::PublicReplyJob.perform_later(log.id)
  end

  def create_log(trigger, inbox, comment)
    CommentAutomation::MessageLog.create!(
      trigger: trigger, account: inbox.account, inbox: inbox,
      comment_id: comment[:id], commenter_id: comment.dig(:from, :id)
    )
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.info("[comment_automation] event=duplicate_comment comment_id=#{comment[:id]}")
    nil
  end
end
```

- [ ] **Step 5: Run the spec to verify it passes**

Run: `bundle exec rspec spec/jobs/comment_automation/inbound_comment_job_spec.rb`
Expected: PASS, 5 examples, 0 failures.

- [ ] **Step 6: Run Task 3's controller spec again to confirm no regression**

Run: `bundle exec rspec spec/controllers/webhooks/instagram_controller_spec.rb`
Expected: PASS — Task 3's tests stubbed `perform_later` so they're unaffected, but this proves the real class still loads and the routing integration is intact.

- [ ] **Step 7: Commit**

```bash
git add app/jobs/comment_automation/inbound_comment_job.rb spec/jobs/comment_automation/inbound_comment_job_spec.rb
git commit -m "feat(comment-automation): implement the inbound comment dedup gate"
```

---

### Task 6: Public reply job

**Files:**
- Modify: `app/jobs/comment_automation/public_reply_job.rb` (replace the Task-5 placeholder body)
- Create: `app/jobs/comment_automation/dm_dispatch_job.rb` (minimal placeholder, same reason as Task 5's step 1)
- Test: `spec/jobs/comment_automation/public_reply_job_spec.rb`

**Interfaces:**
- Consumes: `CommentAutomation::MessageLog` (Task 1).
- Produces: `CommentAutomation::PublicReplyJob.perform_later(message_log_id)`. On success, updates the log to `status: public_replied` and enqueues `CommentAutomation::DmDispatchJob.perform_later(message_log_id)` after a 3–12 second jitter. On failure, updates the log to `status: dm_failed` (this is the plan's single terminal failure state — see Global Constraints' logging note; no separate "public reply failed" state, matching the spec doc's state machine).

- [ ] **Step 1: Add the placeholder DmDispatchJob this task needs**

```ruby
# app/jobs/comment_automation/dm_dispatch_job.rb
class CommentAutomation::DmDispatchJob < ApplicationJob
  queue_as :default

  def perform(message_log_id); end
end
```

- [ ] **Step 2: Write the failing spec**

```ruby
# spec/jobs/comment_automation/public_reply_job_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::PublicReplyJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account) }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account, public_replies: ['Thanks!', 'Check your DMs!']) }
  let(:log) { create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox, comment_id: 'comment-1') }

  it 'posts a reply to the Instagram comment and marks the log public_replied' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/comment-1/replies').to_return(status: 200, body: '{}')

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'public_replied'
  end

  it 'enqueues CommentAutomation::DmDispatchJob after a successful reply' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/comment-1/replies').to_return(status: 200, body: '{}')

    expect { described_class.perform_now(log.id) }.to have_enqueued_job(CommentAutomation::DmDispatchJob).with(log.id)
  end

  it 'marks the log dm_failed and does not enqueue a DM when the reply call fails' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/comment-1/replies').to_return(status: 400, body: '{"error":"bad request"}')

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'marks the log dm_failed when the network call itself raises a timeout' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/comment-1/replies').to_timeout

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'does nothing if the log is not pending' do
    log.update!(status: :engaged)

    expect { described_class.perform_now(log.id) }.not_to have_enqueued_job(CommentAutomation::DmDispatchJob)
  end
end
```

- [ ] **Step 3: Run the spec to verify it fails**

Run: `bundle exec rspec spec/jobs/comment_automation/public_reply_job_spec.rb`
Expected: FAIL — the placeholder `perform` method does nothing, so status stays `pending` and no HTTP request is made (WebMock would also flag the stub as unused, but the status assertions fail first).

- [ ] **Step 4: Implement the job**

```ruby
# app/jobs/comment_automation/public_reply_job.rb
class CommentAutomation::PublicReplyJob < ApplicationJob
  queue_as :default

  NETWORK_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, SocketError].freeze

  def perform(message_log_id)
    log = CommentAutomation::MessageLog.find_by(id: message_log_id)
    return if log.blank? || !log.pending?

    response = post_reply(log, rotate_reply(log.trigger))

    if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['error'].blank?
      log.update!(status: :public_replied)
      Rails.logger.info("[comment_automation] event=public_replied campaign_id=#{log.trigger.campaign_id} trigger_id=#{log.trigger_id} comment_id=#{log.comment_id}")
      CommentAutomation::DmDispatchJob.set(wait: rand(3..12).seconds).perform_later(log.id)
    else
      fail_log(log, response.parsed_response)
    end
  rescue *NETWORK_ERRORS => e
    fail_log(log, e.message)
  end

  private

  def rotate_reply(trigger)
    replies = trigger.public_replies
    index = trigger.message_logs.count % replies.size
    replies[index]
  end

  def post_reply(log, text)
    HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{log.comment_id}/replies",
      body: { message: text },
      query: { access_token: log.inbox.channel.access_token }
    )
  end

  def fail_log(log, error)
    log.update!(status: :dm_failed)
    Rails.logger.error("[comment_automation] event=public_reply_failed comment_id=#{log.comment_id} error=#{error}")
  end
end
```

- [ ] **Step 5: Run the spec to verify it passes**

Run: `bundle exec rspec spec/jobs/comment_automation/public_reply_job_spec.rb`
Expected: PASS, 5 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/jobs/comment_automation/public_reply_job.rb app/jobs/comment_automation/dm_dispatch_job.rb \
        spec/jobs/comment_automation/public_reply_job_spec.rb
git commit -m "feat(comment-automation): implement the rotating public reply job"
```

---

### Task 7: Per-inbox rate limiter

**Files:**
- Create: `app/services/comment_automation/rate_limiter.rb`
- Test: `spec/services/comment_automation/rate_limiter_spec.rb`

**Interfaces:**
- Consumes: `Redis::Alfred` (`lib/redis/alfred.rb` — `set`, `keys_count`), an `Inbox`.
- Produces: `CommentAutomation::RateLimiter.new(inbox:).within_limit?` (Boolean, fails closed on `Redis::BaseError`) and `#track_send` (records one send in the current 1-second window). Task 8 (`DmDispatchJob`) calls both.

- [ ] **Step 1: Write the failing spec**

```ruby
# spec/services/comment_automation/rate_limiter_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::RateLimiter do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:rate_limiter) { described_class.new(inbox: inbox) }

  it 'is within limit with no recent sends' do
    expect(rate_limiter.within_limit?).to be true
  end

  it 'is over limit after tracking 10 sends in the same window' do
    10.times { rate_limiter.track_send }

    expect(rate_limiter.within_limit?).to be false
  end

  it 'fails closed when Redis raises an error' do
    allow(Redis::Alfred).to receive(:keys_count).and_raise(Redis::BaseError, 'connection lost')

    expect(rate_limiter.within_limit?).to be false
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/services/comment_automation/rate_limiter_spec.rb`
Expected: FAIL with `uninitialized constant CommentAutomation::RateLimiter`.

- [ ] **Step 3: Add the Redis key constants**

In `lib/redis/redis_keys.rb`, add next to the existing `ASSIGNMENT_KEY` / `ASSIGNMENT_KEY_PATTERN` constants:

```ruby
  COMMENT_AUTOMATION_SEND_KEY = 'COMMENT_AUTOMATION::SEND::%<inbox_id>d::%<token>s'.freeze
  COMMENT_AUTOMATION_SEND_KEY_PATTERN = 'COMMENT_AUTOMATION::SEND::%<inbox_id>d::*'.freeze
```

- [ ] **Step 4: Write the implementation**

```ruby
# app/services/comment_automation/rate_limiter.rb
class CommentAutomation::RateLimiter
  LIMIT_PER_SECOND = 10

  pattr_initialize [:inbox!]

  def within_limit?
    current_count < LIMIT_PER_SECOND
  rescue Redis::BaseError => e
    Rails.logger.error("[comment_automation] event=rate_limiter_redis_error error=#{e.message}")
    false # ponytail: fail-closed rate limiter, revisit if legit sends get delayed by Redis blips
  end

  def track_send
    Redis::Alfred.set(send_key, 1, ex: 1)
  end

  private

  def current_count
    Redis::Alfred.keys_count(send_key_pattern)
  end

  def send_key
    format(Redis::RedisKeys::COMMENT_AUTOMATION_SEND_KEY, inbox_id: inbox.id, token: SecureRandom.hex(4))
  end

  def send_key_pattern
    format(Redis::RedisKeys::COMMENT_AUTOMATION_SEND_KEY_PATTERN, inbox_id: inbox.id)
  end
end
```

- [ ] **Step 5: Run the spec to verify it passes**

Run: `bundle exec rspec spec/services/comment_automation/rate_limiter_spec.rb`
Expected: PASS, 3 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add lib/redis/redis_keys.rb app/services/comment_automation/rate_limiter.rb spec/services/comment_automation/rate_limiter_spec.rb
git commit -m "feat(comment-automation): add per-inbox outbound rate limiter"
```

---

### Task 8: DM dispatch job

**Files:**
- Modify: `app/jobs/comment_automation/dm_dispatch_job.rb` (replace the Task-6 placeholder body)
- Test: `spec/jobs/comment_automation/dm_dispatch_job_spec.rb`

**Interfaces:**
- Consumes: `CommentAutomation::MessageLog` (Task 1), `CommentAutomation::RateLimiter` (Task 7).
- Produces: `CommentAutomation::DmDispatchJob.perform_later(message_log_id)`. On success, updates the log to `status: dm_sent, sent_at: Time.current`. On failure, `status: dm_failed`. When over the rate limit, requeues itself 1 second later instead of sending. This is the last automated step before a human replies — Task 9's attribution logic looks for logs left in `dm_sent` by this job.

- [ ] **Step 1: Write the failing spec**

```ruby
# spec/jobs/comment_automation/dm_dispatch_job_spec.rb
require 'rails_helper'

RSpec.describe CommentAutomation::DmDispatchJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account, dm_text_body: 'Here is the link!') }
  let(:log) do
    create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox,
                                             comment_id: 'comment-1', commenter_id: 'commenter-1', status: :public_replied)
  end

  it 'sends a DM and marks the log dm_sent' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/ig-account-1/messages').to_return(status: 200, body: '{}')

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'dm_sent'
    expect(log.sent_at).to be_present
  end

  it 'sends the recipient id and message text from the trigger' do
    stub = stub_request(:post, 'https://graph.instagram.com/v22.0/ig-account-1/messages')
           .with(body: { recipient: { id: 'commenter-1' }, message: { text: 'Here is the link!' } })
           .to_return(status: 200, body: '{}')

    described_class.perform_now(log.id)

    expect(stub).to have_been_requested
  end

  it 'marks the log dm_failed when the API returns an error' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/ig-account-1/messages').to_return(status: 200, body: '{"error":{"message":"bad token"}}')

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'marks the log dm_failed when the network call itself raises a timeout' do
    stub_request(:post, 'https://graph.instagram.com/v22.0/ig-account-1/messages').to_timeout

    described_class.perform_now(log.id)

    expect(log.reload.status).to eq 'dm_failed'
  end

  it 'requeues instead of sending when the inbox is over the rate limit' do
    allow_any_instance_of(CommentAutomation::RateLimiter).to receive(:within_limit?).and_return(false)

    expect { described_class.perform_now(log.id) }.to have_enqueued_job(described_class).with(log.id)
  end

  it 'does nothing if the log is not public_replied' do
    log.update!(status: :pending)

    expect(HTTParty).not_to receive(:post)
    described_class.perform_now(log.id)
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/jobs/comment_automation/dm_dispatch_job_spec.rb`
Expected: FAIL — the placeholder `perform` method does nothing.

- [ ] **Step 3: Implement the job**

```ruby
# app/jobs/comment_automation/dm_dispatch_job.rb
class CommentAutomation::DmDispatchJob < ApplicationJob
  queue_as :default

  NETWORK_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, SocketError].freeze

  def perform(message_log_id)
    log = CommentAutomation::MessageLog.find_by(id: message_log_id)
    return if log.blank? || !log.public_replied?

    rate_limiter = CommentAutomation::RateLimiter.new(inbox: log.inbox)
    unless rate_limiter.within_limit?
      self.class.set(wait: 1.second).perform_later(message_log_id)
      return
    end

    response = send_dm(log)
    rate_limiter.track_send

    if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['error'].blank?
      log.update!(status: :dm_sent, sent_at: Time.current)
      Rails.logger.info("[comment_automation] event=dm_sent campaign_id=#{log.trigger.campaign_id} trigger_id=#{log.trigger_id} comment_id=#{log.comment_id}")
    else
      fail_log(log, response.parsed_response)
    end
  rescue *NETWORK_ERRORS => e
    fail_log(log, e.message)
  end

  private

  def send_dm(log)
    channel = log.inbox.channel
    HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{channel.instagram_id}/messages",
      body: { recipient: { id: log.commenter_id }, message: { text: log.trigger.dm_text_body } },
      query: { access_token: channel.access_token }
    )
  end

  def fail_log(log, error)
    log.update!(status: :dm_failed)
    Rails.logger.error("[comment_automation] event=dm_failed comment_id=#{log.comment_id} error=#{error}")
  end
end
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `bundle exec rspec spec/jobs/comment_automation/dm_dispatch_job_spec.rb`
Expected: PASS, 6 examples, 0 failures.

- [ ] **Step 5: Run the full comment_automation suite to confirm no regressions across tasks**

Run: `bundle exec rspec spec/models/comment_automation/ spec/services/comment_automation/ spec/jobs/comment_automation/ spec/controllers/webhooks/instagram_controller_spec.rb spec/models/channel/instagram_spec.rb`
Expected: PASS, all examples green.

- [ ] **Step 6: Commit**

```bash
git add app/jobs/comment_automation/dm_dispatch_job.rb spec/jobs/comment_automation/dm_dispatch_job_spec.rb
git commit -m "feat(comment-automation): implement rate-limited DM dispatch"
```

---

### Task 9: Attribution — the point of the whole feature

**Files:**
- Modify: `app/services/instagram/webhooks_base_service.rb`
- Create: `spec/services/instagram/message_text_spec.rb`

**Interfaces:**
- Consumes: `CommentAutomation::MessageLog` (Task 1), the existing `@inbox` / `@contact` instance state inside `Instagram::WebhooksBaseService#find_or_create_contact`.
- Produces: when a real Instagram DM arrives from a commenter with a `dm_sent` `CommentAutomation::MessageLog` in that inbox, the resulting `Contact#custom_attributes` gets `comment_automation_campaign_id` / `comment_automation_trigger_id` merged in, and that `MessageLog` transitions to `status: engaged` with `contact` set. This is the gate the entire feature exists to implement — no other task changes `custom_attributes` or the `engaged` status.

- [ ] **Step 1: Write the failing spec**

```ruby
# spec/services/instagram/message_text_spec.rb
require 'rails_helper'

RSpec.describe Instagram::MessageText do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account) }
  let(:service) { described_class.new({}, channel) }

  before do
    service.instance_variable_set(:@inbox, inbox)
    stub_request(:get, /graph\.instagram\.com/).to_return(
      status: 200,
      body: { id: 'commenter-1', name: 'Jane', username: 'jane_doe' }.to_json
    )
  end

  context 'when the commenter has a dm_sent comment automation log' do
    let!(:log) do
      create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox,
                                                comment_id: 'comment-1', commenter_id: 'commenter-1', status: :dm_sent)
    end

    it 'merges campaign attribution onto the new contact' do
      service.ensure_contact('commenter-1')

      contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
      expect(contact.custom_attributes['comment_automation_campaign_id']).to eq campaign.id
      expect(contact.custom_attributes['comment_automation_trigger_id']).to eq trigger.id
    end

    it 'marks the message log engaged and links the new contact' do
      service.ensure_contact('commenter-1')

      contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
      expect(log.reload.status).to eq 'engaged'
      expect(log.contact).to eq contact
    end
  end

  context 'when the commenter has no comment automation log' do
    it 'creates the contact without touching custom_attributes' do
      service.ensure_contact('commenter-1')

      contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
      expect(contact.custom_attributes['comment_automation_campaign_id']).to be_nil
    end
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/services/instagram/message_text_spec.rb`
Expected: FAIL on the two `dm_sent` examples — `custom_attributes['comment_automation_campaign_id']` is `nil` and the log stays `dm_sent` instead of `engaged`, because `find_or_create_contact` doesn't call any attribution logic yet.

- [ ] **Step 3: Implement the attribution hook**

Replace `find_or_create_contact` in `app/services/instagram/webhooks_base_service.rb` and add the new private method below `update_instagram_profile_link`:

```ruby
  def find_or_create_contact(user)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
    @contact = @contact_inbox.contact if @contact_inbox

    if @contact
      update_instagram_profile_link(user)
      apply_comment_automation_attribution(user['id'])
      return
    end

    @contact_inbox = @inbox.channel.create_contact_inbox(
      user['id'], user['name']
    )

    @contact = @contact_inbox.contact
    update_instagram_profile_link(user)
    apply_comment_automation_attribution(user['id'])
    Avatar::AvatarFromUrlJob.perform_later(@contact, user['profile_pic']) if user['profile_pic']
  end
```

```ruby
  def apply_comment_automation_attribution(commenter_id)
    log = CommentAutomation::MessageLog.where(inbox: @inbox, commenter_id: commenter_id, status: :dm_sent).order(created_at: :desc).first
    return if log.blank?

    @contact.update!(custom_attributes: @contact.custom_attributes.merge(
      'comment_automation_campaign_id' => log.trigger.campaign_id,
      'comment_automation_trigger_id' => log.trigger_id
    ))
    log.update!(status: :engaged, contact: @contact)
    Rails.logger.info("[comment_automation] event=engaged campaign_id=#{log.trigger.campaign_id} trigger_id=#{log.trigger_id} contact_id=#{@contact.id}")
  end
```

- [ ] **Step 4: Run the spec to verify it passes**

Run: `bundle exec rspec spec/services/instagram/message_text_spec.rb`
Expected: PASS, 3 examples, 0 failures.

- [ ] **Step 5: Run the full feature suite one more time to confirm nothing regressed**

Run: `bundle exec rspec spec/models/comment_automation/ spec/services/comment_automation/ spec/jobs/comment_automation/ spec/services/instagram/message_text_spec.rb spec/controllers/webhooks/instagram_controller_spec.rb spec/models/channel/instagram_spec.rb`
Expected: PASS, all examples green.

- [ ] **Step 6: Run RuboCop over everything this plan touched**

Run: `bundle exec rubocop -a app/models/comment_automation.rb app/models/comment_automation/ app/services/comment_automation/ app/jobs/comment_automation/ app/models/channel/instagram.rb app/controllers/webhooks/instagram_controller.rb app/services/instagram/webhooks_base_service.rb lib/redis/redis_keys.rb`
Expected: no offenses (or auto-fixed cleanly).

- [ ] **Step 7: Commit**

```bash
git add app/services/instagram/webhooks_base_service.rb spec/services/instagram/message_text_spec.rb
git commit -m "feat(comment-automation): attribute engaged contacts back to their campaign"
```

---

## What ships after Task 9

A working Instagram comment → public reply → DM → attribution pipeline, fully tested, fully reusing existing infra (webhook verification, send patterns, Redis, namespacing convention). Explicitly not built here, per Global Constraints: TikTok (same pattern, separate follow-up), short-links, templates table, retention job, button/quick-reply DMs.

