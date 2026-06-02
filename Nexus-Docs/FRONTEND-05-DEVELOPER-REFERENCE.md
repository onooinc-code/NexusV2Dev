# Nexus Frontend - Developer Reference Manual

**Last Updated**: May 25, 2026  
**Project**: Nexus-Frontend  
**Purpose**: In-depth developer reference for building, extending, and maintaining the Nexus frontend

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [App Lifecycle and Providers](#app-lifecycle-and-providers)
3. [Global State and Store Patterns](#global-state-and-store-patterns)
4. [Authentication Architecture](#authentication-architecture)
5. [API Client and Error Handling](#api-client-and-error-handling)
6. [Real-time Integration](#real-time-integration)
7. [Component Library and Composition](#component-library-and-composition)
8. [Page Patterns and UX Flows](#page-patterns-and-ux-flows)
9. [Custom Hooks](#custom-hooks)
10. [Data Models and Type Contracts](#data-models-and-type-contracts)
11. [Styling and Theme System](#styling-and-theme-system)
12. [Testing and Quality Practices](#testing-and-quality-practices)
13. [Extension Guidelines](#extension-guidelines)

---

## 1. Architecture Overview

The Nexus frontend is built with Next.js App Router and a component-driven architecture. It integrates client-side state management with server-side API routes.

### Primary architectural layers
- **Presentation**: `components/`, `app/` pages
- **State**: `store/` (Zustand) and `context/` (Auth)
- **Data access**: `lib/api/client.ts` and `app/api/*` routes
- **Styling**: Tailwind CSS and `components/theme-provider.tsx`

### Feature modules
- `ContactsHub`
- `AgentsHub`
- `WorkflowsHub`
- `ConversationsHub`
- `TasksHub`
- `MemoryHub`
- `LogsHub`
- `SettingsHub`
- `SchedulerHub`
- `AIModelsHub`

### Patterns
- `AppLayout` shell for feature pages
- `StoreProvider` to use Zustand across the app
- `AuthProvider` for token lifecycle and route protection
- `Axios interceptors` for auth and global error handling
- `Serverless API route` for Gemini AI proxy
- `LocalStorage` hydration for persisted UI state

---

## 2. App Lifecycle and Providers

### Root layout
`app/layout.tsx` wraps the entire application with the following providers:
- `StoreProvider`
- `ThemeProvider`
- `AuthProvider`
- `RealTimeJobListener`

It also imports global styles from `./globals.css`.

### AuthProvider
- initializes auth state from `localStorage`
- redirects unauthenticated users to `/login`
- exposes `login` and `logout`
- uses `useRouter` and `usePathname`

### StoreProvider
- provides the Zustand store via `StoreContext`
- uses `useGlobalStore` as the singleton store implementation
- ensures components can use `useAppStore` safely

### RealTimeJobListener
- subscribes to active job channels via Laravel Echo
- updates job progress in the global store
- leaves channels after terminal status

---

## 3. Global State and Store Patterns

### Store initialization
`store/index.ts` defines the global state and actions.

#### Basic state slices
- UI state: `isSidebarOpen`, `isOnline`, `isJobMonitorOpen`, `loading`
- Notifications: `notifications`
- Background jobs: `jobs`
- Data slices: `contacts`, `tasks`, `workflows`, `memories`

#### Actions and side effects
- `setLoading(key, isLoading)` updates loading registry
- `addNotification(type, message)` appends toast messages
- `hydrateContacts` and `hydrateTasks` fetch backend data
- `createContact` uses optimistic UI updates and backend persistence
- `createTask` persists tasks and rolls back on failure

### Store selector usage
Use `useAppStore` with selector functions to subscribe to specific state slices.

```ts
const contacts = useAppStore((state) => state.contacts);
const hydrateContacts = useAppStore((state) => state.hydrateContacts);
```

### LocalStorage hydration patterns
- `hydrateMemories` initializes memory data from localStorage
- `agents` list in `app/agents/page.tsx` is persisted directly within the page component
- localStorage fallback data sets ensure the UI remains interactive without backend connectivity

### Optimistic updates
The contact and task flows use optimistic updates.
- createContact inserts a temporary record before API confirmation
- if the backend fails, the temp data is removed
- updateTask persists status locally and writes to localStorage

---

## 4. Authentication Architecture

### Auth context contract
`context/AuthContext.tsx` exposes:
- `user`
- `token`
- `isLoading`
- `login(email, password)`
- `logout()`

### Login flow
1. user submits login form in `app/login/page.tsx`
2. `AuthContext.login` posts to `/v1/login`
3. stores token in localStorage via `setToken`
4. stores user payload via `setUser`
5. navigates to `/`

### Logout flow
- sends `POST /v1/logout`
- clears local token and user data
- navigates to `/login`

### Route protection
- `AuthProvider` checks `isAuthenticated()` against `PUBLIC_PATHS`
- if unauthenticated and path is protected, redirects to `/login`

### Token storage functions
`lib/auth.ts` handles token storage and retrieval.

---

## 5. API Client and Error Handling

### Axios API client
Defined in `lib/api/client.ts`.

Key configuration:
- `baseURL`: `NEXT_PUBLIC_API_BASE_URL`
- `timeout`: 10000 ms
- `withCredentials`: true
- `Content-Type`: `application/json`

### Request interceptor
- reads `nexus_auth_token` from localStorage
- attaches `Authorization: Bearer <token>` to outgoing requests

### Response interceptor
- converts errors into `ApiError`
- clears token on `401`
- returns rejected promise with normalized error object

### Error contract
```ts
export interface ApiError {
  message: string;
  code?: string;
  status?: number;
}
```

### Handling API errors in pages
- show toast notifications
- log errors to console for debugging
- fallback to local data when backend is unavailable

---

## 6. Real-time Integration

### WebSocket architecture
`hooks/useWebSocket.ts` creates a Laravel Echo client configured for Pusher compatibility.

Important details
- `Pusher` is assigned to `window.Pusher`
- `key`: `NEXT_PUBLIC_REVERB_APP_KEY`
- `wsHost` and `wsPort`: environment variables
- `forceTLS`: determined by `NEXT_PUBLIC_REVERB_FORCE_TLS`
- authorizer posts to `${NEXT_PUBLIC_API_BASE_URL}/broadcasting/auth`

### Connection lifecycle
- sets `connectionStatus` using the Pusher `state_change` event
- sets `error` on any WebSocket error
- disconnects cleanup on unmount

### Broadcast authorization
- uses bearer token in header
- authorizes private channels via backend endpoint

### Job progress listener
`components/RealTimeJobListener.tsx`
- subscribes to `job.batch.{job.id}`
- listens for `.App\Events\BatchProgressUpdated`
- calls `updateJobProgress` in the global store
- leaves the channel when job completes

---

## 7. Component Library and Composition

### Naming convention
All reusable components use the `Nx` prefix.
Examples:
- `NxButton` (not present explicitly in the codebase but this naming pattern is followed)
- `NxAgentCard`
- `NxContactCard3D`
- `NxGlassCard`
- `NxChatBubble`
- `NxWorkflowNode`

### Composition patterns
- many components accept `children` and custom class names
- components are designed for reusable composition across hubs

### Example component contract
`NxActionButton` props:
- `variant`: `primary | secondary | danger`
- `size`: `sm | md | lg`
- `isLoading`: boolean
- `leftIcon`, `rightIcon`: ReactNode

### UI primitives
- `NxInput`, `NxSelect`, `NxSwitch`, `NxSlider` are used for form controls
- `NxModal`, `NxDrawer`, `NxPopover`, `NxTooltip` are used for overlays
- `NxTable`, `NxTableRow`, `NxTableCell` implement accessible tabular layouts
- `NxSkeleton` and `NxEmptyState` provide loading/empty states

### Design tokens
- `styles/tokens.css` and `tailwind.config.ts` define design tokens and theme colors
- the component set leverages Tailwind utility classes for spacing, responsiveness, and dark mode

---

## 8. Page Patterns and UX Flows

### Dashboard (`app/page.tsx`)
- client-side only page
- uses React state and effects to simulate analytics streams
- sends `POST /api/gemini` for AI assistant responses
- handles `isTyping`/`chatError`

### Login (`app/login/page.tsx`)
- controlled form with local state
- toggles password visibility
- validates required fields
- calls `AuthContext.login`
- displays error message on authentication failure

### Contacts Hub (`app/contacts/page.tsx`)
- uses `useAppStore` selectors for contacts and actions
- supports filters and search
- toggles grid/table layouts
- persists state in global store and optionally backend
- uses semantic UI patterns for empty state and loading state

### Agents Hub (`app/agents/page.tsx`)
- maintains local agent list persisted to `localStorage`
- updates agent configuration via drawer form
- uses `NxAgentCard` to render list of agents
- simulates deployment and token usage updates

### Workflows Hub (`app/workflows/page.tsx`)
- renders a canvas of workflow nodes
- uses `NxWorkflowNode` for node rendering
- executes step-by-step pipeline simulation
- persists node graph in localStorage
- provides reset, clear, and add node actions

### Conversations Hub (`app/conversations/page.tsx`)
- two-pane conversation interface
- left pane lists conversation threads
- right pane displays chat history
- uses `NxChatBubble`, `NxChatInput`
- UI-only simulation without backend persistence

### Tasks Hub (`app/tasks/page.tsx`)
- loads tasks from backend using `hydrateTasks`
- updates task status locally and persists to localStorage
- uses `NxDrawer`, `NxActionButton`, and `NxSelect`
- adds job tracker entries when tasks change state

---

## 9. Custom Hooks

### `useWebSocket`
- manages the Echo connection
- returns `{ echo, connectionStatus, error }`
- binds to state and error events
- authorizes channels through backend route

### `use-haptic.ts`
- likely implements haptic feedback for mobile actions
- provides a device-safe vibration API wrapper

### `use-mobile.ts`
- likely detects mobile viewport conditions
- should expose flags such as `isMobile` and `isLandscape`

Additional hooks are stored in `hooks/` and can be extended for UI and feature-specific behaviors.

---

## 10. Data Models and Type Contracts

### Shared type files
- `types/api.ts`
- `types/models.ts`

### Key interfaces
- `AuthUser`
- `Contact`
- `ApiContact`
- `Task`
- `Workflow`
- `Agent`
- `MemoryItem`
- `Job`
- `ToastMessage`

### Example `AuthUser`
```ts
export interface AuthUser {
  id: number;
  name: string;
  email: string;
}
```

### Example `ApiContact`
```ts
export interface ApiContact {
  id: number;
  uuid: string;
  name: string;
  role: string;
  company: string;
  email: string;
  phone: string;
  avatar_url?: string;
}
```

---

## 11. Styling and Theme System

### Global styles
- `app/globals.css` imports Tailwind base styles and global utilities
- `styles/tokens.css` defines design tokens used across the app

### Theme provider
- `components/theme-provider.tsx` wraps `next-themes`
- `layout.tsx` configures theme behavior with `defaultTheme='dark'`
- theme switching is supported through `NxThemeSwitcher`

### Responsive design
- layout components use Tailwind CSS classes such as `grid`, `flex`, `sm:`, `md:`, `lg:`
- mobile navigation is handled by `MobileHeader` and `NxNavRail`

---

## 12. Testing and Quality Practices

### Current state
- ESLint and Prettier are set up in the repository
- TypeScript strict mode is active

### Recommended test strategy
- Add Vitest and React Testing Library for component and hook tests
- Build snapshots for core UI components
- Add integration tests for `AuthContext`, `useWebSocket`, and route components
- Add API contract tests for `lib/api/client.ts`

### Example test targets
- `LoginPage` form behavior and auth redirect
- `ContactsPage` filter and CRUD workflow
- `AgentsPage` configuration changes and persistence
- `WorkflowsPage` pipeline run simulation
- `useWebSocket` connection lifecycle and error handling

---

## 13. Extension Guidelines

### Adding a new hub
1. Create a new folder under `app/` with `page.tsx`
2. Add a page entry in `NxNavRail` if navigation is required
3. Add a route title to `pageNames` in `components/AppLayout.tsx`
4. Add UI components and a store slice if needed

### Extending the global store
1. Add new state and actions to `store/index.ts`
2. Type the new state in `GlobalState`
3. Use `useAppStore` selectors in components
4. Persist state to localStorage or backend as needed

### Adding a server API route
1. Create `app/api/<route>/route.ts`
2. Export `GET`, `POST`, or other methods as needed
3. Use server-side environment variables safely
4. Keep API routes idempotent and stateless where possible

### Adding secure auth
- Prefer `httpOnly` cookies for production auth tokens
- Keep token-only logic in server-side code where possible
- Avoid storing secrets in client-visible environment variables

---

## 14. Recommended Developer Workflow

1. Install dependencies: `npm install`
2. Run lint: `npm run lint`
3. Start dev server: `npm run dev`
4. Work in feature branch for changes
5. Validate pages by navigating through all hubs
6. Add tests for new behavior before merging
7. Build locally: `npm run build`
8. Deploy to staging and verify `/api/health` and `/api/gemini`

---

## 15. Reference Files
- `app/layout.tsx`
- `app/page.tsx`
- `app/login/page.tsx`
- `app/contacts/page.tsx`
- `app/agents/page.tsx`
- `app/workflows/page.tsx`
- `app/conversations/page.tsx`
- `app/tasks/page.tsx`
- `store/index.ts`
- `context/AuthContext.tsx`
- `lib/api/client.ts`
- `hooks/useWebSocket.ts`
- `components/RealTimeJobListener.tsx`
- `.env.example`
- `package.json`

---

**End of Nexus Frontend Developer Reference Manual**
