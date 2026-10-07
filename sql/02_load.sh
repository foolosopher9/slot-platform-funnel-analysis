#!/usr/bin/env bash
set -euo pipefail

# Move to project root regardless of where the script is invoked from
cd "$(dirname "$0")/.."

DB="${DB:-igaming}"

# --- Preflight checks ------------------------------------------------------

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found in PATH. Install PostgreSQL client tools." >&2
  exit 1
fi

for t in players sessions spins; do
  if [ ! -f "data/raw/$t.csv" ]; then
    echo "ERROR: data/raw/$t.csv not found." >&2
    echo "Download the dataset from Kaggle and place the CSVs under data/raw/." >&2
    exit 1
  fi
done

# --- 1. Create empty tables ------------------------------------------------

echo "[1/5] Creating schema (drop + create tables)..."
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/01a_schema.sql

# --- 2. Load data ----------------------------------------------------------

for t in players sessions spins; do
  echo "[2/5] Loading $t.csv..."
  psql -v ON_ERROR_STOP=1 -d "$DB" \
    -c "\copy $t FROM 'data/raw/$t.csv' WITH (FORMAT csv, HEADER true)"
done

# --- 3. Add primary/foreign keys + refresh stats ---------------------------

echo "[3/5] Adding constraints and running ANALYZE..."
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/01b_constraints.sql

# --- 4. Create analytical indexes ------------------------------------------

echo "[4/5] Creating indexes..."
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/04_indexes.sql

# --- 5. Verify row counts --------------------------------------------------

echo "[5/5] Verifying row counts..."
psql -d "$DB" -c "
SELECT 'players' AS table_name, count(*) AS rows FROM players
UNION ALL
SELECT 'sessions', count(*) FROM sessions
UNION ALL
SELECT 'spins',    count(*) FROM spins;
"

echo "Done. Database: $DB"
