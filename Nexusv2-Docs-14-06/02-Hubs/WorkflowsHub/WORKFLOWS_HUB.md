# WorkflowsHub — Full Documentation

## Hub Overview

WorkflowsHub provides visual, event-driven automation. Users create multi-step workflows using a drag-and-drop canvas (React Flow). Workflows can be triggered manually, on a schedule, by system events, or via webhooks.

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/workflows` | `WorkflowController@index` | List workflows |
| POST | `/api/workflows` | `WorkflowController@store` | Create workflow |
| GET | `/api/workflows/{id}` | `WorkflowController@show` | Workflow details |
| PUT | `/api/workflows/{id}` | `WorkflowController@update` | Update workflow |
| DELETE | `/api/workflows/{id}` | `WorkflowController@destroy` | Delete workflow |
| POST | `/api/workflows/{id}/execute` | `WorkflowController@execute` | Manual trigger |
| GET | `/api/workflows/{id}/progress` | `WorkflowController@getProgress` | Execution progress |
| GET | `/api/workflows/{id}/executions` | List execution history |
| GET | `/api/workflows/templates` | `WorkflowController@getTemplates` | Template library |
| POST | `/api/workflows/{id}/schedules` | Create cron schedule |
| POST | `/api/workflows/{id}/event-triggers` | Create event trigger |
| POST | `/api/workflows/{id}/webhooks` | Create webhook trigger |
| GET | `/api/workflow-webhooks/{id}` | `WorkflowWebhookController` | Get webhook URL |
| POST | `/api/webhooks/workflow/{token}` | Inbound webhook endpoint |

---

## 1.2 Workflow Data Structure

```json
{
  "id": "uuid",
  "name": "Contact Welcome Workflow",
  "trigger_type": "event",
  "trigger_config": {
    "event": "contact.created",
    "conditions": { "type": "individual" }
  },
  "steps": [
    {
      "id": "step-1",
      "type": "send_notification",
      "config": {
        "template_id": "welcome-email",
        "channel": "email"
      }
    },
    {
      "id": "step-2",
      "type": "ai_inference",
      "config": {
        "prompt": "Generate a personalized intro for {{contact.name}}",
        "model": "gpt-4o-mini"
      },
      "depends_on": ["step-1"]
    },
    {
      "id": "step-3",
      "type": "update_contact",
      "config": {
        "field": "status",
        "value": "onboarded"
      },
      "depends_on": ["step-2"]
    }
  ],
  "nodes": [...],   // React Flow visual positions
  "edges": [...],   // React Flow connections
  "error_handling": {
    "on_step_failure": "abort",   // or "continue" or "retry"
    "max_retries": 3
  }
}
```

---

## 1.3 Step Types

| Step Type | Description | Config Keys |
|-----------|-------------|-------------|
| `ai_inference` | Call an LLM with a prompt | `prompt`, `model`, `output_var` |
| `send_notification` | Send email/SMS/WhatsApp | `template_id`, `channel`, `contact_id` |
| `update_contact` | Modify a contact field | `contact_id`, `field`, `value` |
| `execute_agent` | Run an AI agent | `agent_id`, `context` |
| `http_request` | Call an external API | `url`, `method`, `headers`, `body` |
| `wait_for_event` | Pause until an event occurs | `event`, `timeout` |
| `delay` | Wait for a duration | `duration_minutes` |
| `condition` | Branch based on condition | `condition`, `then`, `else` |
| `loop` | Iterate over a collection | `collection`, `steps` |
| `memory_write` | Store to memory | `memory_type`, `content` |

---

## 1.4 Core Services

### WorkflowExecutor
```php
// Executes a workflow
$result = $executor->execute($workflow, $context);
// → Resolves step order (dependencies)
// → Executes steps sequentially or in parallel
// → Handles retry logic per WorkflowErrorHandler
// → Returns: { success, steps_completed, log }
```

### WorkflowValidationService
```php
// Validates workflow structure before save/execute
$validation = $validator->validateWorkflow($workflow);
// Checks: step types, required config, circular deps
```

### WorkflowErrorHandler
```php
// Determines action on step failure
$action = $errorHandler->handleStepFailure($step, $error, $config);
// Returns: 'retry' | 'abort' | 'continue_next'
```

---

## 1.5 Trigger Types

### Schedule (Cron)
```
WorkflowSchedule: { cron_expression: "0 9 * * 1-5", timezone: "UTC" }
SchedulerWorker command polls → triggers WorkflowExecutor
```

### Event
```
WorkflowEventTrigger: { event_name: "contact.created", conditions: {...} }
Laravel event fired → Listener checks matching triggers → Executes workflow
```

### Webhook
```
WorkflowWebhook: { token: "unique-secure-token" }
POST /api/webhooks/workflow/{token} → validates → executes workflow
```

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/workflows/page.tsx`)

Features:
- Workflow list with status, last run, trigger type
- Create workflow wizard
- Visual workflow canvas editor (React Flow)
- Trigger configuration panel
- Execution history log

## 2.2 Visual Canvas

Built with **@xyflow/react** (React Flow v12):

```typescript
// app/workflows/page.tsx
const [nodes, setNodes] = useNodesState(initialNodes);
const [edges, setEdges] = useEdgesState(initialEdges);

// Custom node types
const nodeTypes = {
  ai_inference: NxWorkflowNode,
  send_notification: NxWorkflowNode,
  // ...all step types
};
```

### Key Workflow Components

| Component | Purpose |
|-----------|---------|
| `NxWorkflowCanvas` | React Flow canvas wrapper |
| `NxWorkflowNode` | Individual workflow step node |

## 2.3 Workflow Execution Monitoring

```typescript
// Real-time execution progress
Echo.private(`nexus.workflows.${workflowId}`)
  .listen('WorkflowStepCompleted', (e) => highlightStep(e.step_id))
  .listen('WorkflowCompleted', (e) => showResult(e))
  .listen('WorkflowFailed', (e) => showError(e));
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
