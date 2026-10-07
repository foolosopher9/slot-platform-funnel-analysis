#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DB="${DB:-igaming}"

for t in players sessions spins; do
  if [ ! -f "data/raw/$t.csv" ]; then
    echo "Ошибка: Файл data/raw/$t.csv не найден!"
    exit 1
  fi
done

psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/01_schema.sql

for t in players sessions spins; do
  echo "Загрузка $t.csv..."
  psql -v ON_ERROR_STOP=1 -d "$DB" \
    -c "\copy $t FROM 'data/raw/$t.csv' WITH (FORMAT csv, HEADER true)"
done