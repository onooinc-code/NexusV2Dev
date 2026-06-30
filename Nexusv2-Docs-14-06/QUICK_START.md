# 🚀 NexusV2 — Quick Start Guide

> **Version:** 2.0.0 · **Date:** 2026-06-19 · **Status:** Production Ready

---

## ⚡ الخطوة الأولى — التشغيل السريع

### 📌 الخيار الأسهل (One-Click)

```batch
Double-click: StartNexus\quick-start.bat
```

هذا سيقوم بـ:

1. ✅ التحقق من التثبيت الأول
2. ✅ تشغيل setup (إن لزم)
3. ✅ بدء جميع الخدمات مع Redis

**ستصل إلى:**

- 🌐 Frontend: http://localhost:3000
- 🔌 API: http://localhost:8000
- ⚡ Vite: http://localhost:5173
- 🔄 WebSocket: ws://localhost:6001
- 🗄️ Redis: redis://localhost:6379

---

## 📁 StartNexus Scripts Overview

جميع الـ scripts موجودة في مجلد `StartNexus/`:

### 1. 📦 **setup.bat** — الإعداد الكامل (في المرة الأولى)

```batch
Purpose: Initial project setup
Does:
  - Checks Node.js, PHP, Composer, Docker
  - Installs all dependencies
  - Creates .env files
  - Starts Redis
```

### 2. 🚀 **quick-start.bat** — البدء السريع (التوصية)

```batch
Purpose: One-click start with Redis
Does:
  - Runs setup if needed
  - Starts all services
  - Uses Redis for cache/queue
```

### 3. 🎯 **start-with-redis.bat** — البدء مع Redis

```batch
Purpose: Start all services with Redis queue
Services:
  - Laravel API (8000)
  - Reverb WebSocket (6001)
  - Vite Dev (5173)
  - Queue Worker (Redis)
  - Next.js (3000)
```

### 4. ⚙️ **start-all.bat** — بدء جميع الخدمات (بدون Redis)

```batch
Purpose: Start services without Redis queue
Note: Uses sync queue driver
```

### 5. 🔧 **install-all.bat** — تثبيت المتطلبات

```batch
Purpose: Install npm & composer dependencies
When: After pulling new changes
Command: npm install, composer install
```

### 6. 🏗️ **build-all.bat** — بناء الـ Frontend

```batch
Purpose: Build frontend for production
Output: Nexus-Frontend/.next/
```

### 7. 🖥️ **start-backend-only.bat** — Backend فقط

```batch
Purpose: Start backend services only
Use: When developing backend independently
```

### 8. 🌐 **start-frontend-only.bat** — Frontend فقط

```batch
Purpose: Start frontend only
Requires: Backend running elsewhere
```

### 9. ✅ **check-requirements.bat** — فحص المتطلبات

```batch
Purpose: Verify all required tools installed
Checks:
  - Node.js
  - npm
  - PHP
  - Composer
  - Git
```

### 10. 🔴 **check-redis.bat** — فحص Redis

```batch
Purpose: Check and manage Redis
Does:
  - Verifies Redis container running
  - Starts if not running
  - Shows Redis info
```

### 11. 🗑️ **clean-all.bat** — تنظيف المشروع

```batch
Purpose: Remove all node_modules and build files
Use: When facing issues or resetting project
Warning: Cannot be undone
```

---

## 🐳 متطلبات النظام

### إلزامي:

- ✅ **Node.js** v18+ → https://nodejs.org/
- ✅ **PHP** v8.2+ → https://www.xampp.org/ أو standalone
- ✅ **Composer** → https://getcomposer.org/
- ✅ **Docker Desktop** → https://www.docker.com/products/docker-desktop/
- ✅ **Git** (موصى به)

### اختياري:

- MySQL Server (أو SQLite)
- Redis Client Tools

---

## 🔧 الإعدادات المرئية

### المنافذ المستخدمة:

```
3000   → Next.js Frontend
8000   → Laravel API
5173   → Vite Dev Server
6001   → Reverb WebSocket
6379   → Redis
```

### ملفات الإعدادات:

```
Nexus-backend/.env
  CACHE_STORE=redis
  SESSION_DRIVER=redis
  QUEUE_CONNECTION=redis
  REDIS_HOST=127.0.0.1
  REDIS_PORT=6379
```

---

## 📊 الخدمات التي ستبدأ

| الخدمة       | المنفذ | الحالة          |
| ------------ | ------ | --------------- |
| Laravel API  | 8000   | ✅ Backend      |
| Reverb       | 6001   | 🔄 Real-time    |
| Vite Dev     | 5173   | ⚡ Frontend Dev |
| Queue Worker | —      | 📦 Redis-based  |
| Next.js      | 3000   | 🌐 Frontend     |
| Redis        | 6379   | 🗄️ Cache/Queue  |

---

## ⚡ الأداء المتوقع

| العنصر        | قبل   | بعد    | التحسن       |
| ------------- | ----- | ------ | ------------ |
| Cache Speed   | 50ms  | 1ms    | 50x أسرع ⚡  |
| Queue         | متوقف | مستمر  | ✅           |
| Session Speed | 30ms  | 1ms    | 30x أسرع ⚡  |
| Load Time     | 3-5s  | 1.5-2s | 2-3x أسرع ⚡ |

---

## 🚨 استكشاف الأخطاء

### مشكلة: "Node.js is not installed"

```
الحل: تثبيت Node.js من https://nodejs.org/
     إعادة تشغيل cmd/PowerShell
```

### مشكلة: "PHP is not installed"

```
الحل: 1. تثبيت XAMPP
     2. إضافة PHP إلى PATH
     أو استخدام standalone PHP
```

### مشكلة: "Redis is not running"

```
الحل: docker run -d -p 6379:6379 --name redis-nexus redis:latest
     أو: Double-click check-redis.bat
```

### مشكلة: "Port already in use"

```
الحل: تغيير المنفذ في .env
     أو إيقاف التطبيق الآخر المستخدم للمنفذ
```

---

## 📝 الخطوات التفصيلية (المرة الأولى)

### 1️⃣ استنساخ المشروع

```bash
git clone https://github.com/onooinc-code/NexusV2Dev.git
cd NexusV2
```

### 2️⃣ فحص المتطلبات

```batch
Double-click: StartNexus\check-requirements.bat
```

### 3️⃣ الإعداد الأول

```batch
Double-click: StartNexus\setup.bat
```

سينتظر ~3-5 دقائق لتثبيت كل المتطلبات

### 4️⃣ البدء

```batch
Double-click: StartNexus\quick-start.bat
```

سترى:

```
[VITE] ready in 769 ms
[REVERB] INFO Starting server on 0.0.0.0:6001
[API] INFO Server running on http://127.0.0.1:8000
[NEXT] ✓ Ready in 6.1s
```

### 5️⃣ الوصول للتطبيق

اذهب إلى: http://localhost:3000

---

## 🎯 استخدام شائع

### تطوير Frontend فقط:

```batch
Double-click: StartNexus\start-frontend-only.bat
```

### تطوير Backend فقط:

```batch
Double-click: StartNexus\start-backend-only.bat
```

### إضافة packages جديدة:

```bash
# Backend
cd Nexus-backend && npm install package-name

# Frontend
cd Nexus-Frontend && npm install package-name
```

### بناء للـ Production:

```batch
Double-click: StartNexus\build-all.bat
```

---

## 📚 وثائق إضافية

- [Redis Configuration](./REDIS_CONFIGURATION.md)
- [Backend Setup](../README_BACKEND.md)
- [Frontend Setup](../README_FRONTEND.md)
- [Architecture Overview](./01-General/02-Architecture/ARCHITECTURE.md)

---

## ✅ Checklist قبل البدء

- [ ] تثبيت Node.js
- [ ] تثبيت PHP
- [ ] تثبيت Composer
- [ ] تثبيت Docker Desktop
- [ ] Redis يعمل (`docker ps`)
- [ ] لا توجد تطبيقات تستخدم المنافذ 3000, 8000, 5173, 6001, 6379

---

**جاهز؟ ابدأ الآن: `Double-click StartNexus\quick-start.bat` 🚀**

---

Generated: June 19, 2026
Version: 2.0.0
Status: ✅ Production Ready
