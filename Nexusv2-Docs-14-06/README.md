# 🧠 Nexus v2 — Intelligent Relationship & AI Operations Platform

> **Version:** 2.0.0 · **Date:** 2026-06-19 · **Status:** Production Ready

Nexus is an enterprise-grade AI-powered platform that unifies contact intelligence, autonomous agent orchestration, multi-channel messaging, workflow automation, and memory management into a single cohesive system. It is built for teams that operate at scale and need deep, persistent, AI-augmented understanding of people, tasks, and interactions.

---

## 📚 Documentation Index

| Document                                                             | Description                                    |
| -------------------------------------------------------------------- | ---------------------------------------------- | --- | ------------------------------------------------ | ----------------------------------- | --- | -------------------------------------------------- | ----------------------------------------- |
| [� Quick Start](./QUICK_START.md)                                    | **START HERE** — One-click setup & scripts     |     | [📜 StartNexus Scripts](./STARTNEXUS_SCRIPTS.md) | Complete guide to all build scripts |     | [🗄️ Redis Configuration](./REDIS_CONFIGURATION.md) | Queue system, caching, session management |
| [�📦 Project Overview](./01-General/01-Overview/PROJECT_OVERVIEW.md) | Business goals, vision, and what Nexus solves  |
| [🏛️ Architecture](./01-General/02-Architecture/ARCHITECTURE.md)      | Full system architecture and design decisions  |
| [📐 Tech Stack](./01-General/03-TechStack/TECH_STACK.md)             | All technologies, frameworks, and dependencies |
| [📖 Glossary](./01-General/04-Glossary/GLOSSARY.md)                  | Unified terminology and definitions            |
| [🗄️ Data Models](./01-General/05-DataModels/DATA_MODELS.md)          | All database entities and relationships        |
| [🔐 Auth & Security](./01-General/06-Security/AUTH_AND_SECURITY.md)  | Authentication, authorization, and security    |
| [⚙️ Configuration](./01-General/07-Configuration/CONFIGURATION.md)   | Environment setup and configuration reference  |

---

## 🏗️ Hub Documentation

| Hub                  | Description                                           | Docs                             |
| -------------------- | ----------------------------------------------------- | -------------------------------- |
| **ContactsHub**      | Contact lifecycle, identity resolution, AI enrichment | [→](./02-Hubs/ContactsHub/)      |
| **TaskHub**          | Task creation, queuing, execution, retry              | [→](./02-Hubs/TaskHub/)          |
| **AgentsHub**        | AI agent types, configuration, execution              | [→](./02-Hubs/AgentsHub/)        |
| **WorkflowsHub**     | Automation workflows, triggers, scheduling            | [→](./02-Hubs/WorkflowsHub/)     |
| **MemoryHub**        | 5-type memory system, episodic/semantic/graph         | [→](./02-Hubs/MemoryHub/)        |
| **AIModelsHub**      | LLM provider management, routing, cost optimization   | [→](./02-Hubs/AIModelsHub/)      |
| **HedraSoulHub**     | Nexus personal AI assistant, autonomy control         | [→](./02-Hubs/HedraSoulHub/)     |
| **NotificationsHub** | Multi-channel notifications, templates                | [→](./02-Hubs/NotificationsHub/) |
| **SchedulerHub**     | Cron-based and time-driven automation                 | [→](./02-Hubs/SchedulerHub/)     |
| **PeopleConnectHub** | WhatsApp/messaging integration, live conversations    | [→](./02-Hubs/PeopleConnectHub/) |
| **SettingsHub**      | System settings, admin configuration                  | [→](./02-Hubs/SettingsHub/)      |
| **LogsHub**          | System and application logs viewer                    | [→](./02-Hubs/LogsHub/)          |
| **ProactiveAIHub**   | Proactive AI triggers and autonomous actions          | [→](./02-Hubs/ProactiveAIHub/)   |

---

## 🐛 Known Issues & Gaps

See [03-Issues/KNOWN_ISSUES.md](./03-Issues/KNOWN_ISSUES.md) for logic bugs, missing features, and technical debt.

---

## 📋 Quick Start

### Prerequisites

- PHP 8.2+ with required extensions
- Node.js 20+
- MySQL 8+ or SQLite (dev)
- Redis (optional but recommended)

### Backend

```bash
cd Nexus-backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

### Frontend

```bash
cd Nexus-Frontend
npm install
cp .env.example .env.local
npm run dev
```

### Full Stack (via root)

```bash
# From project root
Start-Nexus.bat   # Windows
```

---

## 📁 Repository Structure

```
NexusV2/
├── Nexus-backend/          # Laravel 11 API backend
├── Nexus-Frontend/         # Next.js 15 frontend
├── StartNexus/             # Development scripts (.bat files)
├── Nexusv2-Docs-14-06/     # This documentation
└── Start-Nexus.bat         # Windows dev launcher (legacy)
```

---

## 🚀 Getting Started

**Fastest Way:** `Double-click StartNexus/quick-start.bat`

See [Quick Start Guide](./QUICK_START.md) for detailed setup instructions.

---

*Last updated: 2026-06-19 | Nexus v2 Documentation* ✅
