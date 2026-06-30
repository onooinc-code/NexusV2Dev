# Nexus v2 — Project Overview

## 1. Executive Summary

Nexus v2 is an **enterprise AI operations platform** that gives teams a unified, intelligent interface to manage their most important asset: their relationships and workflows. It combines:

- **Contact Intelligence** — deep understanding of every person or organization across all channels
- **Autonomous AI Agents** — agents that can think, plan, and execute complex tasks
- **Workflow Automation** — visual, event-driven automation that spans systems
- **Memory Architecture** — persistent, multi-type AI memory for long-term relationship intelligence
- **HedraSoul** — an AI assistant with controllable autonomy levels and human-in-the-loop oversight

---

## 2. Problem Nexus Solves

| Problem | Nexus Solution |
|---------|----------------|
| Scattered contact data across channels | Unified `ContactsHub` with identity resolution and deduplication |
| AI with no persistent memory | 5-type memory system: episodic, semantic, structured, graph, working |
| Manual and repetitive workflows | `WorkflowsHub` with visual nodes, triggers, and schedules |
| No unified view of AI model costs/routing | `AIModelsHub` with dynamic routing, fallback chains, and budget tracking |
| No safe way to run autonomous AI | `HedraSoulHub` with 5 autonomy levels and approval gates |
| Siloed messaging from CRM | `PeopleConnectHub` integrates live WhatsApp messages with contact profiles |

---

## 3. Key Business Capabilities

### 3.1 Contact Intelligence
- Create, import (CSV), and manage contacts across all lifecycle stages
- Automatic deduplication and identity resolution (by email, phone, WhatsApp ID)
- AI-driven contact analysis: sentiment, topics, key decisions, relationships
- Full contact timeline: messages, notes, tags, memories, audit events
- GDPR-compliant erasure and privacy controls

### 3.2 Agent Orchestration
- Define AI agents with personas, tools, skills, and execution configurations
- 5 agent archetypes: Autonomous, Reflection, Supervisor, Specialized, Team
- Run agents against tasks and monitor progress in real-time
- Agents integrate with MCP (Model Context Protocol) for external tool access

### 3.3 Memory Management
- **Episodic Memory**: What happened in past interactions
- **Semantic Memory**: Extracted meaning and inferences
- **Structured Memory**: Facts stored as key-value data
- **Graph Memory**: Relationship networks between entities
- **Working Memory**: In-context ephemeral state during task execution
- Automatic memory extraction from conversations and tasks
- Memory versioning, maintenance, and consolidation

### 3.4 Workflow Automation
- Visual workflow canvas with React Flow nodes
- Trigger types: manual, scheduled (cron), event-based, webhook
- Step types: AI inference, API call, contact update, notification, agent execution
- Execution tracking, rollback, and version history

### 3.5 AI Models Management
- Manage multiple LLM providers: OpenAI, Anthropic, Google Gemini, Groq, and custom REST endpoints
- API key pool management with automatic rotation and health monitoring
- Smart routing: by intent, cost, speed, or quality
- Fallback chains: if provider A fails, try B, then C
- Budget tracking and rate limiting per provider

### 3.6 HedraSoul — The Nexus AI
- Persistent AI assistant with full system context
- 5 autonomy modes: `chat_only`, `copilot`, `operator`, `autopilot_limited`, `emergency_paused`
- Human-in-the-loop: approval gates for high-risk or costly actions
- Clones user personality from existing data sources
- Full audit trail: every decision, model used, cost, and trace

### 3.7 Multi-Channel Notifications
- Email, SMS (Twilio), WhatsApp (WAHA), Push notifications
- Template management with variable substitution
- Notification log, retry, and delivery tracking

### 3.8 PeopleConnect — Live Messaging
- Direct WhatsApp conversation management via WAHA API
- Incoming message webhooks, automatic contact matching
- AI-assisted reply suggestions and contact memory extraction from chats
- Live sync of conversations to the contact profile

---

## 4. Target Users

| User Type | Primary Usage |
|-----------|--------------|
| **Business Owner / Admin** | Dashboard overview, agent oversight, settings management |
| **Customer Success Manager** | ContactsHub, PeopleConnect, memory review |
| **AI Engineer / Developer** | AgentsHub, WorkflowsHub, AIModelsHub configuration |
| **Operations Manager** | TaskHub, SchedulerHub, LogsHub |
| **Nexus AI (HedraSoul)** | Autonomous operations with human oversight |

---

## 5. Project Phases

| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | Core Framework, Auth, Base Models | ✅ Complete |
| Phase 2 | Contact Hub, Agent System, Memory | ✅ Complete |
| Phase 3 | AI Models Hub, Workflows, Tasks | ✅ Complete |
| Phase 4 | HedraSoul, PeopleConnect | ✅ Complete |
| Phase 5 | Production Hardening, Testing | 🔄 In Progress |

---

## 6. Deployment Overview

| Component | Technology | Port |
|-----------|-----------|------|
| Backend API | Laravel 11 (PHP 8.2) | 8000 |
| Frontend | Next.js 15 | 3000 |
| WebSocket | Laravel Reverb | 6001 |
| Queue Worker | Laravel Queue | Background |
| Cache / Session | Redis | 6379 |
| Database | MySQL 8 / SQLite (dev) | 3306 |

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
