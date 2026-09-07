# FRD: Captain AI

**Status:** Shipped
**Module:** Enterprise (assistants/copilot/RAG live under `enterprise/`), `lib/captain/*` inline-task services are OSS-accessible
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** Chatwoot's AI layer, three distinct surfaces — a contact-facing **Assistant** (autonomous bot that answers/handles conversations via RAG + tools, can hand off to a human), an agent-facing **Copilot** (chat sidebar to help an agent while they work a conversation), and inline **Tasks** (one-shot composer utilities: rewrite, summarize, suggest a reply/label, draft a follow-up).

**Who uses it:** Contacts (talk to the Assistant, often without knowing it's AI), agents (Copilot chat, inline task buttons), admins (configure assistants, connect knowledge sources, define custom tools/scenarios).

---

## 2. How it works

### Assistant (autonomous, conversation-facing)
1. A `Captain::Assistant` belongs to an account, has `config` (jsonb — model choice, etc.), `response_guidelines` and `guardrails` (jsonb arrays — behavioral constraints authored by the admin).
2. An assistant is attached to one or more inboxes via `captain_inboxes` — same "bot owns this inbox" pattern as `AgentBot` (see [04-inboxes.md](04-inboxes.md)).
3. `Captain::Assistant::AgentRunnerService#generate_response` is the core loop: builds conversation/contact/campaign state context, then calls `runner.run(message, context:, max_turns: 100)` using the **`agents` Ruby gem** (an agentic tool-calling framework — not hand-rolled) — this is the actual multi-turn reasoning/tool-use loop, not a single-shot completion.
4. Tools available to the assistant are resolved via `Captain::ToolRegistryService` — built-ins (search docs, look up contact, add label, etc. — see Phase 1/2 FRDs' Captain tool references) plus **custom tools** the account defines themselves (`Captain::CustomTool`: arbitrary HTTP endpoint, method, auth type/config, request/response templates, JSON `param_schema` — lets an account wire the assistant to their own APIs without code).
5. `Captain::Scenario`s are pre-packaged instruction+tool bundles ("when X situation, follow these instructions using these tools") — a way to give the assistant task-specific playbooks beyond its general guidelines, toggleable (`enabled`) per assistant.
6. Knowledge comes from two places: **`Captain::Document`** (crawled/uploaded external content — has `sync_status`/`last_synced_at`, dedup'd per assistant by `md5(external_link)`) and **`Captain::AssistantResponse`** (a FAQ-style Q&A knowledge base with a **pgvector `embedding` column, ivfflat-indexed** — real semantic search, not keyword matching). `Captain::EmbeddingService`/`SearchDocumentationService` do the retrieval.
7. `Captain::ArticleWriterService`, `FaqGeneratorService`, `PaginatedFaqGeneratorService`, `HelpCenterCurationService` can auto-generate/curate documents and FAQs from crawled content (`Firecrawl`/`SimplePageCrawlService`/`HtmlPageParser`/`WebsiteAnalyzerService`) — feeding the RAG knowledge base without manual authoring.
8. `Captain::AssistantActionClassifierService` decides in-conversation whether the assistant should keep answering or hand off to a human (bot-handoff — feeds the `conversation_bot_handoff`/`conversation_captain_inference_handoff` reporting events, see [13-reports.md](13-reports.md)).
9. `Captain::Playground` (`POST /assistants/:id/playground`) lets an admin test-chat with an assistant configuration before deploying it live on an inbox.

### Copilot (agent-facing chat sidebar)
10. `CopilotThread`/`CopilotMessage` — a per-agent, per-conversation-context chat with an assistant, separate from the assistant's autonomous conversation-handling role. `Captain::Assistant::ChatService`/`AssistantChatService` drive this.
11. Copilot has its own tool surface scoped to helping the agent, not the contact — e.g. `Captain::Tools::Copilot::GetArticleService`/`SearchArticlesService` (see [14-help-center.md](14-help-center.md)) let the agent ask "find me the article about X" inline.

### Tasks (inline, one-shot, no agent loop)
12. `lib/captain/*_service.rb` (OSS-accessible, not under `enterprise/`) — `RewriteService`, `SummaryService`, `ReplySuggestionService`, `LabelSuggestionService`, `FollowUpService`, `CsatUtilityAnalysisService` — single-purpose LLM calls triggered by composer buttons (`POST .../tasks/rewrite`, `/summarize`, `/reply_suggestion`, `/label_suggestion`, `/follow_up`). These don't use the agent-loop/tool-calling machinery — simpler, cheaper, faster than the Assistant.

### LLM provider layer
13. `lib/llm/config.rb`, `models.rb` centralize multi-provider support — `config/llm.yml` lists available models across **OpenAI, Anthropic, Gemini**, each with a `credit_multiplier` (ties directly into account billing/usage credits — see [19-billing-subscription.md], not yet written). `Llm::Config.initialize!` is called at the start of each agent run.

---

## 3. Data model

```
captain_assistants
  - account_id, name, description
  - config: jsonb {}              # model/behavior config
  - response_guidelines: jsonb []
  - guardrails: jsonb []

captain_documents
  - assistant_id, account_id, name, external_link, content
  - status, sync_status, last_synced_at, last_sync_attempted_at
  - metadata: jsonb {}
  - unique per (assistant_id, md5(external_link))

captain_assistant_responses      # FAQ knowledge base, RAG source
  - assistant_id, account_id, question, answer
  - embedding: vector(1536), ivfflat-indexed   # pgvector semantic search
  - documentable_id/type: polymorphic source (e.g. generated from a conversation)
  - status, edited: boolean

captain_scenarios
  - assistant_id, account_id, title, description, instruction
  - tools: jsonb []
  - enabled: boolean

captain_custom_tools
  - account_id, slug (unique per account), title, description
  - http_method, endpoint_url, request_template, response_template
  - auth_type, auth_config: jsonb {}
  - param_schema: jsonb []
  - enabled: boolean

captain_inboxes           # assistant ↔ inbox link (bot ownership)
copilot_threads           # title, user_id, account_id, assistant_id
copilot_messages          # (schema not individually inspected; child of copilot_threads)
```

---

## 4. Backend / API

**Routes** (`/api/v1/accounts/:account_id/captain/*`):
| Resource | Notes |
|---|---|
| `assistants` | CRUD + member `playground`, collection `tools` |
| `assistants/:id/inboxes` | bot-to-inbox linking |
| `assistants/:id/scenarios` | scenario CRUD |
| `assistant_responses` | FAQ knowledge base CRUD |
| `custom_tools` | CRUD + `test` (dry-run a custom tool call) |
| `documents` | CRUD + `sync` (re-crawl) |
| `copilot_threads` / `copilot_threads/:id/copilot_messages` | agent chat |
| `bulk_actions` | bulk ops on assistant data |
| `branding`, `preferences` | account-level Captain config |
| `tasks#rewrite/summarize/reply_suggestion/label_suggestion/follow_up` | inline one-shot utilities |

**Engine (Enterprise):** `enterprise/app/services/captain/**` (agent runner, tool registry, embedding/search, article/FAQ generation, chat/playground services), `enterprise/app/models/captain/**`.

**Engine (OSS):** `lib/captain/*_service.rb` (inline tasks).

**LLM layer:** `lib/llm/config.rb`, `models.rb`, `config/llm.yml`, `config/llm_models.json`.

---

## 5. Frontend

**Vue:** assistant configuration UI under `dashboard/components-next/captain/` (per git status: `assistant/DocumentCard.vue`, `assistant/ResponseCard.vue`, `pageComponents/assistant/settings/AssistantSystemSettingsForm.vue` — actively worked on); Copilot sidebar panel inside the conversation view; inline task buttons in the composer/`WootWriter`.

---

## 6. Test coverage (as it exists today)

~99 spec files touch Captain/Copilot — by far the most extensively tested feature area found across this whole review. Representative coverage: `spec/enterprise/models/captain/**`, `spec/enterprise/services/captain/**` (agent runner, tool registry, embedding, article writer, FAQ generation, chat, playground), `spec/enterprise/controllers/api/v1/accounts/captain/**`, `spec/lib/captain/*_spec.rb` (inline task services), `spec/enterprise/lib/captain/tools/**` (individual tool specs, e.g. `add_label_to_conversation_tool_spec.rb`), plus frontend specs for the Vue components under `components-next/captain/`.

**Coverage gaps observed:** none identified — this is the best-tested feature area in the codebase, consistent with it being the most actively developed (per recent git status touching Captain files).

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, **`agents` gem** (agentic tool-calling loop — not hand-rolled), **pgvector** (PostgreSQL extension, `vector`/`ivfflat` — semantic search over `captain_assistant_responses`), Firecrawl (web crawling for document ingestion), OpenAI / Anthropic / Gemini APIs (multi-provider, model-selectable per `config/llm.yml`)
- Frontend: Vue 3, chat/streaming UI components

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Agent loop errors (LLM API failure, tool error, etc.) | Caught in `AgentRunnerService#generate_response`, reported to `ChatwootExceptionTracker`, returns a graceful `error_response` instead of crashing the conversation |
| Assistant run with no conversation context (e.g. rake/local testing) | `account` is treated as optional for exception tracking — doesn't blow up outside a real conversation |
| Document re-crawled with unchanged content | Dedup'd via unique `(assistant_id, md5(external_link))` — re-sync updates rather than duplicates |
| Agent loop runs long | Hard cap `max_turns: 100` prevents runaway tool-calling loops |
| Custom tool misconfigured (bad endpoint, auth) | `test` endpoint lets admin dry-run before enabling it live |

---

## 9. Open gaps / notes

- None significant — this is the most mature, most-tested subsystem reviewed. `credit_multiplier` per model ties directly to account billing usage; cross-reference with the Billing/Subscription FRD (next in this phase) for how credits are actually deducted/enforced — not traced in this pass.
