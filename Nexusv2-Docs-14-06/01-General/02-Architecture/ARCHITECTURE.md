# Nexus v2 — System Architecture

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                                  │
│   Next.js 15 (React 19) · TypeScript · Tailwind CSS · Zustand       │
│   App Router · Server Components · TanStack Query · React Flow       │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ REST API (JSON)
                               │ WebSocket (Laravel Reverb / Pusher)
┌──────────────────────────────▼──────────────────────────────────────┐
│                       API GATEWAY LAYER                              │
│   Laravel 11 · PHP 8.2+ · Laravel Sanctum (Bearer Token Auth)       │
│   Route: /api/* · CORS configured for frontend origin               │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         ▼                     ▼                     ▼
┌────────────────┐   ┌──────────────────┐   ┌─────────────────────┐
│  HTTP LAYER    │   │  BROADCAST LAYER  │   │  QUEUE LAYER         │
│  Controllers   │   │  Laravel Reverb   │   │  Laravel Queue       │
│  Middleware    │   │  WebSocket events │   │  Jobs & Listeners    │
│  Form Requests │   │  Real-time push   │   │  llm-inference queue │
└───────┬────────┘   └──────────────────┘   └──────────┬──────────┘
        │                                               │
┌───────▼───────────────────────────────────────────────▼──────────┐
│                      SERVICE LAYER                                │
│  AgentService · ContactHubService · WorkflowExecutor              │
│  MemoryRouter · NotificationService · HedraSoulServices           │
│  AIModelsHub · TaskQueueService · PeopleConnectServices            │
└───────────────────────────────┬───────────────────────────────────┘
                                │
              ┌─────────────────┼──────────────────┐
              ▼                 ▼                  ▼
     ┌────────────────┐ ┌──────────────┐  ┌───────────────────┐
     │  DATA LAYER    │ │ CACHE LAYER  │  │  EXTERNAL AI APIS │
     │  MySQL/SQLite  │ │  Redis       │  │  OpenAI · Claude  │
     │  Eloquent ORM  │ │  File Cache  │  │  Gemini · Groq    │
     │  68 Migrations │ │  Settings    │  │  Custom REST APIs │
     └────────────────┘ └──────────────┘  └───────────────────┘
```

---

## 2. Backend Architecture (Laravel 11)

### 2.1 Layer Responsibilities

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Routes** | `routes/api.php` | URL-to-controller mapping, middleware grouping |
| **Middleware** | `app/Http/Middleware/` | Auth, CORS, rate limiting, idempotency |
| **Controllers** | `app/Http/Controllers/` | Request parsing, response formatting |
| **Form Requests** | `app/Http/Requests/` | Input validation |
| **Services** | `app/Services/` | Business logic, orchestration |
| **Models** | `app/Models/` | Database entities, relationships, casting |
| **Jobs** | `app/Jobs/` | Async background processing |
| **Events & Listeners** | `app/Events/`, `app/Listeners/` | Event-driven decoupled processing |
| **Agents** | `app/Agents/` | AI agent execution strategies |
| **Repositories** | `app/Repositories/` | Data access abstraction |

### 2.2 Request Lifecycle

```
HTTP Request
  → Sanctum Middleware (token validation)
  → Route Matching (api.php)
  → Form Request Validation
  → Controller Method
  → Service Layer (business logic)
  → Model / Eloquent
  → Database
  → Response Formatting (API Resources)
  → JSON Response
```

### 2.3 Event-Driven Processing

```
Action Occurs (e.g., Contact Created)
  → Event fired (ContactCreated)
  → Listener picks up (ProcessContactCreated)
  → Job dispatched (ExtractMemoryJob) to queue
  → Queue worker processes asynchronously
  → WebSocket event broadcast (optional)
  → Frontend receives real-time update
```

### 2.4 AI Request Flow

```
AI Request
  → AiRequestController / AiRouteController
  → IntentRoutingEngine (determine best model)
  → UniversalAiGatewayService
  → DynamicProviderRegistry (find provider)
  → DynamicRestProvider (HTTP call to LLM API)
  → UsageTracker (log tokens, cost)
  → AiAuditTrail (store decision trace)
  → Response returned to caller
```

---

## 3. Frontend Architecture (Next.js 15)

### 3.1 Application Structure

```
Nexus-Frontend/
├── app/                     # Next.js App Router pages
│   ├── (page)/page.tsx      # Dashboard
│   ├── contacts/            # ContactsHub
│   ├── agents/              # AgentsHub
│   ├── tasks/               # TaskHub
│   ├── workflows/           # WorkflowsHub
│   ├── memory/              # MemoryHub
│   ├── ai-models/           # AIModelsHub
│   ├── hedra-soul/          # HedraSoulHub
│   ├── notifications/       # NotificationsHub
│   ├── scheduler/           # SchedulerHub
│   ├── people-connect/      # PeopleConnectHub
│   ├── settings/            # SettingsHub
│   ├── logs/                # LogsHub
│   └── proactive-ai/        # ProactiveAIHub
│
├── components/              # Shared Nx design system components
├── hooks/                   # Custom React hooks
├── lib/                     # API clients, utilities
├── store/                   # Zustand global state
├── context/                 # React contexts
├── types/                   # TypeScript type definitions
└── styles/                  # Global CSS
```

### 3.2 State Management Strategy

| State Type | Tool | Use Case |
|-----------|------|----------|
| **Server state** | TanStack Query | API data fetching, caching, invalidation |
| **Global UI state** | Zustand (`store/index.ts`) | Selected items, modal state, active hub |
| **Component state** | React useState | Local form/UI state |
| **Real-time state** | Laravel Echo + Pusher.js | WebSocket live updates |

### 3.3 API Communication Pattern

```typescript
// All API calls route through lib/api/
const contacts = await api.get('/contacts', { params: { page: 1 } });

// TanStack Query manages caching and refetching
const { data, isLoading } = useQuery({
  queryKey: ['contacts'],
  queryFn: () => fetchContacts(),
});
```

### 3.4 Real-Time Architecture

```typescript
// lib/realtime.ts - Laravel Echo setup
Echo.channel('nexus.dashboard')
  .listen('DashboardUpdated', (e) => { /* update UI */ });

// Hub-specific channels
Echo.private(`nexus.tasks.${taskId}`)
  .listen('TaskProgressUpdated', handler);
```

---

## 4. Hub Architecture Pattern

Every Hub follows the same structural pattern:

### Backend Hub Pattern
```
app/Http/Controllers/{HubName}Controller.php  → REST API endpoints
app/Services/{HubName}Service.php             → Business logic
app/Models/{HubModel}.php                     → Data entity
database/migrations/*_{hub_tables}.php        → Schema
routes/api.php (section)                      → Routes
```

### Frontend Hub Pattern
```
app/{hub-name}/page.tsx                       → Hub main page
app/{hub-name}/components/                    → Hub-specific components
app/{hub-name}/types.ts                       → TypeScript types
lib/api/{hub}.ts                              → API client functions
hooks/use{HubName}.ts                         → Custom hub hook
```

---

## 5. Security Architecture

### Authentication
- **Mechanism**: Laravel Sanctum bearer tokens
- **Token Storage**: Database (`personal_access_tokens` table)
- **Frontend**: Token stored in memory/cookie, sent as `Authorization: Bearer {token}`
- **Expiry**: Configurable via Sanctum config

### Authorization
- **User roles**: `is_admin` flag on users table
- **Admin routes**: Protected by `IsAdmin` middleware
- **Policy classes**: `app/Policies/` for resource-level authorization

### Data Security
- **API keys**: AES-256 encrypted at rest (`CredentialEncryptionService`)
- **Settings**: Sensitive settings encrypted in database
- **CORS**: Configured for frontend origin only
- **Idempotency**: `X-Idempotency-Key` header prevents duplicate operations

---

## 6. Queue & Background Processing

### Queue Configuration
| Queue Name | Purpose | Timeout |
|-----------|---------|---------|
| `llm-inference` | AI model execution | 600s |
| `messages` | Message processing | 120s |
| `memory` | Memory operations | 300s |
| `default` | General jobs | 90s |

### Key Background Jobs
| Job | Trigger | Action |
|-----|---------|--------|
| `ExecuteAiModelJob` | AI request | Run LLM inference with retry |
| `ExtractMemoryJob` | New message/contact | Parse and store memories |
| `SaveToPineconeJob` | Memory created | Vector database storage |
| `VectorizeMemoryJob` | Memory created | Generate embeddings |
| `SyncMemoryJob` | Periodic | Cross-system sync |

---

## 7. Monitoring & Observability

| Feature | Tool |
|---------|------|
| Queue monitoring | Laravel Horizon |
| WebSocket health | `MonitorReverbHealth` command |
| Application logs | `LogsHub` (custom viewer) |
| Dead Letter Queue | `DeadLetterQueueService` |
| AI cost tracking | `UsageLog` model + `AiCostAnalyticsController` |
| System health | `HealthController` at `/api/health` |
| Circuit breaking | `CircuitBreakerService` |

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
