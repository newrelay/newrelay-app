# QA / Testing Guide

How to test this project — running the existing automated suites, seeding data, and manually
verifying the app. The last section is a focused checklist for what's currently changed on
`feature/ui-changes` (Stripe/Razorpay checkout-return sync, signup/login redirects, sidebar
branding, billing page refresh behavior).

## 1. Environment setup

```bash
bundle install && pnpm install
```

Ruby version is managed via `rbenv` — install what `.ruby-version` pins:

```bash
rbenv install $(cat .ruby-version)
eval "$(rbenv init -)"
```

Run the app locally:

```bash
pnpm dev              # overmind start -f ./Procfile.dev — Rails + Vite + workers
```

## 2. Automated test suites

### Backend (RSpec)

```bash
bundle exec rspec                                # full suite
bundle exec rspec spec/path/to/file_spec.rb       # one file
bundle exec rspec spec/path/to/file_spec.rb:42    # one example at line 42
```

Ruby lint:

```bash
bundle exec rubocop -a
```

### Frontend (Vitest)

```bash
pnpm test          # TZ=UTC vitest --no-watch --no-cache --no-coverage
pnpm test:watch    # watch mode while iterating
pnpm test:coverage # with coverage report
```

JS/Vue lint:

```bash
pnpm eslint
pnpm eslint:fix
```

### What CI expects before you open a PR

- `bundle exec rubocop -a` clean
- `pnpm eslint` clean
- `bundle exec rspec` green for any spec file you touched or that covers touched code
- `pnpm test` green for any component/composable you touched

## 3. Seeding test data

```bash
# Minimal data for standard feature verification
bundle exec rails db:seed

# Bulk fixture data for search/performance/manual load testing
bundle exec rails search:setup_test_data

# Richer account data (conversations, contacts, agents) for one account
bundle exec rails runner "Internal::SeedAccountJob.perform_now(Account.find(<id>))"
# or via UI: Super Admin → Accounts → Seed
```

## 4. Manual QA checklist — general areas

Use this as a baseline sweep whenever touching shared UI (sidebar, auth, billing) since those
render on nearly every page.

### Auth (signup / login)

- [ ] Sign up with a new email → redirected to email-verification screen, correct email shown
- [ ] Sign up with an existing email → inline error, no crash
- [ ] Password requirements panel: appears under the password field (not overlapping other
      fields), updates live as you type, all rules resolve to met/unmet correctly
- [ ] Log in with unverified account → redirected to verify-email screen with correct email
      pre-filled
- [ ] Log in with valid verified credentials → lands on dashboard
- [ ] Log in with wrong password → inline error, no redirect

### Dashboard / Sidebar

- [ ] Sidebar loads on all account types (default branding and custom-branded instance)
- [ ] Brand name renders correctly for a self-hosted/white-labeled install (not hardcoded
      "newrelay" when white-labeled)
- [ ] Sidebar navigation (conversations, contacts, reports, settings) all route correctly
- [ ] RTL locale renders sidebar mirrored correctly

### Conversations

- [ ] Open a conversation, send a reply, confirm it appears in the thread
- [ ] Context menu on a conversation row opens and every action is clickable
- [ ] Inbox row actions (mark read/unread, assign, etc.) work from the list view

### Settings

- [ ] Each settings dialog (webhooks, general settings) opens, saves, and closes correctly
- [ ] Form validation errors show inline, not as raw alerts

### Billing

- [ ] Billing settings page loads current plan, usage, and limits
- [ ] Upgrade page shows/hides correctly based on plan and trial status
- [ ] Stripe/Razorpay checkout portal opens correctly

## 5. Focused QA — changes on this branch

These are the areas with real behavioral changes on `feature/ui-changes`. Prioritize these
before merging.

### 5.1 Checkout-return sync (Stripe/Razorpay)

**What changed:** previously, after a Stripe/Razorpay checkout redirect, the billing page waited
for a webhook to unlock the new plan. Now `SyncCheckoutReturnService` actively fetches the
Stripe session / Razorpay subscription on return and fulfills the plan immediately, so the UI
doesn't wait on a possibly-delayed webhook.

Files: [enterprise/app/services/enterprise/billing/sync_checkout_return_service.rb](enterprise/app/services/enterprise/billing/sync_checkout_return_service.rb), [enterprise/app/services/enterprise/billing/handle_stripe_event_service.rb](enterprise/app/services/enterprise/billing/handle_stripe_event_service.rb), [enterprise/app/services/enterprise/billing/record_checkout_abandonment_service.rb](enterprise/app/services/enterprise/billing/record_checkout_abandonment_service.rb), [enterprise/app/controllers/enterprise/api/v1/accounts_controller.rb:122-132](enterprise/app/controllers/enterprise/api/v1/accounts_controller.rb#L122), [app/javascript/dashboard/composables/useBillingCheckoutReturn.js](app/javascript/dashboard/composables/useBillingCheckoutReturn.js), [app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue](app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue)

**Specs to run:**

```bash
bundle exec rspec spec/enterprise/services/enterprise/billing/sync_checkout_return_service_spec.rb
bundle exec rspec spec/enterprise/services/enterprise/billing/handle_stripe_event_service_spec.rb
bundle exec rspec spec/enterprise/services/enterprise/billing/record_checkout_abandonment_service_spec.rb
```

**Manual test — success path (Stripe):**

1. Start a plan checkout from the billing page, complete payment in Stripe test mode.
2. On redirect back (`?checkout_return=success&checkout_session_id=cs_...&checkout_type=plan_checkout&checkout_ref=...`),
   confirm the billing page shows the new plan **without a manual refresh**, even if the Stripe
   webhook hasn't arrived yet.
3. Check server logs — no `[checkout_return] sync failed` warning.
4. Reload the billing page — plan should stay active (idempotent; `already_unlocked?` short-circuits).

**Manual test — cancel/abandon path:**

1. Start checkout, click "back"/cancel on the Stripe page.
2. On redirect (`?checkout_return=cancel&...`), confirm the billing page loads normally (no
   plan change) and a `BillingActivityLog` row with `error_class: checkout_abandoned` is created
   (check via console: `BillingActivityLog.where(account: account, error_class: 'checkout_abandoned').last`).
3. Repeat the same `checkout_ref` — confirm no duplicate abandonment log is written
   (`duplicate_log?` guard).

**Manual test — Razorpay path:** same as above but via Razorpay checkout; confirm
`sync_razorpay_subscription` activates the plan by checking `RAZORPAY_PAID_STATUSES`
(`active`/`authenticated`) trigger `HandleRazorpayEventService`.

**Edge cases to poke at:**
- Tampered `checkout_session_id` for a different account's Stripe session → `session_belongs_to_account?`
  should reject it (plan must NOT unlock).
- Missing/blank `checkout_session_id` on a `success` return → should not throw, falls through
  to Razorpay path and returns `false` gracefully.
- Stripe API error (e.g. invalid/expired session) → rescued, logged as a warning, page still loads.

### 5.2 Billing page account refresh (`accounts/get`)

**What changed:** `accounts/get` no longer requires an account ID argument (always refreshes the
current account); billing page now calls `processCheckoutReturn()` **before**
`fetchAccountDetails()` so the synced plan is reflected on first load, not one refresh later.
Also added `onActivated` to refetch account details when navigating back to a cached billing
page (skipping the very first activation, which `onMounted` already covers).

Files: [app/javascript/dashboard/store/modules/accounts.js](app/javascript/dashboard/store/modules/accounts.js), [app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue](app/javascript/dashboard/routes/dashboard/settings/billing/Index.vue)

**Manual test:**
1. Complete a checkout (see 5.1) → new plan shows immediately on first paint, no flash of stale data.
2. Navigate away from Billing settings to another settings page, then back → account details
   refetch (check network tab for a second `accounts/get`-triggered request), but the very
   first mount doesn't double-fetch.
3. Cancel a Razorpay subscription / cancel an enterprise inquiry → account refreshes and UI
   reflects the change without a manual page reload.

**JS specs:** none exist yet for `useBillingCheckoutReturn.js` or the billing `Index.vue` —
consider adding `vitest` coverage for `buildCheckoutReturnUrls`, `accountHasActivePlan`, and
`waitForActivePlan` polling/timeout behavior if this area sees more changes.

### 5.3 Trial-account gating on Upgrade page

**What changed:** `isTrialAccount` now requires `account.id` and a valid, parseable
`created_at` (previously just truthy `account`), and the trial check moved earlier in
`shouldShowUpgradePage` / `shouldRedirectToBilling` — trial accounts skip the upgrade
interstitial and redirect **regardless of Chatwoot Cloud status**, not only on cloud.

File: [app/javascript/dashboard/routes/dashboard/upgrade/UpgradePage.vue](app/javascript/dashboard/routes/dashboard/upgrade/UpgradePage.vue)

**Manual test:**
- [ ] Account created < 15 days ago, no plan yet → Upgrade page/redirect is **skipped** (trial
      grace period), on both Cloud and self-hosted-style accounts.
- [ ] Account created > 15 days ago with no plan → Upgrade page/redirect **shows** as before.
- [ ] Account with `created_at` missing or unparseable → treated as **not** a trial (fails safe,
      doesn't crash `differenceInDays`).
- [ ] Account with no `id` loaded yet (initial render before account fetch resolves) → treated
      as not a trial, no false negative once the account loads.

### 5.4 Signup / login → verify-email redirect

**What changed:** the redirect to `auth_verify_email` now passes the email via a **query
param** (`?email=...`) instead of `router.push({ state: { email } })`. Vue Router's `state`
option doesn't survive a hard reload/deep link the way a query param does.

Files: [app/javascript/v3/views/auth/signup/components/Signup/Form.vue](app/javascript/v3/views/auth/signup/components/Signup/Form.vue), [app/javascript/v3/views/login/Index.vue](app/javascript/v3/views/login/Index.vue), [app/javascript/v3/views/routes.js](app/javascript/v3/views/routes.js)

**Manual test:**
- [ ] Sign up → verify-email page shows the correct email in its URL (`?email=you@example.com`)
      and pre-filled in the UI.
- [ ] From an unverified login, get redirected to verify-email → same check.
- [ ] Hard-refresh the verify-email page (or open the URL directly) → email still shows
      (this was the actual bug `state` couldn't survive — confirm it's fixed).
- [ ] "Resend email" / whatever action verify-email offers still targets the right address.

### 5.5 Sidebar brand name white-labeling

**What changed:** the sidebar brand name now runs through `replaceInstallationName` from
`useBranding` instead of rendering the raw i18n string.

File: [app/javascript/dashboard/components-next/sidebar/Sidebar.vue](app/javascript/dashboard/components-next/sidebar/Sidebar.vue)

**Manual test:**
- [ ] Default/unbranded instance → sidebar shows the normal product name.
- [ ] Custom-branded / self-hosted install (`isACustomBrandedInstance` true) → brand name in
      sidebar reflects the installation name, not a hardcoded string.

### 5.6 Password requirements panel styling

**What changed:** dropped `absolute top-full start-0 z-50` positioning and `shadow-lg` in
favor of normal in-flow layout with `shadow-sm`.

File: [app/javascript/v3/views/auth/signup/components/Signup/PasswordRequirements.vue](app/javascript/v3/views/auth/signup/components/Signup/PasswordRequirements.vue)

**Manual test:**
- [ ] Panel no longer overlaps content below the password field — it pushes the layout down
      instead of floating over it.
- [ ] No visual clipping/overflow issues on mobile viewport.
- [ ] Check it doesn't now get obscured behind other form elements (it lost `z-50`).

## 6. Suggested run order before opening the PR

```bash
bundle exec rubocop -a
pnpm eslint:fix

bundle exec rspec spec/enterprise/services/enterprise/billing/sync_checkout_return_service_spec.rb \
  spec/enterprise/services/enterprise/billing/handle_stripe_event_service_spec.rb \
  spec/enterprise/services/enterprise/billing/record_checkout_abandonment_service_spec.rb

pnpm test
```

Then walk sections 5.1–5.6 manually in a browser against `pnpm dev`, using Stripe/Razorpay test
mode for the checkout flows.
