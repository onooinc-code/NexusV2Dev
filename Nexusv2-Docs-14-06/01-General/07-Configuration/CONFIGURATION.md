# Nexus v2 — Configuration Reference

## 1. Backend Configuration

### 1.1 Required Environment Variables

```env
# ========================
# APPLICATION CORE
# ========================
APP_NAME=Nexus
APP_ENV=local                    # local | staging | production
APP_KEY=base64:...              # Generated: php artisan key:generate
APP_DEBUG=true                  # false in production
APP_URL=http://localhost:8000   # Full public URL

# ========================
# DATABASE
# ========================
DB_CONNECTION=sqlite            # Development default
# For production (MySQL):
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=nexus
# DB_USERNAME=nexus_user
# DB_PASSWORD=secure_password

# ========================
# QUEUE & CACHE
# ========================
QUEUE_CONNECTION=database       # database | redis (recommended)
CACHE_STORE=database            # database | redis (recommended)
SESSION_DRIVER=database

# ========================
# REDIS (Optional but recommended)
# ========================
REDIS_CLIENT=predis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# ========================
# WEBSOCKET (Laravel Reverb)
# ========================
REVERB_APP_ID=nexus
REVERB_APP_KEY=local
REVERB_APP_SECRET=your-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=6001
REVERB_SCHEME=https             # https in production

# Frontend also needs these (VITE_ prefix for dev):
VITE_REVERB_APP_KEY=local
VITE_REVERB_HOST=127.0.0.1
VITE_REVERB_PORT=6001
VITE_REVERB_SCHEME=https

# ========================
# EMAIL
# ========================
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS=hello@nexus.app
MAIL_FROM_NAME=Nexus

# ========================
# WAHA (WhatsApp)
# ========================
WAHA_BASE_URL=http://localhost:3000
WAHA_SESSION=default
WAHA_API_KEY=your-waha-api-key
WAHA_WEBHOOK_SECRET=your-webhook-secret

# ========================
# LOGGING
# ========================
LOG_CHANNEL=stack
LOG_LEVEL=debug                 # error in production
```

---

### 1.2 AI Provider Configuration (via SettingsHub / Database)

AI providers are configured through the SettingsHub UI or directly in the `settings` table. They are NOT stored in `.env` for security flexibility (multiple providers, key rotation).

**Settings keys for AI:**
```
ai.default_model          → Default model name (e.g., "gpt-4o-mini")
ai.default_provider       → Default provider ID (UUID)
ai.max_tokens_per_request → Token safety limit
ai.cost_budget_monthly    → Monthly USD budget cap
```

---

### 1.3 Queue Configuration Details

Nexus uses 4 named queues with different priorities:

| Queue | Priority | Used For | Timeout |
|-------|---------|---------|---------|
| `llm-inference` | Highest | AI model calls | 600s |
| `messages` | High | Message processing | 120s |
| `memory` | Medium | Memory extraction | 300s |
| `default` | Normal | General jobs | 90s |

**Running all queues:**
```bash
php artisan queue:listen --queue=llm-inference,messages,memory,default
```

---

## 2. Frontend Configuration

### 2.1 Environment Variables

```env
# .env.local (not committed to git)
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_REVERB_HOST=localhost
NEXT_PUBLIC_REVERB_PORT=6001
NEXT_PUBLIC_REVERB_SCHEME=http
NEXT_PUBLIC_APP_NAME=Nexus

# Feature flags (optional)
NEXT_PUBLIC_ENABLE_ADMIN=true
NEXT_PUBLIC_ENABLE_PEOPLECONNECT=true
NEXT_PUBLIC_ENABLE_HEDRASOUL=true
```

### 2.2 next.config.ts Key Settings

```typescript
// next.config.ts highlights:
// - Standalone output mode (for Docker/server deployment)
// - Environment variable passing
// - API proxy configuration (optional)
```

---

## 3. Production Checklist

### Backend
- [ ] Set `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Configure MySQL (not SQLite)
- [ ] Set `QUEUE_CONNECTION=redis` and `CACHE_STORE=redis`
- [ ] Set `REVERB_SCHEME=https`
- [ ] Configure SMTP mail
- [ ] Set strong `APP_KEY` and `REVERB_APP_SECRET`
- [ ] Set `LOG_LEVEL=error`
- [ ] Run `php artisan config:cache`
- [ ] Run `php artisan route:cache`
- [ ] Run `php artisan view:cache`
- [ ] Set up queue worker as a system service (Supervisor)
- [ ] Set up Reverb as a system service

### Frontend
- [ ] Set `NEXT_PUBLIC_API_URL` to production API URL
- [ ] Set `NEXT_PUBLIC_REVERB_SCHEME=https`
- [ ] Run `npm run build`
- [ ] Serve via Node.js (`npm start`) or static hosting

---

## 4. Supervisor Configuration (Production)

For running queue workers and Reverb as persistent services:

```ini
; /etc/supervisor/conf.d/nexus-queue.conf
[program:nexus-queue-llm]
command=php /var/www/nexus/artisan queue:work --queue=llm-inference --timeout=600 --tries=3
directory=/var/www/nexus
user=www-data
numprocs=2
autostart=true
autorestart=true

[program:nexus-queue-default]
command=php /var/www/nexus/artisan queue:work --queue=messages,memory,default --timeout=120
directory=/var/www/nexus
user=www-data
numprocs=4
autostart=true
autorestart=true

[program:nexus-reverb]
command=php /var/www/nexus/artisan reverb:start
directory=/var/www/nexus
user=www-data
autostart=true
autorestart=true

[program:nexus-scheduler]
command=php /var/www/nexus/artisan schedule:work
directory=/var/www/nexus
user=www-data
autostart=true
autorestart=true
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
