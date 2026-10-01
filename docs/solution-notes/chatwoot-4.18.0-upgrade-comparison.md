# Chatwoot 4.18.0 — Fork vs. Upstream Comparison

This is a pre-merge comparison. Nothing from [Chatwoot v4.18.0](https://github.com/chatwoot/chatwoot/releases/tag/v4.18.0) has been merged into `feature/ui-changes` yet.

Upstream tag `v4.18.0` is commit `9f920b5` (18 Sep 2026). From `v4.17.1` it is **123 commits**, **1,801 files**, about **+68,500 / −6,900 lines**. Chatwoot’s own note on that release: upgrade for the latest security fixes.

This fork’s last real upstream base is `vendor/chatwoot-4.17.1`. The finished 4.17.1 integration branch (`feature/ui-changes-4.17.1`, tip `76a2c17470`) split from the current line at `b06cdb09b` and was never merged back. A 4.18.0 merge should reconcile that first, or the drift stacks.

## Where our implementation should stay

These areas already exist on the fork and should not be replaced by the upstream 4.18.0 versions.

| Area | Why ours stays |
|---|---|
| Design system | Relay tokens and components. New upstream screens (WhatsApp setup, inbox health, Captain playground, article editor) need a Relay port, not a raw import. |
| Billing / payments | Stripe Checkout plus Razorpay, with `cancel_at_period_end` already on `Subscription`. Upstream’s “cancel at period end” billing change (`#15666`) and the new Shopify billing stack (`app/services/shopify/*`, `ShopifyBilling.vue`) assume Chatwoot Cloud billing, not this marketplace flow. |
| Custom roles / permissions | `captain_manage` and the rest of the fork permission model stay. Captain assignment in 4.18.0 has to go through that model. |
| Conversation, contact, and company UI | Relay conversation chrome, contact detail, and company screens. Upstream’s new thread navigation and filtered-list sorting are behavior to add on top, not a reason to restore their layout. |
| Sidebar | Custom tree chrome, plus Reputation, Companies, and Campaigns. Upstream’s “open sidebar item in a new tab” (`#15833`) collides with that chrome the same way the 4.17.1 sort-menus did. |
| Help Center portals | Custom-domain routing and the locales UI already shipped here. Article upload and diff preview are the pieces worth taking. |
| WhatsApp identity | Incoming BSUID-only messages and phone/BSUID linking already exist in `Whatsapp::IncomingMessageService`. 4.18.0 extends that (campaigns, calls, rotation); it does not replace the handler we have. |

## What 4.18.0 adds that this fork does not have

Checked against the working tree: the new files below are absent.

| Area | Upstream change | Fork today |
|---|---|---|
| Captain assignment | Assistants can be chosen in the assignment dropdown (`#15421`, `#15437`). | No assignment entry. |
| Captain scenarios and tools | Per-assistant toggles for scenarios and tools (`#15571`). | Not present. |
| Captain playground | Test setup and run details (`PlaygroundTestSetup.vue`, `PlaygroundRunDetails.vue`, `#15652`). | Not present. |
| WhatsApp guided setup | Manual inbox setup flow (`WhatsappManualSetup.vue`, `Whatsapp::ManualSetupService`, `#15079`) and clearer account health (`InboxHealthState.vue`). | Not present. |
| WhatsApp BSUID campaigns and calls | Campaigns and calls follow the active BSUID identity (`#15614`, `#15546`, `#15552`). | Incoming messages only. No campaign or call routing. |
| Call recording | Per-inbox recording and transcription settings (`CallRecordingSettings.vue`, `#15621`). Enterprise. | Not present. |
| Delayed automations | Extra conditions on delayed rules (`#15472`). | Not present. |
| Slack | Alerts-only mode (`SlackMessageMode.vue`, `#15605`). | Not present. |
| Conversation history | Jump between a contact’s conversations from the thread (`useContactConversationNavigation.js`, `ContactConversationLink.vue`, `#15427`). | Contact history exists on the contact page. No in-thread navigator. |
| Filtered conversation sort | `Conversations::SortService` (`#15753`). | Not present. |
| Help Center media | Better article uploads (`#15593`) and media previews in the article diff (`#15640`). | Not present. |
| Audit logs | Message deletions stored with the original content (`#15456`). IP masking and sign-in location (`#15455`, `#15752`). Enterprise. | Not present. |
| Email inboxes | SMTP can be saved without IMAP (`#15783`). | `smtp_enabled` and `imap_enabled` exist, but they are still tied together in the inbox form. |
| Inbox HMAC | Rotate the identity-verification secret (`inbox_secret_management.rb`, `HmacSecretKey.vue`, `#15715`). | Not present. |
| Channel identity | Show and store social provider names; hide opaque Facebook/X ids (`#15527`, `#15629`, `#15628`). | Not present. |
| TikTok | Inbox access request (`#15637`). | Not present. |
| Widget | Estonian translations (`#14701`). RTL icon mirroring (`#15714`). | Not present. |
| Timestamps | Exact date on hover, in the user’s locale (`useExactTimestamp.js`, `#15410`, `#15600`). | Not present. |

## Security fixes to take even when the UI stays ours

Upstream calls these out as the reason to upgrade. None of them are in this tree.

| Fix | Why it matters here |
|---|---|
| Sanitize XSS-prone HTML and markdown (`#14050`) | Messages, Help Center, and the widget all render HTML through `HTMLSanitizer`. |
| Verify Slack webhook signatures (`#15480`) | No Slack signature check in this repo. |
| Fetch non-provider SMS media through the safe fetcher, and scope download credentials to the provider host (`#15466`, `#15463`) | SMS and Twilio media paths. |
| Limit app, widget, and admin search indexing (`#15873`) | Search is on by default in several surfaces. |
| Reject invalid conversation parameters (`#15623`) | Public conversation APIs. |
| Widget DirectUpload CSRF (`#13447`) | Help Center and widget uploads. |

## Collisions — decide before merging

| Upstream piece | Recommendation |
|---|---|
| Shopify billing infrastructure (`#15756`) | Leave it out. This fork bills through Stripe and Razorpay, not Shopify subscriptions. |
| Cloud “cancel at period end” UI (`#15666`) | Leave the upstream screen out. Cancellation at period end is already implemented for Stripe and Razorpay. |
| Captain playground, assignment, scenario toggles | Adopt the behavior, then rebuild the screens with Relay components. Do not import Captain’s upstream markup. |
| WhatsApp manual setup and health UI | Adopt the services and controllers. Rebuild `WhatsappManualSetup.vue` and `InboxHealthState.vue` in Relay. |
| In-thread conversation navigation and filtered sort | Adopt the composable and `SortService`. Fit the links into the Relay conversation header, not upstream’s header. |
| Sidebar “open in new tab” | Skip for now. Same collision as the 4.17.1 sidebar sort-menus. |
| Article editor uploads and diff previews | Adopt, then check the editor against the Relay Help Center pages. |
| HMAC secret rotation | Adopt. Small settings control; restyle the key field with Relay inputs. |

## Merge order

1. Reconcile `feature/ui-changes-4.17.1` into the active line, or start the 4.18.0 vendor merge from `vendor/chatwoot-4.17.1` and expect those conflicts again.
2. Merge `chatwoot-upstream/v4.18.0` onto a new `vendor/chatwoot-4.18.0` branch cut from `vendor/chatwoot-4.17.1`.
3. Merge that vendor branch into an `upgrade/4.18.0-merge` branch cut from the current `feature/ui-changes` tip. Keep it a real merge commit.
4. Apply the table above while resolving conflicts, then fill a post-merge ledger in this file (kept / adopted / bugs / gaps) the same way `docs/solution-notes/chatwoot-4.17.1-upgrade-comparison.md` records 4.17.1.
