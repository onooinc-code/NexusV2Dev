# Nexus v2 — Technology Stack Reference

## 1. Backend Stack

### Core Framework
| Technology | Version | Purpose |
|-----------|---------|---------|
| **PHP** | 8.2+ | Backend language |
| **Laravel** | 11.31 | Application framework |
| **Laravel Sanctum** | 4.3 | API token authentication |
| **Laravel Reverb** | 1.10 | Native WebSocket server |
| **Laravel Horizon** | 5.46 | Queue monitoring dashboard |

### Database & Storage
| Technology | Version | Purpose |
|-----------|---------|---------|
| **MySQL** | 8.0+ | Primary production database |
| **SQLite** | 3 | Development / testing database |
| **Redis** | 7+ | Cache, sessions, queue driver |
| **Predis** | 2.3 | PHP Redis client library |

### AI & Integrations
| Technology | Purpose |
|-----------|---------|
| **OpenAI API** | GPT-4, GPT-4o, GPT-4o-mini |
| **Anthropic API** | Claude 3.5 Sonnet, Claude 3 Haiku |
| **Google Gemini API** | Gemini 1.5 Pro, Gemini Flash |
| **Groq API** | Llama-3, Mixtral (fast inference) |
| **Custom REST APIs** | Dynamic provider registration |
| **WAHA API** | WhatsApp HTTP API bridge |
| **Pusher PHP Server** | 7.2 | Broadcasting compatibility |

### Dev Tools
| Technology | Purpose |
|-----------|---------|
| **PHPUnit** | 11.0 | Unit and feature testing |
| **Faker** | 1.24 | Test data generation |
| **Laravel Sail** | Docker development environment |
| **Laravel Pail** | Real-time log viewer |
| **Laravel Pint** | Code style formatter |

---

## 2. Frontend Stack

### Core Framework
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Next.js** | 15.4.9 | React framework (App Router) |
| **React** | 19.2.1 | UI library |
| **TypeScript** | 5.9.3 | Type-safe JavaScript |

### State Management
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Zustand** | 5.0.13 | Global state management |
| **TanStack Query** | 5.101.0 | Server state, caching, fetching |

### UI & Styling
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Tailwind CSS** | 3.4+ | Utility-first CSS |
| **Lucide React** | 0.553.0 | Icon library |
| **Motion** (Framer) | 12.23.24 | Animations and transitions |
| **Recharts** | 3.8.1 | Charts and data visualization |
| **React Force Graph 2D** | 1.29.1 | Relationship graph rendering |
| **Next Themes** | 0.4.6 | Dark/light theme management |

### Data & Communication
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Axios** | 1.16.1 | HTTP client for API calls |
| **Laravel Echo** | 2.3.4 | WebSocket client abstraction |
| **Pusher JS** | 8.5.0 | WebSocket transport |
| **React Hook Form** | — | Form state management |
| **@hookform/resolvers** | 5.2.1 | Form validation integration |
| **date-fns** | 4.4.0 | Date formatting utilities |

### Workflow Visualization
| Technology | Version | Purpose |
|-----------|---------|---------|
| **@xyflow/react** | 12.10.2 | Visual workflow canvas (React Flow) |

### AI Integration
| Technology | Version | Purpose |
|-----------|---------|---------|
| **@google/genai** | 1.17.0 | Google Gemini client (frontend) |

### Testing
| Technology | Version | Purpose |
|-----------|---------|---------|
| **Vitest** | 4.1.8 | Unit testing framework |
| **Playwright** | 1.60.0 | End-to-end browser testing |
| **Testing Library** | 16.3.2 | React component testing |
| **MSW** | 2.14.6 | API mocking for tests |
| **fast-check** | 3.23.2 | Property-based testing |

---

## 3. Infrastructure & DevOps

### Server Requirements
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 2 GB | 8+ GB |
| **PHP** | 8.2 | 8.3 |
| **Disk** | 10 GB | 50+ GB |

### Environment Variables (Key)

#### Backend (`Nexus-backend/.env`)
```bash
# Application
APP_NAME=Nexus
APP_ENV=production
APP_KEY=base64:...
APP_URL=https://api.yourapp.com

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nexus
DB_USERNAME=nexus_user
DB_PASSWORD=secret

# Queue & Cache
QUEUE_CONNECTION=redis
CACHE_STORE=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Broadcasting (WebSocket)
BROADCAST_DRIVER=reverb
REVERB_HOST=127.0.0.1
REVERB_PORT=6001
REVERB_SCHEME=https

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
```

#### Frontend (`Nexus-Frontend/.env.local`)
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_REVERB_HOST=localhost
NEXT_PUBLIC_REVERB_PORT=6001
NEXT_PUBLIC_APP_NAME=Nexus
```

---

## 4. Key Architecture Patterns

### Backend Patterns
| Pattern | Implementation |
|---------|----------------|
| **Repository Pattern** | `app/Repositories/` (light usage) |
| **Service Layer** | `app/Services/` (heavy usage) |
| **Event Sourcing** | Laravel Events + Listeners |
| **CQRS (partial)** | Read vs write operations separated |
| **Circuit Breaker** | `CircuitBreakerService` for AI calls |
| **Idempotency** | `IdempotencyService` + DB checks |
| **Strategy Pattern** | AI provider implementations |
| **Chain of Responsibility** | Fallback chains in `FallbackChainService` |
| **Observer Pattern** | Model events, Contact observers |

### Frontend Patterns
| Pattern | Implementation |
|---------|----------------|
| **Server Components** | Next.js 15 default pages |
| **Client Components** | Interactive hub pages (`'use client'`) |
| **Compound Components** | Nx design system (NxModal, NxTabs, etc.) |
| **Container/Presentational** | Hook logic + UI component separation |
| **Custom Hooks** | `useHedraSoulHub`, `useWebSocket`, etc. |
| **Optimistic Updates** | TanStack Query mutations |

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
