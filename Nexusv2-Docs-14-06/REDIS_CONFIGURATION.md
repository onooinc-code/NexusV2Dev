# 🗄️ Redis Configuration & Queue System

> **Version:** 2.0.0 · **Date:** 2026-06-19 · **Updated:** Production Ready

---

## 📋 نظرة عامة

NexusV2 استخدم **Redis** لـ:

- ✅ **Cache Store** — تخزين البيانات المؤقتة بسرعة
- ✅ **Session Driver** — إدارة جلسات المستخدمين
- ✅ **Queue Driver** — معالجة الـ background jobs

---

## 🐳 تثبيت Redis عبر Docker

### الخطوة 1: تشغيل Docker Desktop

تأكد من تشغيل Docker:

```bash
docker --version
```

### الخطوة 2: إنشاء Redis Container

```bash
docker run -d -p 6379:6379 --name redis-nexus redis:latest
```

### الخطوة 3: التحقق من الاتصال

```bash
docker exec redis-nexus redis-cli ping
# يجب أن ترى: PONG
```

---

## ⚙️ إعدادات Laravel (.env)

### التكوين الحالي

ملف `Nexus-backend/.env`:

```ini
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_CLIENT=predis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_FALLBACK=false
```

### شرح كل خيار

| الخيار             | القيمة    | الغرض                                    |
| ------------------ | --------- | ---------------------------------------- |
| `CACHE_STORE`      | redis     | يخزن الـ cache في Redis بدلاً من الملفات |
| `SESSION_DRIVER`   | redis     | يخزن جلسات المستخدمين في Redis           |
| `QUEUE_CONNECTION` | redis     | يستخدم Redis لمعالجة الـ background jobs |
| `REDIS_CLIENT`     | predis    | مكتبة PHP للاتصال بـ Redis               |
| `REDIS_HOST`       | 127.0.0.1 | عنوان IP الـ Redis                       |
| `REDIS_PORT`       | 6379      | المنفذ المستخدم                          |
| `REDIS_PASSWORD`   | null      | لا يوجد كلمة مرور (localhost)            |

---

## 🔄 Queue Worker — معالجة الـ Background Jobs

### كيف يعمل

**بدون Queue (Sync):**

```
المستخدم ← يضغط "Send Email" → البرنامج ينتظر 5 ثوان ← ترسل الرسالة
❌ سيء للـ UX — المستخدم ينتظر!
```

**مع Queue (Redis):**

```
المستخدم ← يضغط "Send Email" → تُضاف للـ Queue (فوراً) ← يرى نتيجة
Worker ← يأخذ الـ Job من Redis ← ترسل الرسالة
✅ ممتاز — المستخدم لا ينتظر!
```

### بدء Queue Worker

**أوتوماتياً (مع quick-start):**

```batch
Double-click: StartNexus\quick-start.bat
```

**يدويّاً:**

```bash
cd Nexus-backend
php artisan queue:work --tries=3 --timeout=90
```

### معاملات المهم:

- `--tries=3` — محاولة 3 مرات إذا فشل الـ job
- `--timeout=90` — انتظار 90 ثانية قبل المحاولة التالية

---

## 📊 أوامر Redis الشائعة

### فحص الاتصال

```bash
# التحقق من Redis يعمل
docker exec redis-nexus redis-cli ping
# النتيجة: PONG

# معلومات Redis
docker exec redis-nexus redis-cli INFO server

# عدد المفاتيح المخزنة
docker exec redis-nexus redis-cli DBSIZE

# عرض جميع المفاتيح
docker exec redis-nexus redis-cli KEYS "*"
```

### مسح البيانات

```bash
# مسح قاعدة البيانات الحالية (جميع الـ cache/session)
docker exec redis-nexus redis-cli FLUSHDB

# مسح جميع قواعد البيانات
docker exec redis-nexus redis-cli FLUSHALL
```

### الاتصال التفاعلي

```bash
# فتح Redis CLI
docker exec -it redis-nexus redis-cli

# أوامر يمكنك استخدامها:
PING              # اختبار الاتصال
DBSIZE            # عدد المفاتيح
KEYS "*"          # قائمة المفاتيح
FLUSHDB           # مسح البيانات
INFO              # معلومات النظام
MONITOR           # مراقبة الأوامر الحية
CONFIG GET *      # عرض الإعدادات
```

---

## 🚀 استخدام Redis في الكود

### مثال 1: تخزين البيانات في الـ Cache

```php
// app/Http/Controllers/UserController.php
use Illuminate\Support\Facades\Cache;

class UserController extends Controller {
    public function show($id)
    {
        // تخزين البيانات مع مفتاح
        $user = Cache::remember("user:$id", 60*60, function () use ($id) {
            return User::find($id);
        });

        return response()->json($user);
    }
}
```

### مثال 2: إنشاء background job

```php
// app/Jobs/SendEmailJob.php
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;

class SendEmailJob implements ShouldQueue
{
    use Queueable, SerializesModels, InteractsWithQueue;

    public function __construct(public string $email)
    {}

    public function handle()
    {
        // يعمل في الـ background
        Mail::to($this->email)->send(new UserWelcomeEmail());
    }
}
```

### مثال 3: Dispatch job للـ Queue

```php
// في أي controller
use App\Jobs\SendEmailJob;

class UserController extends Controller {
    public function register(Request $request)
    {
        $user = User::create([...]);

        // يُضاف للـ Queue فوراً
        SendEmailJob::dispatch($user->email);

        return response()->json([
            'message' => 'تم إنشاء حسابك بنجاح!',
            'user' => $user
        ]);
    }
}
```

---

## 🔧 استكشاف الأخطاء

### مشكلة: "Connection refused" عند الوصول لـ Redis

```
الأعراض:
  - الـ job لا يُعالج
  - الـ cache لا يعمل
  - رسالة خطأ في اللوج

الحل:
  1. تحقق: docker ps | findstr redis
  2. إن لم يكن يعمل: docker start redis-nexus
  3. أو أنشئه: docker run -d -p 6379:6379 --name redis-nexus redis:latest
```

### مشكلة: Queue worker يخرج مباشرة

```
الأعراض:
  [QUEUE] exited with code 0

الحل:
  1. تحقق من QUEUE_CONNECTION=redis في .env
  2. تأكد Redis يعمل: docker exec redis-nexus redis-cli ping
  3. شغّل من جديد: php artisan queue:work
```

### مشكلة: الـ Cache لا يحفظ البيانات

```
الأعراض:
  - كل requests بطيئة
  - البيانات المؤقتة لا تُحفظ

الحل:
  1. تحقق: CACHE_STORE=redis في .env
  2. مسح القديمة: php artisan cache:clear
  3. تحقق من التوصيل: docker exec redis-nexus redis-cli ping
```

---

## 📈 مراقبة الأداء

### استخدام Redis INFO

```bash
docker exec redis-nexus redis-cli INFO all
```

يظهر:

- Connections
- Memory usage
- Commands processed
- Keyspace info

### مراقبة القمم (Peak Usage)

```bash
# مراقبة الأوامر الحية
docker exec -it redis-nexus redis-cli MONITOR

# يظهر كل أمر يُنفذ:
1624721234.123456 [0 127.0.0.1:49152] "GET" "cache:user:1"
1624721234.234567 [0 127.0.0.1:49152] "SET" "session:abc" ...
```

---

## 🔄 التبديل بين Queue Drivers

### من Redis إلى Database

```ini
# في .env
QUEUE_CONNECTION=database

# ثم أنشئ جدول:
php artisan queue:table
php artisan migrate
```

### من Redis إلى Sync (فوري)

```ini
# في .env
QUEUE_CONNECTION=sync

# لا توجد queue worker مطلوبة!
```

### العودة لـ Redis

```ini
# في .env
QUEUE_CONNECTION=redis

# وتأكد Redis يعمل:
docker start redis-nexus
```

---

## 🎯 أفضل الممارسات

### ✅ افعل هذا:

1. **استخدم Caching للبيانات الثقيلة**

   ```php
   Cache::remember("expensive:query", 3600, function () {
       return DB::table(...)->get();
   });
   ```

2. **قسّم الـ Jobs الطويلة**

   ```php
   // استخدم batches أو فسّم الـ job
   Bus::batch([...])
   ```

3. **راقب Queue بانتظام**

   ```bash
   php artisan queue:monitor --max=1000
   ```

4. **استخدم Retry Logic**
   ```php
   class MyJob implements ShouldQueue {
       public $tries = 3;
       public $timeout = 90;
   }
   ```

### ❌ تجنب هذا:

1. **لا تشغّل jobs بدون Queue** — سيبطئ التطبيق
2. **لا تخزّن بيانات ضخمة في Cache** — استخدم Database
3. **لا تترك Queue worker متوقفة** — الـ jobs ستتراكم
4. **لا تستخدم FLUSHALL بدون قصد** — ستخسر جميع البيانات

---

## 📊 مقارنة Queue Drivers

| الميزة         | Sync        | Database  | Redis        |
| -------------- | ----------- | --------- | ------------ |
| **السرعة**     | ❌ بطيء     | ⚠️ متوسط  | ✅ سريع جداً |
| **الموثوقية**  | ❌ لا retry | ✅ نعم    | ✅ نعم       |
| **الذاكرة**    | ❌ عالية    | ⚠️ متوسطة | ✅ منخفضة    |
| **التعقيد**    | ✅ بسيط     | ⚠️ متوسط  | ✅ بسيط      |
| **Production** | ❌ لا       | ⚠️ ربما   | ✅ أفضل      |

---

## 🚀 الخطوات التالية

1. ✅ تشغيل Redis (عبر Docker)
2. ✅ تحديث .env مع `QUEUE_CONNECTION=redis`
3. ✅ بدء queue worker: `php artisan queue:work`
4. ✅ اختبار job: `php artisan tinker` → `Mail::queue(...)`
5. ✅ مراقبة: `php artisan queue:monitor`

---

**التوثيق آخر تحديث: June 19, 2026** ✅

للمزيد من التفاصيل انظر:

- [Laravel Queue Documentation](https://laravel.com/docs/11.x/queues)
- [Redis Documentation](https://redis.io/docs/)
- [Quick Start Guide](./QUICK_START.md)
