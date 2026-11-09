# علمني (3lemne) — منصة تعليم اللغة الإنجليزية للناطقين بالعربية

منصة تعليمية متكاملة لتعليم اللغة الإنجليزية موجهة بالدرجة الأولى للمتحدثين بالعربية، تتضمن تطبيق موبايل بـ Flutter، خادم واجهات برمجية بـ ASP.NET Core 8، قاعدة بيانات PostgreSQL، ولوحة تحكم بـ React.

---

## 📁 هيكل المستودع (Monorepo)

```
3lemne/
├─ reference/prototype/        # النموذج الأولي القديم «خُطوة» (للقراءة فقط والبيانات)
├─ backend/                    # ASP.NET Core 8 Web API
│  ├─ Alemni.Api/              # Controllers، Program.cs، Middleware، Swagger
│  ├─ Alemni.Application/      # DTOs، Validators، Interfaces
│  ├─ Alemni.Domain/           # Entities، Enums
│  ├─ Alemni.Infrastructure/   # EF Core، PostgreSQL، Seed، Providers
│  ├─ Alemni.Tests/            # xUnit Tests
│  ├─ Alemni.sln
│  └─ Dockerfile
├─ mobile/                     # تطبيق الموبايل (Flutter + Dart)
├─ dashboard/                  # لوحة التحكم (React + Vite + TypeScript)
├─ docker-compose.yml          # تشغيل PostgreSQL و API محليًا
└─ README.md
```

---

## 🚀 التشغيل السريع

### الطريقة 1: باستخدام Docker Compose (الموصى بها)

تأكد من تشغيل Docker Desktop، ثم نفّذ في مجلد المشروع:

```bash
docker compose up -d
```

- **Swagger UI**: افتح المتصفح على [http://localhost:5000/swagger](http://localhost:5000/swagger)
- **Health Check**: [http://localhost:5000/api/health](http://localhost:5000/api/health)
- **PostgreSQL**: يعمل على المنفذ `5432` (`alemni_db` / `alemni_user` / `alemni_secret`).

### الطريقة 2: التشغيل المباشر عبر .NET CLI

1. تشغيل قاعدة البيانات (أو حاوية PostgreSQL):
   ```bash
   docker run --name alemni_pg -e POSTGRES_DB=alemni_db -e POSTGRES_USER=alemni_user -e POSTGRES_PASSWORD=alemni_secret -p 5432:5432 -d postgres:16-alpine
   ```
2. تشغيل الـ API:
   ```bash
   cd backend
   dotnet run --project Alemni.Api/Alemni.Api.csproj
   ```
3. افتح المتصفح على [http://localhost:5104/swagger](http://localhost:5104/swagger).

---

## 📱 تشغيل تطبيق الموبايل (Flutter)

### 1. التشغيل على الويب (Web):
```bash
cd mobile
flutter run -d chrome --web-port 5050
```

### 2. التشغيل على هاتف Android حقيقي أو محاكي:
- **باستخدام كابل USB وأمر `adb reverse` (الأسرع والأسهل)**:
  ```bash
  adb reverse tcp:5104 tcp:5104
  cd mobile
  flutter run -d <DEVICE_ID>
  ```
- **باستخدام عنوان IP الشبكة المحلية (LAN IP)**:
  ```bash
  cd mobile
  flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://192.168.1.xxx:5104
  ```

---

## 🧪 تشغيل الاختبارات

```bash
# اختبارات الـ Backend
dotnet test backend/Alemni.sln

# اختبارات الـ Flutter
cd mobile && flutter test
cd mobile && flutter analyze
```

