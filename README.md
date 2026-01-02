# Oracle APEX + ORDS Docker Setup

## 🚀 الإعداد السريع (3 خطوات فقط!)

### 1. إنشاء ملف `.env`
```bash
cp .env.example .env
```

ثم عدّل كلمة المرور في `.env`:
```env
ORACLE_PWD=YourStrongPassword123!
APEX_DOMAIN=apex.yourdomain.com
```

### 2. التشغيل
```bash
docker-compose up -d
```

### 3. انتظر 5-10 دقائق للإعداد الأولي

## 🌐 الوصول لـ APEX

بعد اكتمال التشغيل:
```
APEX:     http://localhost:8181/ords/apex
Username: ADMIN
Password: [كلمة المرور من ORACLE_PWD]
```

## 📁 التخزين الدائم

جميع البيانات محفوظة في `./data/`:
```
data/
├── oracle/     # قاعدة البيانات
├── ords/       # إعدادات ORDS
└── apex/       # صور APEX
```

## 💾 النسخ الاحتياطي والاستعادة

```bash
# النسخ الاحتياطي
./scripts/backup.sh

# الاستعادة
./scripts/restore.sh ./backups/[backup-file].tar.gz
```

## ☁️ Coolify

فقط ارفع المشروع وأضف المتغيرات البيئية - كل شيء جاهز!

## 🔧 أوامر مفيدة

```bash
# Logs
docker-compose logs -f ords

# إعادة تشغيل
docker-compose restart

# إيقاف
docker-compose down
```

## ⚠️ استكشاف الأخطاء

إذا ظهرت مشكلة "Password cannot be null":
```bash
# أوقف كل شيء
docker-compose down -v

# أنشئ ملف .env
cp .env.example .env

# عدل ORACLE_PWD في .env

# ابدأ من جديد
docker-compose up -d
```
