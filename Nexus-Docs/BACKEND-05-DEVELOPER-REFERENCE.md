# Nexus Backend - Developer Reference Manual

**Last Updated**: May 25, 2026  
**Project**: Nexus-Backend (Laravel 11)  
**Purpose**: Deep reference for core logic, patterns, and utilities

---

## Table of Contents

1. [Core Services Deep Dive](#core-services-deep-dive)
2. [Agent Execution Pipeline](#agent-execution-pipeline)
3. [Memory Management Detailed](#memory-management-detailed)
4. [Workflow Execution Engine](#workflow-execution-engine)
5. [Event System & Broadcasting](#event-system--broadcasting)
6. [Error Handling Patterns](#error-handling-patterns)
7. [Caching Strategies](#caching-strategies)
8. [Database Query Patterns](#database-query-patterns)
9. [Authentication & Authorization Deep Dive](#authentication--authorization-deep-dive)
10. [Queue Job System](#queue-job-system)
11. [Utility Functions & Helpers](#utility-functions--helpers)
12. [Testing Utilities & Factories](#testing-utilities--factories)

---

## Core Services Deep Dive

### AgentOrchestrationService

**File**: `app/Services/AgentOrchestrationService.php`  
**Purpose**: Coordinate multi-agent workflows and task distribution

#### Key Methods

```php
public function executeAgent(Agent $agent, string $input, array $context = []): AgentExecution
{
    // 1. Validate agent
    $this->validateAgentStatus($agent);
    
    // 2. Prepare context
    $enrichedContext = $this->enrichContext($agent, $context);
    
    // 3. Get previous memory
    $memory = $this->memoryService->retrieve($agent, null, 10);
    
    // 4. Call appropriate provider
    $response = $this->callProvider($agent->model, $input, $memory, $enrichedContext);
    
    // 5. Process response
    $execution = $this->processResponse($response, $agent);
    
    // 6. Store execution record
    $this->storeExecution($execution);
    
    // 7. Update metrics
    $this->updateMetrics($agent, $execution);
    
    return $execution;
}

public function orchestrateTeam(Collection $agents, string $task, array $context = []): TeamExecution
{
    // 1. Decompose task into subtasks
    $subtasks = $this->decomposeTask($task, $agents->count());
    
    // 2. Assign agents to subtasks
    $assignments = $this->assignAgents($agents, $subtasks);
    
    // 3. Execute in parallel (with coordination)
    $results = $this->executeParallel($assignments, $context);
    
    // 4. Aggregate results
    $aggregated = $this->aggregateResults($results);
    
    // 5. Validate consistency
    $validated = $this->validateConsistency($aggregated);
    
    // 6. Store team execution
    $this->storeTeamExecution($validated);
    
    return $validated;
}
```

#### Provider Selection Logic

```php
private function callProvider(string $model, string $input, array $memory, array $context): ProviderResponse
{
    // Router selects optimal provider
    if (in_array(strtolower($model), ['gpt-4', 'gpt-3.5-turbo'])) {
        return $this->openaiProvider->call($input, $memory, $context);
    } elseif (in_array(strtolower($model), ['gemini-pro', 'gemini-pro-vision'])) {
        return $this->geminiProvider->call($input, $memory, $context);
    } elseif (in_array(strtolower($model), ['claude-3', 'claude-3-opus'])) {
        return $this->claudeProvider->call($input, $memory, $context);
    } elseif (in_array(strtolower($model), ['mixtral', 'llama'])) {
        return $this->groqProvider->call($input, $memory, $context);
    } else {
        throw new UnsupportedModelException("Model {$model} not supported");
    }
}
```

---

### MemoryManagementService

**File**: `app/Services/MemoryManagementService.php`  
**Purpose**: Unified interface for 8 memory types

#### Memory Type System

```php
// Memory Type Constants
const MEMORY_EPISODIC = 'episodic';      // Events/interactions
const MEMORY_SEMANTIC = 'semantic';      // Facts/knowledge
const MEMORY_STRUCTURED = 'structured';  // Schemas/facts
const MEMORY_GRAPH = 'graph';            // Relationships
const MEMORY_WORKING = 'working';        // Short-term context
const MEMORY_SUMMARY = 'summary';        // Compressed memory

// Access via service
$memory = $this->memoryService->store(
    type: 'semantic',
    content: 'Customer wants enterprise features',
    agent: $agent,
    conversation: $conversation,
    importance: 0.85
);

$retrieved = $this->memoryService->retrieve(
    agent: $agent,
    query: 'enterprise features',
    limit: 10,
    minImportance: 0.5
);
```

#### Memory Storage Deep Dive

```php
public function store(
    string $type,
    string $content,
    ?Agent $agent = null,
    ?Conversation $conversation = null,
    float $importance = 0.5,
    string $retentionPolicy = 'permanent'
): Memory
{
    // 1. Validate memory type
    $this->validateMemoryType($type);
    
    // 2. Generate embedding (for semantic search)
    $embedding = null;
    if ($type === self::MEMORY_SEMANTIC) {
        $embedding = $this->embeddingService->generate($content);
    }
    
    // 3. Create memory record
    $memory = Memory::create([
        'user_id' => auth()->id(),
        'agent_id' => $agent?->id,
        'conversation_id' => $conversation?->id,
        'type' => $type,
        'content' => $content,
        'embedding' => $embedding,
        'importance_score' => $importance,
        'retention_policy' => $retentionPolicy,
    ]);
    
    // 4. Cache the memory
    Cache::put(
        "memory.{$memory->id}",
        $memory,
        $this->getCacheTTL($retentionPolicy)
    );
    
    // 5. Update agent memory usage
    if ($agent) {
        $this->updateAgentMemoryUsage($agent);
    }
    
    // 6. Dispatch event for indexing
    event(new MemoryStored($memory));
    
    return $memory;
}
```

#### Memory Retrieval Strategy

```php
public function retrieve(
    Agent $agent,
    ?string $query = null,
    int $limit = 10,
    float $minImportance = 0.0,
    ?string $type = null
): Collection
{
    // Build query
    $qb = Memory::where('agent_id', $agent->id)
        ->where('importance_score', '>=', $minImportance)
        ->orderByDesc('timestamp_accessed');
    
    // Filter by type if specified
    if ($type) {
        $qb->where('type', $type);
    }
    
    // Vector similarity search if query provided (semantic type)
    if ($query && $type === self::MEMORY_SEMANTIC) {
        $queryEmbedding = $this->embeddingService->generate($query);
        $results = $this->vectorStore->search($queryEmbedding, $limit);
        return collect($results)->map(fn($r) => Memory::find($r['id']));
    }
    
    // Text search (keyword matching)
    if ($query) {
        $qb->whereRaw("content ILIKE ?", ["%{$query}%"]);
    }
    
    // Get results and update access timestamps
    $memories = $qb->limit($limit)->get();
    
    $memories->each(function ($memory) {
        $memory->update(['timestamp_accessed' => now()]);
    });
    
    return $memories;
}
```

---

### WorkflowExecutionService

**File**: `app/Services/WorkflowExecutionService.php`  
**Purpose**: Execute workflow definitions with support for branches and parallel steps

#### Workflow Execution Loop

```php
public function execute(Workflow $workflow, array $context = []): WorkflowExecution
{
    // Wrap in transaction for atomicity
    return DB::transaction(function () use ($workflow, $context) {
        // 1. Validate workflow definition
        $this->validateWorkflow($workflow);
        
        // 2. Create execution record
        $execution = WorkflowExecution::create([
            'workflow_id' => $workflow->id,
            'status' => 'running',
            'context' => $context,
            'started_at' => now(),
        ]);
        
        try {
            // 3. Execute steps sequentially
            foreach ($workflow->steps as $step) {
                $execution = $this->executeStep($step, $execution, $context);
                
                if ($execution->status === 'failed') {
                    break; // Stop on first failure
                }
            }
            
            // 4. Mark as completed
            $execution->update([
                'status' => 'completed',
                'completed_at' => now(),
            ]);
            
        } catch (Exception $e) {
            // 5. Handle errors
            $execution->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
                'completed_at' => now(),
            ]);
            
            // 6. Trigger error handlers/rollback
            $this->handleExecutionError($execution, $e);
        }
        
        // 7. Dispatch completion event
        event(new WorkflowCompleted($execution));
        
        return $execution;
    });
}

private function executeStep(Step $step, WorkflowExecution $execution, array $context): WorkflowExecution
{
    // Update context with previous step outputs
    $context = $this->updateContextWithPreviousResults($execution, $context);
    
    // Execute based on step type
    $result = match($step->type) {
        'agent_execution' => $this->executeAgentStep($step, $context),
        'api_call' => $this->executeApiCallStep($step, $context),
        'notification' => $this->executeNotificationStep($step, $context),
        'conditional' => $this->executeConditionalBranch($step, $context),
        default => throw new InvalidStepTypeException($step->type),
    };
    
    // Store step result
    WorkflowStepResult::create([
        'workflow_execution_id' => $execution->id,
        'step_id' => $step->id,
        'result' => $result,
        'completed_at' => now(),
    ]);
    
    return $execution;
}

private function executeConditionalBranch(Step $step, array $context): mixed
{
    // Evaluate condition
    $condition = $step->config['condition'];
    $conditionMet = $this->evaluateCondition($condition, $context);
    
    // Execute appropriate branch
    if ($conditionMet) {
        return $this->executeStep($step->config['then_step'], $context);
    } else {
        return $this->executeStep($step->config['else_step'] ?? null, $context);
    }
}
```

---

## Agent Execution Pipeline

### Complete Execution Flow

```
User Request
    ↓
AgentController::execute
    ↓
Validate Request (FormRequest)
    ↓
AgentOrchestrationService::executeAgent
    ├─ Validate agent status
    ├─ Enrich context (add history, user info, etc.)
    ├─ Retrieve agent memory (recent interactions)
    ├─ Call AI Provider
    │  ├─ Prepare system prompt
    │  ├─ Format message history
    │  ├─ Send to LLM API
    │  └─ Parse response
    ├─ Process response
    │  ├─ Extract citations
    │  ├─ Calculate confidence
    │  └─ Format for frontend
    ├─ Store execution record
    ├─ Update metrics
    │  ├─ Token usage
    │  ├─ Response time
    │  └─ Success rate
    ├─ Store new memories
    │  ├─ Episodic (this interaction)
    │  └─ Semantic (extracted facts)
    └─ Event::dispatch(AgentTaskCompleted)
        ├─ Sync Listeners
        │  ├─ BroadcastResponse (WebSocket)
        │  └─ LogActivity (Audit)
        └─ Queued Listeners
           ├─ TriggerWorkflows
           ├─ UpdateContactEngagement
           └─ ExtractMetadata
    ↓
Response sent to Frontend
    ↓
WebSocket notification to other clients
```

### Memory Integration in Execution

```php
// Before sending to LLM, include recent memories
private function enrichWithMemory(Agent $agent, string $userInput): array
{
    // Get different memory types
    $episodic = $this->memoryService->retrieve(
        agent: $agent,
        type: 'episodic',
        limit: 5  // Last 5 interactions
    );
    
    $semantic = $this->memoryService->retrieve(
        agent: $agent,
        query: $userInput,
        type: 'semantic',
        limit: 3  // Top 3 relevant facts
    );
    
    $structured = $this->memoryService->retrieve(
        agent: $agent,
        type: 'structured',
        limit: 10  // All structured facts
    );
    
    // Build context for LLM
    return [
        'user_input' => $userInput,
        'recent_interactions' => $episodic->pluck('content'),
        'relevant_knowledge' => $semantic->pluck('content'),
        'known_facts' => $structured->pluck('content'),
        'agent_instructions' => $agent->system_prompt,
    ];
}
```

---

## Memory Management Detailed

### Episodic Memory (Event-Based)

**Use Case**: Store events and interactions  
**Retention**: 90 days (configurable)  
**Example**:
```
"User mentioned they're looking to expand to EU market"
"Customer approved budget for Q3 implementation"
"Agent suggested 3-month timeline"
```

```php
// Store episodic memory
$this->memoryService->store(
    type: 'episodic',
    content: 'Customer approved budget for Q3 implementation',
    agent: $agent,
    conversation: $conversation,
    importance: 0.9,
    retentionPolicy: 'decay'  // Importance decreases over time
);
```

### Semantic Memory (Fact-Based)

**Use Case**: Store knowledge and facts  
**Retention**: Permanent unless explicitly pruned  
**Example**:
```
"ABC Corp is in the tech industry"
"Customer has 500+ employees"
"Key contact is John Smith (VP Sales)"
```

```php
// Store with vector embedding for similarity search
$this->memoryService->store(
    type: 'semantic',
    content: 'ABC Corp specializes in cloud infrastructure',
    agent: $agent,
    importance: 0.95,
    retentionPolicy: 'permanent'
);

// Later: query by similarity
$results = $this->memoryService->retrieve(
    agent: $agent,
    query: 'What does the customer do?',
    type: 'semantic'
);
```

### Structured Memory (Schema-Based)

**Use Case**: Store facts in structured format  
**Example**:
```json
{
  "company": "ABC Corp",
  "industry": "Technology",
  "employees": 500,
  "founded": 2010,
  "funding_stage": "Series B"
}
```

```php
$this->memoryService->store(
    type: 'structured',
    content: json_encode([
        'company_name' => 'ABC Corp',
        'industry' => 'Technology',
        'employee_count' => 500,
        'stage' => 'Series B',
    ]),
    agent: $agent,
    importance: 1.0
);
```

### Memory Pruning Strategy

```php
public function prune(Agent $agent, array $criteria = []): int
{
    $query = Memory::where('agent_id', $agent->id);
    
    // Apply criteria
    if (isset($criteria['min_importance'])) {
        $query->where('importance_score', '<', $criteria['min_importance']);
    }
    
    if (isset($criteria['older_than_days'])) {
        $query->where('created_at', '<', now()->subDays($criteria['older_than_days']));
    }
    
    if (isset($criteria['type'])) {
        $query->where('type', $criteria['type']);
    }
    
    // Apply decay policy
    $query->where(function ($q) {
        $q->where('retention_policy', 'decay')
          ->whereRaw('importance_score < importance_score * 0.1');
    });
    
    // Delete and count
    $count = $query->delete();
    
    // Update agent memory usage
    $this->updateAgentMemoryUsage($agent);
    
    event(new MemoryPruned($agent, $count));
    
    return $count;
}
```

---

## Workflow Execution Engine

### Step Types Implementation

#### AgentExecutionStep
```php
private function executeAgentStep(Step $step, array $context): string
{
    // Interpolate template with context
    $prompt = $this->interpolateTemplate(
        $step->config['input_template'],
        $context
    );
    
    // Execute agent
    $result = $this->agentService->execute(
        agent_id: $step->config['agent_id'],
        input: $prompt,
        context: $context
    );
    
    // Store result in context for next steps
    $context[$step->config['output_path']] = $result->output;
    
    return $result->output;
}
```

#### ApiCallStep
```php
private function executeApiCallStep(Step $step, array $context): array
{
    $url = $this->interpolateTemplate($step->config['url'], $context);
    $payload = $this->interpolateTemplate($step->config['payload'], $context);
    
    $response = Http::timeout(30)
        ->withHeaders($step->config['headers'] ?? [])
        ->{strtolower($step->config['method'])}($url, $payload);
    
    if (!$response->successful()) {
        throw new ApiCallFailedException($response->status());
    }
    
    return $response->json();
}
```

#### NotificationStep
```php
private function executeNotificationStep(Step $step, array $context): bool
{
    $this->notificationService->send(
        recipient: $this->interpolateTemplate($step->config['recipient'], $context),
        channel: $step->config['channel'],
        subject: $this->interpolateTemplate($step->config['subject'], $context),
        content: $this->interpolateTemplate($step->config['template'], $context),
        metadata: $context
    );
    
    return true;
}
```

---

## Event System & Broadcasting

### Event-Listener Registration

```php
// EventServiceProvider::boot()
protected $listen = [
    // Contact Events
    ContactCreated::class => [
        LogContactActivity::class,
        InvalidateContactCache::class,
        SendContactNotification::class,
    ],
    
    // Message Events
    MessageReceived::class => [
        ProcessWithAI::class,           // Queued
        ExtractCitations::class,        // Queued
        UpdateMemory::class,            // Queued
        BroadcastMessageToClients::class, // Sync
    ],
    
    // Workflow Events
    WorkflowExecuted::class => [
        LogWorkflowExecution::class,
        UpdateWorkflowMetrics::class,
        TriggerDependentWorkflows::class, // Queued
    ],
];
```

### Broadcasting Example

```php
class MessageReceived implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    
    public function __construct(
        public Message $message,
        public Conversation $conversation
    ) {}
    
    public function broadcastOn(): Channel
    {
        return new PrivateChannel('conversation.' . $this->conversation->id);
    }
    
    public function broadcastAs(): string
    {
        return 'message.received';
    }
    
    public function broadcastWith(): array
    {
        return [
            'message' => $this->message->only('id', 'content', 'role', 'created_at'),
            'sender' => [
                'type' => $this->message->sender_type,
                'id' => $this->message->sender_id,
            ],
        ];
    }
}
```

---

## Error Handling Patterns

### Service Exception Handling

```php
public function executeAgent(Agent $agent, string $input): AgentExecution
{
    try {
        return $this->performExecution($agent, $input);
    } catch (AgentNotFoundException $e) {
        Log::error('Agent not found', ['agent_id' => $agent->id, 'error' => $e]);
        throw new HttpException(404, 'Agent not found');
    } catch (AIProviderException $e) {
        Log::warning('AI Provider failed', ['provider' => $agent->model, 'error' => $e]);
        // Fallback to secondary provider
        return $this->fallbackExecution($agent, $input);
    } catch (RateLimitException $e) {
        Log::warning('Rate limit exceeded', ['agent_id' => $agent->id]);
        throw new HttpException(429, 'Rate limit exceeded');
    } catch (Exception $e) {
        Log::error('Unexpected error during agent execution', ['error' => $e]);
        throw new HttpException(500, 'Internal server error');
    }
}
```

### Circuit Breaker Pattern

```php
class AIProviderCircuitBreaker
{
    private const FAILURE_THRESHOLD = 5;
    private const RESET_TIMEOUT = 300; // 5 minutes
    
    public function call(callable $callback): mixed
    {
        $key = 'circuit_breaker:ai_provider';
        
        // Check if open
        if (Cache::get($key) === 'open') {
            throw new CircuitBreakerOpenException();
        }
        
        try {
            $result = $callback();
            // Success: reset failure count
            Cache::forget("$key:failures");
            return $result;
        } catch (Exception $e) {
            // Increment failure count
            $failures = Cache::increment("$key:failures");
            
            if ($failures >= self::FAILURE_THRESHOLD) {
                Cache::put($key, 'open', self::RESET_TIMEOUT);
            }
            
            throw $e;
        }
    }
}
```

---

## Caching Strategies

### Multi-Layer Caching

```php
// Layer 1: Memory (current request)
private array $requestCache = [];

// Layer 2: Redis (all instances)
Cache::put("contact.{$id}", $contact, 3600); // 1 hour

// Layer 3: Database (source of truth)
$contact = Contact::find($id);

// Usage pattern
public function getContact(string $id): Contact
{
    // Check request cache first (fastest)
    if (isset($this->requestCache[$id])) {
        return $this->requestCache[$id];
    }
    
    // Check Redis (fast, shared)
    $contact = Cache::get("contact.{$id}");
    
    if (!$contact) {
        // Fetch from database
        $contact = Contact::find($id);
        
        // Cache in Redis
        Cache::put("contact.{$id}", $contact, 3600);
    }
    
    // Cache in memory for this request
    $this->requestCache[$id] = $contact;
    
    return $contact;
}
```

### Cache Invalidation on Updates

```php
public function updateContact(Contact $contact, array $data): Contact
{
    // Update database
    $contact->update($data);
    
    // Invalidate related caches
    Cache::forget("contact.{$contact->id}");
    Cache::forget("contact.{$contact->id}.engagement");
    Cache::forget("user.{$contact->user_id}.contacts");
    
    // Broadcast update to clients
    event(new ContactUpdated($contact));
    
    return $contact;
}
```

---

## Database Query Patterns

### Efficient Eager Loading

```php
// Bad: N+1 problem
$contacts = Contact::all();
foreach ($contacts as $contact) {
    echo $contact->user->name; // Query for each contact
}

// Good: Single query with eager loading
$contacts = Contact::with('user')
    ->with('conversations.messages')
    ->with('tasks')
    ->get();

foreach ($contacts as $contact) {
    echo $contact->user->name; // No additional queries
}
```

### Query Scopes for Reusability

```php
class Contact extends Model
{
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
    
    public function scopeHighEngagement($query, float $threshold = 0.7)
    {
        return $query->where('engagement_score', '>=', $threshold);
    }
    
    public function scopeWithAgent($query, Agent $agent)
    {
        return $query->whereHas('agent', fn($q) => $q->where('id', $agent->id));
    }
}

// Usage
$contacts = Contact::active()
    ->highEngagement()
    ->with('user', 'conversations')
    ->paginate(50);
```

### Chunking Large Datasets

```php
// Process 100,000 contacts without memory exhaustion
Contact::chunk(1000, function ($contacts) {
    foreach ($contacts as $contact) {
        // Process contact
        $contact->updateEngagementScore();
    }
});

// With eager loading
Contact::with('user', 'conversations')
    ->chunk(1000, function ($contacts) {
        foreach ($contacts as $contact) {
            // Process
        }
    });
```

---

## Authentication & Authorization Deep Dive

### Token Generation & Validation

```php
// Generate token
$user = User::find(1);
$token = $user->createToken('api-token', ['read:contacts', 'write:agents'])
    ->plainTextToken;

// Token structure: {user_id}|{token_hash}
// Example: 1|Hs3xNqCqB7mL8vN2qQ4rS6tU8vW0xY2z

// Validation happens automatically via middleware
// app/Http/Middleware/AuthorizationMiddleware
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/api/v1/contacts', [ContactController::class, 'index']);
});
```

### Policy-Based Authorization

```php
// ContactPolicy
class ContactPolicy
{
    public function view(User $user, Contact $contact): bool
    {
        return $user->id === $contact->user_id || $user->is_admin;
    }
    
    public function update(User $user, Contact $contact): bool
    {
        return $user->id === $contact->user_id;
    }
    
    public function delete(User $user, Contact $contact): bool
    {
        return $user->id === $contact->user_id && !$contact->is_locked;
    }
}

// Usage in controller
class ContactController
{
    public function update(Contact $contact, UpdateContactRequest $request)
    {
        $this->authorize('update', $contact);
        
        $contact->update($request->validated());
        return $contact;
    }
}

// Usage in Blade
@can('update', $contact)
    <button>Edit Contact</button>
@endcan
```

---

## Queue Job System

### Creating Custom Jobs

```bash
php artisan make:job ProcessLargeReport
```

```php
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

class ProcessLargeReport implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;
    
    // Retry configuration
    public $tries = 3;
    public $backoff = [10, 60, 300]; // 10s, 1m, 5m
    public $timeout = 300; // 5 minutes
    
    public function __construct(
        public Contact $contact,
        public string $reportType
    ) {
        $this->onQueue('long-running');
    }
    
    public function handle()
    {
        try {
            // Process report
            $report = $this->generateReport();
            
            // Send notification
            Notification::send($this->contact->user, 
                new ReportReady($report));
                
        } catch (Exception $e) {
            Log::error('Report generation failed', [
                'contact_id' => $this->contact->id,
                'error' => $e->getMessage(),
            ]);
            
            // Will retry based on $tries and $backoff
            throw $e;
        }
    }
    
    public function failed(Exception $exception)
    {
        // Handle permanent failure
        Log::critical('Report generation permanently failed', [
            'contact_id' => $this->contact->id,
            'exception' => $exception,
        ]);
        
        // Notify user
        Notification::send($this->contact->user,
            new ReportGenerationFailed($exception));
    }
}
```

### Job Dispatching

```php
// Dispatch immediately
ProcessLargeReport::dispatch($contact, 'annual');

// Dispatch with delay
ProcessLargeReport::dispatch($contact, 'annual')
    ->delay(now()->addHours(1));

// Dispatch to specific queue
ProcessLargeReport::dispatch($contact, 'annual')
    ->onQueue('long-running');

// Chain multiple jobs
ProcessLargeReport::dispatch($contact, 'annual')
    ->chain([
        new SendReportNotification($contact),
        new UpdateReportMetrics($contact),
    ]);
```

---

## Utility Functions & Helpers

### Common Helpers

```php
// Format currency
format_currency(1500, 'USD'); // $1,500.00

// Parse engagement score
$engagement = calculate_engagement_score([
    'interaction_frequency' => 0.8,
    'response_time' => 0.9,
    'recency' => 0.75,
]);

// Sanitize input
sanitize_input('<script>alert("xss")</script>');

// Generate unique reference
generate_reference_id(); // REF-2026-05-25-ABC123

// Format duration
format_duration(3661); // 1h 1m 1s

// Chunk array
chunk_array([1,2,3,4,5], 2); // [[1,2], [3,4], [5]]
```

### Model Helpers

```php
// Check if user owns resource
if ($user->owns($contact)) {
    // User can modify
}

// Get user's statistics
$stats = $user->getStatistics(); // [
//     'total_contacts' => 156,
//     'active_conversations' => 12,
//     'pending_tasks' => 5,
// ]

// Get contact's relationship status
$contact->getRelationshipStatus();
// 'prospect', 'customer', 'partner'
```

---

## Testing Utilities & Factories

### Model Factories

```php
// Generate test data
$contact = Contact::factory()->create();

$contacts = Contact::factory()
    ->count(10)
    ->create();

// With specific attributes
$contact = Contact::factory()
    ->for(User::factory())
    ->create([
        'name' => 'John Doe',
        'engagement_score' => 0.9,
    ]);

// Relationships
$conversation = Conversation::factory()
    ->for($contact)
    ->has(Message::factory()->count(5))
    ->create();
```

### Test Helpers

```php
// Create authenticated request
$response = $this->actingAs($user)
    ->postJson('/api/v1/contacts', $data);

// Assert JSON structure
$response->assertJsonStructure([
    'data' => ['id', 'name', 'email']
]);

// Assert database has record
$this->assertDatabaseHas('contacts', [
    'email' => 'john@example.com'
]);

// Assert event fired
Event::fake();
$this->postJson('/api/v1/contacts', $data);
Event::assertDispatched(ContactCreated::class);

// Assert job queued
Queue::fake();
ProcessAIResponse::dispatch($message);
Queue::assertPushed(ProcessAIResponse::class);
```

---

## Summary of Key Patterns

### Design Patterns Used
1. **Service Layer**: Encapsulate business logic
2. **Repository**: Abstract data access
3. **Strategy**: Multiple AI provider implementations
4. **Observer**: Event system for loose coupling
5. **Command**: Queue jobs for async processing
6. **Factory**: Model factories for testing
7. **Circuit Breaker**: AI provider resilience
8. **Caching**: Multi-layer cache strategy
9. **Policy**: Authorization rules

### Best Practices
- Use eager loading to prevent N+1 queries
- Implement proper error handling with specific exceptions
- Cache frequently accessed data
- Use events for decoupled components
- Queue long-running operations
- Implement authorization checks
- Use transactions for data consistency
- Write comprehensive tests
- Document complex logic with inline comments
- Monitor and log important operations

---

**End of Developer Reference Manual**
