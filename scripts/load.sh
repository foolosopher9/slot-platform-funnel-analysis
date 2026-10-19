#!/usr/bin/env bash
set -euo pipefail

# Run from project root regardless of where the script is called from
cd "$(dirname "$0")/.."

DB="${DB:-igaming}"

# Check that psql and the CSV files are available
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

# Check that the PostgreSQL server is running
if ! pg_isready -q; then
  echo "ERROR: PostgreSQL server is not running. Start it and try again." >&2
  exit 1
fi

# Hide NOTICE messages such as "table does not exist, skipping"
export PGOPTIONS="-c client_min_messages=warning"

# Create the database on first run
if ! psql -d "$DB" -Atc "SELECT 1" >/dev/null 2>&1; then
  echo "Database $DB not found, creating..."
  createdb "$DB"
fi

# 1. Create empty tables
echo "[1/4] Creating tables..."
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/01_schema.sql

# 2. Load CSV files
for t in players sessions spins; do
  echo "[2/4] Loading $t.csv..."
  psql -v ON_ERROR_STOP=1 -d "$DB" \
    -c "\copy $t FROM 'data/raw/$t.csv' WITH (FORMAT csv, HEADER true)"
done

# 3. Add keys and indexes, refresh statistics
echo "[3/4] Adding keys and indexes..."
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f sql/02_keys_indexes.sql

# 4. Show row counts
echo "[4/4] Row counts:"
psql -d "$DB" -c "
SELECT 'players' AS table_name, COUNT(*) AS row_count FROM players
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'spins', COUNT(*) FROM spins;
"

echo "Done. Database: $DB"
