# Settings & Administration (settings)

## Overview
Manage application configuration, integrations, health monitoring, and system controls. Settings are grouped by categories.

## Design Details
- **Header**: Icon (Settings, blue, pulsing), title, and description.
- **Tabs Navigation**: Pill-shaped horizontal tabs (`general`, `integrations`, `health`, `api-tester`, `seeds`, `advanced`).
- **Save Action Footer**: Sticky or bottom-placed button group to "Reload From Server" and "Save Settings" (only visible on relevant tabs).

## Core Features

### 1. General Tab (`GeneralTab`)
- Form inputs for standard configuration settings dynamically loaded from the backend (grouped).

### 2. Integrations Tab (`IntegrationsTab`)
- Manages API keys and third-party connection strings.
- **Security Features**: Supports masked credentials (e.g., `sk-****1234`). Includes a toggle to temporarily unmask or replace encrypted values.

### 3. Health & Diagnostics Tab (`HealthTab`)
- Fetches from `/monitoring/health`.
- Shows a diagnostic report of the application's dependencies (e.g., database connectivity, cache status).

### 4. API Tester Tab (`ApiTesterPanel`)
- A mini Postman-like interface to ping endpoints and test integrations directly from the UI.

### 5. Database Seeds Tab (`SeedsTab`)
- Lists available database seeders.
- Button to trigger specific seeders directly (`/settings/seeds/{id}/run`).

### 6. Advanced Tab (`AdvancedTab`)
- **Agent Pause**: Global emergency kill-switch to pause all agent activities.
- **Factory Reset**: Clears system cache, logs, and reloads settings. Prompts for confirmation before executing.
