# FRD: Help Center

**Status:** Shipped
**Module:** OSS core, Enterprise (AI-assisted article writing via Captain)
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** A self-service knowledge base — a `Portal` (one per help-center site, can bind a custom domain) contains `Categories` → `Folders` → `Articles`, each translatable per-locale, publicly readable, and searchable.

**Who uses it:** Admins/agents (author articles), end users/contacts (read articles, either standalone or as an `article`-type message inside a conversation — see [02-messages.md](02-messages.md) `content_type: article`).

---

## 2. How it works

1. A `Portal` is the top-level container — `slug` (path-based access via `/hc/:slug`) or `custom_domain` (unique, direct-domain access), branding (`color`, `page_title`, `header_text`, `homepage_link`), and `config` (jsonb, `allowed_locales`, default `["en"]`).
2. A portal can optionally attach to a `channel_web_widget` — surfacing help articles inside the chat widget itself.
3. Structure: `Portal has_many :categories → has_many :folders (through categories) → has_many :articles`. Categories support self-referencing hierarchy (`parent_category_id`) and can be one locale's translation of another (`associated_category_id`), same pattern as articles (`associated_article_id`/`root_article`).
4. Each `Article` has `status` enum (`draft / published / archived`), `locale` (default `en`, unique-per-locale via composite constraints on category/slug), `position` (manual ordering), `views` (read counter), and `meta` (jsonb — SEO fields likely).
5. Multi-locale content works by chaining translated articles/categories via `associated_article_id`/`associated_category_id` back to a `root_article` — not a single row with per-locale columns, but sibling rows linked together.
6. **Public access** is entirely separate from the authenticated dashboard API — `public/api/v1/portals/*` controllers serve the actual help-center website (no login required): `portals#show_root/show/sitemap`, `portals/categories#index/show`, `portals/articles#index/show/show_markdown/tracking_pixel`, `portals/search#index`.
7. Custom domains get clean URLs (no `/hc/:slug` prefix) via a separate constraint-based route block; the default path is `hc/:slug[/:locale]/...`.
8. `show_markdown` serves the raw article content as `.md` (useful for LLM/RAG ingestion — likely used by Captain); `tracking_pixel` serves a `.png` per article view for open/view tracking.
9. **Enterprise AI writing:** `Captain::Articles` jobs + `Onboarding::HelpCenterArticleBuilder`/`HelpCenterArticleWriterJob`/`HelpCenterArticleGenerationJob` can auto-draft articles (e.g. during onboarding) using an LLM; `Captain::Llm::ArticleTranslationService` auto-translates existing articles into other locales.
10. Articles also feed the AI assistant/copilot directly — `Captain::Tools::Copilot::GetArticleService`/`SearchArticlesService` let Captain look up help-center content when answering agent/contact questions, and `LlmFormatter::ArticleLlmFormatter` shapes articles for that context.

---

## 3. Data model

**Table:** `portals`
```
portals
  - account_id: integer, not null
  - name, slug (unique), custom_domain (unique): string
  - color, homepage_link, page_title, header_text: branding
  - config: jsonb, default {"allowed_locales": ["en"]}
  - ssl_settings: jsonb, default {}
  - archived: boolean, default false
  - channel_web_widget_id: bigint (optional)
```

**Table:** `categories`
```
categories
  - account_id, portal_id: integer, not null
  - name, description, icon: string/text
  - slug: string (unique per portal_id + locale)
  - locale: string, default "en"
  - position: integer
  - parent_category_id: bigint (self-referencing hierarchy)
  - associated_category_id: bigint (locale-translation link)
```

**Table:** `folders`
```
folders
  - account_id, category_id: integer, not null
  - name: string
```

**Table:** `articles`
```
articles
  - account_id, portal_id: integer, not null
  - category_id, folder_id: integer (optional)
  - title, description, content: string/text
  - slug: string, unique
  - status: integer          # enum draft:0 published:1 archived:2
  - locale: string, default "en"
  - position, views: integer
  - author_id: bigint (User)
  - associated_article_id: bigint (locale-translation link)
  - meta: jsonb, default {}
```

**Related:** `related_categories` (cross-links between categories, see `spec/models/related_category_spec.rb`).

---

## 4. Backend / API

**Authenticated (dashboard) routes:** `/portals` (+ nested categories/folders/articles CRUD — not individually enumerated here), `POST /portals/:id/clear_portal_custom_domain` (or similar member action).

**Public routes** (no auth):
| Path | Controller#action |
|---|---|
| `GET /`, `/hc`, `/hc/:slug`, `/hc/:slug/:locale` | `portals#show_root` / `#show` |
| `GET /hc/:slug/sitemap.xml` | `portals#sitemap` |
| `GET /:locale/search`, `/hc/:slug/:locale/search` | `portals/search#index` |
| `GET .../categories`, `.../categories/:category_slug` | `portals/categories#index/show` |
| `GET .../articles`, `/articles/:article_slug` | `portals/articles#index/show` |
| `GET .../articles/:article_slug.md` | `portals/articles#show_markdown` |
| `GET .../articles/:article_slug.png` | `portals/articles#tracking_pixel` |

**Enterprise AI:** `app/jobs/enterprise/.../help_center_article_writer_job.rb`, `help_center_article_generation_job.rb`, `app/services/enterprise/.../help_center_article_builder.rb` (via `spec/enterprise/...` paths), `Captain::Llm::ArticleTranslationService`, `Captain::Tools::Copilot::GetArticleService`/`SearchArticlesService`.

**Mailers:** `PortalInstructionsMailer` (e.g. sending portal setup instructions).

---

## 5. Frontend

**Vue:** article authoring/portal management under `dashboard/routes/dashboard/helpcenter/`; the public-facing help-center site itself is a **separate rendering path** (server-rendered or a distinct public SPA — not part of the authenticated dashboard bundle), consistent with the public-controller split noted above.

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/portal_spec.rb`, `category_spec.rb`, `folder_spec.rb`, `article_spec.rb`, `related_category_spec.rb` | model validations, associations |
| `spec/policies/portal_policy_spec.rb`, `article_policy_spec.rb`, `category_policy_spec.rb` + Enterprise variants | authorization |
| `spec/controllers/public/api/v1/portals_controller_spec.rb`, `spec/controllers/public/api/v1/portals/*` | public site endpoints |
| `spec/controllers/api/v1/accounts/articles/*` | authenticated article CRUD |
| `spec/helpers/portal_helper_spec.rb` | rendering helpers |
| `spec/mailers/portal_instructions_mailer_spec.rb` | setup email |
| `spec/services/llm_formatter/article_llm_formatter_spec.rb` | AI-context formatting |
| `spec/enterprise/services/onboarding/help_center_article_builder_spec.rb`, `spec/enterprise/jobs/onboarding/help_center_article_writer_job_spec.rb`, `help_center_article_generation_job_spec.rb` | AI-generated onboarding articles |
| `spec/enterprise/services/captain/llm/article_translation_service_spec.rb` | AI translation |
| `spec/enterprise/services/captain/tools/copilot/get_article_service_spec.rb`, `search_articles_service_spec.rb` | Captain article lookup tools |
| `spec/enterprise/models/enterprise/concerns/portal_spec.rb` | Enterprise portal extensions |

**Coverage gaps observed:** none significant — both the public-facing surface and the AI-assisted authoring paths have dedicated specs.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, Markdown rendering (`.md` article export), LLM (Enterprise — article generation/translation, see Captain AI FRD not yet written)
- Custom domain support implies its own SSL/DNS handling (`ssl_settings` jsonb) — exact provisioning mechanism not verified here

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Article requested in a locale with no translation | Falls back per `associated_article_id`/`root_article` chain — exact fallback-to-default-locale logic not verified here |
| Custom domain not yet configured/verified | `ssl_settings` presumably tracks cert status — verification flow not detailed here |
| Draft/archived article accessed via public URL | Presumably blocked (only `published` should be publicly visible) — worth confirming against `portals/articles_controller.rb`'s scoping |

---

## 9. Price / plan gating

**Gating type:** Mixed — Help Center itself is ungated; embedding search is Business-only.
**`feature_key`(s):** `help_center` (all plans); `help_center_embedding_search` (premium)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes (Help Center) | — | embedding search off |
| Standard | yes (Help Center) | — | embedding search off |
| Business | yes | — | `help_center_embedding_search` on |
| Enterprise | yes | negotiated | |

**Credits / usage:** none (article generation via Captain is billed under [18-captain-ai.md](18-captain-ai.md))
**Enforced by:** `account.feature_enabled?` after `ReconcilePlanFeaturesService`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- Locale-fallback behavior (what a visitor sees when their locale has no translated article) not directly confirmed — worth a quick check if multi-locale help centers are actively used.
- Custom-domain SSL provisioning mechanism (`ssl_settings`) not investigated — flag if custom domains are a priority area.
