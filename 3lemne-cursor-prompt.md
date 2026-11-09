# برومت مشروع «علمني» (3lemne)

> انسخ هذا الملف كاملًا إلى Cursor / Claude Code (أو ضعه في جذر المشروع باسم `PROMPT.md` أو `.cursor/rules`).
> اشتغل على **مرحلة واحدة كل مرة**، ولا تنتقل للمرحلة التالية قبل ما تتحقق شروط القبول للمرحلة الحالية.

---

## 1) دورك

أنت مهندس برمجيات Senior (Flutter + ASP.NET Core + React). مهمتك بناء تطبيق **«علمني»** من الصفر وفق هذا الملف، مع إعادة استخدام محتوى وأفكار نموذج ويب أولي موجود في `reference/prototype/` (اسمه «خُطوة»، HTML/JS بدون سيرفر).

قواعد العمل:
- اشتغل بمراحل (القسم 11). بعد كل مرحلة: شغّل الاختبارات، لخّص ما تم، وانتظر موافقتي.
- إذا شي غير واضح أو فيه قرار كبير (مزوّد LLM، مزوّد TTS، الاستضافة) **اسألني** ولا تخمّن.
- لا تضع أي مفتاح سري داخل الكود. استخدم `appsettings.Development.json` (خارج git) و environment variables.
- اكتب كود نظيف، صغير الملفات، مع اختبارات للمنطق المهم. لا تعمل ملفات ضخمة (النموذج الأولي فيه `app.js` من ~1600 سطر — لا تكرر هذا).

---

## 2) فكرة المنتج

تطبيق موبايل **واجهته عربية بالكامل (RTL)** هدفه **تعليم اللغة الإنجليزية فقط** للناطقين بالعربية (جمهور عراقي بالدرجة الأولى).
أربع مهارات، بهذا الترتيب: **الكتابة ← القراءة ← الاستماع ← التكلم**.

مستويات الصعوبة: `A1 / A2 / B1 / B2` (مثل النموذج الأولي). كل مهارة فيها **زر صعوبة** خاص بها (يغيّر مستوى التمارين داخل هذه المهارة، ويحفظ آخر اختيار).

### 2.1 الكتابة (Writing)
- الفكرة: المستخدم **يسمع الكلمة بالإنجليزي ويكتبها**.
- عناصر الشاشة:
  - زر **كلمة جديدة**
  - زر **سماع الصوت** (ويفضّل زر ثاني «بطيء»)
  - زر **مساعدة** (يكشف أول حرف، ثم حرف إضافي كل ضغطة، ويخصم نقاط)
  - **مربعات الحروف** بعدد حروف الكلمة (تصحيح حرفًا بحرف: أخضر/أحمر)
  - زر **الصعوبة**
- بعد الإجابة الصحيحة: تظهر الكلمة + معناها بالعربي + نقاط خبرة. محاولتان قبل ظهور الحل.

### 2.2 القراءة (Reading)
- الفكرة: تظهر **قصة قصيرة** بمستوى المستخدم، يقرأها، و**يضغط على أي كلمة** فتظهر ترجمتها بالعربي مع زر صوت وزر «أضف إلى مفرداتي».
- عناصر الشاشة: زر **عمل قصة جديدة**، زر **تغيير الصعوبة**، (اختياري/مرحلة لاحقة) زر **قراءة القصة بصوت** مع تمييز الكلمة الحالية.
- بعد القصة: 2–3 أسئلة فهم.

### 2.3 الاستماع (Listening)
- الفكرة: يسمع جملة إنجليزية ثم **يختار الجملة الصحيحة** من الخيارات.
- عناصر الشاشة: زر **استماع**، زر **أبطأ**، زر **الصعوبة**، **مربعات الخيارات** (3–4).
- نوعان من التمارين (بدّل بينهما):
  1. اختيار **الجملة الإنجليزية** التي سمعها (الهدف الأصلي).
  2. اختيار **المعنى العربي** للجملة (موجود في النموذج الأولي).
- بعد الإجابة: يظهر النص الإنجليزي + الترجمة العربية.

### 2.4 التكلم (Speaking)
- الفكرة: تظهر جملة إنجليزية، يقولها المستخدم، والتطبيق يقيّم.
- عناصر الشاشة: زر **الصعوبة**، زر **تكلّم** (ميكروفون)، زر **جملة جديدة**، وزر سماع النموذج (عادي/بطيء).
- التقييم: يقارن النص المتعرَّف عليه بالجملة المطلوبة كلمة بكلمة ويظهر الكلمات التي لم تُنطق بوضوح. (اشرح للمستخدم داخل التطبيق أن النتيجة تقيس «وضوح النطق كما فهمه الجهاز» وليست تقييم لغوي دقيق.)

### 2.5 ميزات إضافية
- **مخارج الحروف** و**حروف العلة** (قسم «النطق»، انظر القسم 8).
- **ترجمة الكلمات** (في كل مكان تظهر فيه كلمة إنجليزية).
- **مفرداتي**: الكلمات المحفوظة + مراجعة.
- نقاط خبرة (XP)، أيام متتابعة (streak)، تقدم لكل مستوى.

---

## 3) المرجع الموجود: `reference/prototype/`

المشروع الأولي (ويب) يحتوي محتوى جاهز ومنطق مفيد. **استخدمه كمرجع ومصدر بيانات، لا تنسخ بنيته.**

| الملف | فيه شنو | شنو تسوي به |
|---|---|---|
| `js/data-vocab.js` | ~1100 كلمة `[english, arabic]` | حوّله لجدول `Words` عبر seed |
| `js/data-skills.js` | 95 كلمة إملاء، 28 جملة استماع، 32 جملة تكلم، وقوالب توليد قصص (`DATA.gen`) | seed لجداول المحتوى |
| `js/data-reading.js` | 10 قطع قراءة (جمل + ترجمة لكل جملة + أسئلة) | seed لجداول القصص |
| `js/app.js` | دالة `lookup()` (التعامل مع الجمع/الماضي/-ing)، و`scoreSpeech()` (مقارنة الكلام) | أعد كتابتهما بالـ Dart / C# مع اختبارات |
| `tools/validate.mjs` | فحص أن كل كلمة في المحتوى لها ترجمة | اعمل نسخة منه كـ seed validation test |

**مهم:** سكربت seed لازم يكون **idempotent** (يقدر ينعاد بدون تكرار)، ويفحص: كل كلمة داخل القصص/الجمل موجودة في القاموس.

---

## 4) التقنيات (ثابتة، لا تغيّرها بدون سؤالي)

| الجزء | التقنية |
|---|---|
| Mobile | Flutter + Dart |
| Backend | ASP.NET Core 8 (Web API) |
| Database | PostgreSQL |
| Dashboard | React + TypeScript (Vite) |
| Authentication | JWT + Refresh Tokens |
| API Docs | Swagger / OpenAPI |

مقترحات (اعتمدها إلا إذا عندك سبب أقوى، واشرحه):
- Backend: EF Core + Npgsql، FluentValidation، Serilog، xUnit + Testcontainers (أو SQLite in-memory للاختبارات السريعة).
- Flutter: Riverpod، go_router، dio، `flutter_tts`، `speech_to_text`، `just_audio`، `hive` أو `drift` للتخزين المحلي/offline.
- Dashboard: React Query، React Router، مكتبة UI خفيفة (shadcn/ui أو MUI)، Axios.
- Docker Compose للتطوير: `postgres` + `api`.

---

## 5) هيكل المستودع (monorepo)

```
3lemne/
├─ reference/prototype/        # النموذج الأولي (للقراءة فقط)
├─ backend/
│  ├─ Alemni.Api/              # Controllers، Middleware، Program.cs
│  ├─ Alemni.Application/      # Services، DTOs، Validators
│  ├─ Alemni.Domain/           # Entities، Enums
│  ├─ Alemni.Infrastructure/   # EF Core، Repositories، Seed، Providers (TTS/LLM)
│  └─ Alemni.Tests/
├─ mobile/                     # Flutter app
├─ dashboard/                  # React + TS
├─ docker-compose.yml
└─ README.md
```

---

## 6) الـ Backend

### 6.1 الكيانات الأساسية (اقتراح — عدّل إذا تحتاج)
- `User` (Id, Email, PasswordHash, DisplayName, CreatedAt, Role: `Learner|Admin`)
- `RefreshToken` (UserId, TokenHash, ExpiresAt, RevokedAt, ReplacedByTokenHash, DeviceInfo)
- `Word` (Id, English, Arabic, Level, PartOfSpeech?, ExampleEn?, ExampleAr?, IpaOptional?)
- `WritingItem` (WordId, Level) — أو علّم `Word.UsedInWriting`
- `Story` (Id, Title, TitleAr, Level, IsGenerated, CreatedAt) + `StorySentence` (StoryId, Order, English, Arabic) + `StoryQuestion` (+ options + answer)
- `ListeningItem` (Id, Level, English, Arabic, Distractors[])
- `SpeakingItem` (Id, Level, English, Arabic, Tip?)
- `PhonicsItem` (Id, Kind: `Letter|Sound|Vowel`, Symbol, IpaOrSpelling, ArabicApprox, MouthTipAr, ExampleWords[], AudioUrl?)
- `UserProgress` (UserId, Skill, Level, ItemId, Score, CompletedAt)
- `UserStats` (UserId, Xp, StreakDays, LastActiveDate)
- `SavedWord` (UserId, WordId, AddedAt)

### 6.2 الـ Endpoints (REST، كلها مُوثّقة في Swagger)
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh          # rotation: يلغي القديم ويصدر جديد
POST   /api/auth/logout

GET    /api/writing/next?level=A1
POST   /api/writing/check         # {wordId, answer} -> {correct, letters[]}
GET    /api/reading/story?level=A1            # من DB
POST   /api/reading/story/generate            # {level} -> قصة جديدة (القسم 7)
POST   /api/reading/story/{id}/answers
GET    /api/listening/next?level=A1&type=sentence|meaning
POST   /api/listening/answer
GET    /api/speaking/next?level=A1
POST   /api/speaking/score        # {itemId, recognizedText} -> {score, chips[]}

GET    /api/words/lookup?q=running   # ترجمة كلمة (مع التعامل مع الصيغ)
GET    /api/words/saved   POST /api/words/saved   DELETE /api/words/saved/{id}
GET    /api/phonics?kind=Letter|Sound|Vowel
GET    /api/me/stats

# Admin (Role=Admin) — للداشبورد
CRUD   /api/admin/words | stories | listening | speaking | phonics
GET    /api/admin/users   GET /api/admin/analytics
POST   /api/admin/import          # استيراد CSV/JSON
```

### 6.3 الأمان
- JWT access token قصير (≈15 دقيقة) + refresh token طويل (≈30 يوم)، **يتخزن مُهشّر (hash) في DB**، مع rotation واكتشاف إعادة الاستخدام (reuse detection → إلغاء كل الجلسات).
- Password hashing بـ ASP.NET Identity hasher أو Argon2/BCrypt.
- Rate limiting (خاصة `/auth/*` و`/reading/story/generate`)، CORS محدد، HTTPS، validation لكل DTO، رسائل خطأ موحدة (ProblemDetails).
- Authorization بـ policies: `Learner` و`Admin`.

### 6.4 الاختبارات
- Unit tests: `lookup` (جمع/ماضي/ing/اختصارات)، `scoreSpeech`، تصحيح الكتابة، rotation للـ refresh token.
- Integration tests: auth flow كامل، وendpoint واحد لكل مهارة.

---

## 7) توليد القصص (زر «عمل قصة»)

النموذج الأولي يولّد قصص من **قوالب عشوائية** (تتكرر بسرعة وبدون أسئلة). المطلوب بدلها:

1. **المصدر الأساسي:** قصص جاهزة من DB (يكتبها/يراجعها الأدمن).
2. **التوليد عند الطلب:** واجهة `IStoryGenerator` مع تنفيذين:
   - `TemplateStoryGenerator` (النسخة القديمة كـ fallback بدون إنترنت/تكلفة).
   - `LlmStoryGenerator` (مزوّد LLM — **اسألني أي مزوّد قبل ما تنفّذ**). المخرجات JSON صارمة: جمل + ترجمة كل جملة + 3 أسئلة، ثم **validation**: كل كلمة لازم تكون ضمن مستوى الصعوبة أو موجودة بالقاموس، وإلا تُرفض وتُعاد المحاولة.
3. خزّن كل قصة مولّدة في DB (cache) حتى لا تُولَّد مرتين وتقل التكلفة.
4. قيود: طول القصة حسب المستوى، محتوى آمن ومناسب لكل الأعمار، rate limit لكل مستخدم.

---

## 8) النطق: مخارج الحروف وحروف العلة

قسم مستقل «النطق» في التطبيق، يركّز على الأصوات الصعبة على المتحدث العربي (العراقي):

- أصوات **غير موجودة أو ملتبسة** عندنا: `P` (مقابل `B`)، `V` (مقابل `F`)، `th` الاحتكاكية (ذ/ث بحالتين: this / think)، `ng` (sing)، `r` الإنجليزية، `ch/j`.
- **حروف العلة (Vowels):** الإنجليزية فيها أكثر من الأصوات القصيرة والطويلة بالعربي (مثال: ship/sheep، cat/cut، full/fool). اعمل **أزواج مقارنة (minimal pairs)** مع صوت لكل كلمة.
- لكل عنصر `PhonicsItem`: الرمز، تقريب عربي، **وصف وضع اللسان/الشفتين بالعربي**، 3–5 كلمات مثال مع صوت، وتمرين «اسمع واختر الكلمة الصحيحة» (minimal pairs).
- الصوت: TTS من الجهاز كبداية، ويُفضَّل لاحقًا ملفات صوتية مُسجّلة/مولّدة من مزوّد TTS (**اسألني**) وتُخزَّن وتُقدَّم من الـ API.

---

## 9) تطبيق Flutter

- **RTL كامل** (`Directionality`، `locale: ar`) مع عزل الجمل الإنجليزية بالـ LTR داخل النص العربي.
- بنية: `features/{auth,writing,reading,listening,speaking,phonics,words,home}` + `core/{api,theme,storage,tts,stt}`.
- شاشة رئيسية: بطاقات المهارات الأربع + تقدم + XP + streak (مثل النموذج الأولي).
- **صوت:**
  - النطق: `flutter_tts` مع التحقق من وجود صوت إنجليزي على الجهاز، وإذا غير موجود يعرض رسالة بالعربي تشرح طريقة تحميله، أو يستخدم صوت من الـ API.
  - التعرف على الكلام: `speech_to_text` (طلب صلاحية الميكروفون بشكل واضح، وحالة بديلة إذا الصلاحية مرفوضة: تسجيل ثم استماع أو تقييم ذاتي).
- **Offline:** خزّن آخر محتوى محمّل محليًا (كلمات/جمل/قصص) ليشتغل التمرين بدون إنترنت، وزامن التقدم لاحقًا.
- حالات الخطأ/التحميل/الفراغ لكل شاشة، وأنيميشن خفيف للتصحيح.
- اختبارات widget للشاشات الأربع على الأقل (خاصة مربعات الكتابة).

---

## 10) Dashboard (React + TypeScript)

- تسجيل دخول Admin بنفس الـ JWT.
- إدارة المحتوى: كلمات، قصص (مع الأسئلة)، جمل الاستماع، جمل التكلم، عناصر النطق — إضافة/تعديل/حذف/بحث/فلترة بالمستوى.
- **استيراد CSV/JSON** مع معاينة وأخطاء واضحة (مثلًا كلمة ناقصة الترجمة).
- إحصائيات: عدد المستخدمين، النشطين، أكثر الكلمات خطأً، معدل إكمال كل مهارة.
- واجهة الداشبورد: عربية RTL أيضًا.

---

## 11) مراحل التنفيذ (وشروط القبول)

**المرحلة 0 — التأسيس**
- هيكل الـ monorepo، docker-compose (postgres)، CI بسيط، README للتشغيل.
- ✅ قبول: `docker compose up` يشغّل DB + API، وSwagger يفتح.

**المرحلة 1 — Backend الأساسي + Auth**
- الكيانات، migrations، Auth كامل (register/login/refresh/logout).
- ✅ قبول: اختبارات الـ auth تمر، وrefresh rotation + reuse detection شغالين.

**المرحلة 2 — المحتوى والـ seed**
- استيراد بيانات `reference/prototype` إلى DB (idempotent) مع validation.
- ✅ قبول: ~1100 كلمة، 95 كلمة كتابة، 28 استماع، 32 تكلم، 10 قصص؛ وفحص التغطية يمر.

**المرحلة 3 — Endpoints المهارات الأربع + lookup + scoring**
- ✅ قبول: اختبارات `lookup` و`scoreSpeech` و`writing/check` تمر؛ كل endpoint موثّق.

**المرحلة 4 — Flutter: الأساس + الكتابة**
- Auth، الشاشة الرئيسية، شاشة الكتابة كاملة بكل أزرارها (قسم 2.1).
- ✅ قبول: يشتغل على Android حقيقي، الصوت يُنطق، المربعات تتصحح.

**المرحلة 5 — Flutter: القراءة + الاستماع**
- ضغط الكلمة = ترجمة + صوت + حفظ. استماع بنوعيه.

**المرحلة 6 — Flutter: التكلم + مفرداتي + النطق (Phonics)**

**المرحلة 7 — توليد القصص** (بعد ما أختار المزوّد)

**المرحلة 8 — Dashboard**

**المرحلة 9 — صقل:** offline، أداء، إتاحة الوصول (accessibility)، تحسين رسائل الأخطاء، README نهائي.

---

## 12) تعريف «تم» (Definition of Done) لأي مهمة
- الكود يبني بدون تحذيرات مهمة، والاختبارات المتعلقة تمر.
- لا أسرار في git، ولا كلمات مرور بنص صريح.
- كل endpoint جديد موثّق في Swagger مع أمثلة.
- النصوص الظاهرة للمستخدم بالعربي وسليمة لغويًا وبدون أخطاء RTL.
- تلخيص قصير: شنو تغيّر، شنو الاختبارات، شنو الخطوة التالية.

---

## 13) أول مهمة لك الآن
1. اقرأ `reference/prototype/` كاملًا (خصوصًا ملفات `data-*.js` و`scoreSpeech` و`lookup`).
2. اكتب لي **خطة معمارية قصيرة** (صفحة واحدة) تتضمن: ERD مبسّط، قائمة الـ endpoints النهائية، وأي أسئلة عندك (مزوّد LLM، مزوّد TTS، الاستضافة).
3. **لا تكتب كود** قبل موافقتي على الخطة، ثم ابدأ بالمرحلة 0.
