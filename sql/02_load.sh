#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DB="${DB:-igaming}"

psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/01_schema.sql

for t in players sessions spins; do
  psql -v ON_ERROR_STOP=1 -d "$DB" \
    -c "\copy $t FROM 'data/raw/$t.csv' WITH (FORMAT csv, HEADER true)"
done