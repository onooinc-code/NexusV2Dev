# 🧠 Nexus v2

**Enterprise AI-Powered Relationship & Operations Platform**

Nexus unifies contact intelligence, autonomous AI agents, workflow automation, multi-channel messaging, and persistent AI memory into a single production-grade system.

---

## 🚀 Quick Start

### Prerequisites
| Tool | Version | Required |
|------|---------|---------|
| PHP | 8.2+ | ✅ Backend |
| Composer | 2.x | ✅ Backend |
| Node.js | 20+ | ✅ Frontend |
| MySQL | 8.0+ | ✅ Production |
| Redis | 7+ | ⚠️ Recommended |

### 1. Clone & Setup
```bash
git clone <repo-url> NexusV2
cd NexusV2
```

### 2. Backend Setup
```bash
cd Nexus-backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

### 3. Frontend Setup
```bash
cd Nexus-Frontend
npm install
cp .env.example .env.local
# Edit .env.local: set NEXT_PUBLIC_API_URL=http://localhost:8000
npm run dev
```

### 4. Queue & WebSocket (separate terminals)
```bash
# Queue worker
cd Nexus-backend && php artisan queue:listen

# WebSocket server
cd Nexus-backend && php artisan reverb:start

# Scheduler (optional)
cd Nexus-backend && php artisan schedule:work
```

### 5. Windows All-in-One
```batch
# From project root
Start-Nexus.bat
```

---

## 🏗️ Project Structure

```
NexusV2/
├── Nexus-backend/          # Laravel 11 API (PHP 8.2)
├── Nexus-Frontend/         # Next.js 15 App
├── Nexusv2-Docs-14-06/     # Documentation
└── Start-Nexus.bat         # Windows dev launcher
```

---

## 🗺️ Hubs (Feature Modules)

| Hub | Route | Description |
|-----|-------|-------------|
| **Dashboard** | `/` | System overview and key metrics |
| **ContactsHub** | `/contacts` | Contact management and intelligence |
| **AgentsHub** | `/agents` | AI agent configuration and execution |
| **TaskHub** | `/tasks` | Background task monitoring |
| **WorkflowsHub** | `/workflows` | Visual automation builder |
| **MemoryHub** | `/memory` | AI memory management |
| **AIModelsHub** | `/ai-models` | LLM provider and routing management |
| **HedraSoulHub** | `/hedra-soul` | Personal AI assistant |
| **NotificationsHub** | `/notifications` | Multi-channel notification system |
| **SchedulerHub** | `/scheduler` | Time-based automation |
| **PeopleConnectHub** | `/people-connect` | Live WhatsApp messaging |
| **SettingsHub** | `/settings` | System configuration |
| **LogsHub** | `/logs` | Application logs |
| **ProactiveAIHub** | `/proactive-ai` | Autonomous AI triggers |

---

## 📚 Documentation

See [Nexusv2-Docs-14-06/README.md](./Nexusv2-Docs-14-06/README.md) for complete documentation.

---

## 🧪 Testing

```bash
# Backend tests
cd Nexus-backend && php artisan test

# Frontend unit tests
cd Nexus-Frontend && npm run test

# Frontend E2E tests
cd Nexus-Frontend && npx playwright test
```

---

## 🔐 Default Credentials (Development)

After seeding, use:
- **Email**: `admin@nexus.local`
- **Password**: `password`

> ⚠️ Change these immediately in any non-development environment.

---

## 📋 Environment Variables

See `Nexus-backend/.env.example` and `Nexus-Frontend/.env.example` for the full list of required configuration variables.

---

*Nexus v2 · 2026-06-14*
