# Nexus Frontend - Development & Deployment Guide

**Last Updated**: May 25, 2026  
**Project**: Nexus-Frontend  
**Purpose**: Step-by-step setup, development, build, and deployment guidance for the Nexus frontend

---

## 1. Prerequisites

### Software Requirements
- Node.js 20.x or later
- npm 10.x or later
- Git

### Recommended Tools
- VS Code with TypeScript and ESLint extensions
- Browser with developer tools
- Docker (optional for local backend integration)

### Project Requirements
- Backend API available at `NEXT_PUBLIC_API_BASE_URL`
- Reverb WebSocket server accessible via `NEXT_PUBLIC_REVERB_HOST` and `NEXT_PUBLIC_REVERB_PORT`
- Gemini API key defined in environment variables

---

## 2. Initial Setup

### Clone the repository
```bash
cd c:/Users/hedra/Desktop/Sourcecode/NexusV2
cd Nexus-Frontend
```

### Install dependencies
```bash
npm install
```

### Environment configuration
1. Copy `.env.example` to `.env.local`
2. Populate required variables:
   - `GEMINI_API_KEY`
   - `APP_URL`
   - `NEXT_PUBLIC_API_BASE_URL`
   - `NEXT_PUBLIC_BROADCAST_AUTH_URL`
   - `NEXT_PUBLIC_REVERB_APP_KEY`
   - `NEXT_PUBLIC_REVERB_HOST`
   - `NEXT_PUBLIC_REVERB_PORT`
   - `NEXT_PUBLIC_REVERB_SCHEME`

### Example `.env.local`
```env
GEMINI_API_KEY="your-gemini-api-key"
APP_URL="http://localhost:3000"
NEXT_PUBLIC_API_BASE_URL="http://localhost:8000/api"
NEXT_PUBLIC_BROADCAST_AUTH_URL="http://localhost:8000/broadcasting/auth"
NEXT_PUBLIC_REVERB_APP_KEY="local"
NEXT_PUBLIC_REVERB_HOST="127.0.0.1"
NEXT_PUBLIC_REVERB_PORT="8080"
NEXT_PUBLIC_REVERB_SCHEME="http"
```

### Notes
- `GEMINI_API_KEY` must be set inside the local environment or workspace secret store.
- `NEXT_PUBLIC_REVERB_*` values must correspond to the Reverb backend service configuration.

---

## 3. Local Development

### Start frontend
```bash
npm run dev
```
The app will be available at `http://localhost:3000` by default.

### Recommended local workflow
1. Start backend API locally (Laravel app, Postgres, Redis, Reverb) if available.
2. Confirm `NEXT_PUBLIC_API_BASE_URL` points to the local backend API.
3. Confirm `NEXT_PUBLIC_BROADCAST_AUTH_URL` points to the backend broadcast auth route.
4. Open browser and verify login page loads.

### Common development commands
- `npm run dev` — development server
- `npm run build` — compile production assets
- `npm run lint` — lint source files
- `npm run clean` — removes Next.js cache files

---

## 4. Build Workflow

### Production build
```bash
npm run build
```

### Start production server
```bash
npm run start
```

### Static export
This project is not configured as a pure static export because it uses server-side API routes (`/api/gemini`) and dynamic runtime behavior.

### Build artifact location
- built server files: `.next/`
- production server entry: `.next/standalone/server.js`

---

## 5. Deployment Targets

### Vercel or AI Studio
The project is well-suited for deployment on Vercel or Google AI Studio because it is a Next.js App Router application with server-side API routes.

#### Vercel deployment steps
1. Connect repository to Vercel.
2. Set environment variables in Vercel dashboard.
3. Ensure build command is `npm run build`.
4. Ensure output directory is `.next`.
5. Deploy.

#### AI Studio deployment steps
1. Configure workspace secrets for `GEMINI_API_KEY`.
2. Set runtime environment variables to match `.env.local`.
3. Deploy using AI Studio build process.

### Custom Node host
1. Build the app: `npm run build`
2. Run the app: `npm run start`
3. Configure reverse proxy or load balancer to route traffic to port `3000` or custom port

---

## 6. API & WebSocket Configuration

### Backend API
- Base URL: `NEXT_PUBLIC_API_BASE_URL`
- Used by `lib/api/client.ts`
- Must accept JSON requests and a Bearer token header

### WebSocket/Reverb
- Uses Laravel Echo and Pusher-compatible client in `hooks/useWebSocket.ts`
- Key: `NEXT_PUBLIC_REVERB_APP_KEY`
- Host: `NEXT_PUBLIC_REVERB_HOST`
- Port: `NEXT_PUBLIC_REVERB_PORT`
- Scheme: `NEXT_PUBLIC_REVERB_SCHEME`

### Broadcast auth route
- `lib/api/client.ts` uses tokens from `localStorage`
- the authorizer posts to `${NEXT_PUBLIC_API_BASE_URL}/broadcasting/auth`
- needs a valid Bearer token in the Authorization header

---

## 7. Deployment Configuration

### `tsconfig.json`
- `strict`: true
- `baseUrl`: `.`
- path alias `@/*` → `./*`

### `next.config.ts`
- standard project configuration
- ensure `reactStrictMode` is enabled where appropriate

### `tailwind.config.ts`
- content includes `app/**/*` and `components/**/*`
- extends theme with custom colors and keyframes

---

## 8. Authentication Setup

### Local login testing
- Backend login route expected: `POST /v1/login`
- The frontend stores token in `localStorage` under `nexus_auth_token`
- The `AuthProvider` redirects unauthorized users to `/login`

### Recommended production change
- Move token handling to secure cookies or authentication proxy for improved security

---

## 9. Health Checks and Monitoring

### Health endpoint
- `/api/health` returns `{ status: 'healthy', timestamp: ... }`
- Use this route for deployment and uptime checks

### Frontend readiness checks
- `/login` should load
- `app/page.tsx` should render after login
- `/api/gemini` should return `success: true` when environment variables are configured

---

## 10. Troubleshooting

### 10.1 Frontend fails to start
- Ensure Node 20+ is installed
- Run `npm install` again
- Delete `.next` and rerun `npm run dev`

### 10.2 API requests fail
- Confirm `NEXT_PUBLIC_API_BASE_URL` is correct
- Confirm backend is running and reachable
- Check browser console network tab for 401/403 errors

### 10.3 Authentication loop or redirect issues
- Confirm `nexus_auth_token` is present in `localStorage`
- Ensure `AuthContext` can read token only in browser environment
- Clear localStorage and reload

### 10.4 Gemini AI route errors
- Confirm `GEMINI_API_KEY` is configured correctly
- Ensure server-side environment variables are available during build/run time
- Check the AI Studio or Vercel secret store if deployed to cloud

### 10.5 WebSocket connection failures
- Confirm `NEXT_PUBLIC_REVERB_HOST` and `NEXT_PUBLIC_REVERB_APP_KEY`
- Inspect console logs from `useWebSocket.ts`
- Ensure broadcast auth endpoint is reachable and returns valid auth payload

---

## 11. Developer Commands

| Command | Purpose |
|---|---|
| `npm install` | install dependencies |
| `npm run dev` | run local development server |
| `npm run build` | build production artifacts |
| `npm run start` | start production server |
| `npm run lint` | lint files |
| `npm run clean` | remove Next.js build cache |

---

## 12. Recovery and Rollback

### Local cleanup
```bash
rm -rf node_modules .next
npm install
```

### Rollback deployment
- use your host or Vercel dashboard to rollback to last successful deployment
- confirm environment variables remain unchanged

---

## 13. Integration Notes

### Backend dependency
The frontend depends on the backend for:
- contact records
- task hydration
- auth login/logout
- broadcast authorization
- conversation and workflow metadata if backend integration is extended

### Gemini AI dependency
- `app/api/gemini/route.ts` requires `GEMINI_API_KEY`
- uses `@google/genai` SDK for request handling

### LocalStorage dependency
- data slices such as agent config, workflows, and memories depend on localStorage persistence
- localStorage is used for offline-friendly UI state

---

## 14. Deployment Checklist

- [ ] Install dependencies (`npm install`)
- [ ] Populate `.env.local`
- [ ] Validate `NEXT_PUBLIC_API_BASE_URL`
- [ ] Validate Reverb configuration
- [ ] Run `npm run lint`
- [ ] Run `npm run build`
- [ ] Start the app and confirm `/login` loads
- [ ] Confirm `/api/health` returns healthy status
- [ ] Confirm `app/api/gemini` route responds successfully
- [ ] Test a login and contact page load

---

**End of Nexus Frontend Development & Deployment Guide**
