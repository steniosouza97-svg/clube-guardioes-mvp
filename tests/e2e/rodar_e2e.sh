#!/usr/bin/env bash
# Teste ponta a ponta da interface contra uma réplica local do Supabase:
# PostgreSQL + PostgREST (mesmo motor de API do Supabase) + login simulado.
# Requer: psql, postgrest (github.com/PostgREST/postgrest), python3 com playwright.
# Variáveis: PGHOST, PGPORT, PGUSER; POSTGREST (caminho do binário); CHROMIUM (opcional).
set -euo pipefail
cd "$(dirname "$0")/../.."
export DB=clube_e2e
psql -d postgres -qc "do \$\$ begin if not exists (select 1 from pg_roles where rolname='authenticator') then create role authenticator login password 'local' noinherit; end if; end \$\$; grant anon, authenticated to authenticator;"
dropdb --if-exists --force $DB && createdb $DB
for f in db/0*.sql; do psql -q -v ON_ERROR_STOP=1 -d $DB -f "$f" > /dev/null; done
psql -d $DB -qc "insert into voluntario (email, nome) values ('voluntario@example.com', 'Voluntária de Teste')"
export PGRST_DB_URI="postgres://authenticator:local@/$DB?host=${PGHOST:-/var/run/postgresql}&port=${PGPORT:-5432}"
"${POSTGREST:-postgrest}" tests/e2e/postgrest.conf > /tmp/postgrest_e2e.log 2>&1 & P1=$!
python3 tests/e2e/servidor.py & P2=$!
trap "kill $P1 $P2" EXIT
sleep 2
mkdir -p evidencias/e2e
python3 tests/e2e/e2e.py
