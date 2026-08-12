# SOD & EOD Updates — Chandresh

**Check-in:** 9:30 AM  **Check-out:** 8:00 PM

> Generated from git commit history. Each entry lists what was planned, in progress, and pushed that day.

---

## Date: 23 06 2026

**Planned Today:**
* Bootstrap DakshAI base codebase and branding
* Rebrand Chatwoot references (README, super admin, translations)
* Local dev / Docker setup

**In Progress:**
* Branding rollout across views, controllers, and title helper

**Completed / Pushed:**
* Initial commit of DakshAI base codebase; rebranded README, contributors, translations, super admin views/controllers
* Added local development setup guide and `run_docker.sh` for any PC/VPS
* Fixed rbenv init in `Procfile.dev`; updated logos

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 24 06 2026

**Planned Today:**
* Finalize dev Docker configuration

**In Progress:**
* Docker dev environment tuning

**Completed / Pushed:**
* Set up dev Docker config (iterated)

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 26 06 2026

**Planned Today:**
* SCRUM-11: Build branding feature UI

**In Progress:**
* Branding view / logo update UI

**Completed / Pushed:**
* Branding feature UI, logo update, and brand view UI changes

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 29 06 2026

**Planned Today:**
* SCRUM-11: Per-account workspace support
* Default feature configuration for new accounts

**In Progress:**
* Workspace-per-account setup and migration fixes

**Completed / Pushed:**
* Workspace per account; fixed ActsAsTaggableOn cache constant & Caching namespace migrations
* Script to create admin + enable all features; default features + enterprise mode
* Skip enrichment for disposable/free email domains

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 30 06 2026

**Planned Today:**
* Sub-account creation with hierarchical validation

**In Progress:**
* Multi-tenancy rules and UI restrictions

**Completed / Pushed:**
* Sub-account creation with hierarchical validation and UI restrictions
* Documented hierarchical multi-tenancy / white-labeling rules

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 03 07 2026

**Planned Today:**
* Contacts overhaul (tasks, companies, bulk audit logs)
* Telephony: Exotel + ElevenLabs voice AI

**In Progress:**
* Voice/Video and Voice AI agent specifications

**Completed / Pushed:**
* Contacts table overhaul; tasks, companies, bulk action audit logs
* Local calling mocks, Exotel webhook, ElevenLabs voice AI agent + seed inbox
* Voice/Video and Voice AI agent spec docs

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 06 07 2026

**Planned Today:**
* Telephony webhook validation fixes
* CRM bulk action logs

**In Progress:**
* Contact labels serialization and creation date fixes

**Completed / Pushed:**
* Fixed E164 phone validation in webhooks + safeguard spec
* Serialized contact labels in listing; bulk action logs; fixed website channel inbox crash
* Fixed contact creation date showing 1970

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 07 07 2026

**Planned Today:**
* Widget integration script copy UX

**In Progress:**
* Clipboard fallback for insecure HTTP

**Completed / Pushed:**
* Dynamic copied-state feedback on integration script copy button
* Fallback copy mechanism for insecure HTTP contexts

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 08 07 2026

**Planned Today:**
* Rebrand DakshAI → newrelay across the app
* Phone number E.164 normalization

**In Progress:**
* Branding: frontend config, devise templates, onboarding, locales

**Completed / Pushed:**
* E.164 normalization + rebrand to newrelay (frontend, devise, onboarding)
* Bulk replaced DakshAI with newrelay in locales/views/controllers
* Updated app.json/AGENTS.md branding, title casing, high-res SVG favicon
* Persistent postgres volume + db rename

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 09 07 2026

**Planned Today:**
* Reputation management module (schemas + settings)

**In Progress:**
* Integrations grid, watermark config

**Completed / Pushed:**
* Reputation module core DB schemas + branding assets
* Settings manager, integrations grid, watermark config
* Relocated solution note to docs

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 10 07 2026

**Planned Today:**
* Google Business Profile integration (manual URL/Place ID)
* Pull actual reviews via Google Places API

**In Progress:**
* Review sync job guards and provider enum alignment

**Completed / Pushed:**
* Replaced Google OAuth with manual business profile URL/Place ID + mock review seeding
* Access token guard on review sync; fixed reviews association + provider enums
* Google Places API review pulling; GBP integration user guide + API key docs
* Fixed Captain OpenRouter endpoints and dev peer verification

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 13 07 2026

**Planned Today:**
* Reputation: video testimonial requests
* OAuth callback + Redis connection refactor

**In Progress:**
* Send Invite button logic and standard review request flow

**Completed / Pushed:**
* Refactored OAuth callback + Redis connection management
* Removed dev-only mock locations; video testimonial request logic + UI
* Reworked Send Invite disabled-button logic; typing email auto-creates contact
* Fixed inactive toggle background color

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 14 07 2026

**Planned Today:**
* White-label custom domain support
* AI Magic Branding feature
* Appearance settings (Light/Dark/Custom)

**In Progress:**
* Theme injection, dark-logo, contrast handling

**Completed / Pushed:**
* Custom domain support + CNAME instructions UI; layout-shift fix
* AI Magic Branding (dialog, LLM schema, authenticated axios)
* Dynamic color injection, client-side image resize, auto-reload on save
* Branding page redesign, dark logo, low-contrast warning, theme-changed event
* Light/Dark/Custom appearance settings; theme override precedence fixes

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 15 07 2026

**Planned Today:**
* Custom branding color persistence + live preview
* Cloudflare domain verification

**In Progress:**
* Subscription management docs + billing UI routing

**Completed / Pushed:**
* Branding color persistence + live preview; legacy config cleanup
* Cloudflare domain verification trigger via enterprise job + error logging
* Subscription management docs + billing UI routing
* Expose server IP for white-labeling; A/AAAA record instructions

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 16 07 2026

**Planned Today:**
* ACME HTTP challenge validation for custom domains
* ColorPicker + theme sync in branding

**In Progress:**
* Cloudflare custom hostname lifecycle + SSL pending states

**Completed / Pushed:**
* ACME HTTP challenge validation; root-domain DNS instructions
* Verify button loading state; DNS scan retry on pending Cloudflare/SSL
* ColorPicker component + theme sync; custom hostname deletion logic
* Multiple theme timing/override fixes (live preview, save, navigation)

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 17 07 2026

**Planned Today:**
* TXT-based Cloudflare SSL validation

**In Progress:**
* Deployment env config lookups

**Completed / Pushed:**
* TXT-based Cloudflare SSL validation; GlobalConfigService no-overwrite guard
* DEPLOYMENT_ENV support in db_fallback config lookups

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 20 07 2026

**Planned Today:**
* Account hierarchy + reseller management
* Marketplace billing infrastructure
* Super Admin plan management

**In Progress:**
* Stripe connected accounts, webhook idempotency, billing grace periods

**Completed / Pushed:**
* Account hierarchy management with reseller flag + super admin dashboard
* Account branding fields, unique custom domain index, Stripe connected accounts
* Marketplace billing infra, commission rules, subscription management
* Webhook idempotency, orphaned tenant rescue, billing failure grace periods
* Plan management with feature toggles + per-agent pricing; mock Stripe session in dev
* Fixed ActiveModel::RangeError (features beyond index 63); Featurable overrides precedence

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 21 07 2026

**Planned Today:**
* 4-tier plan matrix with numeric limit enforcement

**In Progress:**
* Enterprise contracts gating

**Completed / Pushed:**
* 4-tier plan matrix + numeric limit enforcement + enterprise contracts
* Updated docs with gating and plan management implementations

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 22 07 2026

**Planned Today:**
* Enterprise billing plan limits
* Make custom plan matrix source of truth for gating

**In Progress:**
* Subscription limits + enterprise fallback + Stripe handling

**Completed / Pushed:**
* Enterprise billing plan limits; merged plan-specific into default limits
* Custom plan matrix as gating source of truth
* Refined subscription limits, enterprise fallback, Stripe handling

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 23 07 2026

**Planned Today:**
* Self-serve Stripe checkout + enterprise inquiry flow

**In Progress:**
* Data retention wiring

**Completed / Pushed:**
* Self-serve Stripe checkout, enterprise inquiry-to-payment flow, data retention

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 24 07 2026

**Planned Today:**
* Billing fixes (Stripe India, period dates, plan prices)
* Payment transaction history + Captain AI credits

**In Progress:**
* Grace period, enterprise inquiry workflow, plan capability gates

**Completed / Pushed:**
* Fixed Stripe India issue; read subscription period dates from item
* Plan prices in change-plan picker; payment transaction history (user + admin)
* Grace period + enterprise inquiry workflow + plan capability gates
* Buy Captain AI credits via Stripe Checkout

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 28 07 2026

**Planned Today:**
* Razorpay checkout, coupons, admin billing views
* Super Admin payment gateway controls

**In Progress:**
* Gateway routing + Stripe/Razorpay separation

**Completed / Pushed:**
* Plan price per month (not per agent); disabled hub telemetry; Captain top-up invoices
* Razorpay checkout, coupons, admin billing views
* Enterprise contract params fix; hide Stripe portal for Razorpay subs
* Super Admin payment gateway controls + country code autocomplete

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 29 07 2026

**Planned Today:**
* Gateway country routing validation
* Unified billing activity logs + payment failure logging

**In Progress:**
* Relay design system adoption (new-ui shell)

**Completed / Pushed:**
* Gateway country routing validation; unified billing activity logs (Super Admin)
* Multiple billing fixes: coupon-optional checkout, plan picker sync, pricing load, Razorpay/Stripe failure logging, checkout abandonment
* Adopted Relay design system + new-ui shell; Relay AI FAQs UI + BrainCircuit mascot

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 30 07 2026

**Planned Today:**
* Align Relay shell, AI pages, and settings with new-ui

**In Progress:**
* Administration submenu; settings general polish

**Completed / Pushed:**
* Aligned Relay shell, AI pages, settings with new-ui
* Administration submenu + account feature enable script
* Polished settings general pages and Relay AI scenarios

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 31 07 2026

**Planned Today:**
* Polish sidebar brand, integrations, custom domain
* Branding themes, billing, people settings polish

**In Progress:**
* Relay UI consistency pass

**Completed / Pushed:**
* Polished sidebar brand, integrations, custom domain
* Polished branding themes, billing, and people settings

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 03 08 2026

**Planned Today:**
* Redesign Campaigns, Conversations, unified inbox, help center
* Billing plan selection redesign

**In Progress:**
* Message bubble styling decoupling from primary

**Completed / Pushed:**
* Redesigned Campaigns layout, Conversations view, unified notification inbox + empty state
* Bulk article selection controls; help center categories/locales dialogs
* Billing: plan selection cards (RelayButton + badges), current plan card states, 2-column picker
* Onboarding UI redesign with progressive steps; codebase-memory-mcp cursor rules
* Decoupled message bubbles from primary styling

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 04 08 2026

**Planned Today:**
* Help center reference-UI designs
* Contacts table sorting; company management module

**In Progress:**
* Tasks view advanced filtering + integration form restyle

**Completed / Pushed:**
* Applied reference UI to help center (categories, locales, article cards, headers)
* Interactive column sorting for contacts table; company management module + bulk audit filtering
* Tasks view: advanced filtering, deletion, localization
* Fixed case-sensitive RelayButton import paths; audit logs header removal + lint fixes
* Restyled integration forms with modern components

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 05 08 2026

**Planned Today:**
* Super Admin redesign (sidebar submenus, tables, modals)
* Chat detail / reply box redesign

**In Progress:**
* Conversation detail layout + header consolidation

**Completed / Pushed:**
* Redesigned super admin + nested sidebar submenus (new-ui tokens); tables, action icons, enterprise inquiry modal
* Setup pre-loader; inbox list filtering + notification handling
* Navigation guard fix for unauthenticated redirects
* Conversation detail: unified background, grouped header with sidebar, header dropdown actions, arrow pagination
* Redesigned chat reply box + internal note styling to match mockup

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 06 08 2026

**Planned Today:**
* Reply editor tabs/toolbar to match NewRelay UI
* Chat detail header + message bubbles redesign
* Reports redesign (overview, conversations tab)

**In Progress:**
* Conversation list assignee tabs; message bubble width/alignment

**Completed / Pushed:**
* Reply editor tabs + toolbar redesign; footer buttons always visible; removed AI Reply tab (2-tab design)
* Chat detail header (more actions, right sidebar toggle); dropdown solid popover + semantic tokens
* Message bubbles: newrelay background, w-fit max-w-85%, dynamic header badge/id dot colors
* Conversation list: assignee tabs, status in dropdown, hide bulk selection/switch layout
* Reports: overview redesign with Relay tokens, conversations tab metric cards + CSS mini charts, all report tabs

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None

---

## Date: 07 08 2026

**Planned Today:**
* Copilot draggable launcher + welcome popover
* Macros section redesign (flowchart canvas + modal)
* ContactPanel / sidebar UI updates

**In Progress:**
* ContactPanel modernized cards + macro modal fullscreen

**Completed / Pushed:**
* Tabs active text color/spacing; context menu redesign; semantic priority badge colors
* @babel/runtime dev dep to fix vite build; amber/emerald tailwind colors + null-ref fix
* Copilot: draggable launcher with welcome popover; drag vs click fix
* Sidebar hover glow removal; nested menu styling
* Macros: responsive flowchart canvas + sidebar details, fullscreen modal, vertical action inputs, direct modal triggers
* Sidebar danger variant + logout styling; ConversationTabsSeeder + seed script
* ContactPanel redesign (modern cards, typography, spacing)

**Risks / Concerns:** None
**Support Required:** None
**Escalation:** None
