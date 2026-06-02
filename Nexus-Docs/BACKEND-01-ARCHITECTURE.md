# Nexus Backend - System Architecture Documentation

**Last Updated**: May 25, 2026  
**Project**: Nexus-Backend (Laravel 11)  
**Purpose**: Comprehensive technical blueprint for developers, architects, and AI agents

---

## Table of Contents

1. [Executive Overview](#executive-overview)
2. [Architectural Patterns](#architectural-patterns)
3. [Directory Structure & Organization](#directory-structure--organization)
4. [Core Domain Models](#core-domain-models)
5. [Service Layer Architecture](#service-layer-architecture)
6. [Event-Driven System](#event-driven-system)
7. [Data Flow & Communication](#data-flow--communication)
8. [API Endpoint Architecture](#api-endpoint-architecture)
9. [Authentication & Authorization](#authentication--authorization)
10. [Queue & Background Processing](#queue--background-processing)
11. [Real-time Communication](#real-time-communication)
12. [Database Architecture](#database-architecture)
13. [Error Handling & Resilience](#error-handling--resilience)
14. [Performance & Optimization](#performance--optimization)

---

## Executive Overview

### System Type
- **Architecture Style**: Service-Oriented Architecture (SOA) with Event-Driven Design
- **Framework**: Laravel 11 (PHP)
- **Database**: PostgreSQL (primary data store)
- **Cache**: Redis (session, cache, queue)
- **Real-time**: Laravel Reverb (WebSocket server)
- **Queue**: Redis Queue with Supervisor management

### Core Responsibilities
The Nexus Backend serves as the central intelligence hub, orchestrating:
- **AI Agent Management**: Multi-model agent orchestration and coordination
- **Conversation & Memory Management**: Persistent context and knowledge storage
- **Workflow Execution**: Visual workflow builder with execution engine
- **Contact Intelligence**: CRM-like relationship management
- **Multi-Provider AI Integration**: OpenAI, Google Gemini, Anthropic Claude, Groq
- **Real-time Communication**: Live updates via WebSocket

### Key Statistics
- **~13 Core Model Families**: User, Contact, Conversation, Agent, Workflow, Memory, Notification, Task, Integration, etc.
- **~30+ Service Classes**: Each handling specific business logic domains
- **25+ API Endpoint Groups**: Covering all major hubs and operations
- **8 Memory Management Services**: Episodic, Semantic, Structured, Graph, Working, Summary, Maintenance
- **4 AI Provider Integrations**: OpenAI, Gemini, Claude, Groq
- **5 Agent Types**: Reflection, Team, Autonomous, Specialized, Supervisor

---

## Architectural Patterns

### 1. **Service Layer Pattern**
```
Request → Controller → Validator → Service → Repository → Model
```
**Purpose**: Separation of concerns, testability, reusability  
**Location**: `app/Services/*`  
**Examples**:
- `AgentOrchestrationService` - Manages agent lifecycle
- `MemoryManagementService` - Handles context persistence
- `WorkflowExecutionService` - Executes workflow definitions
- `NotificationService` - Coordinated notification dispatch

### 2. **Repository Pattern**
```
Service → Repository → Query Builder → Database
```
**Purpose**: Abstract data access, enable in-memory caching  
**Location**: `app/Repositories/*`  
**Provides**: Single responsibility data access methods

### 3. **Observer/Event Pattern**
```
Event Triggered → Listeners Queued → Async Processing
```
**Purpose**: Decouple components, enable async workflows  
**Types**:
- **Synchronous Events**: Immediate processing (validation, notifications)
- **Queued Events**: Async processing (email, external APIs)

### 4. **Strategy Pattern**
**AI Providers**: Each provider has a strategy class
- `OpenAIStrategy`
- `GeminiStrategy`
- `ClaudeStrategy`
- `GroqStrategy`

**Notification Channels**: Each channel implements notification strategy
- `EmailNotification`
- `SMSNotification`
- `WhatsAppNotification`
- `PushNotification`

### 5. **Job/Command Pattern**
**Purpose**: Deferred execution with retry logic  
**Location**: `app/Jobs/*`  
**Types**:
- AI Response processing jobs
- Notification dispatch jobs
- Workflow execution jobs
- Memory maintenance jobs

### 6. **Policy-Based Authorization**
**Purpose**: Fine-grained permission control  
**Location**: `app/Policies/*`  
**Types**:
- UserPolicy
- ContactPolicy
- AgentPolicy
- WorkflowPolicy
- ConversationPolicy

---

## Directory Structure & Organization

### `/app` - Application Logic

#### `Agents/` - AI Agent Types
```
Agents/
├── ReflectionAgent.php       # Self-analysis and improvement
├── TeamAgent.php              # Multi-agent collaboration
├── AutonomousAgent.php        # Independent operation
├── SpecializedAgent.php       # Domain-specific expertise
└── SupervisorAgent.php        # Orchestration & delegation
```
**Responsibility**: Agent type implementations and behavior

#### `Http/` - HTTP Request Handling
```
Http/
├── Controllers/
│   ├── ContactController.php
│   ├── AgentController.php
│   ├── WorkflowController.php
│   ├── ConversationController.php
│   ├── MemoryController.php
│   ├── TaskController.php
│   ├── IntegrationController.php
│   └── AuthController.php
├── Requests/
│   ├── StoreContactRequest.php
│   ├── UpdateAgentRequest.php
│   └── ... (validation rules)
├── Resources/
│   ├── ContactResource.php
│   ├── AgentResource.php
│   └── ... (API response formatting)
└── Middleware/
    ├── ThrottleRequests.php
    ├── VerifyApiToken.php
    └── ...
```
**Responsibility**: Request handling, validation, response formatting

#### `Services/` - Business Logic
```
Services/
├── AgentService.php           # Agent CRUD & lifecycle
├── AgentOrchestrationService.php  # Multi-agent coordination
├── ConversationService.php    # Conversation management
├── MemoryService.php          # Main memory coordinator
├── EpisodicMemoryService.php  # Event-based memory
├── SemanticMemoryService.php  # Meaning & relationships
├── StructuredMemoryService.php # Fact storage
├── WorkflowService.php        # Workflow orchestration
├── NotificationService.php    # Multi-channel notifications
├── RoutingService.php         # Request routing (cost/speed/quality)
├── AIProviderService.php      # AI provider abstraction
├── IntegrationService.php     # Third-party API integration
└── ... (other services)
```
**Responsibility**: Complex business logic, cross-cutting concerns

#### `Models/` - Eloquent Models
```
Models/
├── User.php                   # System users
├── Contact.php                # CRM contacts
├── Conversation.php           # Chat threads
├── Message.php                # Individual messages
├── Agent.php                  # AI agents
├── AgentMemory.php            # Agent-specific memory
├── Workflow.php               # Workflow definitions
├── WorkflowStep.php           # Workflow execution steps
├── Task.php                   # Task items
├── Memory.php                 # Memory records
├── Integration.php            # Third-party integrations
├── Notification.php           # Notification history
└── ... (more models)
```
**Responsibility**: Data structure definitions, relationships

#### `Repositories/` - Data Access Layer
```
Repositories/
├── UserRepository.php
├── ContactRepository.php
├── ConversationRepository.php
├── AgentRepository.php
├── WorkflowRepository.php
├── TaskRepository.php
├── MemoryRepository.php
└── NotificationRepository.php
```
**Responsibility**: Query building, caching, data persistence

#### `Events/` - Event Definitions
```
Events/
├── ContactCreated.php         # Synchronous
├── ContactUpdated.php         # Synchronous
├── ConversationStarted.php    # Synchronous
├── MessageReceived.php        # Synchronous
├── AgentTaskAssigned.php      # Queued
├── WorkflowExecuted.php       # Queued
├── NotificationSent.php       # Queued
└── ... (more events)
```
**Responsibility**: Event object definitions

#### `Listeners/` - Event Handlers
```
Listeners/
├── SendContactNotification.php
├── LogContactActivity.php
├── UpdateContactMetrics.php
├── ProcessAgentTask.php
├── ExecuteWorkflow.php
├── DispatchNotification.php
└── ... (more listeners)
```
**Responsibility**: Event processing logic

#### `Jobs/` - Queued Jobs
```
Jobs/
├── ProcessAIResponse.php
├── SendNotification.php
├── ExecuteWorkflow.php
├── MaintainMemory.php
├── SyncIntegration.php
├── ArchiveConversation.php
└── ... (more jobs)
```
**Responsibility**: Deferred, potentially long-running operations

#### `Policies/` - Authorization Policies
```
Policies/
├── UserPolicy.php
├── ContactPolicy.php
├── AgentPolicy.php
├── WorkflowPolicy.php
├── ConversationPolicy.php
├── TaskPolicy.php
└── MemoryPolicy.php
```
**Responsibility**: Fine-grained authorization logic

#### `Integrations/` - External Service Integration
```
Integrations/
├── Providers/
│   ├── OpenAIProvider.php
│   ├── GeminiProvider.php
│   ├── ClaudeProvider.php
│   └── GroqProvider.php
├── Webhooks/
│   ├── SlackWebhook.php
│   └── GithubWebhook.php
└── Connectors/
    ├── SQLConnector.php
    └── APIConnector.php
```
**Responsibility**: Third-party API integration

#### `Hubs/` - Feature Hub Implementations
```
Hubs/
├── ContactsHub.php
├── AgentsHub.php
├── WorkflowsHub.php
├── ConversationsHub.php
├── MemoryHub.php
├── TasksHub.php
├── NotificationsHub.php
└── SettingsHub.php
```
**Responsibility**: Hub-specific business logic coordination

#### `Console/` - CLI Commands
```
Console/
├── Commands/
│   ├── ProcessQueue.php
│   ├── MaintainMemory.php
│   ├── SyncIntegrations.php
│   ├── GenerateReport.php
│   └── ... (other commands)
```
**Responsibility**: CLI operations for maintenance, cron tasks

#### `Providers/` - Service Providers
```
Providers/
├── AppServiceProvider.php     # Core bindings
├── EventServiceProvider.php   # Event-listener registration
├── RouteServiceProvider.php   # Route registration
├── AuthServiceProvider.php    # Authorization policies
└── BroadcastServiceProvider.php  # WebSocket channels
```
**Responsibility**: Dependency injection, bootstrapping

---

## Core Domain Models

### User Model
```
User
├── id: uuid
├── name: string
├── email: string (unique)
├── password: hashed
├── api_token: string (Sanctum)
├── status: enum (active, inactive, suspended)
├── preferences: json (theme, notifications, etc.)
└── timestamps
```
**Relationships**:
- hasMany Contacts
- hasMany Agents
- hasMany Conversations
- hasMany Tasks

### Contact Model
```
Contact
├── id: uuid
├── user_id: foreign key
├── name: string
├── email: string
├── phone: string
├── company: string
├── tags: json array
├── metadata: json (custom fields)
├── interaction_count: integer
├── last_interaction: timestamp
├── engagement_score: float
└── timestamps
```
**Relationships**:
- belongsTo User
- hasMany Conversations
- hasMany Tasks
- hasMany Memories

### Agent Model
```
Agent
├── id: uuid
├── user_id: foreign key
├── name: string
├── type: enum (reflection, team, autonomous, specialized, supervisor)
├── status: enum (active, inactive, paused)
├── model: string (gpt-4, gemini-pro, claude-3, etc.)
├── system_prompt: text
├── instructions: json
├── capabilities: json array
├── memory_enabled: boolean
├── max_tokens: integer
├── temperature: float
├── memory_size_limit: integer
└── timestamps
```
**Relationships**:
- belongsTo User
- hasMany AgentMemories
- belongsToMany Tasks
- hasMany WorkflowSteps

### Conversation Model
```
Conversation
├── id: uuid
├── user_id: foreign key
├── contact_id: foreign key (nullable)
├── agent_id: foreign key (nullable)
├── title: string
├── status: enum (active, archived, closed)
├── message_count: integer
├── last_activity: timestamp
├── metadata: json
├── workflow_id: foreign key (nullable)
└── timestamps
```
**Relationships**:
- belongsTo User
- belongsTo Contact
- belongsTo Agent
- hasMany Messages
- hasMany Memories

### Message Model
```
Message
├── id: uuid
├── conversation_id: foreign key
├── sender_type: enum (user, agent, system)
├── sender_id: uuid
├── content: text
├── role: enum (user, assistant, system)
├── tokens_used: integer
├── ai_model_used: string
├── metadata: json (citations, confidence, etc.)
└── timestamps
```
**Relationships**:
- belongsTo Conversation
- hasMany Memories

### Workflow Model
```
Workflow
├── id: uuid
├── user_id: foreign key
├── name: string
├── description: text
├── steps: json (workflow definition)
├── status: enum (draft, published, archived)
├── trigger_type: enum (manual, scheduled, event)
├── execution_count: integer
├── success_rate: float
└── timestamps
```
**Relationships**:
- belongsTo User
- hasMany WorkflowExecutions
- hasMany WorkflowSteps

### Memory Model
```
Memory
├── id: uuid
├── user_id: foreign key
├── agent_id: foreign key (nullable)
├── conversation_id: foreign key (nullable)
├── type: enum (episodic, semantic, structured, graph, working, summary)
├── content: text
├── embedding: vector (for semantic search)
├── timestamp_created: timestamp
├── timestamp_accessed: timestamp
├── importance_score: float
├── retention_policy: enum (permanent, temporary, decay)
└── timestamps
```
**Relationships**:
- belongsTo User
- belongsTo Agent
- belongsTo Conversation

### Task Model
```
Task
├── id: uuid
├── user_id: foreign key
├── agent_id: foreign key (nullable)
├── contact_id: foreign key (nullable)
├── title: string
├── description: text
├── status: enum (pending, in-progress, completed, failed)
├── priority: enum (low, medium, high, critical)
├── due_date: timestamp (nullable)
├── assigned_to_agent: foreign key (nullable)
├── metadata: json
└── timestamps
```
**Relationships**:
- belongsTo User
- belongsTo Agent
- belongsTo Contact

### Integration Model
```
Integration
├── id: uuid
├── user_id: foreign key
├── provider: string (slack, github, salesforce, etc.)
├── auth_token: encrypted
├── webhook_url: string
├── settings: json
├── status: enum (active, inactive, error)
├── last_sync: timestamp
├── error_log: text
└── timestamps
```
**Relationships**:
- belongsTo User

### Notification Model
```
Notification
├── id: uuid
├── user_id: foreign key
├── channel: enum (email, sms, whatsapp, push, in-app)
├── recipient: string
├── subject: string
├── content: text
├── status: enum (pending, sent, failed, delivered)
├── triggered_by: string
├── metadata: json
└── timestamps
```
**Relationships**:
- belongsTo User

---

## Service Layer Architecture

### Core Service Dependencies
```
    ┌─────────────────────────┐
    │   Request Handler       │
    │  (Controller/Route)     │
    └────────────┬────────────┘
                 │
    ┌────────────▼──────────────┐
    │   Validation Layer        │
    │  (FormRequest/Validator)  │
    └────────────┬──────────────┘
                 │
    ┌────────────▼──────────────────┐
    │   Business Logic Services     │
    │  (Service Classes)            │
    └────────────┬──────────────────┘
         ┌───────┴───────┐
         │               │
    ┌────▼────┐  ┌──────▼──────┐
    │Repo     │  │Event        │
    │Layer    │  │Dispatcher   │
    └────┬────┘  └──────┬──────┘
         │               │
    ┌────▼────────────────▼────┐
    │  Database & Cache Layer   │
    │  (Eloquent + Redis)       │
    └──────────────────────────┘
```

### Key Service Classes

#### AgentOrchestrationService
**Purpose**: Coordinate multi-agent workflows  
**Methods**:
- `executeAgent(agent, input, context)` - Single agent execution
- `orchestrateTeam(agents, task)` - Multi-agent coordination
- `routeToOptimalAgent(request)` - Request routing
- `trackAgentMetrics(agent)` - Performance monitoring

#### MemoryManagementService
**Purpose**: Unified memory access across all types  
**Methods**:
- `store(type, content, agent, conversation)` - Store memory
- `retrieve(agent, query, limit)` - Query memories
- `updateImportance(memory, score)` - Update relevance
- `prune(retention_policy)` - Clean old memories
- `generateSummary(agent, timeframe)` - Create summaries

#### WorkflowExecutionService
**Purpose**: Execute workflow definitions  
**Methods**:
- `executeWorkflow(workflow, context)` - Run full workflow
- `executeStep(step, input)` - Execute single step
- `validateWorkflow(definition)` - Validate before execution
- `rollbackWorkflow(execution)` - Undo on error

#### NotificationService
**Purpose**: Multi-channel notification dispatch  
**Methods**:
- `notify(user, message, channels)` - Send notification
- `schedule(user, message, time)` - Schedule delivery
- `trackDelivery(notification)` - Monitor delivery status
- `handleBounce(notification)` - Handle delivery failures

#### RoutingService
**Purpose**: Intelligent request routing  
**Methods**:
- `routeByCost(providers)` - Cheapest provider
- `routeByQuality(providers)` - Best quality model
- `routeBySpeed(providers)` - Fastest response
- `routeByCapability(request)` - Feature-specific routing

#### IntegrationService
**Purpose**: Manage third-party integrations  
**Methods**:
- `connect(provider, credentials)` - Establish connection
- `disconnect(provider)` - Close connection
- `syncData(provider)` - Bi-directional sync
- `webhook(provider, payload)` - Handle webhooks

#### AnalyticsService
**Purpose**: Metrics and insights generation  
**Methods**:
- `trackInteraction(contact, interaction)` - Log interactions
- `calculateEngagementScore(contact)` - Compute engagement
- `generateReport(timeframe)` - Create analytics reports
- `predictChurn(contact)` - Churn prediction

---

## Event-Driven System

### Event Categories

#### Synchronous Events
Immediate processing, used for:
- Data validation
- Audit logging
- Cache invalidation
- Immediate notifications

**Examples**:
```php
class ContactCreated {
    public function __construct(public Contact $contact) {}
}

// Listeners (sync)
class LogContactActivity { } // Immediate audit log
class InvalidateContactCache { } // Clear cache
class SendContactNotification { } // Immediate notification
```

#### Queued Events
Deferred processing, used for:
- External API calls
- Email/SMS sending
- Complex calculations
- Database heavy operations

**Examples**:
```php
class MessageReceived implements ShouldQueue {
    public function __construct(public Message $message) {}
}

// Listeners (queued)
class ProcessWithAI { } // AI response generation
class ExtractCitations { } // Citation extraction
class UpdateMemory { } // Memory updates
class TriggerWorkflow { } // Workflow execution
```

### Event Flow Diagram
```
User Action (e.g., "Create Contact")
    ↓
Controller validates request
    ↓
Service method executes
    ↓
Event::dispatch(ContactCreated)
    ↓
┌─────────────────────────────────────┐
│ Listener 1: LogActivity (sync)      │──→ Audit Log
│ Listener 2: InvalidateCache (sync)  │──→ Redis
│ Listener 3: SendNotification (sync) │──→ In-app
│ Listener 4: ProcessWithAI (queued)  │──→ Queue (async)
│ Listener 5: UpdateMemory (queued)   │──→ Queue (async)
└─────────────────────────────────────┘
    ↓
Response sent to user (sync listeners done)
    ↓
Queue workers process listeners
    ↓
Broadcast updates via WebSocket
```

### Event Registry
**Contact Events**:
- `ContactCreated` - New contact added
- `ContactUpdated` - Contact details changed
- `ContactDeleted` - Contact removed
- `ContactEngagementIncreased` - Interaction occurred

**Agent Events**:
- `AgentTaskAssigned` - Task given to agent
- `AgentTaskCompleted` - Task finished
- `AgentError` - Agent encountered error

**Conversation Events**:
- `ConversationStarted` - New conversation
- `MessageReceived` - New message
- `ConversationClosed` - Conversation ended

**Workflow Events**:
- `WorkflowExecuted` - Workflow run
- `WorkflowStepFailed` - Step failed
- `WorkflowCompleted` - Full execution done

**Memory Events**:
- `MemoryStored` - Memory recorded
- `MemoryDecayed` - Memory aged
- `MemoryPurged` - Memory deleted

---

## Data Flow & Communication

**### Message Reception Flow
**```
Message Received from Frontend
    ↓
MessageController::store()
    ↓
Validate (StoreMessageRequest)
    ↓
Message::create() → Event: MessageReceived
    ↓
┌──────────────────────────────────────────┐
│ Sync Listeners:                          │
│ • LogMessageActivity                     │
│ • BroadcastMessageToOthers               │
│ • UpdateConversationMetadata             │
└────┬─────────────────────────────────────┘
     ↓
Response: Message created (HTTP 201)
     ↓
┌──────────────────────────────────────────┐
│ Queued Listeners (async):               │
│ • ProcessWithAI                          │
│   ├─ Route to optimal provider           │
│   ├─ Call LLM API                        │
│   ├─ Extract citations                   │
│   └─ Store response                      │
│ • ExtractMemoryData                      │
│ • UpdateContactEngagement                │
│ • TriggerRelatedWorkflows                │
└──────────────────────────────────────────┘
     ↓
WebSocket Broadcast (AI response)
     ↓
Frontend receives in real-time
```

### Agent Orchestration Flow
```
Conversation with Team Agent
    ↓
Message → AgentController::executeAgent()
    ↓
AgentOrchestrationService::orchestrateTeam()
    ↓
┌─────────────────────────────────┐
│ Agent Assignment                │
│ • Task decomposition            │
│ • Agent capability matching     │
│ • Load balancing               │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────────────────────────────┐
│ Parallel Execution (with Agent-to-Agent Communication) │
│                                                         │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│ │ Agent A      │  │ Agent B      │  │ Agent C      │  │
│ │ Work on Task │→→→│ Depends on A │→→→│ Final       │  │
│ │ Part 1       │  │ Task Part 2  │  │ Assembly    │  │
│ └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓               ↓                  ↓             │
│    (Access shared memory, query each other's context)  │
└───────────────┬──────────────────────────────────────┘
                ↓
    Supervisor Agent Validation
    ├─ Quality check
    ├─ Consistency validation
    └─ Final output composition
                ↓
        Store final response + memories
                ↓
      Broadcast to frontend
```

### Workflow Execution Flow
```
Workflow Trigger (manual/scheduled/event)
    ↓
WorkflowService::executeWorkflow()
    ↓
Parse workflow definition (steps, conditions, branches)
    ↓
Iterate through steps
    ├─ Step 1: Agent execution
    │   └─ Wait for completion
    ├─ Step 2: Conditional branch
    │   ├─ If condition true → go to Step 3
    │   └─ Else → go to Step 4
    ├─ Step 3: API call
    │   └─ Store result in context
    └─ Step 4: Notification
        └─ Send to user
    ↓
Store workflow execution record
    ↓
Update metrics (success/failure)
    ↓
Broadcast completion
```

---

## API Endpoint Architecture

### Endpoint Organization Pattern
```
/api/{version}/{hub}/{resource}/{action}

Examples:
GET    /api/v1/contacts                    - List contacts
POST   /api/v1/contacts                    - Create contact
GET    /api/v1/contacts/{id}              - Get contact detail
PATCH  /api/v1/contacts/{id}              - Update contact
DELETE /api/v1/contacts/{id}              - Delete contact

GET    /api/v1/agents/{id}/execute        - Execute agent
POST   /api/v1/workflows                  - Create workflow
POST   /api/v1/workflows/{id}/execute     - Run workflow
GET    /api/v1/conversations/{id}/messages - Get messages
POST   /api/v1/conversations/{id}/messages - Add message
```

### Core Endpoint Groups

#### Contacts Hub API
```
GET    /api/v1/contacts
POST   /api/v1/contacts
GET    /api/v1/contacts/{id}
PATCH  /api/v1/contacts/{id}
DELETE /api/v1/contacts/{id}
GET    /api/v1/contacts/{id}/conversations
GET    /api/v1/contacts/{id}/tasks
GET    /api/v1/contacts/{id}/memories
GET    /api/v1/contacts/{id}/engagement-score
POST   /api/v1/contacts/{id}/tags
DELETE /api/v1/contacts/{id}/tags/{tag}
```

#### Agents Hub API
```
GET    /api/v1/agents
POST   /api/v1/agents
GET    /api/v1/agents/{id}
PATCH  /api/v1/agents/{id}
DELETE /api/v1/agents/{id}
POST   /api/v1/agents/{id}/execute
POST   /api/v1/agents/{id}/test
GET    /api/v1/agents/{id}/memory
PATCH  /api/v1/agents/{id}/memory/prune
GET    /api/v1/agents/{id}/metrics
```

#### Conversations Hub API
```
GET    /api/v1/conversations
POST   /api/v1/conversations
GET    /api/v1/conversations/{id}
PATCH  /api/v1/conversations/{id}
DELETE /api/v1/conversations/{id}
POST   /api/v1/conversations/{id}/messages
GET    /api/v1/conversations/{id}/messages
DELETE /api/v1/conversations/{id}/messages/{messageId}
POST   /api/v1/conversations/{id}/archive
POST   /api/v1/conversations/{id}/restore
```

#### Workflows Hub API
```
GET    /api/v1/workflows
POST   /api/v1/workflows
GET    /api/v1/workflows/{id}
PATCH  /api/v1/workflows/{id}
DELETE /api/v1/workflows/{id}
POST   /api/v1/workflows/{id}/execute
GET    /api/v1/workflows/{id}/executions
GET    /api/v1/workflows/{id}/executions/{executionId}
POST   /api/v1/workflows/{id}/publish
POST   /api/v1/workflows/{id}/draft
```

#### Memory Hub API
```
GET    /api/v1/memory/{type}
POST   /api/v1/memory/{type}
GET    /api/v1/memory/{type}/{id}
DELETE /api/v1/memory/{type}/{id}
POST   /api/v1/memory/search
PATCH  /api/v1/memory/{id}/importance
POST   /api/v1/memory/summarize
POST   /api/v1/memory/maintenance
```

#### Tasks Hub API
```
GET    /api/v1/tasks
POST   /api/v1/tasks
GET    /api/v1/tasks/{id}
PATCH  /api/v1/tasks/{id}
DELETE /api/v1/tasks/{id}
PATCH  /api/v1/tasks/{id}/status
PATCH  /api/v1/tasks/{id}/priority
POST   /api/v1/tasks/{id}/assign-agent
```

#### AI Models Hub API
```
GET    /api/v1/ai-models
GET    /api/v1/ai-models/{provider}/models
POST   /api/v1/ai-models/test
GET    /api/v1/ai-models/{id}/pricing
GET    /api/v1/ai-models/routing/optimize
```

---

## Authentication & Authorization

### Sanctum Token-Based Authentication
```
┌─────────────────────────────────────┐
│ User Login Flow                     │
└──────────────┬──────────────────────┘
               ↓
    POST /api/v1/auth/login
    {
      "email": "user@example.com",
      "password": "secret"
    }
               ↓
    Verify credentials against database
               ↓
    Generate Sanctum token
               ↓
    Return token in response
    {
      "token": "1|Hs3xNqCqB7mL...",
      "user": { ... }
    }
               ↓
    Client stores token (secure storage)
               ↓
    Include token in subsequent requests
    Authorization: Bearer 1|Hs3xNqCqB7mL...
```

### Token Management
- **Token Generation**: `$user->createToken('token-name')`
- **Token Revocation**: `$user->tokens()->delete()`
- **Token Expiry**: Configurable per token
- **Scopes**: Fine-grained permission scopes

### Authorization Policies
```php
// Example: ContactPolicy
class ContactPolicy {
    public function view(User $user, Contact $contact): bool {
        return $user->id === $contact->user_id;
    }
    
    public function update(User $user, Contact $contact): bool {
        return $user->id === $contact->user_id || $user->is_admin;
    }
    
    public function delete(User $user, Contact $contact): bool {
        return $user->id === $contact->user_id && !$contact->is_locked;
    }
}

// Usage in controller
$this->authorize('view', $contact); // Throws 403 if not authorized
```

### Authorization Hierarchy
```
Admin (all permissions)
├── Contact.view, .create, .update, .delete
├── Agent.view, .create, .update, .delete
├── Workflow.view, .create, .update, .delete
├── Conversation.view, .create, .update, .delete
└── Memory.view, .create, .update, .delete

Regular User (own resources only)
├── Contact.view (own), .create, .update (own), .delete (own)
├── Agent.view (own), .create, .update (own), .delete (own)
├── Workflow.view (own), .create, .update (own), .delete (own)
├── Conversation.view (own), .create, .update (own), .delete (own)
└── Memory.view (own), .create, .update (own), .delete (own)

Guest (read-only)
└── View shared/public resources only
```

---

## Queue & Background Processing

### Queue Structure
```
Job submitted → Redis Queue → Queue Worker → Process → Complete/Failed
```

### Queue Types

#### Critical Queue (Immediate)
- Real-time notifications
- WebSocket broadcasts
- Cache invalidation
- Token generation
- **Timeout**: 30 seconds

#### Default Queue (Standard)
- AI response processing
- Memory updates
- Workflow execution
- Contact engagement updates
- **Timeout**: 60 seconds
- **Retry**: 3 times with exponential backoff

#### Long-Running Queue
- Large memory operations
- Complex data processing
- External API bulk operations
- Report generation
- **Timeout**: 300 seconds
- **Retry**: 2 times

#### Failed Queue (Dead Letter Queue)
- Store failed jobs
- Manual retry capability
- Error logging
- Alert notifications
- **Retention**: 14 days

### Job Classes

#### ProcessAIResponse Job
```php
class ProcessAIResponse implements ShouldQueue {
    public $tries = 3;
    public $backoff = [10, 60, 300]; // 10s, 1m, 5m
    
    public function handle(AIProviderService $service) {
        // Call LLM API
        // Extract response
        // Store in conversation
        // Update memory
        // Trigger related workflows
    }
}
```

#### SendNotification Job
```php
class SendNotification implements ShouldQueue {
    public $tries = 5;
    public $backoff = [5, 15, 30, 60, 300];
    
    public function handle(NotificationService $service) {
        // Route to appropriate channel
        // Send notification
        // Track delivery
        // Handle bounces/failures
    }
}
```

#### ExecuteWorkflow Job
```php
class ExecuteWorkflow implements ShouldQueue {
    public $tries = 2;
    public $timeout = 300;
    
    public function handle(WorkflowExecutionService $service) {
        // Execute workflow steps sequentially
        // Handle conditions/branches
        // Store execution log
        // Handle errors with rollback
    }
}
```

### Queue Monitoring
```
Supervisor Configuration:
├── Process: laravel-worker
│   ├── Command: queue:work --queue=critical,default,long-running
│   ├── Processes: 4
│   ├── Autorestart: true
│   └── Redirect: logs/queue.log
│
└── Health Checks:
    ├── Queue length monitoring
    ├── Failed job alerts
    ├── Worker health checks
    └── Memory usage monitoring
```

---

## Real-time Communication

### Reverb WebSocket Server
```
Client Connection:
  WebSocket Client (Frontend)
       ↓
  wss://websocket.example.com
       ↓
  Laravel Reverb Server
       ↓
  Broadcast Channel Subscription
       ↓
  Real-time message push
```

### Broadcast Channels

#### Private Channels
```php
// Only authenticated users subscribed to conversation
Broadcast::channel('conversation.{id}', function ($user, $id) {
    return $user->conversations()->where('id', $id)->exists();
});

// Usage
Channel: conversation.550e8400-e29b-41d4-a716-446655440000
```

#### Presence Channels
```php
// Track who's online in a conversation
Broadcast::channel('conversation.{id}', function ($user, $id) {
    return ['id' => $user->id, 'name' => $user->name];
});

// Track typing indicators
Broadcast::channel('conversation.{id}.typing', function ($user, $id) {
    return $user->conversations()->where('id', $id)->exists();
});
```

### Event Broadcasting

#### Message Received Event
```php
class MessageReceived implements ShouldBroadcast {
    public function broadcastOn() {
        return new PrivateChannel('conversation.' . $this->message->conversation_id);
    }
    
    public function broadcastAs() {
        return 'message.received';
    }
}
```

#### Typing Indicator Event
```php
class UserTyping implements ShouldBroadcast {
    public function broadcastOn() {
        return new PresenceChannel('conversation.' . $this->conversation_id);
    }
}
```

#### Agent Thinking Event
```php
class AgentThinking implements ShouldBroadcast {
    public function broadcastOn() {
        return new PrivateChannel('agent.' . $this->agent_id);
    }
}
```

---

## Database Architecture

### Connection & Configuration
```php
// config/database.php
'default' => 'pgsql',

'connections' => [
    'pgsql' => [
        'driver' => 'pgsql',
        'host' => env('DB_HOST'),
        'database' => env('DB_DATABASE'),
        'pool' => [
            'min' => 2,
            'max' => 25,
        ],
    ],
],
```

### Indexing Strategy
```sql
-- User queries
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- Contact queries
CREATE INDEX idx_contacts_user_id ON contacts(user_id);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_engagement ON contacts(engagement_score);

-- Conversation queries
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_last_activity ON conversations(last_activity);

-- Message queries
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_timestamp ON messages(created_at);

-- Memory queries
CREATE INDEX idx_memory_user_id ON memory(user_id);
CREATE INDEX idx_memory_type ON memory(type);
CREATE INDEX idx_memory_importance ON memory(importance_score);

-- Task queries
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_agent_id ON tasks(assigned_to_agent);

-- Composite indexes for common queries
CREATE INDEX idx_contacts_user_engagement ON contacts(user_id, engagement_score);
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at);
```

### Soft Deletes
All primary models support soft deletes:
```php
Schema::table('contacts', function (Blueprint $table) {
    $table->softDeletes();
});

// Soft-deleted contacts still exist but are hidden from queries
Contact::where('user_id', $userId)->get(); // Excludes soft-deleted
Contact::withTrashed()->get(); // Includes soft-deleted
```

---

## Error Handling & Resilience

### Exception Handling Strategy
```
┌─────────────────────────────────────────┐
│ Request Processing                      │
└────────────┬────────────────────────────┘
             ↓
    ┌───────────────────┐
    │ Throw Exception?  │
    └───┬───────────────┘
        │
        ├─ ValidationException
        │  ├─ HTTP 422 (Unprocessable Entity)
        │  └─ Return validation errors
        │
        ├─ AuthenticationException
        │  ├─ HTTP 401 (Unauthorized)
        │  └─ Redirect to login
        │
        ├─ AuthorizationException
        │  ├─ HTTP 403 (Forbidden)
        │  └─ Return "Not authorized"
        │
        ├─ ResourceNotFoundException
        │  ├─ HTTP 404 (Not Found)
        │  └─ Return "Resource not found"
        │
        ├─ ThrottleRequestsException
        │  ├─ HTTP 429 (Too Many Requests)
        │  └─ Return rate limit info
        │
        ├─ AIProviderException
        │  ├─ HTTP 502 (Bad Gateway)
        │  ├─ Log error
        │  ├─ Store in DLQ
        │  └─ Retry with exponential backoff
        │
        ├─ DatabaseException
        │  ├─ HTTP 500 (Internal Server Error)
        │  ├─ Log critical error
        │  └─ Alert admin
        │
        └─ Generic Exception
           ├─ HTTP 500
           ├─ Log error with context
           └─ Return generic error message
```

### Resilience Patterns

#### Circuit Breaker (AI Providers)
```php
class AIProviderCircuitBreaker {
    protected int $failureThreshold = 5;
    protected int $resetTimeout = 300; // 5 minutes
    
    public function call(callable $callback) {
        if ($this->isOpen()) {
            throw new CircuitBreakerOpenException();
        }
        
        try {
            return $callback();
        } catch (Exception $e) {
            $this->recordFailure();
            if ($this->exceedsThreshold()) {
                $this->open();
            }
            throw $e;
        }
    }
}
```

#### Retry with Exponential Backoff
```php
class RetryWithBackoff {
    protected array $backoff = [1, 2, 4, 8, 16]; // seconds
    
    public function execute(callable $callback) {
        $lastException = null;
        
        foreach ($this->backoff as $delay) {
            try {
                return $callback();
            } catch (TransientException $e) {
                $lastException = $e;
                sleep($delay);
            }
        }
        
        throw $lastException;
    }
}
```

#### Fallback Strategies
```php
// If primary AI provider fails, try secondary
if ($openaiProvider->isHealthy()) {
    $response = $openaiProvider->call($prompt);
} elseif ($geminiProvider->isHealthy()) {
    $response = $geminiProvider->call($prompt);
} elseif ($claudeProvider->isHealthy()) {
    $response = $claudeProvider->call($prompt);
} else {
    // All providers failed - store in queue for retry
    ProcessAIResponse::dispatch($message)->delay(now()->addMinutes(5));
}
```

#### Timeout Management
```php
// Prevent hanging requests
set_time_limit(300); // 5 minutes

// Database query timeouts
DB::statement('SET SESSION statement_timeout = 30000'); // 30 seconds

// External API timeouts
$client = new GuzzleHttp\Client([
    'timeout' => 30,
    'connect_timeout' => 10,
]);
```

---

## Performance & Optimization

### Caching Strategy
```
Request
  ↓
Check Cache (Redis)
  ├─ Hit → Return cached value
  └─ Miss → Query database → Cache → Return
  ↓
Invalidation Triggers:
  ├─ Resource updated → Invalidate related caches
  ├─ Time-based TTL → Automatic expiration
  └─ Event-based → Listeners invalidate on events
```

### Cache Keys & TTL
```php
// Contact cache
Cache::put("contact.{$id}", $contact, 3600); // 1 hour

// Agent memory cache
Cache::put("agent.{$id}.memory", $memories, 1800); // 30 minutes

// Conversation messages cache
Cache::put("conversation.{$id}.messages", $messages, 600); // 10 minutes

// User preferences cache
Cache::put("user.{$id}.preferences", $prefs, 86400); // 24 hours

// Engagement score cache (frequently accessed)
Cache::remember("contact.{$id}.engagement", 600, function () {
    return $this->calculateEngagementScore();
});
```

### Database Query Optimization
```php
// N+1 Prevention: Use eager loading
// Bad
foreach ($contacts as $contact) {
    $user = $contact->user; // Separate query for each contact
}

// Good
$contacts = Contact::with('user')->get(); // Single query
foreach ($contacts as $contact) {
    $user = $contact->user; // No additional queries
}

// Pagination for large result sets
$contacts = Contact::where('user_id', $userId)
    ->with('conversations')
    ->paginate(50);

// Chunking for bulk operations
Contact::where('engagement_score', '<', 0.2)
    ->chunk(100, function ($contacts) {
        foreach ($contacts as $contact) {
            $contact->update(['status' => 'inactive']);
        }
    });
```

### Connection Pooling
```
Application Instances
       ↓
Connection Pool (Min: 2, Max: 25)
       ↓
Database Connections
       ↓
PostgreSQL
```

### Monitoring & Metrics
```
Prometheus Metrics:
├── Request Duration
│   └── Histogram (p50, p95, p99)
├── Queue Length
│   ├── critical queue
│   ├── default queue
│   ├── long-running queue
│   └─ failed queue
├── Database Performance
│   ├── Query count per request
│   ├── Query duration
│   └─ Connection pool usage
├── Cache Hit Rate
│   └── Percentage of hits vs misses
├── AI Provider Health
│   ├── Response times
│   ├── Error rates
│   └─ Rate limit status
└── WebSocket Connections
    ├── Active connections
    ├── Message throughput
    └─ Connection failures
```

---

## Summary & Architecture Highlights

### Strengths
✅ **Event-Driven Design**: Decoupled components, async processing  
✅ **Service-Oriented**: Clear separation of concerns  
✅ **Multi-Agent Support**: Complex orchestration capabilities  
✅ **Intelligent Routing**: Cost/quality/speed optimization  
✅ **Memory Management**: 8 different memory types  
✅ **Real-time Updates**: WebSocket via Reverb  
✅ **Scalable Queue System**: Multiple queue types with retry logic  
✅ **Comprehensive Authorization**: Policy-based permissions  
✅ **Resilient Design**: Circuit breakers, retries, fallbacks  
✅ **Production-Ready**: Error handling, monitoring, caching  

### Extensibility Points
- **New AI Providers**: Add strategy class inheriting from ProviderInterface
- **Custom Workflows**: Extend WorkflowExecutionService
- **Memory Types**: Add new MemoryTypeService
- **Notification Channels**: Implement NotificationChannelInterface
- **Integration Connectors**: Extend ConnectorInterface
- **Event Listeners**: Register in EventServiceProvider

### Key Technologies
- **Framework**: Laravel 11
- **Database**: PostgreSQL 15+
- **Cache**: Redis 7+
- **Queue**: Redis Queue + Supervisor
- **Real-time**: Laravel Reverb (WebSocket)
- **Authentication**: Laravel Sanctum
- **API**: RESTful with JSON

---

**End of System Architecture Documentation**
