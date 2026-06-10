# Smart Parking Platform (BKR)

Клієнт-серверний прототип для підтримки пошуку паркування в м. Львів: **Flutter** (мобільний клієнт), **NestJS** + **PostgreSQL** (backend), **Docker Compose**, інтеграція **Google Maps Platform**.

## Структура репозиторію

| Каталог | Опис |
|---------|------|
| `backend/` | REST API (`/api/v1`), Prisma, JWT, рекомендації nearby |
| `mobile/` | Flutter-застосунок (карта, рекомендації, профіль) |
| `docs/` | Пояснювальна записка (markdown), діаграми draw.io |
| `scripts/` | Допоміжні скрипти запуску стеку |

## Швидкий старт

### 1. Backend + PostgreSQL (Docker)

```bash
cp .env.example .env
cp backend/.env.example backend/.env

docker compose up --build
# API: http://localhost:3000/api/v1/health
# Swagger: http://localhost:3000/docs
```

Або: `./scripts/start-stack.sh`

### 2. Імпорт паркувань (один раз)

```bash
cd backend
npm run import-parkings
```

### 3. Mobile

```bash
cd mobile
cp assets/env/env.sample assets/env/.env
cp ios/Runner/Secrets.xcconfig.example ios/Runner/Secrets.xcconfig
cp android/secrets.properties.example android/secrets.properties
# Edit Secrets.xcconfig and secrets.properties — paste Google Maps API keys (not committed).

flutter pub get
cd ios && pod install && cd ..
flutter run
```

- iOS Simulator: `http://127.0.0.1:3000/api/v1`
- Android Emulator: `http://10.0.2.2:3000/api/v1`

### Тести backend

```bash
cd backend && npm test
```

Навчальний проєкт (бакалаврська робота).
