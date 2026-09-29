#!/usr/bin/env bash
# Recria o banco de teste do zero, carrega tudo e roda as suítes de teste.
# Gera a evidência em evidencias/testes_local_AAAA-MM-DD_HHMM.log
#
# Uso: DB=clube_teste ./tests/rodar_testes.sh
# Requer psql e as variáveis PGHOST, PGPORT, PGUSER (e PGPASSWORD, se houver).
# No Supabase não é preciso este script: rode no SQL Editor
#   select * from qa.fn_rodar_testes();
#   select * from qa.fn_testes_seguranca();
set -euo pipefail
cd "$(dirname "$0")/.."
DB="${DB:-clube_teste}"
mkdir -p evidencias
LOG="evidencias/testes_local_$(date +%Y-%m-%d_%H%M).log"
Q="psql -q -v ON_ERROR_STOP=1 -d $DB"

{
  echo "== Clube Guardiões do Futuro | execução dos testes"
  echo "== data: $(date '+%d/%m/%Y %H:%M')  banco: $DB  servidor: PostgreSQL $(psql -d postgres -Atc 'show server_version')"
  dropdb --if-exists "$DB"
  createdb "$DB"
  for f in db/01_schema.sql db/02_funcoes.sql db/03_views.sql db/04_dados_referencia.sql db/05_dados_sinteticos.sql; do
    $Q -f "$f" > /dev/null
    echo "carregado: $f"
  done
  TEM_PAPEIS=$(psql -d "$DB" -Atc "select count(*) from pg_roles where rolname in ('anon','authenticated')")
  if [ "$TEM_PAPEIS" = "2" ]; then $Q -f db/06_supabase_seguranca.sql; echo "carregado: db/06_supabase_seguranca.sql"; fi
  $Q -f tests/qa_testes.sql; $Q -f tests/qa_seguranca.sql
  echo "== volumes carregados"
  psql -d "$DB" -Atc "select 'guardioes: '||count(*) from guardiao union all
                      select 'assinaturas ativas: '||count(*) from assinatura where status='ativa' union all
                      select 'cobrancas: '||count(*) from cobranca union all
                      select 'comunicacoes: '||count(*) from comunicacao union all
                      select 'eventos do gateway: '||count(*) from evento_gateway"
  echo "== testes do fluxo"
  psql -d "$DB" -Atc "select resultado from qa.fn_rodar_testes() order by ordem"
  if [ "$TEM_PAPEIS" = "2" ]; then
    echo "== testes de acesso"
    psql -d "$DB" -Atc "select resultado from qa.fn_testes_seguranca() order by ordem"
  fi
} 2>&1 | tee "$LOG"

if grep -q "^FALHA" "$LOG"; then echo "== RESULTADO: HÁ FALHAS"; exit 1; fi
echo "== RESULTADO: todos os testes passaram" | tee -a "$LOG"
echo "evidência gravada em $LOG"
