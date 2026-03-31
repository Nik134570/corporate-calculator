# CLAUDE.md — Корпоративный калькулятор

## Обзор проекта

CRM-система для стекольного/столярного бизнеса. Позволяет рабочим создавать расчёты стоимости изделий, а администраторам — управлять справочниками, пользователями и модерировать изменения цен.

---

## Стек технологий

### Backend
- **Runtime:** Node.js 20
- **Framework:** Express.js
- **ORM:** Prisma 6 (не 7 — несовместимый API)
- **БД:** PostgreSQL 16 (Docker)
- **Auth:** JWT (access 15min + refresh 30d)
- **Контейнеризация:** Docker + docker-compose

### Frontend
- **Framework:** Flutter (Web)
- **State:** BLoC (flutter_bloc)
- **Routing:** go_router
- **DI:** get_it
- **HTTP:** Dio
- **Storage:** flutter_secure_storage
- **PDF:** pdf + printing + google_fonts (для кириллицы)

---

## Структура проекта

```
projects_flutter/
├── docker-compose.yml          # Корневой — поднимает postgres + backend + frontend
├── backend/
│   ├── docker-compose.yml      # Только для разработки (postgres + backend)
│   ├── .env.docker             # Переменные окружения (не в git)
│   ├── Dockerfile
│   ├── server.js
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── seed.js
│   └── src/
│       ├── app.js
│       ├── prisma.js
│       ├── config/logger.js
│       ├── middleware/
│       │   ├── auth.middleware.js
│       │   ├── role.middleware.js
│       │   └── error.middleware.js
│       ├── utils/ApiError.js
│       └── modules/
│           ├── auth/auth.router.js
│           ├── users/users.router.js
│           ├── materials/materials.router.js
│           ├── calculations/calculations.router.js
│           ├── catalog/catalog.router.js
│           ├── settings/settings.router.js
│           └── audit/audit.router.js
└── calculator/
    ├── Dockerfile
    ├── nginx.conf
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── api/api_client.dart
        │   ├── di/injection.dart
        │   ├── router/app_router.dart
        │   ├── storage/secure_storage.dart
        │   └── services/pdf_service.dart
        └── features/
            ├── auth/
            │   ├── data/models/auth_model.dart
            │   ├── data/repositories/auth_repository.dart
            │   ├── presentation/bloc/auth_bloc.dart
            │   └── presentation/screens/login_screen.dart
            ├── calculator/
            │   ├── data/models/
            │   │   ├── calculation_model.dart
            │   │   ├── material_model.dart
            │   │   └── catalog_model.dart
            │   ├── data/repositories/calculator_repository.dart
            │   ├── presentation/bloc/calculator_bloc.dart
            │   └── presentation/screens/
            │       ├── calculations_list_screen.dart
            │       ├── new_calculation_screen.dart
            │       └── calculation_detail_screen.dart
            └── admin/
                └── presentation/screens/
                    ├── admin_screen.dart
                    ├── catalog_edit_screen.dart
                    ├── admin_settings_screen.dart
                    └── audit_screen.dart
```

---

## Роли пользователей

| Роль | Доступ |
|------|--------|
| `WORKER` | Создание/редактирование своих расчётов, отправка на модерацию |
| `MANAGER` | Всё что WORKER + просмотр всех расчётов + управление справочниками |
| `ADMIN` | Всё + управление пользователями + модерация + настройки |

---

## Схема БД (Prisma)

### Основные модели

```
User → RefreshToken (1:N)
User → Calculation (1:N)
Calculation → CalculationProduct (1:N)
Calculation → ReviewRequest (1:1)
CalculationProduct → ProductProcessing (1:N)
CalculationProduct → ProductPieceWork (1:N)
CalculationProduct → Material (N:1)
```

### Статусы расчёта (CalculationStatus)
- `DRAFT` — сохранён, цены не менялись → отображается "Подтверждён" или "Черновик"
- `PENDING` — сохранён с изменёнными ценами, не отправлен → "Не подтверждён"
- `IN_REVIEW` — отправлен на модерацию → "На модерации"
- `APPROVED` — одобрен администратором → "Одобрен"
- `REJECTED` — отклонён → "Отклонён"

### Важные поля

**CalculationProduct:**
- `originalPricePerSqm` — оригинальная цена из справочника (для отслеживания изменений)
- `isTempered` — закалка (+100 ₽ фиксировано, настраивается в AppSettings)
- `quantity` — количество идентичных изделий

**ProductProcessing:**
- `originalPricePerMeter` — оригинальная цена из справочника

**ProductPieceWork:**
- `originalUnitPrice` — оригинальная цена из справочника

---

## API эндпоинты

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

GET    /api/v1/users                    [ADMIN, MANAGER]
POST   /api/v1/users                    [ADMIN, MANAGER]
PATCH  /api/v1/users/:id               [ADMIN, MANAGER]

GET    /api/v1/materials
POST   /api/v1/materials               [ADMIN, MANAGER]
PATCH  /api/v1/materials/:id           [ADMIN, MANAGER]
DELETE /api/v1/materials/:id           [ADMIN]

GET    /api/v1/calculations
GET    /api/v1/calculations/reviews/pending  [ADMIN, MANAGER]
GET    /api/v1/calculations/:id
POST   /api/v1/calculations
PUT    /api/v1/calculations/:id
DELETE /api/v1/calculations/:id
POST   /api/v1/calculations/:id/submit-review
POST   /api/v1/calculations/:id/approve     [ADMIN, MANAGER]
POST   /api/v1/calculations/:id/reject      [ADMIN, MANAGER]

GET    /api/v1/catalog/processings
POST   /api/v1/catalog/processings         [ADMIN, MANAGER]
PATCH  /api/v1/catalog/processings/:id     [ADMIN, MANAGER]
DELETE /api/v1/catalog/processings/:id     [ADMIN, MANAGER]

GET    /api/v1/catalog/piece-works
POST   /api/v1/catalog/piece-works         [ADMIN, MANAGER]
PATCH  /api/v1/catalog/piece-works/:id     [ADMIN, MANAGER]
DELETE /api/v1/catalog/piece-works/:id     [ADMIN, MANAGER]

GET    /api/v1/catalog/services
POST   /api/v1/catalog/services            [ADMIN, MANAGER]
PATCH  /api/v1/catalog/services/:id        [ADMIN, MANAGER]
DELETE /api/v1/catalog/services/:id        [ADMIN, MANAGER]

GET    /api/v1/settings
PATCH  /api/v1/settings                    [ADMIN, MANAGER]

GET    /api/v1/audit                       [ADMIN, MANAGER]
```

---

## Бизнес-логика калькулятора

### Формулы расчёта изделия
```
area = (width / 1000) * (height / 1000)          // м²
perimeter = 2 * (width / 1000 + height / 1000)   // м

baseTotal = area * pricePerSqm
processingsTotal = sum(perimeter * p.pricePerMeter)
pieceWorksTotal = sum(pw.quantity * pw.unitPrice)
temperedAdd = isTempered ? temperedPrice : 0      // из AppSettings, по умолчанию 100₽

unitTotal = baseTotal + processingsTotal + pieceWorksTotal + temperedAdd
total = unitTotal * quantity
```

### Формула итога расчёта
```
productsTotal = sum(product.total)
servicesTotal = delivery + lifting + consumables + measurement + installation

complexityAmount:
  if percent: (productsTotal + servicesTotal) * complexityValue / 100
  if fixed: complexityValue

discountAmount:
  if percent: (productsTotal + servicesTotal + complexityAmount) * discountValue / 100
  if fixed: discountValue

grandTotal = productsTotal + servicesTotal + complexityAmount - discountAmount
```

### Отслеживание изменений цен
Когда работник выбирает материал из справочника — сохраняется `originalPricePerSqm`. Если цена изменена — `hasPriceChanges = true`, появляется кнопка "Отправить на модерацию".

---

## Запуск

### Production (всё через Docker)
```bash
cd projects_flutter
docker-compose up -d --build
# Открыть: http://localhost
```

### Разработка
```bash
# Backend
cd backend
docker-compose up -d      # PostgreSQL + backend

# Flutter
cd calculator
flutter run               # hot reload
```

### Первичная настройка БД
```bash
docker-compose exec backend npx prisma migrate dev --name init
docker-compose exec backend node prisma/seed.js
```

### Пересоздание БД (потеря данных!)
```bash
docker-compose exec backend npx prisma migrate reset --force
docker-compose exec backend node prisma/seed.js
```

---

## Тестовые аккаунты (после seed)

| Email | Пароль | Роль |
|-------|--------|------|
| admin@test.com | admin123 | ADMIN |
| manager@test.com | manager123 | MANAGER |
| worker@test.com | worker123 | WORKER |

---

## Flutter — важные детали

### api_client.dart — определение baseUrl
```dart
static String get baseUrl {
  if (kIsWeb) {
    final port = Uri.base.port;
    if (port != 80 && port != 443) {
      return 'http://localhost:3000/api/v1'; // разработка
    }
    return '/api/v1'; // Docker через nginx
  }
  return 'http://10.0.2.2:3000/api/v1'; // Android эмулятор
}
```

### Редирект по роли после логина (login_screen.dart)
```dart
getIt<SecureStorage>().getUserRole().then((role) {
  if (role == 'ADMIN' || role == 'MANAGER') {
    context.go('/admin');
  } else {
    context.go('/calculations');
  }
});
```

### Важно: flutter_secure_storage в браузере
Хранилище общее для всех вкладок одного домена. При тестировании разных ролей используй разные браузеры (Chrome + Firefox).

### PDF с кириллицей
Используется `PdfGoogleFonts.notoSansRegular()` — загружает шрифт с поддержкой русского языка. Стандартный шрифт пакета `pdf` кириллицу не поддерживает.

### Числовые поля
Все числовые поля используют `FilteringTextInputFormatter` — разрешены только цифры и точка/запятая. Запятая автоматически заменяется на точку при парсинге.

---

## Nginx конфигурация (calculator/nginx.conf)

```nginx
location /api {
    proxy_pass http://backend:3000;
}
```

Flutter web собирается в статику и раздаётся nginx. API запросы проксируются на бэкенд по имени сервиса Docker.

---

## Известные проблемы и решения

| Проблема | Решение |
|----------|---------|
| `prisma migrate dev` — "drift detected" | `prisma migrate reset --force` |
| Контейнер не пересобирается | `docker rmi -f backend-backend && docker-compose up -d --build` |
| Конфликт имён контейнеров | `docker rm -f app_postgres app_backend app_frontend` |
| Текст вводится задом наперёд | TextEditingController должен быть в State, не в build() |
| Кириллица в PDF — чёрные квадратики | Использовать PdfGoogleFonts вместо стандартного шрифта |
| 401 при запросах после логина в двух вкладках | flutter_secure_storage общий для всех вкладок — использовать разные браузеры |

---

## Журнал аудита

Действия которые записываются:
- `CALCULATION_CREATED` — создан расчёт
- `CALCULATION_APPROVED` — расчёт одобрен администратором
- `CALCULATION_REJECTED` — расчёт отклонён
- `REVIEW_SUBMITTED` — отправлен на модерацию

Каждая запись содержит: userId, userFullName, action, entityId, entityTitle, details, createdAt.

---

## .env.docker (backend)

```env
POSTGRES_USER=appuser
POSTGRES_PASSWORD=your_password
POSTGRES_DB=appdb
DATABASE_URL=postgresql://appuser:your_password@postgres:5432/appdb?schema=public
JWT_ACCESS_SECRET=your_access_secret_min_32_chars
JWT_REFRESH_SECRET=your_refresh_secret_min_32_chars
PORT=3000
NODE_ENV=production
```

---

## Справочники (seed данные)

### Материалы (площадные, ₽/м²)
Стекло прозрачное 4мм, 6мм | Стекло матовое 4мм | Стекло бронза 4мм | Зеркало 4мм, 6мм | Триплекс 6.4мм | Закалённое 6мм

### Шаблоны обработки (₽/м пог)
Шлифовка | Фацет | Полировка торца

### Шаблоны штучных работ (₽/шт)
Отверстие | Вырез | Уголок

### Доп. услуги
Доставка | Подъём | Расходники | Замер | Монтаж

### Настройки
Цена закалки: 100 ₽ (настраивается администратором)
