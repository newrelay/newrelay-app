# Chatwoot 4.17.1 Upgrade — Fork vs. Upstream Comparison

This note summarizes how the fork was reconciled with upstream Chatwoot 4.17.1: where our existing implementation was kept because it's more advanced or fork-specific, where upstream's new 4.17.1 work was adopted, and where a deliberate gap was left for follow-up.

Result branch: `feature/ui-changes-4.17.1` (commit `6e4ebe319`, a clean descendant of the pre-upgrade tip — no history was lost).

## Where our implementation was kept

| Area | Why ours wins |
|---|---|
| Design system | Relay semantic tokens (`bg-card`, `text-muted-foreground`, etc.) + `RelayButton`/`RelayInput`/`RelayTooltip` — consistent and themeable. Every upstream feature we adopted was re-skinned onto this system rather than importing upstream's raw components/tokens. |
| Billing / payments | Stripe Checkout redirect flow + a DB-driven `PlanFeatureLimit` system — required for RBI/India payment compliance. Verified against the actual backend services before deciding; upstream's flow assumes a direct off-session charge, which isn't compliant for this fork's market. |
| Custom roles / permissions | `captain_manage` and other custom-role gating layered on top of Chatwoot's base permission model. |
| Conversation card / SharedFiles / ContactInfo | Much richer Relay redesigns (compact file browser, expanded contact panel). Upstream's equivalents were thin stubs by comparison. |
| Sidebar navigation | Custom tree-chrome visual system plus Reputation/Companies/Campaigns nav entries. |
| Conversation header | Relay-based `ConversationProfileSummary` component. |
| Portal settings | Custom-domain routing and nullable-slug support for custom-domain-only portals. |

## Where upstream 4.17.1 was adopted

| Area | What was folded in |
|---|---|
| Captain (AI assistant) | v2 overhaul — FAQ review, outcome tracking, LLM router, generation-details drill-down shown on AI-generated messages. |
| Data Imports | Freshdesk/Intercom migration tooling, restored (the fork had previously removed this). |
| Login / sessions | Concurrent session-limit handling plus a device-picker UI. |
| WhatsApp Account Health | Fuller screen — Business Profile section, grouped health sections, broader status coverage. |
| Teams | Custom emoji icons per team, in both the list view and the create/edit form. |
| API / Webhooks | A feature gate with a paywall state when the account doesn't have API/webhooks access. |
| Meta channels (Facebook/Instagram/TikTok/WhatsApp) | Restriction banners for deactivation/rate-limit messaging. |
| Reports | New drilldown builder and `@chatwoot/viz`-based charts (bar/heatmap/percentage), replacing stale custom chart code — some of which was already dead (referenced `useMemoize` without importing it). |
| Captain assistant settings | Inactivity/auto-resolve warning banners — combined with our existing temperature slider, which upstream had dropped (looked like a regression, not an intentional removal). |
| WhatsApp templates / filters / Copilot editor | Template header preview, a searchable filter dropdown, and a Copilot follow-up submit button in the editor. |
| Emoji picker / reorderable lists | Newer, cleaner slot API and a pagination-aware list API. Our code was calling the old API shape, which would have silently broken once these shared components changed. |

## Bugs found and fixed during the merge

These weren't a "which side is better" call — they were breakage introduced by the merge itself or latent pre-existing bugs surfaced by it:

- `FloatingVue` tooltip plugin was never registered — `v-tooltip` silently did nothing anywhere in the app.
- A missing `globalConfig` store getter in `Dashboard.vue` (`no-undef` — would throw at runtime).
- An unreachable permission check for WhatsApp calling (dead code shadowed by an earlier, more generic check).
- Several dead or duplicate variable declarations left behind by malformed three-way diffs.
- CSS custom properties (`--call-widget`, `--call-widget-border`, etc.) that `CallCard.vue` referenced but that were never defined anywhere in the codebase.

## Deliberate gaps — not yet ported

These upstream features were consciously left out because they conflict with or duplicate an existing fork-specific design, not because they're low value. Flagging for a follow-up decision:

| Feature | Status |
|---|---|
| Sidebar sort-menus and a Data Import nav entry | Not ported — would collide with our custom sidebar tree chrome. |
| Header "unverified session" (HMAC) badge, back-button, and SLA badge | Not ported — our `ConversationProfileSummary` doesn't currently expose these. |
| `FloatingCallWidget` support for multiple simultaneous incoming calls | Not ported. |
| Portal analytics settings UI (GTM/GA4/Hotjar) | Backend support was merged, but no dashboard UI was built to configure it yet. |
