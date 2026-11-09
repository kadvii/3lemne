# «علمني» (3lemne) — إرشادات المشروع وقواعد التطوير

منصة تعليم اللغة الإنجليزية للمتحدثين بالعربية (جمهور عراقي وعربي).
تحتوي على:
- تطبيق الموبايل: **Flutter** (`mobile/`)
- خادم الواجهات البرمجية: **ASP.NET Core 8 Web API** (`backend/`)
- لوحة التحكم: **React + Vite + TypeScript** (`dashboard/`)

---

## 🛠️ أوامر التشغيل والاختبار

### Backend (.NET 8):
```bash
# بناء الحل البرمجي
dotnet build backend/Alemni.sln

# تشغيل كافة الاختبارات
dotnet test backend/Alemni.sln

# تشغيل الـ API محلياً
dotnet run --project backend/Alemni.Api/Alemni.Api.csproj --urls "http://localhost:5104"

# Swagger UI
# http://localhost:5104/swagger
```

### Mobile (Flutter):
```bash
# فحص الكود (Lints & Errors)
cd mobile && flutter analyze

# تشغيل اختبارات الواجهة والمنطق
cd mobile && flutter test

# تشغيل الويب
cd mobile && flutter run -d chrome --web-port 5050

# تمرير رابط الـ API المخصص للأجهزة الحقيقية
cd mobile && flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:5104
```

### Dashboard (React):
```bash
npm --prefix dashboard install
npm --prefix dashboard run dev -- --port 3000
```

---

## 📁 بنية المشروع (Monorepo)

```
3lemne/
├─ backend/
│  ├─ Alemni.Api/            # Controllers، Configuration، Program.cs
│  ├─ Alemni.Application/    # DTOs، Interfaces، Services (Reading, Writing, Word, Stats, StoryGen)
│  ├─ Alemni.Domain/         # Entities، Enums
│  ├─ Alemni.Infrastructure/ # EF Core DbContext، Seeder، Seed Data (reading.json, vocab.json, phonics.json)
│  └─ Alemni.Tests/          # xUnit Tests (Seed, Validation, Morphology, Endpoints)
├─ mobile/
│  └─ lib/
│     ├─ core/               # API Client، Themes، Ltr Widget، TTS، STT
│     └─ features/           # home, reading, writing, listening, speaking, phonics, words
├─ dashboard/                # React Vite Dashboard
├─ reference/prototype/      # النموذج الأولي القديم (مصدر البيانات المرجعي)
└─ CLAUDE.md                 # قواعد وإرشادات العمل الثابتة
```

---

## ⚖️ قواعد المشروع الثابتة (R1 - R8)

> **تحذير:** أي خرق لهذه القواعد يعد فشلاً في المرحلة ويتطلب الإلغاء والتصحيح فوراً.

| # | القاعدة | التفاصيل |
|---|---|---|
| **R1** | **القراءة = قصة قصيرة حقيقية** | شخوص، بداية، توتر/مشكلة، حل، ونهاية إنسانية أو مفارقة ممتعة. ممنوع الجمل المنفصلة أو فقرات المعلومات الجافة. |
| **R2** | **لا ترجمة داخل نص القصة** | ممنوع أزرار «ترجمة الفقرة» أو ترجمة الجمل داخل المتن. الترجمة فقط عند النقر على **كلمة محددة**. |
| **R3** | **الأسئلة مشتقة من نفس القصة 100%** | تُبنى الأسئلة من حقائق القصة (`facts`). يمنع منعاً باتاً وجود سؤال يذكر اسماً أو مكاناً أو حدثاً غير وارد في نص القصة. |
| **R4** | **التصميم Mobile-First** | التطبيق مخصص للهاتف (عرض 360–430px). في الويب أو الشاشات العريضة، يُعرض داخل حاوية مركزية محددة العرض (`maxWidth: 480`) في المنتصف. |
| **R5** | **اتجاه النصوص LTR قطعيًا للإنجليزي** | التطبيق locale عربي RTL، ولذلك كل كلمة، جملة، أو مدخل إنجليزي يُغلف بـ `Ltr` أو `Directionality(ltr)` صريح. |
| **R6** | **نظام تلميحات عشوائي غير كامل** | التلميح في الكتابة يكشف حرفاً عشوائياً (وليس بالترتيب)، بحد أقصى `floor(length/2)` مع بقاء حرفين مخفيين على الأقل. ويخصم نقاط XP. |
| **R7** | **منع البيانات الثابتة (No Hardcoding)** | جميع التمارين والقصص والمفردات تأتي من الـ API والـ Repository. |
| **R8** | **جودة ونظافة الكود** | ممنوع `catch (_) {}` الصامتة. الالتزام بملفات متوسطة الحجم (~250 سطر). عدم تسريب وحدات التحكم أو موارد الذاكرة. |

