# Nexus Backend - API & Technical Specification

**Last Updated**: May 25, 2026  
**Project**: Nexus-Backend (Laravel 11)  
**Purpose**: Complete API reference and technical specifications

---

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication & Headers](#authentication--headers)
3. [Error Handling & Status Codes](#error-handling--status-codes)
4. [Contacts API Specification](#contacts-api-specification)
5. [Agents API Specification](#agents-api-specification)
6. [Conversations API Specification](#conversations-api-specification)
7. [Messages API Specification](#messages-api-specification)
8. [Workflows API Specification](#workflows-api-specification)
9. [Tasks API Specification](#tasks-api-specification)
10. [Memory API Specification](#memory-api-specification)
11. [AI Models & Routing API](#ai-models--routing-api)
12. [Integrations API](#integrations-api)
13. [Notifications API](#notifications-api)
14. [Data Models & Schemas](#data-models--schemas)

---

## API Overview

### Base URL
```
Production: https://api.nexus.example.com/api/v1
Staging:    https://staging-api.nexus.example.com/api/v1
Local:      http://localhost:8000/api/v1
```

### API Versioning
- Current Version: `v1`
- Versioning Strategy: URL-based (`/api/v1/`, `/api/v2/`)
- Backward Compatibility: 12 months minimum support for deprecated versions
- Deprecation Notice: Provided 6 months before removal

### Response Format
All responses are JSON with consistent structure:

```json
{
  "success": true,
  "message": "Resource retrieved successfully",
  "data": { /* actual data */ },
  "meta": {
    "timestamp": "2026-05-25T10:30:00Z",
    "request_id": "req-123-456-789",
    "version": "1.0"
  }
}
```

### Pagination
```json
{
  "data": [ /* array of items */ ],
  "pagination": {
    "total": 1500,
    "per_page": 50,
    "current_page": 1,
    "last_page": 30,
    "from": 1,
    "to": 50,
    "has_more": true
  }
}
```

### Rate Limiting
```
Headers:
- X-RateLimit-Limit: 1000
- X-RateLimit-Remaining: 999
- X-RateLimit-Reset: 1693305600

Limits by endpoint:
- Standard endpoints: 1000 requests/hour
- AI endpoints: 100 requests/hour
- Batch endpoints: 10 requests/hour
- WebSocket: 10 connections per user
```

---

## Authentication & Headers

### Bearer Token Authentication
```
Authorization: Bearer {token}

Example:
Authorization: Bearer 1|Hs3xNqCqB7mL8vN2qQ4rS6tU8vW0xY2z
```

### Required Headers
```
Content-Type: application/json
Authorization: Bearer {token}
X-Request-ID: {unique-identifier}  // Optional but recommended
Accept: application/json
```

### Optional Headers
```
X-Debug-Mode: true              // Enable debug info in response
X-Include-Timestamps: true      // Include creation/update timestamps
X-Include-Relationships: true   // Include nested relationships
X-Timezone: America/New_York    // Client timezone for date formatting
```

### Token Generation
```bash
# Using Tinker
php artisan tinker
$user = App\Models\User::find(1);
$token = $user->createToken('api-token')->plainTextToken;
echo $token;

# Response:
# 1|Hs3xNqCqB7mL8vN2qQ4rS6tU8vW0xY2z
```

### Token Lifecycle
- **Generation**: On user login
- **Expiry**: No default expiry (can be set per token)
- **Revocation**: `$user->tokens()->delete()`
- **Refresh**: Generate new token, revoke old token
- **Scope**: Optional (e.g., 'read:contacts', 'write:agents')

---

## Error Handling & Status Codes

### HTTP Status Codes

#### Success Codes
```
200 OK                  - Request successful, resource returned
201 Created             - Resource created successfully
202 Accepted            - Async operation accepted
204 No Content          - Success, no content to return
```

#### Client Error Codes
```
400 Bad Request         - Invalid request syntax
401 Unauthorized        - Missing or invalid authentication
403 Forbidden           - Authenticated but not authorized
404 Not Found           - Resource doesn't exist
409 Conflict            - Resource conflict (duplicate, etc.)
422 Unprocessable       - Validation failed
429 Too Many Requests   - Rate limit exceeded
```

#### Server Error Codes
```
500 Internal Error      - Server error occurred
502 Bad Gateway         - External API failure
503 Service Unavailable - Server temporarily unavailable
504 Gateway Timeout     - Request timeout
```

### Error Response Format
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["Email is required", "Email must be valid"],
    "name": ["Name must be at least 3 characters"]
  },
  "meta": {
    "error_code": "VALIDATION_ERROR",
    "timestamp": "2026-05-25T10:30:00Z"
  }
}
```

### Common Error Codes
```
VALIDATION_ERROR         - Request validation failed
AUTHENTICATION_ERROR     - Auth token invalid/missing
AUTHORIZATION_ERROR      - Not authorized for resource
NOT_FOUND_ERROR         - Resource doesn't exist
RATE_LIMIT_ERROR        - Rate limit exceeded
EXTERNAL_API_ERROR      - External API failure
DATABASE_ERROR          - Database operation failed
CONFLICT_ERROR          - Resource conflict
INTERNAL_SERVER_ERROR   - Server error
```

---

## Contacts API Specification

### List Contacts
```
GET /api/v1/contacts

Query Parameters:
- page: integer (default: 1)
- per_page: integer (default: 50, max: 100)
- sort: string (default: -created_at)
  - Prefix with '-' for descending
  - Examples: name, -engagement_score, created_at
- filter[status]: string (active, inactive, suspended)
- filter[tags]: array of strings
- search: string (searches name, email, company)
- include: array (relationships to include)
  - Examples: conversations, tasks, memories

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1-555-0000",
      "company": "Acme Corp",
      "status": "active",
      "engagement_score": 0.85,
      "interaction_count": 24,
      "last_interaction": "2026-05-25T08:30:00Z",
      "tags": ["vip", "enterprise"],
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-05-25T08:30:00Z"
    }
  ],
  "pagination": { /* ... */ }
}
```

### Create Contact
```
POST /api/v1/contacts

Body:
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "phone": "+1-555-1111",
  "company": "Tech Industries",
  "tags": ["prospect", "tech"],
  "metadata": {
    "source": "linkedin",
    "custom_field_1": "value"
  }
}

Response:
HTTP 201 Created
{
  "success": true,
  "data": {
    "id": "650e8400-e29b-41d4-a716-446655440001",
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+1-555-1111",
    "company": "Tech Industries",
    "status": "active",
    "engagement_score": 0.0,
    "interaction_count": 0,
    "tags": ["prospect", "tech"],
    "created_at": "2026-05-25T10:35:00Z",
    "updated_at": "2026-05-25T10:35:00Z"
  }
}
```

### Get Contact Details
```
GET /api/v1/contacts/{id}

Query Parameters:
- include: array (relationships)
  - Examples: conversations, tasks, memories, engagement

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "john@example.com",
    // ... full contact details
    "relationships": {
      "conversations": {
        "count": 12,
        "latest": [ /* recent conversations */ ]
      },
      "tasks": {
        "count": 5,
        "open": 3
      },
      "memories": {
        "count": 42,
        "types": {
          "episodic": 20,
          "semantic": 15,
          "structured": 7
        }
      }
    }
  }
}
```

### Update Contact
```
PATCH /api/v1/contacts/{id}

Body (partial update):
{
  "name": "John Doe Updated",
  "engagement_score": 0.90,
  "tags": ["vip", "enterprise", "priority"],
  "metadata": {
    "last_demo": "2026-05-20",
    "renewal_date": "2026-12-25"
  }
}

Response:
HTTP 200 OK
{ /* updated contact */ }
```

### Delete Contact
```
DELETE /api/v1/contacts/{id}

Query Parameters:
- force: boolean (default: false)
  - false: soft delete (recoverable)
  - true: permanent delete

Response:
HTTP 204 No Content
```

### Get Contact's Conversations
```
GET /api/v1/contacts/{id}/conversations

Query Parameters:
- page, per_page, sort, filter[status]

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "750e8400-e29b-41d4-a716-446655440002",
      "title": "Q1 Planning Discussion",
      "status": "active",
      "message_count": 15,
      "created_at": "2026-05-20T14:30:00Z",
      "last_activity": "2026-05-25T09:15:00Z"
    }
  ]
}
```

### Get Contact's Engagement Score
```
GET /api/v1/contacts/{id}/engagement-score

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "contact_id": "550e8400-e29b-41d4-a716-446655440000",
    "score": 0.85,
    "calculation": {
      "interaction_frequency": 0.80,
      "response_time": 0.90,
      "last_interaction_recency": 0.85,
      "message_length_avg": 0.75,
      "keyword_relevance": 0.82
    },
    "trend": "increasing",
    "forecast": "High retention likely",
    "recommendations": [
      "Schedule follow-up call",
      "Share new product features"
    ]
  }
}
```

---

## Agents API Specification

### List Agents
```
GET /api/v1/agents

Query Parameters:
- page, per_page, sort
- filter[type]: reflection, team, autonomous, specialized, supervisor
- filter[status]: active, inactive, paused
- filter[model]: gpt-4, gemini-pro, claude-3, groq
- search: string

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "850e8400-e29b-41d4-a716-446655440003",
      "name": "Sales Specialist",
      "type": "specialized",
      "status": "active",
      "model": "gpt-4",
      "capabilities": ["sales_analysis", "lead_scoring", "objection_handling"],
      "description": "Handles sales interactions and lead qualification",
      "memory_enabled": true,
      "max_tokens": 4096,
      "temperature": 0.7,
      "created_at": "2026-04-10T10:00:00Z"
    }
  ],
  "pagination": { /* ... */ }
}
```

### Create Agent
```
POST /api/v1/agents

Body:
{
  "name": "Customer Support Agent",
  "type": "specialized",
  "model": "gpt-4",
  "description": "Handles customer support inquiries",
  "system_prompt": "You are a helpful customer support representative...",
  "instructions": {
    "tone": "professional",
    "language": "english",
    "max_attempts": 3
  },
  "capabilities": ["ticket_management", "faq_answering", "escalation"],
  "memory_enabled": true,
  "max_tokens": 4096,
  "temperature": 0.7,
  "memory_size_limit": 100000
}

Response:
HTTP 201 Created
{ /* created agent */ }
```

### Get Agent Details
```
GET /api/v1/agents/{id}

Query Parameters:
- include: memory, metrics, tasks, conversations

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "id": "850e8400-e29b-41d4-a716-446655440003",
    "name": "Sales Specialist",
    "type": "specialized",
    "status": "active",
    "model": "gpt-4",
    "capabilities": ["sales_analysis", "lead_scoring"],
    "memory_enabled": true,
    "memory_usage": {
      "total_size": 45000,
      "limit": 100000,
      "utilization_percent": 45
    },
    "metrics": {
      "total_tasks": 156,
      "successful_tasks": 144,
      "success_rate": 0.923,
      "avg_response_time_ms": 2350,
      "total_tokens_used": 450000
    }
  }
}
```

### Update Agent
```
PATCH /api/v1/agents/{id}

Body:
{
  "status": "active",
  "temperature": 0.8,
  "capabilities": ["sales_analysis", "lead_scoring", "proposal_generation"],
  "system_prompt": "Updated system prompt..."
}

Response:
HTTP 200 OK
{ /* updated agent */ }
```

### Execute Agent
```
POST /api/v1/agents/{id}/execute

Body:
{
  "input": "Analyze this lead: John Doe from TechCorp",
  "context": {
    "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
    "contact_id": "550e8400-e29b-41d4-a716-446655440000",
    "temperature": 0.8,
    "max_tokens": 2048
  }
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "execution_id": "exec-abc123",
    "agent_id": "850e8400-e29b-41d4-a716-446655440003",
    "input": "Analyze this lead...",
    "output": "Based on the information provided, John Doe appears to be a qualified lead...",
    "thinking_process": "Let me analyze the key indicators...",
    "tokens_used": {
      "prompt": 150,
      "completion": 380,
      "total": 530
    },
    "citations": [
      {
        "text": "TechCorp's revenue is $50M",
        "source": "CRM data"
      }
    ],
    "confidence": 0.92,
    "execution_time_ms": 2350,
    "executed_at": "2026-05-25T10:40:00Z"
  }
}
```

### Test Agent
```
POST /api/v1/agents/{id}/test

Body:
{
  "input": "Test prompt",
  "max_tokens": 1024
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "response": "Test response...",
    "tokens_used": 250,
    "execution_time_ms": 1200,
    "success": true
  }
}
```

### Get Agent Memory
```
GET /api/v1/agents/{id}/memory

Query Parameters:
- type: episodic, semantic, all
- limit: integer (default: 50)

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "agent_id": "850e8400-e29b-41d4-a716-446655440003",
    "memories": [
      {
        "id": "mem-001",
        "type": "semantic",
        "content": "User prefers direct communication",
        "importance": 0.95,
        "created_at": "2026-05-20T14:30:00Z"
      }
    ],
    "total_memories": 125,
    "memory_usage": "45/100 KB"
  }
}
```

### Prune Agent Memory
```
POST /api/v1/agents/{id}/memory/prune

Body:
{
  "criteria": {
    "min_importance": 0.3,
    "older_than_days": 30,
    "type": "episodic"
  }
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "memories_removed": 23,
    "space_freed_bytes": 12500,
    "new_total_memories": 102
  }
}
```

### Get Agent Metrics
```
GET /api/v1/agents/{id}/metrics

Query Parameters:
- timeframe: day, week, month, all

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "agent_id": "850e8400-e29b-41d4-a716-446655440003",
    "timeframe": "month",
    "metrics": {
      "total_executions": 156,
      "successful": 144,
      "failed": 12,
      "success_rate": 0.923,
      "avg_execution_time_ms": 2350,
      "avg_tokens_per_execution": 530,
      "total_tokens_used": 82680,
      "cost": 1.24
    },
    "trends": {
      "executions_trend": "up",
      "success_rate_trend": "stable",
      "cost_trend": "down"
    }
  }
}
```

---

## Conversations API Specification

### List Conversations
```
GET /api/v1/conversations

Query Parameters:
- page, per_page, sort
- filter[status]: active, archived, closed
- filter[contact_id]: uuid
- filter[agent_id]: uuid
- search: string
- include: messages, agent, contact, memories

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "750e8400-e29b-41d4-a716-446655440002",
      "title": "Product Inquiry Discussion",
      "status": "active",
      "contact_id": "550e8400-e29b-41d4-a716-446655440000",
      "agent_id": "850e8400-e29b-41d4-a716-446655440003",
      "message_count": 15,
      "created_at": "2026-05-20T14:30:00Z",
      "last_activity": "2026-05-25T09:15:00Z"
    }
  ]
}
```

### Create Conversation
```
POST /api/v1/conversations

Body:
{
  "title": "Sales Discussion - Q2 Planning",
  "contact_id": "550e8400-e29b-41d4-a716-446655440000",
  "agent_id": "850e8400-e29b-41d4-a716-446655440003",
  "metadata": {
    "source": "email",
    "department": "sales"
  }
}

Response:
HTTP 201 Created
{ /* created conversation */ }
```

### Get Conversation Details
```
GET /api/v1/conversations/{id}

Query Parameters:
- include: messages, agent, contact, memories

Response:
HTTP 200 OK
{ /* conversation with details */ }
```

### Update Conversation
```
PATCH /api/v1/conversations/{id}

Body:
{
  "title": "Updated Title",
  "status": "archived"
}

Response:
HTTP 200 OK
{ /* updated conversation */ }
```

### Archive Conversation
```
POST /api/v1/conversations/{id}/archive

Response:
HTTP 200 OK
{ /* conversation marked as archived */ }
```

### Delete Conversation
```
DELETE /api/v1/conversations/{id}

Response:
HTTP 204 No Content
```

---

## Messages API Specification

### Get Conversation Messages
```
GET /api/v1/conversations/{id}/messages

Query Parameters:
- page, per_page, sort (default: -created_at)
- filter[sender_type]: user, agent, system

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "msg-001",
      "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
      "sender_type": "user",
      "sender_id": "550e8400-e29b-41d4-a716-446655440000",
      "content": "Can you help me with product pricing?",
      "role": "user",
      "tokens_used": 15,
      "created_at": "2026-05-25T08:30:00Z"
    },
    {
      "id": "msg-002",
      "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
      "sender_type": "agent",
      "sender_id": "850e8400-e29b-41d4-a716-446655440003",
      "content": "Of course! Our enterprise plan starts at...",
      "role": "assistant",
      "tokens_used": 180,
      "ai_model_used": "gpt-4",
      "metadata": {
        "citations": [
          { "text": "enterprise plan", "source": "pricing_page" }
        ],
        "confidence": 0.98
      },
      "created_at": "2026-05-25T08:32:00Z"
    }
  ],
  "pagination": { /* ... */ }
}
```

### Send Message
```
POST /api/v1/conversations/{id}/messages

Body:
{
  "content": "What are the implementation timelines?",
  "sender_type": "user"
}

Response:
HTTP 201 Created
{
  "success": true,
  "data": {
    "id": "msg-003",
    "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
    "sender_type": "user",
    "content": "What are the implementation timelines?",
    "role": "user",
    "created_at": "2026-05-25T10:45:00Z"
  }
}

// Async response: Agent processes and responds
WebSocket Event: message.received
{
  "event": "message.received",
  "data": {
    "id": "msg-004",
    "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
    "sender_type": "agent",
    "sender_id": "850e8400-e29b-41d4-a716-446655440003",
    "content": "Implementation typically takes 2-4 weeks...",
    "role": "assistant"
  }
}
```

### Delete Message
```
DELETE /api/v1/conversations/{id}/messages/{messageId}

Response:
HTTP 204 No Content
```

---

## Workflows API Specification

### List Workflows
```
GET /api/v1/workflows

Query Parameters:
- page, per_page, sort
- filter[status]: draft, published, archived
- filter[trigger_type]: manual, scheduled, event
- search: string

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "wf-001",
      "name": "Lead Qualification Workflow",
      "description": "Qualifies leads and assigns to sales reps",
      "status": "published",
      "trigger_type": "event",
      "execution_count": 245,
      "success_rate": 0.94,
      "created_at": "2026-03-15T10:00:00Z"
    }
  ]
}
```

### Create Workflow
```
POST /api/v1/workflows

Body:
{
  "name": "Customer Onboarding",
  "description": "Complete onboarding process for new customers",
  "trigger_type": "manual",
  "steps": [
    {
      "id": "step-1",
      "type": "agent_execution",
      "agent_id": "850e8400-e29b-41d4-a716-446655440003",
      "input_template": "Onboard new customer: {contact_name}",
      "output_path": "onboarding_notes"
    },
    {
      "id": "step-2",
      "type": "notification",
      "channel": "email",
      "recipient": "{contact_email}",
      "subject": "Welcome to Nexus",
      "template": "welcome_email"
    },
    {
      "id": "step-3",
      "type": "api_call",
      "url": "https://api.slack.com/api/chat.postMessage",
      "method": "POST",
      "payload": {
        "channel": "#onboarding",
        "text": "New customer {contact_name} onboarded"
      }
    }
  ]
}

Response:
HTTP 201 Created
{ /* created workflow */ }
```

### Get Workflow Details
```
GET /api/v1/workflows/{id}

Response:
HTTP 200 OK
{ /* workflow with full definition */ }
```

### Update Workflow
```
PATCH /api/v1/workflows/{id}

Body: { /* partial updates */ }

Response:
HTTP 200 OK
{ /* updated workflow */ }
```

### Execute Workflow
```
POST /api/v1/workflows/{id}/execute

Body:
{
  "context": {
    "contact_id": "550e8400-e29b-41d4-a716-446655440000",
    "contact_name": "John Doe",
    "contact_email": "john@example.com",
    "custom_param": "value"
  }
}

Response:
HTTP 202 Accepted
{
  "success": true,
  "data": {
    "execution_id": "exec-wf-001",
    "workflow_id": "wf-001",
    "status": "pending",
    "created_at": "2026-05-25T10:50:00Z"
  }
}

// Async: Check execution status
GET /api/v1/workflows/{id}/executions/{executionId}

Response:
{
  "success": true,
  "data": {
    "execution_id": "exec-wf-001",
    "workflow_id": "wf-001",
    "status": "completed",
    "steps_completed": 3,
    "total_steps": 3,
    "results": {
      "step-1": { "output": "Onboarding notes..." },
      "step-2": { "status": "sent" },
      "step-3": { "status": "success" }
    },
    "completed_at": "2026-05-25T10:52:15Z"
  }
}
```

### Publish Workflow
```
POST /api/v1/workflows/{id}/publish

Response:
HTTP 200 OK
{ /* workflow marked as published */ }
```

### Get Workflow Executions
```
GET /api/v1/workflows/{id}/executions

Query Parameters:
- page, per_page
- filter[status]: pending, running, completed, failed

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "execution_id": "exec-wf-001",
      "status": "completed",
      "started_at": "2026-05-25T10:50:00Z",
      "completed_at": "2026-05-25T10:52:15Z",
      "duration_ms": 135000
    }
  ]
}
```

---

## Tasks API Specification

### List Tasks
```
GET /api/v1/tasks

Query Parameters:
- page, per_page, sort
- filter[status]: pending, in-progress, completed, failed
- filter[priority]: low, medium, high, critical
- filter[assigned_to_agent]: uuid
- filter[due_date_from]: date
- filter[due_date_to]: date
- include: agent, contact, workflow

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "task-001",
      "title": "Prepare Q2 proposal",
      "description": "Draft proposal for ABC Corp",
      "status": "in-progress",
      "priority": "high",
      "contact_id": "550e8400-e29b-41d4-a716-446655440000",
      "agent_id": "850e8400-e29b-41d4-a716-446655440003",
      "due_date": "2026-06-15T17:00:00Z",
      "created_at": "2026-05-20T10:00:00Z",
      "updated_at": "2026-05-25T10:55:00Z"
    }
  ]
}
```

### Create Task
```
POST /api/v1/tasks

Body:
{
  "title": "Follow up with customer",
  "description": "Call to discuss implementation timeline",
  "priority": "high",
  "contact_id": "550e8400-e29b-41d4-a716-446655440000",
  "agent_id": "850e8400-e29b-41d4-a716-446655440003",
  "due_date": "2026-05-30T17:00:00Z"
}

Response:
HTTP 201 Created
{ /* created task */ }
```

### Get Task Details
```
GET /api/v1/tasks/{id}

Response:
HTTP 200 OK
{ /* task details */ }
```

### Update Task Status
```
PATCH /api/v1/tasks/{id}/status

Body:
{
  "status": "completed"
}

Response:
HTTP 200 OK
{ /* updated task */ }
```

### Delete Task
```
DELETE /api/v1/tasks/{id}

Response:
HTTP 204 No Content
```

---

## Memory API Specification

### Memory Types
```
- episodic: Event-based memories (conversations, interactions)
- semantic: Fact-based memories (relationships, knowledge)
- structured: Fact storage (customer info, preferences)
- graph: Relationship mapping (contact networks)
- working: Short-term context (current conversation)
- summary: Compressed memories (long-form summaries)
```

### Store Memory
```
POST /api/v1/memory/{type}

Parameters:
- type: episodic, semantic, structured, graph, working, summary

Body:
{
  "agent_id": "850e8400-e29b-41d4-a716-446655440003",
  "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
  "content": "Customer expressed interest in enterprise features",
  "importance_score": 0.85,
  "retention_policy": "decay",
  "metadata": {
    "keyword": "enterprise_features",
    "sentiment": "positive"
  }
}

Response:
HTTP 201 Created
{
  "success": true,
  "data": {
    "id": "mem-001",
    "type": "semantic",
    "agent_id": "850e8400-e29b-41d4-a716-446655440003",
    "content": "Customer expressed interest...",
    "importance_score": 0.85,
    "created_at": "2026-05-25T10:58:00Z"
  }
}
```

### Query Memory
```
POST /api/v1/memory/search

Body:
{
  "agent_id": "850e8400-e29b-41d4-a716-446655440003",
  "query": "enterprise features",
  "type": "semantic",
  "limit": 10,
  "min_importance": 0.5
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "mem-001",
      "type": "semantic",
      "content": "Customer expressed interest in enterprise features",
      "importance_score": 0.85,
      "relevance_score": 0.92,
      "created_at": "2026-05-25T10:58:00Z"
    }
  ]
}
```

### Update Memory Importance
```
PATCH /api/v1/memory/{id}/importance

Body:
{
  "importance_score": 0.95
}

Response:
HTTP 200 OK
{ /* updated memory */ }
```

### Delete Memory
```
DELETE /api/v1/memory/{id}

Response:
HTTP 204 No Content
```

### Generate Memory Summary
```
POST /api/v1/memory/summarize

Body:
{
  "agent_id": "850e8400-e29b-41d4-a716-446655440003",
  "conversation_id": "750e8400-e29b-41d4-a716-446655440002",
  "timeframe": "last_30_days"
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "summary": "Customer has shown increasing interest in enterprise features...",
    "key_points": [
      "Interested in scaling",
      "Concerned about implementation time",
      "Budget approved for Q3"
    ],
    "sentiment": "positive",
    "action_items": [
      "Schedule technical demo",
      "Prepare ROI analysis"
    ]
  }
}
```

---

## AI Models & Routing API

### List Available Models
```
GET /api/v1/ai-models

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "gpt-4",
      "provider": "openai",
      "name": "GPT-4",
      "description": "Most capable general-purpose model",
      "pricing": {
        "input_per_1k_tokens": 0.03,
        "output_per_1k_tokens": 0.06,
        "currency": "USD"
      },
      "capabilities": ["reasoning", "coding", "analysis"],
      "max_tokens": 8192,
      "latency_ms_avg": 1500
    },
    {
      "id": "gemini-pro",
      "provider": "google",
      "name": "Gemini Pro",
      "description": "Google's advanced reasoning model",
      "pricing": { /* ... */ },
      "capabilities": ["multimodal", "reasoning", "long_context"],
      "max_tokens": 32768,
      "latency_ms_avg": 2000
    }
  ]
}
```

### Get Provider Models
```
GET /api/v1/ai-models/{provider}/models

Parameters:
- provider: openai, google, anthropic, groq

Response:
HTTP 200 OK
{ /* models for specific provider */ }
```

### Test Model
```
POST /api/v1/ai-models/test

Body:
{
  "model": "gpt-4",
  "input": "Test prompt",
  "temperature": 0.7,
  "max_tokens": 1024
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "model": "gpt-4",
    "response": "Response from model...",
    "tokens_used": {
      "prompt": 20,
      "completion": 150,
      "total": 170
    },
    "cost": 0.015,
    "latency_ms": 1250,
    "success": true
  }
}
```

### Get Model Pricing
```
GET /api/v1/ai-models/{id}/pricing

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "model": "gpt-4",
    "pricing": {
      "input_per_1k_tokens": 0.03,
      "output_per_1k_tokens": 0.06,
      "currency": "USD"
    },
    "monthly_usage": {
      "tokens": 150000,
      "cost": 8.50
    }
  }
}
```

### Optimize Routing
```
POST /api/v1/ai-models/routing/optimize

Body:
{
  "optimization_type": "cost",  // cost, quality, speed, balanced
  "context": {
    "task_type": "sales_analysis",
    "budget_limit": 5.00,
    "quality_requirement": "high"
  }
}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "recommended_model": "gpt-4",
    "reason": "Best quality for sales analysis within budget",
    "alternatives": [
      {
        "model": "gemini-pro",
        "cost_diff": "-0.50",
        "quality_diff": "-0.05"
      }
    ],
    "estimated_cost": 0.18
  }
}
```

---

## Integrations API

### List Integrations
```
GET /api/v1/integrations

Response:
HTTP 200 OK
{
  "success": true,
  "data": [
    {
      "id": "int-001",
      "provider": "slack",
      "status": "active",
      "last_sync": "2026-05-25T10:30:00Z",
      "settings": {
        "webhook_enabled": true,
        "auto_sync": true,
        "sync_interval": "5min"
      }
    }
  ]
}
```

### Create Integration
```
POST /api/v1/integrations

Body:
{
  "provider": "slack",
  "auth_token": "xoxb-token-here",
  "settings": {
    "channel": "#sales",
    "auto_sync": true,
    "webhook_enabled": true
  }
}

Response:
HTTP 201 Created
{ /* created integration */ }
```

### Get Integration Details
```
GET /api/v1/integrations/{id}

Response:
HTTP 200 OK
{ /* integration details */ }
```

### Update Integration
```
PATCH /api/v1/integrations/{id}

Body:
{
  "status": "active",
  "settings": {
    "sync_interval": "10min"
  }
}

Response:
HTTP 200 OK
{ /* updated integration */ }
```

### Delete Integration
```
DELETE /api/v1/integrations/{id}

Response:
HTTP 204 No Content
```

---

## Notifications API

### Send Notification
```
POST /api/v1/notifications/send

Body:
{
  "recipient": "user@example.com",
  "channel": "email",
  "subject": "Task assigned",
  "content": "You have been assigned a new task",
  "type": "task_assignment",
  "metadata": {
    "task_id": "task-001"
  }
}

Response:
HTTP 202 Accepted
{
  "success": true,
  "data": {
    "notification_id": "notif-001",
    "status": "queued",
    "created_at": "2026-05-25T11:00:00Z"
  }
}
```

### List Notifications
```
GET /api/v1/notifications

Query Parameters:
- page, per_page
- filter[status]: pending, sent, failed, delivered
- filter[channel]: email, sms, whatsapp, push

Response:
HTTP 200 OK
{ /* notification list */ }
```

### Get Notification Status
```
GET /api/v1/notifications/{id}

Response:
HTTP 200 OK
{
  "success": true,
  "data": {
    "id": "notif-001",
    "channel": "email",
    "status": "delivered",
    "recipient": "user@example.com",
    "created_at": "2026-05-25T11:00:00Z",
    "delivered_at": "2026-05-25T11:00:30Z"
  }
}
```

---

## Data Models & Schemas

### Contact Schema
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "string (max: 255)",
  "email": "email (unique per user)",
  "phone": "string",
  "company": "string",
  "status": "enum: active, inactive, suspended",
  "engagement_score": "float (0-1)",
  "interaction_count": "integer",
  "last_interaction": "timestamp",
  "tags": "array of strings",
  "metadata": "json object",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "deleted_at": "timestamp (nullable)"
}
```

### Agent Schema
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "string",
  "type": "enum: reflection, team, autonomous, specialized, supervisor",
  "status": "enum: active, inactive, paused",
  "model": "string",
  "system_prompt": "text",
  "instructions": "json object",
  "capabilities": "array of strings",
  "memory_enabled": "boolean",
  "max_tokens": "integer",
  "temperature": "float (0-1)",
  "memory_size_limit": "integer",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Conversation Schema
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "contact_id": "uuid (nullable)",
  "agent_id": "uuid (nullable)",
  "title": "string",
  "status": "enum: active, archived, closed",
  "message_count": "integer",
  "last_activity": "timestamp",
  "metadata": "json object",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Message Schema
```json
{
  "id": "uuid",
  "conversation_id": "uuid",
  "sender_type": "enum: user, agent, system",
  "sender_id": "uuid",
  "content": "text",
  "role": "enum: user, assistant, system",
  "tokens_used": "integer",
  "ai_model_used": "string (nullable)",
  "metadata": "json object (citations, confidence, etc)",
  "created_at": "timestamp"
}
```

### Memory Schema
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "agent_id": "uuid (nullable)",
  "conversation_id": "uuid (nullable)",
  "type": "enum: episodic, semantic, structured, graph, working, summary",
  "content": "text",
  "embedding": "vector (nullable)",
  "importance_score": "float (0-1)",
  "retention_policy": "enum: permanent, temporary, decay",
  "timestamp_created": "timestamp",
  "timestamp_accessed": "timestamp",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Workflow Schema
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "string",
  "description": "text",
  "steps": "json array",
  "status": "enum: draft, published, archived",
  "trigger_type": "enum: manual, scheduled, event",
  "execution_count": "integer",
  "success_rate": "float",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Task Schema
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "agent_id": "uuid (nullable)",
  "contact_id": "uuid (nullable)",
  "title": "string",
  "description": "text",
  "status": "enum: pending, in-progress, completed, failed",
  "priority": "enum: low, medium, high, critical",
  "due_date": "timestamp (nullable)",
  "assigned_to_agent": "uuid (nullable)",
  "metadata": "json object",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

---

**End of API & Technical Specification Document**
