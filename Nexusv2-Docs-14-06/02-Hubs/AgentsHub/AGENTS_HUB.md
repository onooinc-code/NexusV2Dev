# AgentsHub — Full Documentation

## Hub Overview

AgentsHub manages AI agents — configurable entities that can reason, plan, and execute complex tasks autonomously. Each agent has a type, persona, tools, skills, and execution history.

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/agents` | `AgentController@index` | List agents (filterable by type/status) |
| POST | `/api/agents` | `AgentController@store` | Create new agent |
| GET | `/api/agents/{id}` | `AgentController@show` | Agent details + config |
| PUT | `/api/agents/{id}` | `AgentController@update` | Update agent |
| DELETE | `/api/agents/{id}` | `AgentController@destroy` | Delete agent |
| POST | `/api/agents/{id}/execute` | `AgentController@execute` | Trigger agent execution |
| GET | `/api/agents/{id}/status` | `AgentController@getStatus` | Execution status |
| GET | `/api/agents/{id}/logs` | Agent runtime logs |
| GET | `/api/agent-personas` | `AgentPersonaController@index` | List personas |
| POST | `/api/agent-personas` | `AgentPersonaController@store` | Create persona |
| GET | `/api/agent-tool-library` | `AgentToolLibraryController@index` | Available tools |
| GET | `/api/mcp-servers` | `MCPServerController@index` | MCP server list |
| POST | `/api/mcp-servers` | `MCPServerController@store` | Register MCP server |

---

## 1.2 Agent Types

### AutonomousAgent
```
- Executes a task in a self-directed loop
- Loop: think → act → observe → repeat
- Max iterations: configurable (default 10)
- Max execution time: configurable timeout
- Signals completion or stop when done
- Returns: { success, iterations, execution_log }
```

### ReflectionAgent
```
- Analyzes its own decisions and outputs
- Provides self-assessment after each action
- Used for high-accuracy tasks requiring verification
- Reflects on quality before marking complete
```

### SupervisorAgent
```
- Orchestrates multiple sub-agents
- Distributes tasks across specialized agents
- Aggregates and validates results
- Handles sub-agent failures and retries
```

### SpecializedAgent
```
- Deep expertise in a narrow domain
- Single-purpose, highly accurate
- Examples: CodeReviewer, DataAnalyzer, EmailDrafter
```

### TeamAgent
```
- Multi-agent coordination layer
- Manages a team of specialized agents
- Routes tasks to the right team member
- Combines outputs into unified result
```

---

## 1.3 Core Services

### AgentExecutionService
```php
// Orchestrates full agent execution lifecycle
$result = $service->execute($agent, $context);
// → initializes lifecycle
// → resolves agent class from registry
// → calls $agentInstance->execute($context)
// → updates status to completed/error
// → logs execution result
```

### AgentLifecycleService
```php
$lifecycle->initialize($agent);   // status → 'running'
$lifecycle->complete($agent);     // status → 'completed'
$lifecycle->fail($agent, $error); // status → 'error'
$lifecycle->pause($agent);        // status → 'paused'
```

### AgentRegistry
```php
// Maps agent type strings to implementation classes
$registry->register('autonomous', AutonomousAgent::class);
$registry->resolve($agent); // Returns agent instance
```

### AgentConfigurationService
```php
// Merges: default config + agent-specific config + runtime overrides
$config = $configService->load($agent);
$config->get('temperature'); // 0.7
$config->get('max_tokens');  // 4096
```

### AgentToolExecutor
```php
// Executes agent tools (callouts to external APIs, MCP tools, etc.)
$result = $executor->execute($tool, $parameters);
```

### MCPIntegrationService
```php
// Connects agents to MCP (Model Context Protocol) servers
// MCP servers expose external tools and data sources
$tools = $mcpService->listTools($serverId);
$result = $mcpService->callTool($serverId, $toolName, $params);
```

---

## 1.4 Agent Task Flow

```
POST /api/agents/{id}/execute
  → Context provided: { task_description, inputs, priority }
  → AgentTask created (status: pending)
  → Dispatched to queue (llm-inference)
  → AgentExecutionService picks up
  → Agent.execute($context) called
  → For AutonomousAgent:
      → Loop: while(iterations < max AND !done):
          1. Build prompt from context + memories + tools
          2. Call LLM via UniversalAiGatewayService
          3. Parse output: action, tool_calls, or final answer
          4. Execute tool calls if any
          5. Update working memory with results
          6. Check: is task complete?
  → Return result
  → WebSocket broadcast: AgentTaskCompleted
```

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/agents/page.tsx`)

Features:
- Grid of agent cards (`NxAgentCard`) showing name, type, status, last run
- Filter by type, status
- Create agent wizard
- Agent detail drawer with full configuration

## 2.2 Key Components

| Component | Purpose |
|-----------|---------|
| `NxAgentCard` | Agent summary card with status orb |
| `NxAgentBadge` | Type badge (Autonomous, Reflection, etc.) |
| `NxAgentStatusOrb` | Live status indicator (idle/running/error) |
| `NxExecutionDebugger` | Debug panel showing agent step-by-step execution |
| `NxTaskExecutionLog` | Detailed execution log viewer |

## 2.3 Real-Time Updates

```typescript
Echo.private(`nexus.agents.${agentId}`)
  .listen('AgentStatusChanged', (e) => updateAgentStatus(e))
  .listen('AgentTaskCompleted', (e) => loadResult(e.task_id))
  .listen('AgentTaskFailed', (e) => showError(e));
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
