// Jornada pública da doadora (persona Célia, protótipo da semana 5):
// Início → Seus dados → Pagamento Pix → Confirmação → Convite.
// Chama só as funções liberadas ao visitante: fn_aderir_publico e fn_convite_nome.
(function () {
  const $ = s => document.querySelector(s);
  const params = new URLSearchParams(location.search);

  // Canal de origem (QR Code, Instagram...) para medir onde a captação rende mais
  const ORIGENS = {
    qr: "QR Code na comunidade", instagram: "Instagram", whatsapp: "WhatsApp",
    indicacao: "Indicação de Guardião", criancas: "Campanha Dia das Crianças",
    natal: "Campanha de Natal", site: "Site institucional"
  };
  const origem = ORIGENS[params.get("origem")] || "Site institucional";
  const convite = (params.get("convite") || "").trim().toLowerCase() || null;

  // Estado da adesão desta visita (não sai do navegador; nada de CPF aqui)
  let adesao = null;

  // ---------- navegação entre telas ----------
  const TELAS = ["inicio", "cadastro", "pagamento", "erro-pix", "confirmacao", "convite"];
  function ir(tela, empilhar = true) {
    if (!TELAS.includes(tela)) tela = "inicio";
    // telas depois do cadastro exigem uma adesão feita nesta visita
    if (["pagamento", "erro-pix", "confirmacao", "convite"].includes(tela) && !adesao) tela = "cadastro";
    document.querySelectorAll("[data-tela]").forEach(el => { el.hidden = el.dataset.tela !== tela; });
    if (empilhar && location.hash !== "#" + tela) history.pushState(null, "", "#" + tela);
    window.scrollTo(0, 0);
    if (tela === "pagamento") montarPix();
    if (tela === "convite") montarConvite();
    preencher();
  }
  document.addEventListener("click", ev => {
    const a = ev.target.closest("[data-ir]");
    if (!a) return;
    ev.preventDefault();
    ir(a.dataset.ir);
  });
  window.addEventListener("popstate", () => ir(location.hash.slice(1) || "inicio", false));

  function preencher() {
    if (!adesao) return;
    document.querySelectorAll("[data-campo]").forEach(el => {
      const v = { nome: adesao.primeiro_nome, "nome-completo": adesao.nome, valor: fmt.brl(adesao.valor),
                  dia: adesao.dia, convidado: adesao.convidado_por }[el.dataset.campo];
      el.textContent = v ?? "";
    });
    document.querySelectorAll('[data-se="convidado"]').forEach(el => { el.hidden = !adesao.convidado_por; });
  }
  if (!CLUBE_CONFIG.demonstracao) document.querySelectorAll("[data-so-demo]").forEach(el => el.remove());

  // ---------- convite: faixa "Você foi convidado por..." ----------
  if (convite) {
    sb.rpc("fn_convite_nome", { p_codigo: convite }).then(({ data }) => {
      const f = $("#faixa-convite");
      if (data) { f.innerHTML = `💌 <span>Você foi convidado(a) por <strong>${esc(data)}</strong> para o Clube Guardiões do Começo</span>`; f.hidden = false; }
    });
  }

  // ---------- 1. seus dados ----------
  const form = $("#form-adesao"), outro = $("#campo-outro"), res = $("#resultado"), btn = $("#btn-aderir"), campoCpf = $("#cpf");
  cpf.mascara(campoCpf);
  const tel = $("#telefone");
  tel.addEventListener("input", () => {
    const d = tel.value.replace(/\D/g, "").slice(0, 11);
    tel.value = d.length > 10 ? d.replace(/^(\d{2})(\d{5})(\d{0,4})$/, "($1) $2-$3")
              : d.replace(/^(\d{2})(\d{0,4})(\d{0,4})$/, (m, a, b, c) => `(${a}) ${b}${c ? "-" + c : ""}`);
  });
  form.querySelectorAll("input[name=valor]").forEach(r =>
    r.addEventListener("change", () => { outro.hidden = r.value !== "outro" || !r.checked; }));

  function mostrar(tipo, html) { res.innerHTML = `<div class="msg ${tipo}">${html}</div>`; }

  form.addEventListener("submit", async ev => {
    ev.preventDefault();
    const escolhido = form.querySelector("input[name=valor]:checked").value;
    const valor = escolhido === "outro" ? Number($("#valor-outro").value) : Number(escolhido);
    const nome = $("#nome").value.trim();
    const email = $("#email").value.trim();
    const telefone = tel.value.trim();
    const consent = $("#consent").checked;

    if (nome.length < 2) return mostrar("erro", "Informe seu nome.");
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return mostrar("erro", "Confira o e-mail informado.");
    if (!cpf.valido(campoCpf.value)) return mostrar("erro", "Confira o CPF informado.");
    if (!valor || valor < 10 || valor > 5000) return mostrar("erro", "Escolha um valor mensal entre R$ 10 e R$ 5.000.");
    if (!consent) return mostrar("erro", "Para aderir, é preciso autorizar o uso dos seus dados.");

    btn.disabled = true; btn.textContent = "Registrando...";
    const { data, error } = await sb.rpc("fn_aderir_publico", {
      p_nome: nome, p_email: email, p_cpf: cpf.digitos(campoCpf.value), p_telefone: telefone || null, p_origem: origem,
      p_valor: valor, p_dia: Number($("#dia").value), p_consentimento: consent, p_convite: convite
    });
    btn.disabled = false; btn.textContent = "Continuar para o pagamento";
    if (error) return mostrar("erro", esc(mensagemErro(error)));

    adesao = { ...data, nome };
    form.reset(); outro.hidden = true; res.innerHTML = "";
    ir("pagamento");
  });

  // ---------- 2. pagamento Pix ----------
  // Em produção, QR Code e código copia e cola vêm da Asaas. Aqui, um código
  // ilustrativo com o valor, para a demonstração seguir o mesmo fluxo.
  function montarPix() {
    if (!adesao) return;
    const codigo = "00020126580014BR.GOV.BCB.PIX0136clube-guardioes-demonstracao52040000530398654"
      + String(Number(adesao.valor).toFixed(2)).padStart(6, "0") + "5802BR5920INSTITUTO EBENEZER6009SAO PAULO6304DEMO";
    $("#pix-codigo").textContent = codigo;
    // desenho do QR: padrão determinístico, só ilustrativo
    const n = 25; let h = 0; for (const c of codigo) h = (h * 31 + c.charCodeAt(0)) >>> 0;
    let cel = "";
    const olho = (x, y) => (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
    for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
      let on;
      if (olho(x, y)) { const ax = x < 7 ? x : x - (n - 7), ay = y < 7 ? y : y - (n - 7);
        on = ax === 0 || ax === 6 || ay === 0 || ay === 6 || (ax >= 2 && ax <= 4 && ay >= 2 && ay <= 4); }
      else { h = (h * 1103515245 + 12345) >>> 0; on = (h >>> 16) % 2 === 0; }
      if (on) cel += `<rect x="${x}" y="${y}" width="1" height="1"/>`;
    }
    $("#pix-qr").innerHTML = `<svg viewBox="-2 -2 ${n + 4} ${n + 4}" width="180" height="180" shape-rendering="crispEdges"><rect x="-2" y="-2" width="${n + 4}" height="${n + 4}" fill="#fff"/><g fill="#132313">${cel}</g></svg>`;
  }
  async function copiar(texto, botao, rotulo) {
    try { await navigator.clipboard.writeText(texto); } catch (e) { /* navegador sem permissão: o texto segue visível para copiar à mão */ }
    const antes = botao.textContent; botao.textContent = rotulo; setTimeout(() => { botao.textContent = antes; }, 1600);
  }
  $("#btn-copiar-pix").addEventListener("click", ev => copiar($("#pix-codigo").textContent, ev.currentTarget, "Copiado!"));
  $("#btn-ja-paguei").addEventListener("click", () => ir("confirmacao"));
  const falha = $("#btn-simular-falha"); if (falha) falha.addEventListener("click", () => ir("erro-pix"));

  // ---------- convite ----------
  function linkConvite() {
    const base = location.origin + location.pathname.replace(/[^/]*$/, "");
    return `${base}index.html?convite=${encodeURIComponent(adesao.codigo_convite)}`;
  }
  function montarConvite() {
    if (!adesao) return;
    const link = linkConvite();
    $("#link-convite").textContent = link;
    const texto = `Oi! Eu faço parte do Clube Guardiões do Começo, do Instituto Ebenézer, apoiando as crianças do Jardim Ângela com uma doação mensal via Pix. Topa conhecer? ${link}`;
    $("#btn-whatsapp").href = "https://wa.me/?text=" + encodeURIComponent(texto);
  }
  $("#btn-copiar-convite").addEventListener("click", ev => copiar(linkConvite(), ev.currentTarget, "Link copiado!"));

  // tela inicial conforme o endereço (#cadastro etc.)
  ir(location.hash.slice(1) || "inicio", false);
})();
