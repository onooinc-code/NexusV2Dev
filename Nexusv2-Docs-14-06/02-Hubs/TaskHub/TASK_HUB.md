# TaskHub — Full Documentation

## Hub Overview

TaskHub manages the queue-based task execution system. Tasks are units of work executed asynchronously by agents, workflows, or user triggers. The hub provides visibility into all tasks: pending, running, completed, failed, and dead-lettered.

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/tasks` | `TaskController@index` | List tasks (filterable) |
| POST | `/api/tasks` | `TaskController@store` | Create task |
| GET | `/api/tasks/{id}` | `TaskController@show` | Task details + logs |
| PUT | `/api/tasks/{id}` | `TaskController@update` | Update task |
| DELETE | `/api/tasks/{id}` | `TaskController@destroy` | Delete task |
| GET | `/api/tasks/stats` | `TaskController@getStats` | Task statistics |
| GET | `/api/tasks/active` | `TaskController@getActive` | Currently running tasks |
| GET | `/api/tasks/queue-stats` | `TaskController@getQueueStats` | Queue depth and metrics |
| GET | `/api/tasks/routing-stats` | `TaskController@getRoutingStats` | Routing analytics |
| POST | `/api/tasks/{id}/cancel` | `TaskController@cancel` | Cancel pending/running task |
| POST | `/api/tasks/{id}/pause` | `TaskController@pause` | Pause task |
| POST | `/api/tasks/{id}/resume` | `TaskController@resume` | Resume paused task |
| GET | `/api/admin/dlq` | `Admin\DlqController` | Dead Letter Queue |
| POST | `/api/admin/dlq/{id}/retry` | Retry DLQ task |
| POST | `/api/admin/dlq/{id}/discard` | Discard DLQ task |

---

## 1.2 Task Model Fields

**Table:** `agent_tasks`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `agent_id` | UUID | Executing agent (nullable) |
| `workflow_id` | UUID | Parent workflow (nullable) |
| `workflow_execution_id` | UUID | Specific execution (nullable) |
| `title` | string | Task title |
| `type` | string | Task type category |
| `status` | enum | `pending`, `queued`, `running`, `paused`, `completed`, `cancelled`, `failed` |
| `priority` | int | 1 (lowest) to 10 (highest) |
| `input` | JSON | Task input parameters |
| `output` | JSON | Task results/output |
| `context` | JSON | Execution context |
| `error` | text | Failure error message |
| `retry_count` | int | Number of retries |
| `max_retries` | int | Max allowed retries |
| `started_at` | timestamp | Execution start |
| `completed_at` | timestamp | Execution end |
| `timeout_at` | timestamp | Hard timeout |

---

## 1.3 Core Services

### TaskManagementService
```php
// Create task
$task = $service->create([
  'title'       => 'Analyze contact sentiment',
  'type'        => 'contact_analysis',
  'agent_id'    => $agentId,
  'priority'    => 5,
  'input'       => ['contact_id' => $contactId],
]);

// Cancel task
$service->cancel($taskId, reason: 'User requested cancellation');

// Get task statistics
$stats = $service->getStats();
// Returns: { total, pending, running, completed, failed, ... }
```

### TaskQueueService
```php
// Dispatch task to appropriate queue
$service->dispatch($task);
// Queue selection: based on task type and priority
// llm-inference → AI tasks
// messages → message tasks
// memory → memory tasks
// default → general tasks
```

### TaskRoutingService
```php
// Route task to correct handler
$handler = $service->resolve($task);
// Returns appropriate Job class for the task type
```

### TaskRetryService
```php
// Calculate backoff: exponential with jitter
// Default: 30s, 90s, 270s (3 retries)
$delay = $service->calculateBackoff($task);
$service->retry($task);
$service->moveToDeadLetter($task); // After max retries
```

### TaskLogService
```php
// Log task execution details
$service->log($task, 'info', 'Processing step 2 of 5');
$service->log($task, 'error', 'API timeout on step 3');
```

### DeadLetterQueueService
```php
// Tasks that failed all retries land here
$dlq = $service->getAll();
$service->retry($deadLetterTaskId); // Requeue
$service->discard($deadLetterTaskId); // Permanently remove
```

---

## 1.4 Task Execution Flow

```
TaskManagementService.create() → AgentTask saved (status: pending)
  ↓
TaskQueueService.dispatch() → Job dispatched to queue
  ↓
Queue Worker picks up job
  ↓
TaskRoutingService.resolve() → Gets appropriate handler
  ↓
Handler.execute() → Runs task logic
  ↓
TaskLogService.log() → Records steps
  ↓
On success: task.status = 'completed', output saved
On failure (retryable): task.retry_count++, re-queued with backoff
On failure (exhausted): TaskRetryService.moveToDeadLetter()
  ↓
WebSocket: TaskProgressUpdated / TaskCompleted / TaskFailed events
```

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/tasks/page.tsx`)

Features:
- Task list with status color coding
- Filter by status, type, agent, date range
- Task detail panel with execution log
- Real-time status updates via WebSocket
- Queue statistics panel (depth, throughput)
- Dead Letter Queue section (admin only)

## 2.2 Key Components

| Component | Purpose |
|-----------|---------|
| `TaskCard` (`app/tasks/TaskCard.tsx`) | Task summary card |
| `NxTaskModal` | Full task detail modal |
| `NxTaskExecutionLog` | Step-by-step task log viewer |
| `NxQueuePill` | Queue depth indicator |
| `GlobalJobMonitor` | Floating monitor for active jobs |
| `RealTimeJobListener` | WebSocket job event subscriber |

## 2.3 Real-Time Task Updates

```typescript
Echo.private(`nexus.tasks.${userId}`)
  .listen('TaskCreated', (e) => addTask(e.task))
  .listen('TaskStatusChanged', (e) => updateTask(e.task_id, e.status))
  .listen('TaskCompleted', (e) => markComplete(e.task_id, e.output))
  .listen('TaskFailed', (e) => markFailed(e.task_id, e.error));

// Per-task channel for detailed progress
Echo.private(`nexus.task.${taskId}`)
  .listen('TaskProgressUpdated', (e) => updateProgress(e.percent, e.log));
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
