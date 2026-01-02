# Oracle APEX + ORDS Docker Setup for Coolify

## 📋 نظرة عامة

إعداد Docker لتشغيل Oracle APEX مع ORDS مع:
- ✅ تخزين دائم (على السيرفر مباشرة)
- ✅ نظام النسخ الاحتياطي والاستعادة
- ✅ متوافق مع Coolify
- ✅ HTTP و HTTPS

## 📁 هيكل الملفات

```
apex/
├── docker-compose.yml       # ملف Docker الرئيسي
├── .env.example             # متغيرات البيئة
├── data/                    # 📦 التخزين الدائم
│   ├── oracle/              # بيانات قاعدة البيانات
│   ├── ords/
│   │   ├── config/          # إعدادات ORDS
│   │   └── secrets/         # مفاتيح ORDS
│   └── apex/
│       └── images/          # صور APEX
├── backups/                 # 📦 النسخ الاحتياطية
├── scripts/
│   ├── backup.sh            # سكربت النسخ الاحتياطي
│   ├── restore.sh           # سكربت الاستعادة
│   ├── setup/
│   └── startup/
└── README.md
```

## 🚀 البدء السريع

```bash
# 1. نسخ المتغيرات
cp .env.example .env

# 2. تعديل كلمات المرور

# 3. التشغيل
docker-compose up -d
```

## 📦 التخزين الدائم

البيانات محفوظة في مجلد `./data/` على السيرفر مباشرة:

| المسار في السيرفر | المسار في Docker | الوصف |
|------------------|------------------|-------|
| `./data/oracle/` | `/opt/oracle/oradata` | بيانات قاعدة البيانات |
| `./data/ords/config/` | `/etc/ords/config` | إعدادات ORDS |
| `./data/ords/secrets/` | `/etc/ords/secrets` | مفاتيح ORDS |
| `./data/apex/images/` | `/opt/oracle/apex/images` | صور APEX |

## 💾 النسخ الاحتياطي

### إنشاء نسخة احتياطية:
```bash
./scripts/backup.sh
```

النسخ الاحتياطية تُحفظ في: `./backups/apex_backup_YYYYMMDD_HHMMSS.tar.gz`

### الاستعادة من نسخة احتياطية:
```bash
./scripts/restore.sh ./backups/apex_backup_20260102_120000.tar.gz
```

### النسخ الاحتياطي التلقائي (Cron):
```bash
# أضف هذا السطر إلى crontab -e
0 2 * * * /path/to/apex/scripts/backup.sh >> /var/log/apex-backup.log 2>&1
```

## 🌐 البورتات

| البورت | الخدمة |
|--------|--------|
| **8181** | APEX/ORDS (HTTP) |
| 1521 | Oracle Database |
| 5500 | Enterprise Manager |

## ☁️ النشر على Coolify

1. ارفع الملفات إلى Git Repository
2. في Coolify: أنشئ مشروع Docker Compose جديد
3. أضف المتغيرات البيئية:
   ```
   ORACLE_PWD=YourSecurePassword123!
   APEX_DOMAIN=apex.yourdomain.com
   ```
4. Deploy!

## 🔗 الوصول

```
APEX Builder:  http://localhost:8181/ords/apex
APEX Admin:    http://localhost:8181/ords/apex_admin
SQL Developer: http://localhost:8181/ords/sql-developer
```

## 🔧 أوامر مفيدة

```bash
# عرض الـ logs
docker-compose logs -f

# النسخ الاحتياطي
./scripts/backup.sh

# الاستعادة
./scripts/restore.sh ./backups/[backup_file].tar.gz

# إعادة تشغيل
docker-compose restart

# إيقاف
docker-compose down
```

## ⚠️ ملاحظات مهمة

1. **أول تشغيل**: يستغرق 5-10 دقائق
2. **الذاكرة**: 4GB RAM minimum
3. **القرص**: 20GB minimum
4. **Backup**: يُنصح بعمل نسخ احتياطي يومي
