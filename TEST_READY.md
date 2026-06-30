# E2E Test Suite Ready

## Test Runner
- Command: `npm run test:e2e` (using Cypress/Playwright as defined in TEST_INFRA.md)
- Expected: all tests pass with exit code 0

## Coverage Summary
| Tier | Count | Description |
|------|------:|-------------|
| 1. Feature Coverage | 60 | ≥5 tests per feature (12 features) covering equivalence classes |
| 2. Boundary & Corner | 60 | ≥5 tests per feature covering edges, empty states, limits |
| 3. Cross-Feature | 12 | Pairwise combinations of interacting features |
| 4. Real-World Application | 6 | Holistic system usage scenarios |
| **Total** | **138** | |

## Feature Checklist
| Feature | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---------|:------:|:------:|:------:|:------:|
| F1: General Settings - View | 5 | 5 | ✓ | ✓ |
| F2: General Settings - Edit | 5 | 5 | ✓ | ✓ |
| F3: General Settings - Save/Reload | 5 | 5 | ✓ | ✓ |
| F4: Integration Settings - View/Mask | 5 | 5 | ✓ | ✓ |
| F5: Integration Settings - Edit | 5 | 5 | ✓ | ✓ |
| F6: Health & Diagnostics | 5 | 5 | ✓ | ✓ |
| F7: API Tester - Configure/Send | 5 | 5 | ✓ | ✓ |
| F8: API Tester - Response/Error | 5 | 5 | ✓ | ✓ |
| F9: Database Seeds | 5 | 5 | ✓ | ✓ |
| F10: Advanced - Agent Pause | 5 | 5 | ✓ | ✓ |
| F11: Advanced - Clear Cache | 5 | 5 | ✓ | ✓ |
| F12: Navigation & Layout | 5 | 5 | ✓ | ✓ |

## Test Case Designs

### Tier 1: Feature Coverage
**F1: General Settings - View**
- T1.1.1: Verify general tab loads and displays settings grouped by category cards.
- T1.1.2: Verify loading state shows placeholder correctly.
- T1.1.3: Verify empty state displays "No settings are available" when backend returns empty.
- T1.1.4: Verify all setting types (boolean, string, integer, json) render the correct UI control.
- T1.1.5: Verify integrations and security groups are explicitly excluded from the General tab.

**F2: General Settings - Edit**
- T1.2.1: Verify changing a string setting updates local state without auto-saving.
- T1.2.2: Verify toggling a boolean switch updates local state immediately.
- T1.2.3: Verify editing a json/text textarea updates local state properly.
- T1.2.4: Verify modifying an integer input accepts numerical changes to local state.
- T1.2.5: Verify editing multiple settings across different groups tracks all changes.

**F3: General Settings - Save/Reload**
- T1.3.1: Verify clicking "Save Settings" sends bulk PUT request with modified values.
- T1.3.2: Verify success banner appears upon successful save.
- T1.3.3: Verify error message is shown if the bulk save request fails.
- T1.3.4: Verify clicking "Reload From Server" restores original values.
- T1.3.5: Verify "Reload From Server" discards all local unsaved edits.

**F4: Integration Settings - View/Mask**
- T1.4.1: Verify Integrations tab loads settings from the 'integrations' group.
- T1.4.2: Verify empty state shows "No integrations available".
- T1.4.3: Verify encrypted settings display the shield icon and a "Show/Hide" toggle.
- T1.4.4: Verify clicking "Show" successfully fetches and displays the masked value (e.g., sk-***).
- T1.4.5: Verify non-encrypted integrations render standard inputs without the shield.

**F5: Integration Settings - Edit**
- T1.5.1: Verify clicking "Edit" on an encrypted setting reveals a password input.
- T1.5.2: Verify typing a new value in the password input updates local state.
- T1.5.3: Verify clicking "Cancel Edit" hides input and restores original shielded view.
- T1.5.4: Verify saving an edited integration correctly sends it via PUT /settings/bulk.
- T1.5.5: Verify success/error states function properly on Integration save.

**F6: Health & Diagnostics**
- T1.6.1: Verify Health tab fetches GET /monitoring/health on open.
- T1.6.2: Verify system status card displays heading, timestamp, and correct color banner.
- T1.6.3: Verify service sub-checks render individual cards with OK/ERROR and JSON details.
- T1.6.4: Verify "Refresh Health Status" button triggers a new fetch and UI update.
- T1.6.5: Verify fallback UI shows "No health data available" on network failure.

**F7: API Tester - Configure/Send**
- T1.7.1: Verify split-panel UI loads correctly with default GET method.
- T1.7.2: Verify URL field accepts valid input and Enter key submits request.
- T1.7.3: Verify adding, editing, and deleting header key-value pairs works.
- T1.7.4: Verify body textarea accepts valid JSON input.
- T1.7.5: Verify clicking "Send" calls POST /settings/system/api-proxy with configured payload.

**F8: API Tester - Response/Error**
- T1.8.1: Verify response panel displays HTTP status code with correct color (2xx green, etc.).
- T1.8.2: Verify response panel correctly renders JSON body and latency.
- T1.8.3: Verify copy to clipboard button successfully copies the response.
- T1.8.4: Verify failure to connect to proxy displays a styled error panel.
- T1.8.5: Verify warning is shown when entering a body on a GET/DELETE request.

**F9: Database Seeds**
- T1.9.1: Verify Seeds tab automatically fetches and lists available seeders.
- T1.9.2: Verify the danger warning banner is permanently visible.
- T1.9.3: Verify seeder cards display name, description, and "Creates" metadata.
- T1.9.4: Verify clicking "Run Seeder" prompts a browser confirmation dialog.
- T1.9.5: Verify accepting the confirmation executes the seeder and shows success message.

**F10: Advanced - Agent Pause**
- T1.10.1: Verify Advanced tab displays the red "Danger Zone" banner.
- T1.10.2: Verify "Global Agent Pause" card accurately shows current running/paused status.
- T1.10.3: Verify toggling state correctly sends POST /settings/system/agent-pause.
- T1.10.4: Verify button text and status color switch dynamically based on the active state.
- T1.10.5: Verify closing and reopening the tab retains the correct agent pause state.

**F11: Advanced - Clear Cache**
- T1.11.1: Verify the "Clear Cache" card is displayed in the advanced tab.
- T1.11.2: Verify clicking "Reset Cache" triggers a confirmation dialog.
- T1.11.3: Verify canceling the dialog aborts the cache reset.
- T1.11.4: Verify confirming cache reset calls POST /logs/clear.
- T1.11.5: Verify after clearing, settings are automatically reloaded and a success message appears.

**F12: Navigation & Layout**
- T1.12.1: Verify the page is rendered under AppLayout with "Settings & Administration" title.
- T1.12.2: Verify all 6 tabs are present and clickable.
- T1.12.3: Verify switching to a tab renders its specific sub-component and sets it active.
- T1.12.4: Verify "Save Settings" button is explicitly hidden on non-general/integration tabs.
- T1.12.5: Verify mobile responsiveness adjusts tab layouts without horizontal scrolling.

### Tier 2: Boundary & Corner Cases
**F1: General Settings - View**
- T2.1.1: Very large number of settings (100+) renders properly (virtualization/scroll).
- T2.1.2: Empty group name or missing descriptions handled gracefully.
- T2.1.3: Malformed JSON type setting renders without crashing the view.
- T2.1.4: Extreme string length in setting keys or values.
- T2.1.5: Server times out while loading settings.

**F2: General Settings - Edit**
- T2.2.1: Invalid JSON syntax entered into JSON textarea (should not break UI).
- T2.2.2: Extremely large integer input exceeding Number.MAX_SAFE_INTEGER.
- T2.2.3: Entering HTML/JS tags in string inputs (XSS prevention check).
- T2.2.4: Rapid consecutive toggling of boolean switches.
- T2.2.5: Removing all text from a required setting input.

**F3: General Settings - Save/Reload**
- T2.3.1: Clicking Save while a save request is already in flight.
- T2.3.2: 500 Internal Server error returned during save.
- T2.3.3: Reloading from server while offline.
- T2.3.4: Partial failure (e.g., some settings save, others fail due to validation).
- T2.3.5: Modifying settings, then navigating away without saving (unsaved changes warning).

**F4: Integration Settings - View/Mask**
- T2.4.1: Masked value endpoint returns 403 Forbidden.
- T2.4.2: Clicking "Show" multiple times rapidly.
- T2.4.3: Integration setting with missing metadata properties.
- T2.4.4: Corrupted encrypted payload rendering.
- T2.4.5: Masked value endpoint timeout handling.

**F5: Integration Settings - Edit**
- T2.5.1: Editing to an empty password and saving.
- T2.5.2: Canceling edit after entering extensive text.
- T2.5.3: Pasting >10,000 characters into the integration password field.
- T2.5.4: Concurrent editing of multiple integration keys.
- T2.5.5: Saving when API key validation fails on the backend.

**F6: Health & Diagnostics**
- T2.6.1: Health endpoint returns completely malformed response.
- T2.6.2: One sub-check returns massive JSON output.
- T2.6.3: Rapid clicking of the Refresh button.
- T2.6.4: All sub-checks fail simultaneously (system offline scenario).
- T2.6.5: Health check takes >30 seconds (timeout simulation).

**F7: API Tester - Configure/Send**
- T2.7.1: Extremely long URL input (>2000 chars).
- T2.7.2: Empty URL submission on Send.
- T2.7.3: 100+ Header pairs added.
- T2.7.4: Sending a request with a 10MB JSON body.
- T2.7.5: Using special/unicode characters in header keys.

**F8: API Tester - Response/Error**
- T2.8.1: Proxy endpoint returns 502 Bad Gateway.
- T2.8.2: Response body is non-JSON binary data or HTML.
- T2.8.3: Request times out.
- T2.8.4: Proxy endpoint returns a completely empty response.
- T2.8.5: Response contains deeply nested JSON.

**F9: Database Seeds**
- T2.9.1: 50+ seeders returned from backend.
- T2.9.2: Seeder execution takes >1 minute (timeout handling).
- T2.9.3: Running seeder results in a constraint violation error.
- T2.9.4: Clicking run, canceling dialog, and re-running rapidly.
- T2.9.5: Zero seeders available condition explicitly verified.

**F10: Advanced - Agent Pause**
- T2.10.1: Toggling agent pause while another agent pause request is pending.
- T2.10.2: Backend returns 401 Unauthorized for pause operation.
- T2.10.3: Providing an extremely long reason string for agent pause.
- T2.10.4: Server state desync (frontend thinks paused, backend is running).
- T2.10.5: Network disconnect during pause toggle request.

**F11: Advanced - Clear Cache**
- T2.11.1: Clear cache request hangs indefinitely.
- T2.11.2: Backend returns error stating cache is locked.
- T2.11.3: User clicks reset, then quickly navigates to another tab before completion.
- T2.11.4: Reloading settings part of cache clear fails after logs clear succeeds.
- T2.11.5: Rapid double-click on Reset Cache button.

**F12: Navigation & Layout**
- T2.12.1: Viewport width 320px (extreme narrow mobile).
- T2.12.2: High contrast mode or dark mode (visual regression).
- T2.12.3: Clicking a tab while its data is still loading.
- T2.12.4: Attempting to access non-existent tab via URL parameter (if routing supports it).
- T2.12.5: Browser zoom set to 200%.

### Tier 3: Cross-Feature Interactions
1. F1 & F12: Navigate between General and Integrations tabs repeatedly, verify data doesn't bleed.
2. F2 & F3: Edit settings in General, navigate to Integrations without saving, verify unsaved state/behavior.
3. F7 & F8: Send invalid proxy requests and ensure error states clear upon next valid request.
4. F10 & F6: Pause agents (F10), then navigate to Health (F6) and verify health check reflects paused status or continues working.
5. F11 & F1: Clear cache (F11), which forces a settings reload, and verify General tab (F1) immediately reflects updated defaults.
6. F5 & F3: Edit integration setting, click save, verify the bulk save mechanism handles both General and Integration edits if supported.
7. F9 & F6: Run a massive seeder (F9) and simultaneously check Health (F6) for load latency.
8. F7 & F10: Use API Tester (F7) to manually query the agent status endpoint while paused via UI (F10).
9. F4 & F5: Show masked value (F4), enter edit mode (F5), cancel edit, verify it correctly reverts to masked state.
10. F12 & F3: Verify "Save Settings" visibility triggers instantly when switching from Health back to General.
11. F1 & F2: Verify editing a JSON text area resizes layout without breaking card containers.
12. F10 & F11: Pause agents, then clear cache. Ensure system recovers in a paused state if expected by backend design.

### Tier 4: Real-World Scenarios
1. **First-time System Setup**: Admin logs in, opens General Settings, sets base URLs, updates third-party API keys in Integrations, saves everything, and checks the Health tab to ensure services are green.
2. **Integration Troubleshooting & Verification**: Admin sees a failing service in Health. Navigates to Integrations, checks API key. Uses API Tester to manually ping the external service through the proxy to debug auth errors. Updates API key and saves.
3. **System Outage Diagnostic Flow**: Admin observes red Health check. Pauses agents via Advanced tab to prevent data loss. Clears Cache to attempt state reset. Refreshes Health tab to monitor recovery, then resumes agents.
4. **Developer Environment Bootstrapping**: Dev clears cache, runs the 'Demo Workflow' Database Seeder. Uses the API tester to immediately invoke the newly seeded workflow via an HTTP trigger.
5. **Security Audit of Credentials**: Auditor navigates to Integrations, iterates through all encrypted settings viewing the masked values, attempts an edit but cancels, verifying that raw passwords are never unintentionally exposed in UI.
6. **Comprehensive Admin Maintenance Routine**: Admin checks Health (green), pauses agents (maintenance window), runs a migration/data seeder, clears the system cache, and resumes agents. Finally, they verify the system is back online via the API tester.
