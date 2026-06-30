# Nexus v2 — Unified Glossary

> This glossary defines all domain terms, hub names, component names, and concepts used throughout the Nexus v2 codebase and documentation. All developers and AI agents should reference this document as the single source of truth for terminology.

---

## A

**Agent** (`App\Models\Agent`)
An AI-powered entity configured with a persona, tools, and skills. Can be of types: Autonomous, Reflection, Supervisor, Specialized, or Team. Agents execute tasks and can be triggered manually or via workflows.

**AgentHub** (`/agents` route)
The frontend hub for creating, managing, and monitoring AI agents. Corresponds to `AgentController` on the backend.

**AgentsHub** = The `/agents` section of the Nexus frontend. Displays agent cards, run history, and status.

**Autonomy Mode** (HedraSoulHub concept)
Controls how independently HedraSoul can act. Five levels:
- `chat_only` — reads and responds to messages only
- `copilot` — suggests actions, user approves
- `operator` — executes low-risk actions automatically
- `autopilot_limited` — acts autonomously within defined safe boundaries
- `emergency_paused` — all autonomous actions suspended

**Approval Gate**
A human-in-the-loop mechanism. When HedraSoul wants to perform a high-risk or costly action, it creates an `HedrasoulApprovalRequest` that must be approved/rejected by a user before execution proceeds.

**AIModelsHub** (`/ai-models` route)
The hub for managing LLM providers, AI models, API keys, routing rules, and cost/budget tracking.

---

## B

**BaseModel** (`App\Models\BaseModel`)
The abstract parent class for all Nexus Eloquent models. Provides UUID primary keys, JSON column helpers, common scopes (`active()`, `inactive()`, `byStatus()`), and consistent timestamp handling.

**Broadcast Channel**
A named channel used by Laravel Reverb (WebSocket) to push real-time events to the frontend. Examples: `nexus.dashboard`, `nexus.tasks.{id}`, `nexus.hedrasoul.{sessionId}`.

**Budget** (AIModelsHub concept)
A per-provider spending cap tracked by `ProviderHealthMonitor`. When budget is exhausted, the provider is deprioritized in routing decisions.

---

## C

**Circuit Breaker** (`CircuitBreakerService`)
A fault-tolerance pattern implementation. After N consecutive failures, the circuit "opens" and subsequent calls to the failing service are rejected immediately (fail-fast) until a recovery period passes.

**Clone Source** (`HedraCloneSource`)
A piece of content ingested from an external source (documents, chat history, emails) that is processed to build the HedraSoul personality profile / memory of the user.

**ContactsHub** (`/contacts` route)
The hub for managing all contacts in the Nexus system. Provides contact listing, search/filtering, contact detail view with timeline, notes, tags, memories, messages, AI analysis, and relationship graphs.

**Contact** (`App\Models\Contact`)
A person or organization entity in Nexus. Has identifiers (email, phone, WhatsApp ID), notes, tags, custom fields, rules, memories, conversations, and AI-analyzed topics. The central entity of the platform.

**ContactIdentifier** (`App\Models\ContactIdentifier`)
A typed lookup key for a contact. Types include: `email`, `phone`, `whatsapp_id`, `external_id`, `username`. Used for identity resolution and deduplication.

**Context Snapshot** (`HedrasoulContextSnapshot`)
A serialized snapshot of HedraSoul's execution context at a given moment — the assembled prompt tokens, active model, persona, and instruction version. Used for auditing and debugging AI decisions.

**Conversation** (`App\Models\Conversation`)
A multi-message thread between a contact and the system (or agent). Has sessions, messages, and is linked to a topic.

---

## D

**Dead Letter Queue (DLQ)**
A special queue where jobs that have exceeded all retry attempts are moved. Managed by `DeadLetterQueueService` and viewable via the admin panel.

**Dynamic Provider Registry** (`DynamicProviderRegistry`)
The core registry in `AIModelsHub` that maps provider configurations to runtime provider instances. Supports OpenAI-compatible and custom REST API providers dynamically.

---

## E

**ECA Rule** (`EcaRule` — Event-Condition-Action Rule)
An automation rule that fires when: an Event occurs + a Condition is met → an Action is executed. Used in the ProactiveAI and notification systems.

**Episodic Memory**
One of the 5 memory types. Stores discrete events that happened ("user mentioned they have a meeting on Friday"). Tied to a specific interaction instance.

---

## F

**Fallback Chain** (`FallbackChainService`)
An ordered list of AI model configurations. When the first model fails (error, rate limit, timeout), execution falls through to the next model in the chain, providing resilience.

**Finding** (`ContactAnalysisFinding`)
A specific insight extracted from a contact's interactions by the AI analysis system. Has a type (e.g., `topic`, `preference`, `emotion`), content, confidence score, and evidence.

---

## G

**Graph Memory** (`GraphMemoryService`)
One of the 5 memory types. Stores relationships between entities (contacts, topics, concepts) as a graph. Used to understand who knows whom and how concepts relate.

---

## H

**HedraSoulHub** (`/hedra-soul` route)
The hub for interacting with and managing the Nexus personal AI assistant (HedraSoul / Souly). Includes: chat interface, session management, autonomy control, approval inbox, memory management, and personality cloning.

**HedraSoul** / **Souly**
The AI entity at the heart of Nexus. Has persistent memory, a cloned personality model of the user, and varying levels of autonomy. The two names refer to the same entity — "HedraSoul" is the feature/hub name, "Souly" is the internal name for the runtime profile and instruction layer.

**Hub**
A self-contained functional domain within Nexus. Each hub has its own frontend route, backend controllers, services, and models. Current hubs: ContactsHub, TaskHub, AgentsHub, WorkflowsHub, MemoryHub, AIModelsHub, HedraSoulHub, NotificationsHub, SchedulerHub, PeopleConnectHub, SettingsHub, LogsHub, ProactiveAIHub.

---

## I

**Idempotency Key** (`X-Idempotency-Key` header)
A client-generated unique key for critical operations (especially contact creation). If the same key is sent twice, the second request returns the first operation's result instead of creating a duplicate. Handled by `IdempotencyService`.

**Intent Routing** (`IntentRoutingEngine`)
The system that analyzes an incoming AI request and determines which model/provider is best suited based on the declared intent (e.g., `code_generation`, `summarization`, `analysis`).

---

## L

**LogsHub** (`/logs` route)
The hub for viewing application logs. Displays structured log entries from `application`, `agent`, `system`, `task`, and `security` channels.

---

## M

**MCP (Model Context Protocol)**
A protocol for connecting AI agents to external tools and data sources. Nexus supports MCP servers, allowing agents to call external APIs and tools via a standardized interface.

**Memory** (`App\Models\Memory`)
A general-purpose knowledge storage unit. Has a type (`episodic`, `semantic`, `structured`, `graph`, `working`), content, confidence score, and vector embedding for semantic search.

**MemoryHub** (`/memory` route)
The hub for viewing, searching, and managing all stored memories across all memory types.

**Memory Router** (`MemoryRouter`)
Determines which memory service to use based on the nature of the content being stored. Routes to one of: EpisodicMemoryService, SemanticMemoryService, StructuredMemoryService, GraphMemoryService, or WorkingMemoryService.

---

## N

**Nexus**
The name of the platform. V2 is the current version, a ground-up rewrite with full AI capabilities.

**NotificationsHub** (`/notifications` route)
The hub for managing notification templates and viewing notification delivery logs.

---

## P

**PeopleConnectHub** (`/people-connect` route)
The hub for live WhatsApp-based conversation management. Integrates with the WAHA API to receive and send WhatsApp messages, matched to Nexus contacts.

**Persona** (`AgentPersona`)
A configured personality and behavior profile for an AI agent. Controls tone, style, capabilities, and interaction approach.

**Proactive AI** / **ProactiveAIHub** (`/proactive-ai` route)
The system that allows Nexus to take action without being explicitly asked. Triggers are defined (time-based, event-based, condition-based) and when fired, actions are executed autonomously.

**Profile Fact** (`HedraProfileFact`)
A specific memory about the user stored in HedraSoul's memory. Memory types include: `working`, `episodic`, `semantic`, `structured`, `graph`, `preference`, `tone_style`, `decision`, `boundary`, `correction`.

---

## R

**Reverb** (Laravel Reverb)
Nexus's WebSocket server, running at port 6001. Replaces Pusher for real-time broadcast. The frontend connects via `laravel-echo` + `pusher-js`.

---

## S

**SchedulerHub** (`/scheduler` route)
The hub for managing time-based automation jobs. Creates and monitors `SchedulerJob` entries that fire on cron schedules.

**Semantic Memory** (`SemanticMemoryService`)
One of the 5 memory types. Stores meaning-based information extracted from interactions ("user prefers formal communication style"). Supports vector-based search.

**SettingsHub** (`/settings` route)
The hub for managing all system settings: AI provider configuration, user preferences, system behavior, and integrations.

**Souly Runtime Profile** (`SoulyRuntimeProfile`)
The active configuration state of HedraSoul at runtime. Defines which model, persona, and instruction version are currently active, plus access permissions (memory access, contact access, workflow execution, etc.).

**Structured Memory** (`StructuredMemoryService`)
One of the 5 memory types. Stores verifiable facts with defined schemas (name, birthday, company, role, etc.).

---

## T

**TaskHub** (`/tasks` route)
The hub for viewing and managing all background tasks — pending, running, completed, and failed. Tasks are created by agents, workflows, or user actions.

**Task** (`AgentTask`)
A discrete unit of work in the system. Has a type, priority, status, and execution logs. Dispatched to the queue and executed by `TaskExecutionService`.

**Topic** (`App\Models\Topic`)
A subject categorization for conversations. Used to group and filter related interactions.

---

## U

**Universal AI Gateway** (`UniversalAiGatewayService`)
The single entry point for all AI LLM calls within Nexus. Abstracts provider differences, handles routing, retries, usage tracking, and audit logging.

---

## W

**WAHA** (WhatsApp HTTP API)
A third-party service that exposes WhatsApp functionality via a REST API. Nexus integrates with WAHA via `WahaMessageDispatcher` and incoming webhooks (`WahaWebhookIngestionService`).

**Working Memory** (`WorkingMemoryService`)
One of the 5 memory types. Ephemeral, in-context state that persists only for the duration of a task or conversation session. Cleared when the session ends.

**WorkflowsHub** (`/workflows` route)
The hub for creating and managing automation workflows. Features a visual canvas built with React Flow, trigger configuration, and execution monitoring.

**Workflow** (`App\Models\Workflow`)
A sequence of steps that automate a process. Can be triggered manually, by schedule, by events, or via webhooks. Has version history and execution logs.

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
