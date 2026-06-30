# Nexus v2 — Frontend README

**Next.js 15 Application**

---

## 📦 Tech Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| Next.js | 15.4.9 | React framework (App Router) |
| React | 19.2.1 | UI library |
| TypeScript | 5.9.3 | Type safety |
| Tailwind CSS | 3.4+ | Styling |
| Zustand | 5.0.13 | Global state |
| TanStack Query | 5.101.0 | Server state & caching |
| Axios | 1.16.1 | HTTP client |
| Laravel Echo | 2.3.4 | WebSocket client |
| Motion | 12.23.24 | Animations |
| React Flow | 12.10.2 | Workflow visual canvas |
| Recharts | 3.8.1 | Charts |

---

## 🚀 Setup

```bash
cd Nexus-Frontend

# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env.local
# Edit .env.local:
# NEXT_PUBLIC_API_URL=http://localhost:8000
# NEXT_PUBLIC_REVERB_HOST=localhost
# NEXT_PUBLIC_REVERB_PORT=6001

# 3. Start development server
npm run dev   # → http://localhost:3000
```

---

## 🔧 Available Scripts

| Script | Command | Purpose |
|--------|---------|---------|
| Development | `npm run dev` | Start dev server (hot reload) |
| Build | `npm run build` | Production build |
| Start | `npm start` | Serve production build |
| Lint | `npm run lint` | ESLint code check |
| Test | `npm run test` | Run Vitest unit tests |
| Test UI | `npm run test:ui` | Vitest with browser UI |
| Test Watch | `npm run test:watch` | Watch mode |
| Clean | `npm run clean` | Clean .next cache |

---

## 📁 Directory Structure

```
Nexus-Frontend/
├── app/                    # Next.js App Router
│   ├── page.tsx            # Dashboard (root page)
│   ├── layout.tsx          # Root layout + providers
│   ├── globals.css         # Global CSS
│   ├── contacts/           # ContactsHub
│   │   ├── page.tsx        # Contact list
│   │   └── [id]/           # Contact detail
│   ├── agents/             # AgentsHub
│   ├── tasks/              # TaskHub
│   ├── workflows/          # WorkflowsHub
│   ├── memory/             # MemoryHub
│   ├── ai-models/          # AIModelsHub
│   ├── hedra-soul/         # HedraSoulHub
│   │   ├── page.tsx
│   │   ├── types.ts        # TypeScript types
│   │   ├── api.ts          # API client
│   │   └── components/     # Hub components
│   ├── notifications/      # NotificationsHub
│   ├── scheduler/          # SchedulerHub
│   ├── people-connect/     # PeopleConnectHub
│   ├── settings/           # SettingsHub
│   ├── logs/               # LogsHub
│   ├── proactive-ai/       # ProactiveAIHub
│   ├── admin/              # Admin panel
│   └── login/              # Authentication page
│
├── components/             # Shared Nx design system (90+ components)
│   ├── NxNavRail.tsx       # Sidebar navigation
│   ├── NxTopBar.tsx        # Top bar with context controls
│   ├── NxStatusBar.tsx     # System status bottom bar
│   ├── NxModal.tsx         # Modal container
│   ├── NxDataGrid.tsx      # Data table
│   ├── NxCommandBar.tsx    # Global command bar (⌘K)
│   ├── NxNotificationDrawer.tsx  # Notification panel
│   ├── NxWorkflowCanvas.tsx      # Workflow visual editor
│   ├── NxRelationshipGraph.tsx   # Contact graph view
│   ├── NxMemoriesViewer.tsx      # Memory browser
│   ├── NxAiAnalysisModal.tsx     # AI analysis modal
│   └── ...80+ more components
│
├── hooks/                  # Custom React hooks
│   ├── useHedraSoulHub.ts  # Full HedraSoul hook (21KB)
│   ├── useWebSocket.ts     # WebSocket connection
│   ├── useDashboardStats.ts
│   ├── useActivityFeed.ts
│   └── ...
│
├── lib/                    # Utilities and API clients
│   ├── api/                # Per-hub API client functions
│   ├── hooks/              # Lib-level hooks
│   ├── utils/              # Utility functions
│   ├── auth.ts             # Auth token management
│   └── realtime.ts         # Laravel Echo setup
│
├── store/                  # Zustand state management
│   └── index.ts            # Global store (44KB)
│
├── context/                # React contexts
├── types/                  # TypeScript type definitions
├── styles/                 # Global styles
├── constants/              # App constants
└── utils/                  # Utility functions
```

---

## 🎨 Nx Design System

The Nexus frontend has a custom component library prefixed with `Nx*`:

### Layout Components
| Component | Purpose |
|-----------|---------|
| `NxNavRail` | Left sidebar navigation rail |
| `NxTopBar` | Top bar with breadcrumbs and actions |
| `NxStatusBar` | Bottom status bar (live metrics) |
| `AppLayout` | Root layout wrapper |
| `NxResizablePanel` | Resizable split-pane panels |

### Data Display
| Component | Purpose |
|-----------|---------|
| `NxDataGrid` | Sortable, filterable data table |
| `NxTable`, `NxTableRow`, `NxTableCell` | Table primitives |
| `NxMetricCard` | KPI metric card |
| `NxActivityHeatmap` | Contribution-style heatmap |
| `NxEngagementRing` | Ring chart |

### AI & Intelligence
| Component | Purpose |
|-----------|---------|
| `NxAiAnalysisModal` | Contact AI analysis trigger |
| `NxIntelligencePanel` | AI insights panel |
| `NxEmotionRadar` | Emotion analysis radar chart |
| `NxMemoriesViewer` | Memory browser |
| `NxRelationshipGraph` | Force-directed graph |
| `NxThinkingIndicator` | AI "thinking" animation |

### Forms & Input
| Component | Purpose |
|-----------|---------|
| `NxInput` | Styled text input |
| `NxSelect` | Styled dropdown |
| `NxCheckbox` | Styled checkbox |
| `NxSwitch` | Toggle switch |
| `NxSlider` | Range slider |
| `NxChatInput` | Rich chat input |

### Feedback & Overlays
| Component | Purpose |
|-----------|---------|
| `NxModal` | Centered modal dialog |
| `NxDrawer` | Slide-out drawer panel |
| `NxToast` | Toast notifications |
| `NxTooltip` | Hover tooltip |
| `NxPopover` | Click popover |
| `NxSkeleton` | Loading skeleton |
| `NxEmptyState` | Empty data state |

---

## 🔑 Key Environment Variables

```env
NEXT_PUBLIC_API_URL=http://localhost:8000        # Backend API base URL
NEXT_PUBLIC_REVERB_HOST=localhost                # WebSocket host
NEXT_PUBLIC_REVERB_PORT=6001                     # WebSocket port
NEXT_PUBLIC_REVERB_SCHEME=http                   # http | https
NEXT_PUBLIC_APP_NAME=Nexus                       # App name
```

---

## 🌐 State Management Patterns

### Server State (TanStack Query)
```typescript
// All API data is managed by TanStack Query
const { data: contacts, isLoading } = useQuery({
  queryKey: ['contacts', filters],
  queryFn: () => fetchContacts(filters),
  staleTime: 30_000,  // 30 seconds
});

// Mutations with optimistic updates
const mutation = useMutation({
  mutationFn: createContact,
  onSuccess: () => queryClient.invalidateQueries(['contacts']),
});
```

### Global UI State (Zustand)
```typescript
// Access global store
const { selectedContact, setSelectedContact } = useStore();
```

### Real-Time State (Laravel Echo)
```typescript
// Subscribe to WebSocket events
const { isConnected } = useWebSocket();

// Hub-specific subscriptions in useHedraSoulHub.ts, etc.
```

---

## 🧪 Testing

```bash
# Unit tests (Vitest)
npm run test

# Specific test file
npm run test -- contacts.test.ts

# E2E tests (Playwright)
npx playwright test

# E2E with browser visible
npx playwright test --headed
```

**Test files location:**
- Unit: `__tests__/` directories per hub, `app/*/__tests__/`
- E2E: `tests/` (Playwright)

---

## 📐 TypeScript Types

Key type definitions:
- `types/` — Global shared types
- `app/hedra-soul/types.ts` — HedraSoul domain types
- `app/settings/types.ts` — Settings types
- `lib/api/*.ts` — API response types per hub

---

## 🔗 Routing

All routes use the Next.js App Router:

| Pattern | Example | Description |
|---------|---------|-------------|
| `/` | `/` | Dashboard |
| `/[hub]` | `/contacts` | Hub main page |
| `/[hub]/[id]` | `/contacts/abc-123` | Resource detail |
| `/admin` | `/admin` | Admin panel |
| `/login` | `/login` | Authentication |

---

*Nexus v2 Frontend · 2026-06-14*
