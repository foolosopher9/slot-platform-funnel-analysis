# Анализ данных платформы онлайн-слотов

Портфолио-проект продуктового аналитика на синтетическом датасете [Online Slot Games - Players, Sessions & Spins](https://www.kaggle.com/datasets/monikamitrovic/online-slot-games-players-sessions-and-spins) (Kaggle, CC0): 8 000 игроков, 46 690 сессий и 4,6 млн спинов за 120 дней.

## Статус

| Глава | Содержание | Статус |
|---|---|---|
| [1. Данные](report/01_data.md) | Источник, структура, проверки качества, профиль данных, ограничения | Готова |
| 2. Постановка задачи | Цели исследования и исследовательские вопросы | В работе |

## Структура

```
report/
  01_data.md               глава 1: данные
  02_questions.md          глава 2: постановка задачи (в работе)
sql/
  01_schema.sql            таблицы (до загрузки)
  02_keys_indexes.sql      ключи и индексы (после загрузки)
  03_quality_checks.sql    проверки качества (раздел 1.3)
  04_profiling.sql         профиль данных (разделы 1.1 и 1.4)
scripts/
  load.sh                  сборка базы из CSV
data/raw/                  CSV с Kaggle (не хранятся в репозитории)
```

## Как воспроизвести

Нужен PostgreSQL с клиентскими утилитами (`psql`, `createdb`, `pg_isready`); сервер должен быть запущен.

1. Скачайте датасет с Kaggle и положите `players.csv`, `sessions.csv` и `spins.csv` в `data/raw/`.
2. Соберите базу:
   ```bash
   ./scripts/load.sh
   ```
   При первом запуске скрипт создаёт базу `igaming`, при повторных пересобирает таблицы с нуля. Другое имя базы: `DB=my_db ./scripts/load.sh`.
3. Получите цифры главы 1:
   ```bash
   psql -d igaming -f sql/03_quality_checks.sql
   psql -d igaming -f sql/04_profiling.sql
   ```
