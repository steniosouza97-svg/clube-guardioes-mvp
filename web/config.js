// Configuração do projeto Supabase.
// A chave abaixo é a chave PÚBLICA (publishable/anon): pode ficar no navegador.
// Quem protege os dados são as regras do banco (db/06_supabase_seguranca.sql).
// NUNCA coloque aqui a chave service_role nem a chave de API da Asaas.
window.CLUBE_CONFIG = {
  supabaseUrl: "https://fakihzzncafuqtgxnqbi.supabase.co",
  supabaseKey: "sb_publishable_p9IqiIWRaOf3F4MV4hg4yw_ffvxzE3p",
  // true enquanto a base for de demonstração: mostra o aviso e o simulador do gateway
  demonstracao: true
};
