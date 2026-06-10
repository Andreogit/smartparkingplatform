# Автоматичні тести backend (Smart Parking Platform)

Папка `test/unit/` містить **модульні тести** (Jest), які перевіряють окремі алгоритми без запуску PostgreSQL і без зовнішніх викликів Google API.

Додатково в `src/common/health.controller.spec.ts` — перевірка endpoint `GET /api/v1/health`.

## Запуск

```bash
cd backend
npm test
```

З покриттям:

```bash
npm run test:cov
```

## Що покривається

| Файл тесту | Перевіряє |
|------------|-----------|
| `unit/recommendation-score.spec.ts` | формула score, нормалізація відстані, рівні трафіку |
| `unit/haversine.spec.ts` | відстань між координатами (Haversine) |
| `unit/google-traffic-intensity.spec.ts` | перетворення відповіді Directions у рівень трафіку |
| `../src/common/health.controller.spec.ts` | статус API `ok` |

## Обмеження (для звіту з БКР)

- немає інтеграційних тестів з реальною БД;
- немає e2e-тестів HTTP API (Supertest) і тестів мобільного клієнта (Flutter);
- сценарії з JWT, nearby і маршрутом перевіряються вручну (Swagger, Postman, емулятор).

Ці обмеження навмисні для навчального прототипу й описані в розділі 1.7 пояснювальної записки.
