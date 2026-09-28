// Funções compartilhadas pelas duas telas
(function () {
  const cfg = window.CLUBE_CONFIG;
  window.sb = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseKey);

  const brl = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
  const brl0 = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 });
  const int = new Intl.NumberFormat("pt-BR");
  const pct = new Intl.NumberFormat("pt-BR", { style: "percent", maximumFractionDigits: 1 });
  const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

  window.fmt = {
    brl: v => v == null ? "–" : brl.format(v),
    brl0: v => v == null ? "–" : brl0.format(v),
    int: v => v == null ? "–" : int.format(v),
    pct: v => v == null ? "–" : pct.format(v),
    // datas do banco chegam como "AAAA-MM-DD": formatar sem passar por fuso horário
    data: s => { if (!s) return "–"; const [a, m, d] = s.slice(0, 10).split("-"); return `${d}/${m}/${a}`; },
    dataHora: s => s ? new Date(s).toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" }) : "–",
    mes: s => { if (!s) return "–"; const [a, m] = s.split("-"); return `${MESES[+m - 1]}/${a.slice(2)}`; },
    mesLongo: s => { if (!s) return "–"; const [a, m] = s.split("-"); return `${MESES[+m - 1]}/${a}`; },
  };

  // Escapa texto antes de inserir em HTML (dados vêm de formulários públicos)
  window.esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  // CPF: mesma regra do banco (fn_cpf_valido), para avisar antes de enviar
  window.cpf = {
    digitos: v => String(v || "").replace(/\D/g, ""),
    valido: v => {
      const d = String(v || "").replace(/\D/g, "");
      if (!/^\d{11}$/.test(d) || /^(\d)\1{10}$/.test(d)) return false;
      const dv = n => { let s = 0; for (let i = 0; i < n; i++) s += +d[i] * (n + 1 - i); const r = s % 11; return r < 2 ? 0 : 11 - r; };
      return dv(9) === +d[9] && dv(10) === +d[10];
    },
    // formata enquanto digita: 000.000.000-00
    mascara: el => el.addEventListener("input", () => {
      const d = el.value.replace(/\D/g, "").slice(0, 11);
      el.value = d.replace(/^(\d{3})(\d)/, "$1.$2").replace(/^(\d{3})\.(\d{3})(\d)/, "$1.$2.$3").replace(/\.(\d{3})(\d{1,2})$/, ".$1-$2");
    })
  };

  // Traduz erros do banco para mensagens de gente
  window.mensagemErro = e => {
    const m = (e && (e.message || e.error_description || e.msg)) || String(e);
    if (/Consentimento LGPD/.test(m)) return "Para aderir, é preciso autorizar o uso dos seus dados.";
    if (/E-mail inválido/.test(m)) return "Confira o e-mail informado.";
    if (/CPF inválido/.test(m)) return "Confira o CPF informado.";
    if (/já possui assinatura ativa/.test(m)) return "Este CPF já é de um Guardião ativo. Obrigado!";
    if (/E-mail já cadastrado para outro CPF/.test(m)) return "Este e-mail já está cadastrado com outro CPF.";
    if (/Valor mensal/.test(m)) return "Escolha um valor mensal entre R$ 10 e R$ 5.000.";
    if (/Acesso restrito/.test(m)) return "Seu usuário não está cadastrado como voluntário do Clube.";
    if (/Invalid login credentials/.test(m)) return "E-mail ou senha incorretos.";
    if (/Failed to fetch|NetworkError/.test(m)) return "Sem conexão com o servidor. Verifique a internet e tente de novo.";
    return m;
  };

  if (cfg.demonstracao) {
    document.addEventListener("DOMContentLoaded", () => {
      const a = document.createElement("div");
      a.className = "aviso-demo";
      a.setAttribute("role", "note");
      a.textContent = "Ambiente de demonstração com dados sintéticos. Não use dados reais: e-mails devem terminar em @example.com.";
      document.body.prepend(a);
    });
  }
})();
