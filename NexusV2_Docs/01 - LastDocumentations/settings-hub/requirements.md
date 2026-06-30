# Settings Hub — Requirements

## Introduction

SettingsHub is the system configuration and administration interface for Nexus. It provides a centralized place to manage backend settings grouped by category, view and edit third-party integration credentials, monitor system health, test API endpoints, run database seeders, and perform advanced operations such as emergency agent pause and cache clearing.

## Glossary

| Term | Definition |
|------|-----------|
| Setting | A key-value configuration entry stored in the backend settings registry with a type (string, integer, boolean, json, text) |
| Setting Group | A logical grouping of settings (e.g., "general", "integrations", "security") |
| Encrypted Setting | A setting whose value is stored encrypted; its masked value can be retrieved separately |
| Health Status | The aggregated system check result from GET `/monitoring/health`, including per-service sub-checks |
| Seeder | A backend class that populates the database with test data or workflow templates |
| Agent Pause | An emergency global control to halt all agent executions system-wide |
| Factory Reset (Clear Cache) | Clearing all application logs and reloading settings from the backend |

---

## Requirement 1: General Settings

**User Story:** As an administrator, I want to view and edit all application settings grouped by category, so that I can configure the system behavior from a single interface.

### Acceptance Criteria

1. WHEN the user opens SettingsHub and the General tab is active, THE system SHALL call GET `/settings/grouped` and display settings organized by group in cards.
2. WHILE settings are loading, THE system SHALL display a loading placeholder message.
3. WHEN no settings are returned, THE system SHALL display a message "No settings are available. Please verify backend configuration."
4. EACH setting group SHALL be rendered as a card showing: group name (uppercase), description "Configuration Group," and a count of keys.
5. EACH setting entry SHALL display: key name, description (if present), type badge (uppercase), and an appropriate input control based on type.
6. THE type-to-control mapping SHALL be: boolean → `NxSwitch`, integer → `NxInput[type=number]`, json/text → scrollable textarea, string → `NxInput`.
7. THE General tab SHALL exclude settings in the `integrations` and `security` groups (those are shown in Integrations tab).
8. WHEN the user modifies any setting value, THE change SHALL be tracked in the local `editedValues` state.
9. WHEN the user clicks "Save Settings," THE system SHALL call PUT `/settings/bulk` with all current edited values and display a success message.
10. WHEN the save fails, THE system SHALL display an error message with the failure reason.
11. THE user SHALL be able to reload settings from the server via a "Reload From Server" button, discarding any unsaved local changes.

---

## Requirement 2: Integration Settings

**User Story:** As an administrator, I want to manage third-party API credentials securely, with the ability to view masked values and update them when needed.

### Acceptance Criteria

1. WHEN the Integrations tab is active, THE system SHALL display settings from the `integrations` group.
2. WHEN no integration settings exist, THE system SHALL display a message "No integrations available."
3. EACH encrypted setting SHALL display a shield icon to indicate it is encrypted.
4. THE user SHALL be able to toggle visibility of a masked credential value via an "Show/Hide" button, which calls GET `/settings/{key}/masked`.
5. WHEN the masked value is loaded, THE system SHALL display the masked string (e.g., `sk-...***`) next to the "Hide" button.
6. THE user SHALL be able to edit an encrypted credential via an "Edit" button that reveals a password input field.
7. WHEN the user clicks "Cancel Edit," THE input SHALL collapse and the original value SHALL be restored.
8. Non-encrypted integration settings SHALL render the same controls as General settings.
9. WHEN the user saves changes from the Integrations tab, THE same PUT `/settings/bulk` endpoint SHALL be used.

---

## Requirement 3: Health & Diagnostics

**User Story:** As an administrator, I want to view the current system health status, so that I can detect and diagnose failing services.

### Acceptance Criteria

1. WHEN the user opens the Health tab, THE system SHALL call GET `/monitoring/health` to load health status.
2. WHILE health is loading, THE system SHALL display a spinner with "Loading health status…".
3. THE header area of the Health tab SHALL include a "Refresh Health Status" button.
4. THE overall system status card SHALL display: "System Status" heading, last-checked timestamp, and a colored status banner (green=healthy, yellow=degraded, red=other).
5. EACH service sub-check SHALL be rendered as a separate card showing: service name, OK/ERROR badge, and the raw JSON of the check result in a code block.
6. WHEN health data is unavailable or the request fails, THE system SHALL display "No health data available."

---

## Requirement 4: API Tester

**User Story:** As an administrator, I want to make HTTP requests to internal or external APIs directly from SettingsHub, so that I can debug integrations without leaving the application.

### Acceptance Criteria

1. THE API Tester tab SHALL display a split-panel layout: request configuration on the left, response on the right.
2. THE request panel SHALL include: HTTP method selector (GET, POST, PUT, PATCH, DELETE), URL input field, Headers tab (list of key-value pairs), and Body tab (raw text/JSON textarea).
3. THE user SHALL be able to add and remove header key-value pairs.
4. THE body textarea SHALL warn when using GET or DELETE methods (body usually ignored).
5. WHEN the user clicks "Send," THE system SHALL call POST `/settings/system/api-proxy` with the method, URL, headers, and body.
6. THE response panel SHALL display: HTTP status code (color-coded: 2xx=green, 3xx=blue, 4xx=yellow, 5xx=red), latency in ms, and the response body formatted as JSON (if applicable).
7. THE user SHALL be able to copy the response body to the clipboard via a copy button that appears on hover.
8. WHEN the request fails (network error or proxy error), THE system SHALL display the error message in a styled error panel.
9. THE URL field SHALL support pressing Enter to send the request.

---

## Requirement 5: Database Seeds

**User Story:** As an administrator, I want to run database seeders to populate test data and workflow templates, so that I can quickly set up development or demo environments.

### Acceptance Criteria

1. WHEN the user opens the Seeds tab, THE system SHALL call GET `/settings/seeds` to load available seeders.
2. WHILE seeds are loading, THE system SHALL display a spinner.
3. A warning banner SHALL be permanently visible stating that seeders populate the database with test data and should be used with caution in production.
4. EACH seeder SHALL be displayed as a card with: seeder name, description, "Creates: {data_count}" metadata, and a "Run Seeder" button.
5. WHEN the user clicks "Run Seeder," THE system SHALL display a browser confirmation dialog before proceeding.
6. IF confirmed, THE system SHALL call POST `/settings/seeds/{id}/run` and display a success message on completion.
7. WHEN no seeders are available, THE system SHALL display "No seeders available."

---

## Requirement 6: Advanced Operations

**User Story:** As an administrator, I want access to emergency controls like global agent pause and cache clearing, so that I can respond to critical system issues.

### Acceptance Criteria

1. THE Advanced tab SHALL display a red "Danger Zone" warning card at the top.
2. THE "Global Agent Pause" card SHALL display: title, description, current pause status (⚠️ PAUSED or ✓ RUNNING), and a toggle button.
3. WHEN the user clicks the toggle button, THE system SHALL call POST `/settings/system/agent-pause` with `{ enabled, reason }` and update the UI to reflect the new state.
4. THE button label SHALL read "Pause Agents" when agents are running and "Resume Agents" when paused.
5. WHEN agent pause is active, THE status text SHALL be styled red.
6. THE "Clear Cache" card SHALL display a description and a "Reset Cache" button.
7. WHEN the user clicks "Reset Cache," THE system SHALL display a browser confirmation dialog.
8. IF confirmed, THE system SHALL call POST `/logs/clear`, then reload settings, and display a success message "System cache cleared and settings refreshed from backend."

---

## Requirement 7: Navigation & Layout

**User Story:** As an administrator, I want a clearly organized tabbed interface for SettingsHub so that I can quickly navigate between configuration areas.

### Acceptance Criteria

1. THE page SHALL render within `AppLayout` with the title "Settings & Administration."
2. THE page SHALL provide six tabs: General, Integrations, Health & Diagnostics, API Tester, Database Seeds, and Advanced.
3. TAB labels SHALL be: "General," "Integrations," "Health & Diagnostics," "API Tester," "Database Seeds," "Advanced."
4. WHEN switching to the Health tab, THE system SHALL automatically trigger a health status load.
5. WHEN switching to the Seeds tab, THE system SHALL automatically trigger a seeds list load.
6. THE Save Settings button SHALL only be visible when the General or Integrations tab is active.
7. SUCCESS and error messages SHALL be displayed as banners below the tab navigation bar.
8. THE page SHALL support responsive layout for mobile screens.
