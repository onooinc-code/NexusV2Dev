# NotificationsHub, SchedulerHub, SettingsHub, LogsHub & ProactiveAIHub

---

# NotificationsHub

## Overview
NotificationsHub manages multi-channel notification delivery: email, SMS (Twilio), WhatsApp (WAHA), and push notifications. Templates with variable substitution allow reusable message formats.

## Backend

### API Endpoints
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/notification-templates` | `NotificationController@indexTemplates` | List templates |
| POST | `/api/notification-templates` | `NotificationController@storeTemplate` | Create template |
| PUT | `/api/notification-templates/{id}` | Update template |
| DELETE | `/api/notification-templates/{id}` | Delete template |
| GET | `/api/notification-logs` | `NotificationController@indexLogs` | Delivery log |
| POST | `/api/notifications/send` | `NotificationController@send` | Send notification |
| POST | `/api/notification-logs/{id}/retry` | Retry failed notification |

### NotificationService
```php
$service->send([
  'contact_id'  => $contactId,
  'template_id' => $templateId,
  'channel'     => 'email',  // or 'sms', 'whatsapp', 'push'
  'variables'   => ['name' => 'John', 'meeting_time' => '2pm'],
]);
// → Resolves template → replaces variables → dispatches via channel driver
```

### Template Variable Substitution
```
Template: "Hello {{contact.name}}, your appointment is at {{meeting_time}}."
Variables: { contact: {...}, meeting_time: "2pm" }
Output: "Hello John, your appointment is at 2pm."
```

### Notification Channels
| Channel | Driver | Config |
|---------|--------|--------|
| Email | Laravel Mail (SMTP) | MAIL_* env vars |
| SMS | Twilio | TWILIO_* env vars |
| WhatsApp | WAHA API | WAHA_* env vars |
| Push | Laravel Notifications | FCM/APNS config |

## Frontend
**Page:** `app/notifications/page.tsx`
- Template library with CRUD
- Send notification form (select contact, template, channel)
- Delivery log with status, retry button
- Channel health indicators

---

# SchedulerHub

## Overview
SchedulerHub manages time-based automation via `SchedulerJob` definitions. Each job has a cron expression and runs via the `SchedulerWorker` artisan command.

## Backend

### API Endpoints
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/scheduler/jobs` | `SchedulerController@index` | List scheduled jobs |
| POST | `/api/scheduler/jobs` | `SchedulerController@store` | Create job |
| PUT | `/api/scheduler/jobs/{id}` | Update job |
| DELETE | `/api/scheduler/jobs/{id}` | Delete job |
| POST | `/api/scheduler/jobs/{id}/trigger` | Manual trigger |
| GET | `/api/scheduler/jobs/{id}/runs` | Execution history |

### SchedulerJob Model
```php
// Key fields:
// name         - Job name
// cron         - Cron expression ("0 9 * * 1-5")
// job_class    - Laravel job class to dispatch
// payload      - JSON parameters for the job
// is_active    - Enable/disable without deleting
// last_run_at  - Last execution time
// next_run_at  - Calculated next execution
// timezone     - Job timezone
```

### SchedulerWorker Command
```bash
php artisan scheduler:work
# Polls every minute
# Checks all active SchedulerJobs
# If due → dispatch the job_class with payload
```

## Frontend
**Page:** `app/scheduler/page.tsx`
- Scheduler job list with next/last run times
- Cron expression builder UI
- Countdown to next run (`useSchedulerCountdowns` hook)
- Manual trigger button
- Execution history log

---

# SettingsHub

## Overview
SettingsHub manages all system settings stored in the `settings` table. Settings are grouped by category, support data type casting, and sensitive ones are encrypted.

## Backend

### Key Endpoints
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/settings` | `SettingController@index` | All settings grouped |
| GET | `/api/settings/{key}` | `SettingController@show` | Single setting |
| PUT | `/api/settings/{key}` | `SettingController@update` | Update setting |
| POST | `/api/settings/batch` | Bulk update |
| GET | `/api/admin/settings` | `SettingsHubAdminController` | Admin settings view |

### Setting Model
```php
// Key structure: "category.subcategory.key"
// Examples:
// "ai.default_model" → "gpt-4o"
// "notifications.email.enabled" → true
// "notifications.whatsapp.waha_url" → "http://..." (encrypted)
// "system.timezone" → "UTC"
```

### SettingCacheService
```php
// Settings are Redis-cached for performance
// Cache invalidated on any setting update
$value = $cacheService->get('ai.default_model');
$cacheService->set('ai.default_model', 'gpt-4o');
$cacheService->flush(); // Clear all settings cache
```

## Frontend
**Page:** `app/settings/page.tsx`
- Settings organized in tabs by category
- Inline editing with auto-save
- Sensitive fields masked (show/hide toggle)
- AI provider configuration (links to AIModelsHub)

---

# LogsHub

## Overview
LogsHub provides a structured log viewer for the Nexus application. Displays application events, agent logs, system events, task logs, and security events.

## Backend

### API Endpoints
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/logs` | `LogController@index` | Application logs |
| GET | `/api/logs/{id}` | `LogController@show` | Log details |
| DELETE | `/api/logs` | `LogController@clear` | Clear logs |

### Log Model
```php
// Log channels: 'application', 'agent', 'system', 'task', 'security', 'ai'
// Log levels: 'debug', 'info', 'warning', 'error', 'critical'
// Context: JSON with relevant data
```

## Frontend
**Page:** `app/logs/page.tsx`
- Real-time log streaming
- Filter by channel, level, date range, search query
- Log entry details modal
- Color-coded by severity level
- Export log to CSV

---

# ProactiveAIHub

## Overview
ProactiveAIHub enables Nexus to take autonomous action without user prompting. ECA (Event-Condition-Action) rules define when to automatically notify, update, or take action based on system events and conditions.

## Backend

### API Endpoints
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/proactive/triggers` | `ProactiveAIController@index` | List triggers |
| POST | `/api/proactive/triggers` | `ProactiveAIController@store` | Create trigger |
| PUT | `/api/proactive/triggers/{id}` | Update trigger |
| DELETE | `/api/proactive/triggers/{id}` | Delete trigger |
| POST | `/api/proactive/triggers/{id}/test` | Test trigger |

### ProactiveTrigger Model
```php
// trigger_type: 'event' | 'schedule' | 'threshold' | 'pattern'
// event_name: 'contact.inactive' | 'memory.updated' | ...
// conditions: JSON rules that must match
// actions: Array of actions to execute
// is_active: Enable/disable
```

### ProactiveAIController Service Layer
```
Event fires → ProactiveSchedulerCommand evaluates
  → Find matching ProactiveTriggers
  → Evaluate conditions against current data
  → Execute action: send_notification | create_task | update_contact | execute_agent
```

## Frontend
**Page:** `app/proactive-ai/page.tsx`
- Trigger list with enable/disable toggle
- Create trigger wizard (select event → configure condition → define action)
- Trigger test panel
- Recent trigger execution log

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
