# 🚀 StartNexus Scripts Documentation

> **Version:** 2.0.0 · **Date:** 2026-06-19

---

## 📍 الموقع

جميع الـ scripts موجودة في مجلد:

```
NexusV2/StartNexus/
```

---

## 📋 قائمة Scripts

### 1. 🎯 **quick-start.bat** ⭐ (الموصى به)

**الوصف:** الطريقة الأسهل للبدء

**ماذا يفعل:**

1. يتحقق من أول تشغيل
2. يشغّل setup إذا لزم
3. يبدأ جميع الخدمات مع Redis

**متى تستخدمه:**

```
الاستخدام اليومي — الأفضل والأسرع
```

**المثال:**

```
Double-click: quick-start.bat
```

**النتيجة:**

```
✅ Laravel API (8000)
✅ Reverb (6001)
✅ Vite (5173)
✅ Queue Worker (Redis)
✅ Next.js (3000)
```

---

### 2. 📦 **setup.bat**

**الوصف:** الإعداد الكامل للمشروع

**ماذا يفعل:**

1. يفحص Node.js, PHP, Composer, Docker
2. ينشئ Redis container
3. يثبّت جميع المتطلبات
4. ينشئ .env files

**متى تستخدمه:**

```
المرة الأولى فقط
بعد حذف node_modules
بعد pull من git
```

**المثال:**

```
Double-click: setup.bat
# انتظر 3-5 دقائق
```

**ما الذي يثبّت:**

- npm install (root)
- composer install (backend)
- npm install (backend)
- npm install (frontend)

---

### 3. 🎯 **start-with-redis.bat**

**الوصف:** بدء الخدمات مع Redis Queue

**ماذا يفعل:**

1. يتحقق من Redis
2. يبدأ Laravel API
3. يبدأ Reverb
4. يبدأ Vite
5. يبدأ Queue Worker
6. يبدأ Next.js

**متى تستخدمه:**

```
عندما تريد الـ production-ready setup
لضمان معالجة الـ background jobs
```

**المثال:**

```
Double-click: start-with-redis.bat
```

**الخدمات المبدأة:**

```
[VITE]    ➜ http://localhost:5173
[REVERB]  ➜ ws://localhost:6001
[API]     ➜ http://127.0.0.1:8000
[QUEUE]   ➜ Redis Queue (pid: 1234)
[NEXT]    ➜ http://localhost:3000
```

---

### 4. ⚙️ **start-all.bat**

**الوصف:** بدء الخدمات بدون Redis Queue

**ماذا يفعل:**

- يبدأ جميع الخدمات
- يستخدم sync queue بدلاً من Redis

**متى تستخدمه:**

```
إذا لم تكن Redis مثبّتة
إذا أردت الـ quick testing
```

**الفرق مع start-with-redis.bat:**

```
start-all.bat          → Sync queue (jobs فوراً)
start-with-redis.bat   → Redis queue (background)
```

---

### 5. 🔧 **start-backend-only.bat**

**الوصف:** بدء backend فقط

**ماذا يفعل:**

- يبدأ Laravel API
- يبدأ Reverb
- يبدأ Vite
- يبدأ Queue Worker
- **لا يبدأ Next.js**

**متى تستخدمه:**

```
تطوير API فقط
تطوير backend features
اختبار الـ APIs
```

**المثال:**

```
Double-click: start-backend-only.bat
# في terminal آخر:
Double-click: start-frontend-only.bat
```

---

### 6. 🌐 **start-frontend-only.bat**

**الوصف:** بدء frontend فقط

**ماذا يفعل:**

- يبدأ Next.js على port 3000
- **لا يبدأ backend**

**متى تستخدمه:**

```
تطوير UI فقط
عندما يعمل backend في مكان آخر
اختبار frontend separately
```

**المثال:**

```
# Terminal 1:
Double-click: start-backend-only.bat

# Terminal 2:
Double-click: start-frontend-only.bat
```

---

### 7. 📥 **install-all.bat**

**الوصف:** تثبيت جميع المتطلبات

**ماذا يفعل:**

```bash
npm install (root)
cd Nexus-backend && composer install
cd Nexus-backend && npm install
cd Nexus-Frontend && npm install
```

**متى تستخدمه:**

```
بعد إضافة packages جديد
بعد pull من git
عندما ترى خطأ "module not found"
```

**المثال:**

```
Double-click: install-all.bat
```

---

### 8. 🏗️ **build-all.bat**

**الوصف:** بناء الـ Frontend للـ Production

**ماذا يفعل:**

- يشغل `npm run build` على frontend
- ينتج `.next` folder

**متى تستخدمه:**

```
قبل deployment
اختبار production build محليّاً
إنشاء optimized build
```

**المثال:**

```
Double-click: build-all.bat
# النتيجة: Nexus-Frontend/.next/
```

---

### 9. ✅ **check-requirements.bat**

**الوصف:** فحص المتطلبات المثبّتة

**ماذا يفعل:**

- يتحقق من Node.js
- يتحقق من npm
- يتحقق من PHP
- يتحقق من Composer
- يتحقق من Git

**متى تستخدمه:**

```
قبل البدء
عند مشاكل التشغيل
للتأكد من البيئة
```

**المثال:**

```
Double-click: check-requirements.bat
```

**النتيجة المتوقعة:**

```
[OK] Node.js found: v18.12.0
[OK] npm found: 8.19.0
[OK] PHP found: PHP 8.2.0
[OK] Composer found: Composer 2.4.0
[OK] Git found: git version 2.35.0
```

---

### 10. 🔴 **check-redis.bat**

**الوصف:** فحص وإدارة Redis

**ماذا يفعل:**

1. يتحقق من Docker
2. يبحث عن Redis container
3. يبدأ Redis إذا توقف
4. يختبر الاتصال
5. يعرض معلومات Redis

**متى تستخدمه:**

```
عند مشاكل Queue
عند مشاكل Cache
للتأكد من Redis يعمل
```

**المثال:**

```
Double-click: check-redis.bat
```

**النتيجة:**

```
[OK] Docker is installed
[OK] Redis container exists
[OK] Redis is running
[INFO] Redis version: 7.0.0
```

---

### 11. 🗑️ **clean-all.bat**

**الوصف:** تنظيف المشروع

**ماذا يفعل:**

- يحذف Root node_modules
- يحذف Backend node_modules
- يحذف Backend vendor
- يحذف Frontend node_modules
- يحذف Frontend .next cache

**⚠️ تحذير:**

```
هذا يحذف ملفات كثيرة
لا يمكن التراجع
استخدم فقط عند الضرورة
```

**متى تستخدمه:**

```
عند مشاكل persistant
عند الحاجة لـ fresh install
عند تغيير packages
```

**المثال:**

```
Double-click: clean-all.bat
# اكتب: yes
# انتظر...
# ثم: setup.bat
```

---

## 📊 خريطة الـ Scripts

```
استخدام يومي:
  quick-start.bat ← START HERE

الإعداد:
  setup.bat (first time only)
  install-all.bat (when needed)
  clean-all.bat (if broken)

الفحص:
  check-requirements.bat
  check-redis.bat

التطوير:
  start-backend-only.bat
  start-frontend-only.bat
  start-all.bat

الـ Build:
  build-all.bat

الوثائق:
  README.txt
  REDIS_GUIDE.txt
  REDIS_SETUP_COMPLETE.txt
```

---

## 🔄 سيناريوهات استخدام شائعة

### سيناريو 1: أول مرة استخدام

```
1. Double-click: setup.bat
2. Wait for completion (~5 min)
3. Double-click: quick-start.bat
4. Go to: http://localhost:3000
```

### سيناريو 2: الاستخدام اليومي

```
1. Double-click: quick-start.bat
2. Development...
3. Ctrl+C to stop
```

### سيناريو 3: Pull جديد من Git

```
1. git pull
2. Double-click: install-all.bat
3. Double-click: quick-start.bat
```

### سيناريو 4: مشاكل أداء

```
1. Ctrl+C (stop all)
2. Double-click: check-redis.bat
3. Double-click: check-requirements.bat
4. Double-click: quick-start.bat
```

### سيناريو 5: مشروع معطوب

```
1. Double-click: clean-all.bat
2. Double-click: setup.bat
3. Double-click: quick-start.bat
```

### سيناريو 6: تطوير منفصل

```
# Terminal 1: Backend فقط
Double-click: start-backend-only.bat

# Terminal 2: Frontend فقط
Double-click: start-frontend-only.bat
```

---

## 🆘 Troubleshooting

### "Redis is not running"

```
دعني: Double-click: check-redis.bat
سيبدأ Redis تلقائياً
```

### "Port already in use"

```
قد تشغل التطبيق مرتين
أو تطبيق آخر يستخدم المنفذ
```

### "node_modules not found"

```
اشغل: Double-click: install-all.bat
```

### "PHP not found"

```
تثبيت: XAMPP أو PHP standalone
أو استخدم الـ WSL
```

---

## 📝 ملاحظات

- جميع الـ scripts تُفترض أنك في مجلد StartNexus
- استخدم PowerShell أو CMD لتشغيل .bat files
- Windows fقط (.bat files)
- في Linux/Mac استخدم .sh equivalents (إذا موجودة)

---

**التوثيق آخر تحديث: June 19, 2026** ✅
