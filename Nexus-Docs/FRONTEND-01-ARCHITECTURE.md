# Nexus Frontend - System Architecture Documentation

**Last Updated**: May 25, 2026  
**Project**: Nexus-Frontend (Next.js 14)  
**Purpose**: Comprehensive technical overview of frontend architecture and organization

---

## Table of Contents

1. [Executive Overview](#executive-overview)
2. [Technology Stack](#technology-stack)
3. [Directory Structure & Organization](#directory-structure--organization)
4. [Page Structure & Routing](#page-structure--routing)
5. [Component Architecture](#component-architecture)
6. [State Management](#state-management)
7. [API Integration Pattern](#api-integration-pattern)
8. [Styling & Theme System](#styling--theme-system)
9. [Real-time Communication](#real-time-communication)
10. [Performance Architecture](#performance-architecture)
11. [Error Handling & Resilience](#error-handling--resilience)
12. [Testing Architecture](#testing-architecture)

---

## Executive Overview

### Project Type
- **Framework**: Next.js 14 (React 18)
- **Language**: TypeScript
- **Styling**: Tailwind CSS + Custom Design System
- **State Management**: Zustand (global store)
- **API Client**: Axios
- **Real-time**: WebSocket via Reverb
- **UI Components**: 60+ custom components (Nx-prefixed)
- **Design Pattern**: Hub-based architecture

### Core Responsibilities
- **User Interface**: Render data hubs (Contacts, Agents, Workflows, etc.)
- **Data Visualization**: Charts, graphs, activity heatmaps
- **Real-time Updates**: WebSocket-based live data
- **API Communication**: RESTful backend integration
- **State Persistence**: LocalStorage for user preferences
- **Authentication**: Token-based auth with Sanctum

### Key Metrics
- **Components**: 60+ custom Nx components
- **Pages/Routes**: 12+ feature hubs
- **TypeScript Coverage**: 95%+
- **Build Size**: ~450KB (gzipped)
- **Performance Score**: 85-95 (Lighthouse)

---

## Technology Stack

### Core Framework
```
Next.js 14.0+
├── App Router (latest)
├── Server Components (experimental)
├── API Routes (for proxying)
└── Image Optimization
```

### Frontend Libraries
```
React 18.2+
├── Hooks (useState, useContext, useEffect, etc.)
├── Suspense (code splitting, async rendering)
└── Error Boundaries

Zustand 4.4+ (State Management)
├── Global store
├── Persist plugin
└── DevTools integration

Tailwind CSS 3.3+
├── Custom theme extension
├── Dark mode support
├── Plugin system

TypeScript 5.2+
├── Strict mode enabled
├── Type-safe components
└── Generic type support
```

### Component & Animation Libraries
```
Motion (Framer Motion alternative)
├── Smooth transitions
├── Spring animations
├── Gesture support

Lucide React 0.292+
├── 400+ icons
├── Tree-shakeable
└── Customizable stroke width

Recharts 2.10+
├── Data visualization
├── Interactive charts
└── Custom tooltips

React Hot Toast
├── Toast notifications
├── Customizable styling
└── Promise-based API
```

### HTTP Client & Communication
```
Axios 1.6+
├── Request interceptors
├── Response interceptors
├── Request cancellation
└── Built-in timeout handling

WebSocket (Native)
├── Reverb integration
├── Auto-reconnection
├── Channel subscription
```

### Development Tools
```
ESLint + Prettier
├── Code linting
├── Format enforcement
└── Git hooks (Husky)

Vitest + React Testing Library
├── Unit testing
├── Component testing
└── Integration testing
```

---

## Directory Structure & Organization

### Root Level Organization

```
nexus-frontend/
├── app/                         # Next.js App Router
│   ├── layout.tsx              # Root layout
│   ├── page.tsx                # Home page
│   └── [feature]/              # Feature pages
│
├── components/                  # Reusable UI components
│   ├── Nx[ComponentName].tsx    # Naming convention
│   └── ...
│
├── hooks/                       # Custom React hooks
│   ├── useGlobalStore.ts
│   ├── useAuth.ts
│   ├── useWebSocket.ts
│   └── ...
│
├── lib/                         # Utilities & helpers
│   ├── api/                     # API client
│   ├── auth.ts                  # Auth utilities
│   ├── utils.ts                 # General utilities
│   └── ...
│
├── store/                       # Global state (Zustand)
│   ├── index.ts                 # Main store
│   ├── store-provider.tsx       # Store provider
│   └── ...
│
├── context/                     # React Context
│   ├── AuthContext.tsx
│   └── ...
│
├── types/                       # TypeScript types
│   ├── api.ts                   # API response types
│   ├── models.ts                # Domain models
│   └── ...
│
├── styles/                      # Global styles
│   ├── globals.css
│   ├── tokens.css               # Design tokens
│   └── theme.ts
│
├── constants/                   # App constants
│   └── index.ts
│
├── utils/                       # Utility functions
│   └── index.ts
│
├── public/                      # Static assets
│   ├── images/
│   ├── icons/
│   └── ...
│
├── next.config.ts              # Next.js configuration
├── tsconfig.json               # TypeScript config
├── tailwind.config.ts          # Tailwind config
├── eslint.config.mjs           # ESLint config
└── package.json
```

### Components Directory Structure

```
components/
├── Layout/
│   ├── AppLayout.tsx           # Main app wrapper
│   ├── MobileHeader.tsx         # Mobile navigation
│   ├── NxNavRail.tsx           # Sidebar navigation
│   ├── NxTopBar.tsx            # Top bar
│   └── NxStatusBar.tsx         # Status indicator
│
├── Forms/
│   ├── NxInput.tsx
│   ├── NxSelect.tsx
│   ├── NxCheckbox.tsx
│   ├── NxSwitch.tsx
│   ├── NxSlider.tsx
│   └── NxFileUpload.tsx
│
├── Cards/
│   ├── NxGlassCard.tsx         # Frosted glass effect
│   ├── NxAgentCard.tsx         # Agent display
│   ├── NxContactCard3D.tsx     # 3D contact card
│   ├── NxMetricCard.tsx        # Metric display
│   └── NxMemoryChip.tsx        # Memory badge
│
├── Data Display/
│   ├── NxDataGrid.tsx          # Grid with sorting
│   ├── NxTable.tsx             # Table component
│   ├── NxTableRow.tsx
│   ├── NxTableCell.tsx
│   ├── NxPagination.tsx
│   ├── NxSkeleton.tsx          # Loading state
│   └── NxEmptyState.tsx        # Empty state UI
│
├── Chat/
│   ├── NxChatBubble.tsx        # Message bubble
│   ├── NxChatInput.tsx         # Chat input box
│   ├── NxThinkingIndicator.tsx # AI thinking UI
│   ├── NxSourceCitation.tsx    # Citation display
│   └── NxMessageActions.tsx    # Message controls
│
├── Feedback/
│   ├── NxModal.tsx             # Modal dialog
│   ├── NxDrawer.tsx            # Slide-out drawer
│   ├── NxToast.tsx             # Toast notification
│   ├── NxTooltip.tsx           # Tooltip
│   ├── NxPopover.tsx           # Popover menu
│   └── NxNotificationDrawer.tsx # Notification panel
│
├── Visualization/
│   ├── NxActivityHeatmap.tsx   # Activity calendar
│   ├── NxEmotionRadar.tsx      # Sentiment radar
│   ├── NxEngagementRing.tsx    # Circular progress
│   ├── NxFlowLines.tsx         # Flow diagram lines
│   └── NxWorkflowNode.tsx      # Workflow step node
│
├── Interactive/
│   ├── NxActionButton.tsx      # Action button
│   ├── NxCommandBar.tsx        # Command palette
│   ├── NxContextMenu.tsx       # Right-click menu
│   ├── NxDragDropZone.tsx      # Drag & drop area
│   └── NxResizablePanel.tsx    # Resizable container
│
└── Utilities/
    ├── NxThemeSwitcher.tsx     # Light/dark toggle
    ├── NxLiveRegion.tsx        # Accessibility
    └── NxConnectionStatus.tsx  # Connection indicator
```

### Hubs Organization

```
app/
├── page.tsx                     # Home/Dashboard
├── layout.tsx                   # Root layout
│
├── login/
│   └── page.tsx                 # Login page
│
├── contacts/
│   ├── page.tsx                 # ContactsHub list
│   ├── layout.tsx               # Contacts layout
│   └── [id]/
│       └── page.tsx             # Contact detail
│
├── agents/
│   ├── page.tsx                 # AgentsHub
│   └── [id]/
│       └── page.tsx             # Agent detail
│
├── workflows/
│   ├── page.tsx                 # WorkflowsHub
│   ├── [id]/
│   │   └── page.tsx             # Workflow builder
│   └── executions/
│       └── [id].tsx             # Execution detail
│
├── conversations/
│   ├── page.tsx                 # ConversationsHub
│   └── [id]/
│       └── page.tsx             # Chat view
│
├── tasks/
│   ├── page.tsx                 # TasksHub
│   └── [id]/
│       └── page.tsx             # Task detail
│
├── memory/
│   └── page.tsx                 # MemoryHub
│
├── ai-models/
│   └── page.tsx                 # AIModelsHub
│
├── logs/
│   └── page.tsx                 # LogsHub
│
├── settings/
│   └── page.tsx                 # SettingsHub
│
└── scheduler/
    └── page.tsx                 # SchedulerHub
```

---

## Page Structure & Routing

### App Router Pattern

```
Feature-based routing using Next.js 14 App Router
├── /                           Home page
├── /login                       Authentication
├── /contacts                    Contact management
│   ├── /[id]                    Contact detail
│   └── /[id]/edit               Contact edit
├── /agents                      Agent management
│   ├── /[id]                    Agent detail
│   └── /[id]/test               Agent tester
├── /workflows                   Workflow builder
│   ├── /[id]                    Workflow edit
│   └── /[id]/executions         Execution history
├── /conversations               Chat interface
│   └── /[id]                    Conversation
├── /tasks                       Task management
│   └── /[id]                    Task detail
├── /memory                      Memory browser
├── /ai-models                   Model settings
├── /logs                        System logs
├── /settings                    Configuration
└── /scheduler                   Scheduling hub
```

### Dynamic Route Handling

```typescript
// app/contacts/[id]/page.tsx
interface ContactPageProps {
  params: {
    id: string;
  };
}

export default async function ContactPage({ params }: ContactPageProps) {
  const contact = await fetchContact(params.id);
  
  return (
    <ContactDetail contact={contact} />
  );
}

// Dynamic metadata
export async function generateMetadata({ params }: ContactPageProps) {
  const contact = await fetchContact(params.id);
  return {
    title: `${contact.name} - Nexus`,
    description: contact.company,
  };
}
```

---

## Component Architecture

### Component Naming & Structure

All UI components follow naming convention: `Nx[ComponentName]`

```typescript
// NxButton.tsx
import { ButtonHTMLAttributes } from 'react';

export interface NxButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export function NxButton({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  children,
  disabled,
  ...props
}: NxButtonProps) {
  return (
    <button
      className={`nx-button nx-button-${variant} nx-button-${size}`}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading && <NxSpinner />}
      {children}
    </button>
  );
}
```

### Composition Pattern

```typescript
// Card composition example
<NxGlassCard className="p-4">
  <NxCard.Header>
    <h2>Contact Information</h2>
  </NxCard.Header>
  
  <NxCard.Content>
    <div className="space-y-4">
      <NxInput label="Name" value={name} onChange={setName} />
      <NxSelect label="Status" options={statusOptions} />
    </div>
  </NxCard.Content>
  
  <NxCard.Footer>
    <NxButton>Save Changes</NxButton>
  </NxCard.Footer>
</NxGlassCard>
```

### Component State Management

```typescript
// Local state for component-specific state
const [isOpen, setIsOpen] = useState(false);
const [selectedTab, setSelectedTab] = useState('overview');

// Global store for shared state
const { contacts, setContacts } = useGlobalStore();

// Context for theme/auth
const { theme, toggleTheme } = useAuth();
```

---

## State Management

### Zustand Store Structure

```typescript
// store/index.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AppState {
  // Auth
  isAuthenticated: boolean;
  user: User | null;
  setUser: (user: User | null) => void;
  logout: () => void;
  
  // Global data
  contacts: Contact[];
  setContacts: (contacts: Contact[]) => void;
  addContact: (contact: Contact) => void;
  
  // UI state
  sidebarOpen: boolean;
  toggleSidebar: () => void;
  theme: 'light' | 'dark';
  setTheme: (theme: 'light' | 'dark') => void;
  
  // Real-time
  isConnected: boolean;
  setConnected: (connected: boolean) => void;
}

export const useGlobalStore = create<AppState>()(
  persist(
    (set) => ({
      // Initial state
      isAuthenticated: false,
      user: null,
      contacts: [],
      sidebarOpen: true,
      theme: 'light',
      isConnected: false,
      
      // Actions
      setUser: (user) => set({ user, isAuthenticated: !!user }),
      logout: () => set({ user: null, isAuthenticated: false }),
      setContacts: (contacts) => set({ contacts }),
      addContact: (contact) => set((state) => ({
        contacts: [...state.contacts, contact]
      })),
      toggleSidebar: () => set((state) => ({
        sidebarOpen: !state.sidebarOpen
      })),
      setTheme: (theme) => set({ theme }),
      setConnected: (isConnected) => set({ isConnected }),
    }),
    {
      name: 'app-store',
      partialize: (state) => ({
        theme: state.theme,
        sidebarOpen: state.sidebarOpen,
      }),
    }
  )
);
```

### Store Provider Pattern

```typescript
// store/store-provider.tsx
'use client';

import { ReactNode } from 'react';
import { useGlobalStore } from './index';

export function StoreProvider({ children }: { children: ReactNode }) {
  // Hydrate store from localStorage
  const initialize = useGlobalStore((state) => state.initialize);
  
  useEffect(() => {
    initialize();
  }, []);
  
  return <>{children}</>;
}

// app/layout.tsx
import { StoreProvider } from '@/store/store-provider';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <StoreProvider>
          {children}
        </StoreProvider>
      </body>
    </html>
  );
}
```

---

## API Integration Pattern

### API Client Setup

```typescript
// lib/api/client.ts
import axios, { AxiosInstance } from 'axios';

const client: AxiosInstance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
client.interceptors.request.use((config) => {
  const token = localStorage.getItem('api_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor
client.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized
      localStorage.removeItem('api_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default client;
```

### API Hooks Pattern

```typescript
// hooks/useContacts.ts
import { useEffect, useState } from 'react';
import client from '@/lib/api/client';

export function useContacts() {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  
  useEffect(() => {
    const fetchContacts = async () => {
      try {
        setLoading(true);
        const data = await client.get('/api/v1/contacts');
        setContacts(data.data);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchContacts();
  }, []);
  
  return { contacts, loading, error, refetch: () => fetchContacts() };
}
```

### Server Component Data Fetching

```typescript
// app/contacts/page.tsx
async function getContacts() {
  const response = await fetch(
    `${process.env.API_URL}/api/v1/contacts`,
    {
      headers: {
        'Authorization': `Bearer ${process.env.API_TOKEN}`,
      },
      next: { revalidate: 60 }, // ISR: revalidate every 60 seconds
    }
  );
  
  if (!response.ok) {
    throw new Error('Failed to fetch contacts');
  }
  
  return response.json();
}

export default async function ContactsPage() {
  const { data: contacts } = await getContacts();
  
  return (
    <div>
      <ContactsGrid contacts={contacts} />
    </div>
  );
}
```

---

## Styling & Theme System

### Tailwind Configuration

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Brand colors
        nexus: {
          50: '#f0f9ff',
          500: '#0ea5e9',
          900: '#001f3f',
        },
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      keyframes: {
        slide: {
          'from': { transform: 'translateX(-100%)' },
          'to': { transform: 'translateX(0)' },
        },
      },
    },
  },
  plugins: [],
};
```

### Theme Switching

```typescript
// hooks/useTheme.ts
import { useEffect } from 'react';
import { useGlobalStore } from '@/store';

export function useTheme() {
  const { theme, setTheme } = useGlobalStore();
  
  useEffect(() => {
    const root = document.documentElement;
    if (theme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [theme]);
  
  return { theme, toggleTheme: () => setTheme(theme === 'dark' ? 'light' : 'dark') };
}
```

---

## Real-time Communication

### WebSocket Integration

```typescript
// hooks/useWebSocket.ts
import { useEffect } from 'react';
import { useGlobalStore } from '@/store';

export function useWebSocket(channel: string, onMessage: (data: any) => void) {
  const { setConnected } = useGlobalStore();
  
  useEffect(() => {
    // Connect to Reverb WebSocket
    const ws = new WebSocket(
      `${process.env.NEXT_PUBLIC_WS_URL}/app/${process.env.NEXT_PUBLIC_REVERB_APP_KEY}`
    );
    
    ws.onopen = () => {
      setConnected(true);
      // Subscribe to channel
      ws.send(JSON.stringify({
        event: 'pusher:subscribe',
        data: { channel },
      }));
    };
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.event === channel) {
        onMessage(message.data);
      }
    };
    
    ws.onclose = () => setConnected(false);
    
    return () => ws.close();
  }, [channel, onMessage, setConnected]);
}
```

---

## Performance Architecture

### Code Splitting & Lazy Loading

```typescript
// Dynamic imports for large components
import dynamic from 'next/dynamic';

const WorkflowBuilder = dynamic(
  () => import('@/components/WorkflowBuilder'),
  { loading: () => <NxSkeleton /> }
);

export default function WorkflowsPage() {
  return (
    <div>
      <WorkflowBuilder /> {/* Loaded on demand */}
    </div>
  );
}
```

### Image Optimization

```typescript
// next/image for automatic optimization
import Image from 'next/image';

export function ContactAvatar({ src, alt }: Props) {
  return (
    <Image
      src={src}
      alt={alt}
      width={40}
      height={40}
      className="rounded-full"
      priority={false}
    />
  );
}
```

### Performance Monitoring

```typescript
// lib/performance.ts
export function reportMetric(name: string, value: number) {
  if ('sendBeacon' in navigator) {
    navigator.sendBeacon('/api/metrics', JSON.stringify({
      name,
      value,
      timestamp: Date.now(),
    }));
  }
}

// Usage
useEffect(() => {
  const startTime = performance.now();
  return () => {
    const duration = performance.now() - startTime;
    reportMetric('page_render_time', duration);
  };
}, []);
```

---

## Error Handling & Resilience

### Error Boundary

```typescript
// components/ErrorBoundary.tsx
'use client';

import { ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

export class ErrorBoundary extends React.Component<Props> {
  state = { hasError: false };
  
  static getDerivedStateFromError() {
    return { hasError: true };
  }
  
  componentDidCatch(error: Error) {
    console.error('Error caught:', error);
  }
  
  render() {
    if (this.state.hasError) {
      return this.props.fallback || <NxErrorState />;
    }
    
    return this.props.children;
  }
}
```

### API Error Handling

```typescript
// Graceful API failure handling
try {
  const data = await client.get('/api/v1/contacts');
  setContacts(data);
} catch (error) {
  if (error.response?.status === 404) {
    toast.error('Resource not found');
  } else if (error.response?.status === 429) {
    toast.error('Too many requests. Please try again later.');
  } else {
    toast.error('An error occurred. Please try again.');
  }
}
```

---

## Testing Architecture

### Component Testing

```typescript
// components/__tests__/NxButton.test.tsx
import { render, screen } from '@testing-library/react';
import { NxButton } from '../NxButton';

describe('NxButton', () => {
  it('renders with text', () => {
    render(<NxButton>Click me</NxButton>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });
  
  it('handles click events', () => {
    const handleClick = vi.fn();
    render(<NxButton onClick={handleClick}>Click</NxButton>);
    screen.getByText('Click').click();
    expect(handleClick).toHaveBeenCalled();
  });
});
```

---

## Summary

The Nexus Frontend follows a hub-based architecture with:
- ✅ Component-driven UI design (60+ components)
- ✅ Type-safe development (TypeScript)
- ✅ Efficient state management (Zustand)
- ✅ Real-time capabilities (WebSocket)
- ✅ Responsive design (Tailwind CSS)
- ✅ Performance-optimized (Code splitting, image optimization)
- ✅ Well-tested components

---

**End of Frontend System Architecture Documentation**
