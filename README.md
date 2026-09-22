# منصة قاتي (Qaati) — الإصدار 2.0

<div dir="rtl">

## 🎯 نظرة عامة

**قاتي** هي منصة تجارة إلكترونية وتسويق وتوصيل متكاملة، مبنية على أحدث التقنيات مع تركيز شديد على **الأمان** و**الموثوقية** و**قابلية التوسع**.

### الميزات الرئيسية
- 🏪 سوق إلكتروني مع خريطة تفاعلية (PostGIS)
- 💬 نظام تفاوض ومحادثة فورية (Socket.io + JWT)
- 📺 بث مباشر للمنتجات
- 🚚 نظام توصيل متكامل مع تتبع GPS
- 💰 محفظة إلكترونية مع دعم 10+ مزودي دفع محليين
- ⭐ نظام تقييم ومراجعات
- 🔍 بحث متقدم (Elasticsearch)

---

## 🏗️ البنية التقنية

### Backend (NestJS + PostgreSQL/PostGIS)
```
backend/
├── src/
│   ├── auth/           # المصادقة + OTP + JWT + Roles
│   ├── users/          # إدارة المستخدمين
│   ├── shops/          # إدارة المتاجر
│   ├── products/       # إدارة المنتجات + المزادات
│   ├── orders/         # إدارة الطلبات + State Machine
│   ├── deliveries/     # إدارة التوصيل + GPS
│   ├── payments/       # بوابات الدفع + المحافظ المحلية
│   ├── wallet/         # المحفظة الإلكترونية
│   ├── conversations/  # المحادثات
│   ├── notifications/  # الإشعارات (Firebase)
│   ├── reviews/        # التقييمات
│   ├── search/         # البحث
│   ├── live-streams/   # البث المباشر
│   ├── gateways/       # WebSockets (Chat + Tracking)
│   └── admin/          # لوحة الإدارة
├── Dockerfile
├── .env.example
└── package.json
```

### Mobile App (Flutter)
```
qaati_app/
├── lib/
│   ├── screens/
│   │   ├── auth/           # تسجيل + OTP
│   │   ├── buyer/          # الشاشات الرئيسية
│   │   ├── seller/         # لوحة البائع
│   │   └── driver/         # لوحة الموصّل
│   ├── providers/          # State Management
│   ├── models/             # Data Models
│   ├── core/               # Constants + Services + Utils
│   └── widgets/            # Reusable Widgets
├── pubspec.yaml
└── (android/ios/web)       # Generated via flutter create
```

### Infrastructure
```
├── docker-compose.yml      # Docker services + healthchecks
├── nginx.conf              # Reverse proxy + SSL + gzip
├── 01_database.sql         # Complete PostgreSQL schema
└── .gitignore
```

---

## 🚀 التثبيت والتشغيل

### المتطلبات
- Node.js 18+
- PostgreSQL 15+ with PostGIS
- Redis 7+
- Flutter 3.16+ (للموبايل)
- Docker & Docker Compose (اختياري)

### 1. Backend

```bash
# 1. Clone
# 2. Environment
cp backend/.env.example backend/.env
# عدّل backend/.env بقيمك

# 3. Install
cd backend
npm install

# 4. Database
# تأكد من تشغيل PostgreSQL + PostGIS + Redis
# ثم شغّل: npm run migration:run

# 5. Start
npm run start:dev        # Development
npm run start:prod       # Production
```

### 2. Mobile App

```bash
cd qaati_app

# 1. Generate platforms
flutter create . --platforms android,ios,web

# 2. Create assets
mkdir -p assets/images assets/icons assets/fonts

# 3. Install dependencies
flutter pub get

# 4. Build
flutter build apk --release    # Android
flutter build ios --release    # iOS (macOS only)
```

### 3. Docker (Production)

```bash
# 1. Environment
cp backend/.env.example .env
# عدّل .env بقيم الإنتاج

# 2. SSL Certificates
mkdir -p ssl
# ضع شهاداتك في ssl/fullchain.pem و ssl/privkey.pem

# 3. Start
docker-compose up -d

# 4. Logs
docker-compose logs -f api
```

---

## 🔐 الأمان

### ما تم إنجازه
| الثغرة | الحالة |
|--------|--------|
| إيداع رصيد وهمي | ✅ معالج — التحقق من المحفظة |
| payments بدون صلاحيات | ✅ معالج — RolesGuard |
| خلط shopId/userId | ✅ معالج — ownerId |
| IDOR إنشاء منتجات | ✅ معالج — req.user.shopId |
| FK Violation | ✅ معالج — userId صحيح |
| تحديث حالة الطلب | ✅ معالج — State Machine |
| تسريب البيانات | ✅ معالج — Ownership checks |
| غياب RBAC | ✅ معالج — RolesGuard فعّال |
| Socket.io بدون مصادقة | ✅ معالج — JWT |
| أسرار مكشوفة | ✅ معالج — .gitignore + env |

### Headers الأمانية
- Secure response headers middleware — CSP + HSTS + X-Frame-Options
- `CORS` — origins مُحددة فقط
- `Rate Limiting` — 10 طلب/دقيقة افتراضياً

---

## 💳 مزودو الدفع المدعومون

| المزود | الكود | الحالة |
|--------|-------|--------|
| جوالي (Jawali) | `jawali` | ✅ جاهز (يحتاج API Key) |
| جيب (Jip) | `jip` | ✅ جاهز (يحتاج API Key) |
| فلوسك (Fulusk) | `fulusk` | ✅ جاهز (يحتاج API Key) |
| كاش (Cash) | `cash` | ✅ جاهز |
| ون كاش (One Cash) | `one_cash` | ✅ جاهز |
| أمان (Aman) | `aman` | ✅ جاهز |
| كريمي (Kurimi) | `kurimi` | ✅ جاهز |
| معاملات (Moamalat) | `moamalat` | ✅ جاهز |
| حرام (Haram) | `haram` | ✅ جاهز |
| محفظة يمنية | `yemen_wallet` | ✅ جاهز |

### تدفق الدفع
```
1. المستخدم يختار المزود
2. يرسل المبلغ عبر المحفظة
3. يحصل على رقم العملية + كود التصديق
4. يُدخلهما في التطبيق
5. النظام يتحقق (Webhook/API)
6. يُضاف الرصيد تلقائياً
```

---

## 📱 شاشات التطبيق

### المشتري
- 🏠 الرئيسية (منتجات + متاجر)
- 🗺️ الخريطة (أسواق قريبة)
- 🛒 السلة + الدفع
- 📋 طلباتي + التتبع
- 💬 المحادثات + التفاوض

### البائع
- 📊 لوحة التحكم (إحصائيات)
- 📦 إدارة المنتجات
- 📋 إدارة الطلبات
- 📺 البث المباشر
- 💰 الأرباح + السحب

### الموصّل
- 🏠 الرئيسية (حالة + إحصائيات)
- 🚚 الطلبات المتاحة
- 📍 التتبع + GPS
- 💰 الأرباح

---

## 🧪 الاختبارات

```bash
# Backend Unit Tests
cd backend
npm run test

# Backend e2e Tests
npm run test:e2e

# Flutter Tests
cd qaati_app
flutter test
```

---

## 🛡️ CI/CD

GitHub Actions pipeline يتضمن:
- ✅ Linting
- ✅ Unit Tests
- ✅ e2e Tests
- ✅ Security Scan (Trivy)
- ✅ Flutter Build
- ✅ Auto-deploy to Staging/Production

---

## 📊 Monitoring

### Health Checks
- `/health` — API status
- Docker healthchecks لكل service

### Logs
- Structured logging via NestJS
- Nginx access logs
- PostgreSQL slow query log

### Metrics (اختياري)
- Prometheus + Grafana
- Node Exporter
- PostgreSQL Exporter

---

## 📝 API Documentation

Swagger UI متاح في:
```
Development: http://localhost:3000/api/docs
```

> ⚠️ عطّل Swagger في الإنتاج!

---

## 🤝 المساهمة

1. Fork
2. Branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Pull Request

---

## 📄 الترخيص

MIT License — انظر `LICENSE`

---

## 👥 الفريق

تم تطوير هذا المشروع بإشراف خبراء تقنيين متخصصين في:
- أمن المعلومات
- هندسة البرمجيات
- تجربة المستخدم

---

## 📞 الدعم

للاستفسارات أو الإبلاغ عن مشاكل:
- البريد: support@qaati.app
- التلغرام: @qaati_support

---

<div align="center">

**صنع بـ ❤️ في اليمن**

</div>

</div>
