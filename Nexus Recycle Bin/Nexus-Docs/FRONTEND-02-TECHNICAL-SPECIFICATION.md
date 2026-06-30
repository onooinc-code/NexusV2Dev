# Nexus Frontend - Technical Specification

**Last Updated**: May 25, 2026  
**Project**: Nexus-Frontend (Next.js)  
**Purpose**: Detailed frontend technical specification for implementation, integration, and developer reference

---

## 1. Overview

### Purpose
This document defines the technical specification for the Nexus Frontend application. It captures:
- the frontend architecture and module responsibilities
- the supported data models and interfaces
- API contracts between frontend, backend, and internal app APIs
- component input/output contracts
- environment configuration required to run the app

### Audience
- Frontend developers
- Integration engineers
- QA/test engineers
- AI agents requiring explicit frontend behavior and contract details

---

## 2. Technology Stack

### Core Framework
- Next.js 15.4.9
- React 19.2.1
- TypeScript 5.9.3
- Tailwind CSS 4.1.11
- Zustand 5.0.13
- Axios 1.16.1
- Lucide React 0.553.0
- Motion 12.23.24
- Recharts 3.8.1

### Build and Toolchain
- npm scripts
  - `npm run dev` — start development server
  - `npm run build` — compile production build
  - `npm run start` — run production server
  - `npm run lint` — run ESLint
  - `npm run clean` — clean build cache
- ESLint 9.39.1 with Next.js config
- TypeScript strict mode enabled

### Runtime Environment
- Browser support targets modern evergreen browsers
- Node 20+ recommended for build and production

---

## 3. Project Structure

```
Nexus-Frontend/
├── app/                       # Next.js App Router pages and API routes
├── components/                # Reusable UI components
├── hooks/                     # Custom React hooks
├── lib/                       # Client and auth utilities
├── store/                     # Global state and state provider
├── context/                   # Auth context implementation
├── types/                     # TypeScript models and shared interfaces
├── constants/                 # Static configuration constants
├── styles/                    # Tailwind and global styles
├── public/                    # Static assets and images
├── package.json               # Dependencies and scripts
├── tsconfig.json              # TypeScript configuration
└── .env.example               # Environment variables
```

### App Router Structure
- `app/layout.tsx`: root layout with global providers
- `app/page.tsx`: dashboard overview
- `app/login/page.tsx`: login experience
- `app/contacts/page.tsx`: contacts hub
- `app/agents/page.tsx`: agent configuration hub
- `app/workflows/page.tsx`: workflow orchestration canvas
- `app/conversations/page.tsx`: chat interface
- `app/tasks/page.tsx`: task and objective management
- `app/memory/page.tsx`: memory browser and management
- `app/logs/page.tsx`: logs and audit trail view
- `app/settings/page.tsx`: application settings
- `app/scheduler/page.tsx`: scheduler interface
- `app/apis/...`: API tester and proxy features
- `app/api/gemini/route.ts`: internal Gemini AI server endpoint
- `app/api/health/route.ts`: health check endpoint

---

## 4. Environment Configuration

### Required Variables
The frontend expects the following environment variables, defined in `.env.local` or the workspace secrets panel:

```env
GEMINI_API_KEY="MY_GEMINI_API_KEY"
APP_URL="MY_APP_URL"
NEXT_PUBLIC_API_BASE_URL="http://localhost:8000/api"
NEXT_PUBLIC_BROADCAST_AUTH_URL="http://localhost:8000/broadcasting/auth"
NEXT_PUBLIC_REVERB_APP_KEY="your-reverb-app-key"
NEXT_PUBLIC_REVERB_HOST="localhost"
NEXT_PUBLIC_REVERB_PORT="8080"
NEXT_PUBLIC_REVERB_SCHEME="http"
```

### Runtime Configuration
- `NEXT_PUBLIC_API_BASE_URL` is the frontend-to-backend API gateway.
- `NEXT_PUBLIC_BROADCAST_AUTH_URL` is used by WebSocket authorization.
- `GEMINI_API_KEY` is required by the internal `/api/gemini` route.
- `NEXT_PUBLIC_REVERB_*` variables configure the Laravel Echo / Pusher connection.

### Notes
- `NEXT_PUBLIC_*` variables are exposed to browser code.
- `GEMINI_API_KEY` must remain secret and is only read on the server side in `app/api/gemini/route.ts`.

---

## 5. API Contracts

### 5.1 Backend API Contract
The frontend uses Axios to call the backend API. The base client is defined in `lib/api/client.ts`:

```ts
const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 10000,
  withCredentials: true,
});
```

### Request Interceptor
- reads `nexus_auth_token` from localStorage
- sets `Authorization: Bearer <token>` header
- uses JSON content type

### Response Interceptor
- on `401` clears local token and triggers re-authentication
- unwraps backend errors into `ApiError`

### Primary Backend Endpoints
The frontend assumes the backend exposes these resources. Most routes are accessed by the Zustand store.

#### Auth
- `POST /v1/login`
  - body: `{ email, password }`
  - response: `{ access_token, user }`
- `POST /v1/logout`
  - body: `{}`
  - clears server session/token

#### Contacts
- `GET /v1/contacts`
- `GET /v1/contacts/{id}`
- `POST /v1/contacts`
- `PUT /v1/contacts/{id}`
- `DELETE /v1/contacts/{id}`
- `GET /v1/contacts/{id}/timeline`
- `GET /v1/contacts/{id}/notes`
- `POST /v1/contacts/{id}/notes`
- `DELETE /v1/contacts/{id}/notes/{noteId}`
- `POST /v1/contacts/{id}/relationships`
- `DELETE /v1/contacts/{id}/relationships/{relationshipId}`
- `POST /v1/contacts/{id}/preferences`
- `PUT /v1/contacts/{id}/preferences/{prefId}`
- `DELETE /v1/contacts/{id}/preferences/{prefId}`
- `POST /v1/contacts/{id}/aliases`
- `DELETE /v1/contacts/{id}/aliases/{aliasId}`

#### Tasks
- `GET /v1/tasks`
- `POST /v1/tasks`

#### Workflows
- `GET /v1/workflows`

#### Generic Infrastructure
- `DELETE /v1/tasks/{id}` (implicitly supported by delete operation)

### 5.2 Internal Frontend API Contract

#### `/api/gemini`
- method: `POST`
- request body:
  - `message: string`
  - `history: Array<{ role: string; content: string }>`
  - `context?: string`
- response body:
  - `success: boolean`
  - `text: string`
  - `error?: string`

This route executes a Gemini AI call using the server-side environment variable `GEMINI_API_KEY` and returns a plain-text assistant response.

#### `/api/health`
- method: `GET`
- response body:
  - `status: 'healthy'`
  - `timestamp: string`

Used as a lightweight health probe for deployment verification.

---

## 6. Data Model Specification

### 6.1 Contact Model
Defined in `store/index.ts` as a frontend contract for backend contact records.

```ts
export interface Contact {
  id: string;
  name: string;
  role: string;
  company: string;
  email: string;
  phone: string;
  avatar?: string;
  created_at?: string;
  updated_at?: string;
  timeline?: any[];
  notes?: any[];
}
```

### 6.2 Agent Model
Frontend agent configuration model used in `app/agents/page.tsx`.

```ts
export interface Agent {
  id: string;
  name: string;
  role: string;
  status: 'online' | 'busy' | 'offline' | 'error';
  tokenUsage: number;
  model: string;
  temperature: number;
  memorySync: boolean;
  capabilities: string[];
  assignedTasks: string[];
}
```

### 6.3 Workflow Model
Used for workflow listing and local persistence.

```ts
export interface Workflow {
  id: string;
  name: string;
  role: string;
  status: 'draft' | 'active' | 'archived';
  nodesCount: number;
}
```

### 6.4 Task Model
Frontend task item contract.

```ts
export interface Task {
  id: string;
  title: string;
  description: string;
  status: 'todo' | 'in-progress' | 'completed';
  priority: 'low' | 'medium' | 'high';
  dueDate: string;
}
```

### 6.5 Memory Model
Used by the Memory hub and persisted in localStorage.

```ts
export interface MemoryItem {
  id: string;
  fact: string;
  type: 'semantic' | 'episodic' | 'working';
  relevance: number;
  agentName: string;
  timestamp: string;
  metaTags: string[];
}
```

### 6.6 Job Model
Used by real-time job monitoring.

```ts
export interface Job {
  id: string;
  name: string;
  status: 'running' | 'success' | 'failed';
  progress: number;
}
```

### 6.7 Toast Message Model

```ts
export interface ToastMessage {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  message: string;
  duration?: number;
}
```

---

## 7. Global Application State

### Store Architecture
- The frontend uses a single global Zustand store in `store/index.ts`.
- `StoreProvider` exposes the store through React context.
- `useAppStore` selects values and actions from the store.
- State is persisted in localStorage for some slices.

### Store Slices

#### UI & Navigation
- `isSidebarOpen`
- `isOnline`
- `isJobMonitorOpen`
- `isNotificationDrawerOpen`
- `loading: Record<string, boolean>`

#### Notifications
- `notifications`
- `addNotification(type, message)`
- `dismissNotification(id)`

#### Jobs
- `jobs`
- `addJob(name, backendJobId)`
- `updateJobProgress(id, progress, status?)`
- `cancelJob(id)`
- `clearCompletedJobs()`

#### Contacts
- `contacts`
- `currentContact`
- `hydrateContacts()`
- `fetchContactDetails(id)`
- `createContact(data)`
- `updateContact(id, data)`
- `deleteContact(id)`
- `fetchContactTimeline(id)`
- `fetchContactNotes(id)`
- `addContactNote(id, data)`
- `deleteContactNote(id, noteId)`
- `addContactRelationship(contactId, data)`
- `deleteContactRelationship(contactId, relationshipId)`
- `addContactPreference(contactId, data)`
- `updateContactPreference(contactId, prefId, data)`
- `deleteContactPreference(contactId, prefId)`
- `addContactAlias(contactId, data)`
- `deleteContactAlias(contactId, aliasId)`

#### Tasks
- `tasks`
- `hydrateTasks()`
- `createTask(data)`
- `updateTask(id, status)`
- `deleteTask(id)`

#### Workflows
- `workflows`
- `hydrateWorkflows()`
- `createWorkflow(data)`
- `updateWorkflow(id, data)`
- `deleteWorkflow(id)`

#### Memories
- `memories`
- `hydrateMemories()`
- `createMemory(data)`
- `deleteMemory(id)`
- `resetAllMemories()`

---

## 8. Component Contracts

### AppLayout
Provides the global application shell with a sidebar, header, and status bar.

```ts
export const AppLayout = ({ children }: { children: React.ReactNode }) => { ... }
```

Inputs:
- `children: ReactNode`

Behaviors:
- renders `NxNavRail`, `NxTopBar`, `NxStatusBar`, `NxNotificationDrawer`
- toggles sidebar state via `useAppStore`
- protects nested layouts by `AppLayoutContext`

### NxNavRail
- primary navigation menu for feature hubs
- uses `useAppStore` to open/close on mobile

### NxTopBar
- top header with search, status, and user actions

### NxStatusBar
- global status line including network/connectivity state

### NxNotificationDrawer
- dismissible toast and notification inbox
- connected to global notification state

### NxActionButton
- `variant`: `primary | secondary | danger`
- `size`: `sm | md | lg`
- `isLoading`: boolean

### NxInput, NxSelect, NxSwitch, NxSlider
- standardized interactive form controls
- consistent focus, validation, and icon support
- used throughout core forms and hub filters

### NxContactCard3D
- renders 3D simulated contact cards
- used in Contacts hub grid view

### NxWorkflowNode
- visual workflow node with statuses and position metadata
- used in Workflows hub canvas

### NxChatBubble
- conversation message bubble component
- supports roles `user | assistant`, timestamp, actions

---

## 9. Authentication & Authorization Behavior

### Auth Context
`context/AuthContext.tsx` manages frontend authentication state.

State exposed:
- `user: AuthUser | null`
- `token: string | null`
- `isLoading: boolean`
- `login(email, password)`
- `logout()`

### Token Storage
- Token stored in `localStorage` under `nexus_auth_token`
- User profile stored in `nexus_auth_user`
- Auth interception is handled by `lib/api/client.ts`

### Login Flow
1. User submits credentials in `/login`
2. `AuthContext.login()` calls `POST /v1/login`
3. On success, token and user are persisted
4. Router redirects to `/`

### Logout Flow
1. `AuthContext.logout()` calls `POST /v1/logout`
2. Clears local auth storage
3. Redirects to `/login`

### Route Protection
- `AuthProvider` redirects unauthenticated visitors to `/login`
- `PUBLIC_PATHS` contains `['/login']`
- all other routes require a token

---

## 10. Real-time Integration

### WebSocket Implementation
- `hooks/useWebSocket.ts` manages the Laravel Echo / Pusher connection
- uses `Pusher.js` and `laravel-echo`
- authorizes private channels through `NEXT_PUBLIC_BROADCAST_AUTH_URL`
- updates connection state through hook return values
- binds to `state_change` and `error` events

### RealTimeJobListener
- `components/RealTimeJobListener.tsx` subscribes to active job channels
- listens for `.App\Events\BatchProgressUpdated`
- updates job progress state in the global store
- leaves channels when jobs reach terminal state

### Real-time Channels
- channel naming convention: `job.batch.{backendJobId}`
- event payload: `{ percentage: number; status: string }`

---

## 11. Frontend API Route Behavior

### `/api/gemini`
- server-side route that proxies frontend chat requests into Gemini AI.
- required request body fields:
  - `message`
  - `history`
  - `context`
- constructs a `systemInstruction` prompt describing Nexus role and environment
- uses `@google/genai` with `model: 'gemini-3.5-flash'`
- returns `success` and `text` fields

### `/api/health`
- simple health endpoint used for deployment checks
- returns current server time and health status

---

## 12. Page Contracts and UX Flows

### Dashboard (`app/page.tsx`)
- main landing page for high-level metrics
- renders chat composer and AI assistant stream
- uses client-side fetch to `/api/gemini`
- displays dynamic metric widgets and activity logs
- provides stateful feedback for AI typing and errors

### Contacts Hub (`app/contacts/page.tsx`)
- loads contact records from backend via store action
- supports search, company filter, role filter
- toggles view mode between grid and table
- adds and edits contacts through modal/drawer UI
- uses optimistic update pattern for create/edit flows
- on save, dispatches `addJob` notification and job tracker event

### Agents Hub (`app/agents/page.tsx`)
- visual agent configuration and management
- persists agent configuration to localStorage
- supports agent status, model selection, temperature, memorySync, capabilities
- uses simulated deployment latency and token usage updates
- stores default agent list in local storage to support offline preview

### Workflows Hub (`app/workflows/page.tsx`)
- graphical workflow canvas using absolute positioning
- node types: `trigger`, `agent`, `condition`, `action`
- simulates execution with step-by-step progression
- persists workflow graph to localStorage
- supports adding, resetting, clearing, and running the pipeline

### Conversations Hub (`app/conversations/page.tsx`)
- two-pane chat interface with conversation list and chat thread
- messages are simulated locally
- user messages are appended and mocked assistant responses are added after delay
- no backend conversation persistence is currently implemented

### Tasks Hub (`app/tasks/page.tsx`)
- task board split into `todo`, `in-progress`, and `completed`
- task creation supports title, description, priority, due date
- toggling status updates local application state and localStorage
- createTask sends request to backend and uses optimistic UI update

### Memory Hub (`app/memory/page.tsx`)
- memory store is persisted locally in localStorage
- supports search, fact creation, and deletion
- memory facts are seeded with example semantics

### Logs Hub (`app/logs/page.tsx`)
- monitors event information and system status
- built for audit-style timeline display
- uses static or mock data; primarily for UI demonstration

### Settings Hub (`app/settings/page.tsx`)
- persistent preferences and theme toggles
- integrates `next-themes` and `ThemeProvider`
- likely uses local storage or persisted state for theme selection

### Scheduler Hub (`app/scheduler/page.tsx`)
- provides scheduling interactions, calendar-style tasks, and planning utilities
- likely contains event configuration and timeline controls

---

## 13. Build and Compilation Contracts

### Next.js Build Lifecycle
- `next dev`: local development with hot reload
- `next build`: compile production output
- `next start`: run the compiled production server

### TypeScript and ESLint
- strict mode enabled; compile-time type safety is enforced
- `tsx` and `ts` files are required to satisfy compiler options
- `baseUrl` configured to allow `@/*` alias imports

### Path Aliases
Configured in `tsconfig.json`:
- `@/*` → `./*`
- `@/components/*` → `./components/*`
- other path aliases may exist in the config

---

## 14. Failure Modes and Error Handling

### API Failures
- `apiClient` converts backend errors into standardized `ApiError`
- `401` unauthorized responses clear the local token and optionally redirect to login
- network timeouts are configured at 10 seconds

### Gemini Route Errors
- missing `GEMINI_API_KEY` returns `500` with guidance
- downstream AI failures return `success: false` and `error`
- frontend chat UI surfaces `chatError` to the user

### WebSocket Errors
- websocket initialization failure logs warnings but does not crash the app
- connection state is inferred by `useWebSocket` as `disconnected`
- channel auth failures are handled gracefully with warnings

---

## 15. Security Considerations

### Sensitive Storage
- `nexus_auth_token` in `localStorage` is a secure token bearer pattern for browser clients
- token storage exposes some risk; longer-term security may require httpOnly cookies or secure storage

### Input Validation
- user form inputs are validated locally before submission
- server-side validation should occur in backend endpoints

### CORS and Authentication
- `withCredentials: true` is enabled for API client
- broadcast auth uses a custom authorizer to attach bearer token

### Secrets
- `GEMINI_API_KEY` is stored server-side in environment variables and not shipped to the browser

---

## 16. Glossary

- **Hub**: A major app page or feature area (ContactsHub, AgentsHub, WorkflowsHub)
- **Store**: Global application state managed by Zustand
- **Job**: background process tracked by the job monitor UI
- **Memory Item**: semantic or episodic fact stored locally in the Memory hub
- **Agent**: AI logic unit represented by frontend configuration
- **Workflow Node**: visual step in the workflow canvas
- **Gemini Route**: internal serverless API route for AI generation

---

## 17. References
- `store/index.ts`
- `app/layout.tsx`
- `context/AuthContext.tsx`
- `lib/api/client.ts`
- `app/api/gemini/route.ts`
- `app/api/health/route.ts`
- `CURRENT_REQUIREMENTS_CHECKLIST.md`
- `package.json`

---

**End of Nexus Frontend Technical Specification**
