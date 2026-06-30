# Nexus v2 — Data Models Reference

## 1. Core Entity Relationships

```
User
 └── has many → Contacts
 └── has many → Settings
 └── has many → Logs

Contact
 ├── has many → ContactIdentifiers  (email, phone, whatsapp_id)
 ├── has many → ContactNotes
 ├── has many → ContactTags
 ├── has many → ContactCustomFields
 ├── has many → ContactAliases
 ├── has many → ContactRules
 ├── has many → ContactPreferences
 ├── has many → ContactMessages
 ├── has many → ContactRelationships (to other Contacts)
 ├── has many → Memories
 ├── has many → ContactTopics
 ├── has many → ContactAnalysisRuns
 └── has many → NotificationLogs

Conversation
 ├── belongs to → Contact
 ├── belongs to → Topic
 ├── has many → Messages
 └── has many → ConversationSessions

Agent
 ├── has many → AgentTasks
 ├── has many → AgentTools
 ├── has many → AgentSkills
 ├── belongs to → AgentPersona (optional)
 └── has many → MCPServers (pivot)

Workflow
 ├── has many → WorkflowVersions
 ├── has many → WorkflowExecutions
 ├── has many → WorkflowSchedules
 ├── has many → WorkflowEventTriggers
 └── has many → WorkflowWebhooks

Memory (5 types stored in same table)
 ├── belongs to → Contact (optional)
 └── belongs to → Conversation (optional)
```

---

## 2. Model Definitions

### 2.1 User
**Table:** `users`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | string | Display name |
| `email` | string | Unique login email |
| `password` | string | Bcrypt hashed |
| `is_admin` | boolean | Admin flag |
| `is_super_admin` | boolean | Super admin flag |
| `workspace_id` | UUID | Multi-tenant workspace |
| `email_verified_at` | timestamp | Email verification |
| `remember_token` | string | Auth remember |
| `created_at` | timestamp | — |
| `updated_at` | timestamp | — |

---

### 2.2 Contact
**Table:** `contacts`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner |
| `name` | string | Full name |
| `type` | enum | `individual`, `organization`, `system` |
| `status` | enum | `active`, `inactive`, `archived`, `blocked` |
| `email` | string | Primary email (nullable) |
| `phone` | string | Primary phone (nullable) |
| `whatsapp_id` | string | WhatsApp identifier (nullable) |
| `avatar_url` | string | Profile image URL |
| `language` | string | Preferred language |
| `timezone` | string | Timezone |
| `location` | string | Location string |
| `bio` | text | Description / bio |
| `company` | string | Organization name |
| `job_title` | string | Role / title |
| `metadata` | JSON | Flexible extra data |
| `settings` | JSON | Contact-level settings |
| `tags` | JSON | Cached tag array |
| `source` | string | Import source (`csv`, `api`, `manual`, `whatsapp`) |
| `last_contacted_at` | timestamp | Last interaction |
| `deleted_at` | timestamp | Soft delete |

---

### 2.3 Memory
**Table:** `memories`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner |
| `contact_id` | UUID | Related contact (nullable) |
| `conversation_id` | UUID | Source conversation (nullable) |
| `type` | enum | `episodic`, `semantic`, `structured`, `graph`, `working` |
| `content` | text | Memory text |
| `summary` | text | Condensed version |
| `embedding` | JSON | Vector embedding |
| `confidence` | float | 0.0–1.0 confidence score |
| `relevance_score` | float | Computed relevance |
| `source` | string | Origin (`conversation`, `analysis`, `import`) |
| `metadata` | JSON | Extra structured data |
| `expires_at` | timestamp | Auto-expiry (for working memory) |
| `extraction_source` | string | Which service extracted this |
| `extraction_run_id` | UUID | Batch extraction reference |

---

### 2.4 Agent
**Table:** `agents`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner |
| `name` | string | Agent name |
| `type` | enum | `autonomous`, `reflection`, `supervisor`, `specialized`, `team` |
| `status` | enum | `idle`, `running`, `completed`, `error`, `paused` |
| `persona_id` | UUID | Linked AgentPersona (nullable) |
| `description` | text | Purpose description |
| `instructions` | text | System prompt / instructions |
| `capabilities` | JSON | List of capabilities |
| `configuration` | JSON | Runtime config (temperature, max_tokens, etc.) |
| `model` | string | Default AI model name |
| `max_iterations` | int | Max execution loops (for autonomous) |
| `max_execution_time` | int | Timeout in seconds |
| `execution_log` | JSON | Last execution log |
| `last_run_at` | timestamp | Last execution time |

---

### 2.5 Workflow
**Table:** `workflows`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner |
| `name` | string | Workflow name |
| `description` | text | Purpose |
| `status` | enum | `draft`, `active`, `paused`, `archived` |
| `trigger_type` | enum | `manual`, `schedule`, `event`, `webhook` |
| `trigger_config` | JSON | Trigger-specific configuration |
| `steps` | JSON | Ordered array of step definitions |
| `nodes` | JSON | React Flow node positions |
| `edges` | JSON | React Flow edge definitions |
| `variables` | JSON | Workflow-level variables |
| `settings` | JSON | Execution settings |
| `error_handling` | JSON | Error strategy config |
| `version` | int | Current version number |
| `last_run_at` | timestamp | Last execution |
| `run_count` | int | Total runs |

---

### 2.6 AIModel
**Table:** `ai_models`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `provider_id` | UUID | Parent AI provider |
| `name` | string | Model identifier (e.g., `gpt-4o`) |
| `display_name` | string | Human-readable name |
| `type` | enum | `chat`, `completion`, `embedding`, `vision`, `code` |
| `capabilities` | JSON | List of capabilities |
| `context_window` | int | Max token context |
| `max_output_tokens` | int | Max output tokens |
| `input_cost_per_1k` | decimal | USD per 1K input tokens |
| `output_cost_per_1k` | decimal | USD per 1K output tokens |
| `speed_tier` | enum | `ultra_fast`, `fast`, `medium`, `slow` |
| `quality_tier` | enum | `premium`, `standard`, `economy` |
| `routing_profiles` | JSON | Intent-to-routing preferences |
| `is_active` | boolean | Available for use |

---

### 2.7 HedrasoulSession
**Table:** `hedrasoul_sessions`

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `title` | string | Session title |
| `status` | enum | `active`, `archived`, `closed` |
| `topic` | string | Current conversation topic |
| `task_count` | int | Tasks created in session |
| `approval_count` | int | Approvals requested in session |
| `instruction_version_id` | bigint | Active instruction set |
| `last_autonomy_mode` | string | Last autonomy mode used |
| `opened_at` | timestamp | Session start |
| `closed_at` | timestamp | Session end |
| `summary` | text | AI-generated session summary |

---

### 2.8 SoulyRuntimeProfile
**Table:** `souly_runtime_profiles`

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `autonomy_mode` | enum | `chat_only`, `copilot`, `operator`, `autopilot_limited`, `emergency_paused` |
| `active_model_instance_id` | bigint | Current AI model in use |
| `active_instruction_version_id` | bigint | Active instruction set |
| `active_persona_id` | bigint | Active agent persona |
| `tool_permissions` | JSON | Per-tool allow/deny map |
| `memory_access` | boolean | Can read/write memories |
| `contact_access` | boolean | Can read/modify contacts |
| `task_execution_access` | boolean | Can create/run tasks |
| `workflow_execution_access` | boolean | Can trigger workflows |
| `external_messaging_access` | boolean | Can send messages |
| `is_quarantined` | boolean | Emergency lock |

---

### 2.9 NotificationLog
**Table:** `notification_logs`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `contact_id` | UUID | Recipient contact |
| `template_id` | UUID | Used template |
| `channel` | enum | `email`, `sms`, `whatsapp`, `push` |
| `status` | enum | `pending`, `sent`, `delivered`, `failed` |
| `subject` | string | Email subject |
| `body` | text | Message body |
| `metadata` | JSON | Channel-specific delivery data |
| `sent_at` | timestamp | Dispatch time |
| `error` | text | Failure reason |

---

## 3. Database Migration Timeline

| Date | Migration | Purpose |
|------|-----------|---------|
| 2026-05-17 | `create_phase_02_database_models` | Core models: contacts, conversations, agents, tasks |
| 2026-05-17 | `create_structured_memories_table` | Structured memory storage |
| 2026-05-17 | `create_graph_memory_tables` | Graph memory for relationships |
| 2026-05-19 | `create_ai_providers_table` | LLM provider management |
| 2026-05-19 | `update_ai_models_table` | AI model enhancements |
| 2026-05-19 | `create_ai_api_keys_table` | Encrypted API key storage |
| 2026-05-19 | `create_intent_routing_table` | Intent-to-model mapping |
| 2026-05-24 | `create_contacts_and_notifications_hubs_tables` | Contact hub + notifications |
| 2026-05-27 | `create_ai_audit_trails_table` | AI decision audit log |
| 2026-05-28 | `create_agent_personas_table` | Agent personality profiles |
| 2026-05-28 | `create_mcp_servers_table` | MCP server registry |
| 2026-05-30 | `create_contact_hub_vnext_tables` | ContactHub v2: topics, messages, threads |
| 2026-05-30 | `upgrade_workflows_hub_schema` | Workflow v2 with visual canvas support |
| 2026-06-01 | `create_workflow_schedules_table` | Cron-based workflow triggers |
| 2026-06-10 | `create_hedrasoul_sessions_table` | HedraSoul chat sessions |
| 2026-06-10 | `create_hedrasoul_messages_table` | HedraSoul messages with trace |
| 2026-06-10 | `create_souly_runtime_profiles_table` | Autonomy and permission profile |
| 2026-06-10 | `create_hedrasoul_approval_requests_table` | Human-in-the-loop approvals |
| 2026-06-10 | `create_souly_action_traces_table` | Full AI action audit trail |
| 2026-06-11 | `create_peopleconnect_tables` | WhatsApp messaging integration |

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
