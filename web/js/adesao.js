// Jornada pública (persona Célia, protótipo da semana 5, evoluída em 29/09):
// Início → Seus dados → Pagamento Pix → Confirmação → Indique um novo Doador,
// para o Guardião (R$ 85/mês) e para a doação única (qualquer valor),
// e a Minha Área do Guardião (entrada por WhatsApp + CPF).
// Chama só funções liberadas ao visitante: fn_aderir_publico, fn_doar_unica,
// fn_confirmar_doacao_demo, fn_convite_nome, fn_area, fn_area_acao, fn_area_recibo.
(function () {
  const $ = s => document.querySelector(s);
  const $$ = s => document.querySelectorAll(s);
  const params = new URLSearchParams(location.search);
  const VALOR_GUARDIAO = 85;

  // Canal de origem (QR Code, Instagram...) para medir onde a captação rende mais
  const ORIGENS = {
    qr: "QR Code na comunidade", instagram: "Instagram", whatsapp: "WhatsApp",
    indicacao: "Indicação de Guardião", criancas: "Campanha Dia das Crianças",
    natal: "Campanha de Natal", site: "Site institucional"
  };
  const origem = ORIGENS[params.get("origem")] || "Site institucional";
  const convite = (params.get("convite") || "").trim().toLowerCase() || null;

  // Estado desta visita. Fica só na memória da página (nada em localStorage).
  let doacao = null;       // resultado da última doação feita nesta visita
  let sessao = null;       // { telefone, cpf } da Minha Área
  let area = null;         // dados da Minha Área

  // ---------- navegação entre telas ----------
  const TELAS = ["inicio", "cadastro", "pagamento", "erro-pix", "confirmacao", "convite", "entrar", "area", "recibo"];
  function ir(tela, empilhar = true) {
    if (!TELAS.includes(tela)) tela = "inicio";
    if (["pagamento", "erro-pix", "confirmacao", "convite"].includes(tela) && !doacao) tela = "cadastro";
    if (["area", "recibo"].includes(tela) && !area) tela = "entrar";
    $$("[data-tela]").forEach(el => { el.hidden = el.dataset.tela !== tela; });
    if (empilhar && location.hash !== "#" + tela) history.pushState(null, "", "#" + tela);
    window.scrollTo(0, 0);
    if (tela === "pagamento") montarPix();
    if (tela === "convite" || tela === "confirmacao") montarConvite();
    if (tela === "area") desenharArea();
    preencher();
  }
  document.addEventListener("click", ev => {
    const a = ev.target.closest("[data-ir]");
    if (!a) return;
    ev.preventDefault();
    if (a.dataset.tipo) escolherTipo(a.dataset.tipo);
    ir(a.dataset.ir);
  });
  window.addEventListener("popstate", () => ir(location.hash.slice(1) || "inicio", false));

  function preencher() {
    const tipo = doacao ? doacao.tipo : null;
    $$('[data-se="guardiao"]').forEach(el => { el.hidden = tipo !== "guardiao"; });
    $$('[data-se="unica"]').forEach(el => { el.hidden = tipo !== "unica"; });
    $$('[data-se="convidado"]').forEach(el => { el.hidden = !(doacao && doacao.convidado_por); });
    if (!doacao) return;
    $$("[data-campo]").forEach(el => {
      const v = { nome: doacao.primeiro_nome, "nome-completo": doacao.nome, valor: fmt.brl(doacao.valor),
                  dia: doacao.dia, convidado: doacao.convidado_por }[el.dataset.campo];
      el.textContent = v ?? "";
    });
  }
  if (!CLUBE_CONFIG.demonstracao) $$("[data-so-demo]").forEach(el => el.remove());

  // ---------- convite recebido: faixa "Você foi convidado por..." ----------
  if (convite) {
    sb.rpc("fn_convite_nome", { p_codigo: convite }).then(({ data }) => {
      const f = $("#faixa-convite");
      if (data) {
        f.innerHTML = `💌 <span><strong>${esc(data)}</strong> já ajuda as crianças do Jardim Ângela e convidou você. ` +
                      `Seja Guardião do Começo com R$ 85 por mês, ou faça uma doação única de qualquer valor.</span>`;
        f.hidden = false;
      }
    });
  }

  // ---------- 1. seus dados ----------
  const form = $("#form-adesao"), outro = $("#campo-outro"), res = $("#resultado"), btn = $("#btn-aderir"), campoCpf = $("#cpf");
  cpf.mascara(campoCpf);
  const mascaraTel = el => el.addEventListener("input", () => {
    const d = el.value.replace(/\D/g, "").slice(0, 11);
    el.value = d.length > 10 ? d.replace(/^(\d{2})(\d{5})(\d{0,4})$/, "($1) $2-$3")
             : d.replace(/^(\d{2})(\d{0,4})(\d{0,4})$/, (m, a, b, c) => `(${a}) ${b}${c ? "-" + c : ""}`);
  });
  const tel = $("#telefone");
  mascaraTel(tel);
  form.querySelectorAll("input[name=valor]").forEach(r =>
    r.addEventListener("change", () => { outro.hidden = r.value !== "outro" || !r.checked; }));

  function escolherTipo(tipo) {
    const r = form.querySelector(`input[name=tipo][value=${tipo}]`);
    if (r) { r.checked = true; atualizarTipo(); }
  }
  function tipoAtual() { return form.querySelector("input[name=tipo]:checked").value; }
  function atualizarTipo() {
    const unica = tipoAtual() === "unica";
    $("#bloco-valor-unica").hidden = !unica;
    $("#campo-dia").hidden = unica;
    btn.textContent = unica ? "Continuar para o Pix" : "Continuar para o pagamento";
  }
  form.querySelectorAll("input[name=tipo]").forEach(r => r.addEventListener("change", atualizarTipo));
  atualizarTipo();

  function mostrar(tipo, html) { res.innerHTML = `<div class="msg ${tipo}">${html}</div>`; }

  form.addEventListener("submit", async ev => {
    ev.preventDefault();
    const tipo = tipoAtual();
    let valor = VALOR_GUARDIAO;
    if (tipo === "unica") {
      const escolhido = form.querySelector("input[name=valor]:checked").value;
      valor = escolhido === "outro" ? Number($("#valor-outro").value) : Number(escolhido);
    }
    const nome = $("#nome").value.trim();
    const email = $("#email").value.trim();
    const telefone = tel.value.trim();
    const consent = $("#consent").checked;

    if (nome.length < 2) return mostrar("erro", "Informe seu nome.");
    if (tipo === "guardiao" && telefone.replace(/\D/g, "").length < 10)
      return mostrar("erro", "Informe seu WhatsApp com DDD: é por onde chega o Pix do mês.");
    if (!cpf.valido(campoCpf.value)) return mostrar("erro", "Confira o CPF informado.");
    if (email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return mostrar("erro", "Confira o e-mail informado.");
    if (!valor || valor < 10 || valor > 50000) return mostrar("erro", "Escolha um valor entre R$ 10 e R$ 50.000.");
    if (!consent) return mostrar("erro", "Para doar, é preciso autorizar o uso dos seus dados.");

    btn.disabled = true; const rotulo = btn.textContent; btn.textContent = "Registrando...";
    const comum = { p_nome: nome, p_email: email || null, p_cpf: cpf.digitos(campoCpf.value),
                    p_telefone: telefone || null, p_origem: origem, p_valor: valor, p_consentimento: consent, p_convite: convite };
    const { data, error } = tipo === "guardiao"
      ? await sb.rpc("fn_aderir_publico", { ...comum, p_dia: Number($("#dia").value) })
      : await sb.rpc("fn_doar_unica", comum);
    btn.disabled = false; btn.textContent = rotulo;
    if (error) return mostrar("erro", esc(mensagemErro(error)));

    doacao = { ...data, nome, tipo };
    // credenciais da Minha Área só na memória desta página, para "Ir para minha Área"
    sessao = tipo === "guardiao" ? { telefone, cpf: cpf.digitos(campoCpf.value) } : sessao;
    form.reset(); outro.hidden = true; res.innerHTML = ""; atualizarTipo();
    ir("pagamento");
  });

  // ---------- 2. pagamento Pix ----------
  // Em produção, QR Code e código copia e cola vêm da Asaas. Aqui, um código
  // ilustrativo com o valor, para a demonstração seguir o mesmo fluxo.
  function montarPix() {
    if (!doacao) return;
    const codigo = "00020126580014BR.GOV.BCB.PIX0136clube-guardioes-demonstracao52040000530398654"
      + String(Number(doacao.valor).toFixed(2)).padStart(6, "0") + "5802BR5920INSTITUTO EBENEZER6009SAO PAULO6304DEMO";
    $("#pix-codigo").textContent = codigo;
    $("#pix-qr").innerHTML = qrIlustrativo(codigo);
  }
  function qrIlustrativo(codigo) {
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
    return `<svg viewBox="-2 -2 ${n + 4} ${n + 4}" width="180" height="180" shape-rendering="crispEdges"><rect x="-2" y="-2" width="${n + 4}" height="${n + 4}" fill="#fff"/><g fill="#132313">${cel}</g></svg>`;
  }
  async function copiar(texto, botao, rotulo) {
    try { await navigator.clipboard.writeText(texto); } catch (e) { /* sem permissão: o texto segue visível para copiar à mão */ }
    const antes = botao.textContent; botao.textContent = rotulo; setTimeout(() => { botao.textContent = antes; }, 1600);
  }
  $("#btn-copiar-pix").addEventListener("click", ev => copiar($("#pix-codigo").textContent, ev.currentTarget, "Copiado!"));
  $("#btn-ja-paguei").addEventListener("click", async () => {
    // Doação única: na demonstração, "Já paguei" confirma (em produção, o webhook da Asaas)
    if (doacao.tipo === "unica" && CLUBE_CONFIG.demonstracao) {
      await sb.rpc("fn_confirmar_doacao_demo", { p_codigo: doacao.codigo_convite });
    }
    ir("confirmacao");
  });
  const falha = $("#btn-simular-falha"); if (falha) falha.addEventListener("click", () => ir("erro-pix"));

  // ---------- Indique um novo Doador ----------
  // Mensagem de impacto para quem é convidado: fala da causa, do valor do
  // Guardião e da doação única, com o link pessoal de quem convida.
  function linkConvite(codigo) {
    const base = location.origin + location.pathname.replace(/[^/]*$/, "");
    return `${base}index.html?convite=${encodeURIComponent(codigo)}`;
  }
  function mensagemConvite(link) {
    return "Oi! 💚 Eu apoio o Instituto Ebenézer, que cuida de 120 crianças no Jardim Ângela, em São Paulo, " +
      "com contraturno escolar, oficinas e acompanhamento terapêutico.\n\n" +
      "Com R$ 85 por mês você vira Guardião do Começo e recebe todo mês a prestação de contas do que a sua doação sustentou. " +
      "Se não puder ser mensal, uma doação única de qualquer valor já faz diferença.\n\n" +
      "\"Se mudarmos o começo da história, mudamos a história toda.\"\n\n" +
      "Doe pelo meu link: " + link;
  }
  const whats = texto => "https://wa.me/?text=" + encodeURIComponent(texto);
  function montarConvite() {
    if (!doacao) return;
    const link = linkConvite(doacao.codigo_convite), texto = mensagemConvite(link);
    $("#link-convite").textContent = link;
    $("#msg-convite").textContent = texto;
    $("#btn-whatsapp").href = whats(texto);
    $("#btn-indicar").href = whats(texto);
  }
  $("#btn-copiar-convite").addEventListener("click", ev => copiar($("#link-convite").textContent, ev.currentTarget, "Link copiado!"));

  // ---------- Minha Área ----------
  const formEntrar = $("#form-entrar"), msgEntrar = $("#msg-entrar");
  mascaraTel($("#lg-whats")); cpf.mascara($("#lg-cpf"));
  async function entrar(telefone, numeroCpf) {
    const { data, error } = await sb.rpc("fn_area", { p_telefone: telefone, p_cpf: cpf.digitos(numeroCpf) });
    if (error) { msgEntrar.innerHTML = `<div class="msg erro">${esc(mensagemErro(error))}</div>`; return false; }
    if (data.erro) { msgEntrar.innerHTML = `<div class="msg erro">${esc(data.erro)}</div>`; return false; }
    sessao = { telefone, cpf: cpf.digitos(numeroCpf) }; area = data; msgEntrar.innerHTML = "";
    ir("area");
    return true;
  }
  formEntrar.addEventListener("submit", async ev => {
    ev.preventDefault();
    const t = $("#lg-whats").value, c = $("#lg-cpf").value;
    if (t.replace(/\D/g, "").length < 10 || !cpf.valido(c))
      return (msgEntrar.innerHTML = `<div class="msg erro">Confira o WhatsApp (com DDD) e o CPF.</div>`);
    await entrar(t, c);
  });
  const demo = $("#btn-entrar-demo");
  if (demo) demo.addEventListener("click", () => {
    $("#lg-whats").value = CLUBE_CONFIG.guardiaoDemo.telefone; $("#lg-cpf").value = CLUBE_CONFIG.guardiaoDemo.cpf;
    entrar(CLUBE_CONFIG.guardiaoDemo.telefone, CLUBE_CONFIG.guardiaoDemo.cpf);
  });
  // "Ir para minha Área" logo depois de virar Guardião
  document.addEventListener("click", async ev => {
    const a = ev.target.closest('[data-ir="area"]');
    if (a && !area && sessao) { ev.stopImmediatePropagation(); ev.preventDefault(); await entrar(sessao.telefone, sessao.cpf); }
  }, true);
  $("#btn-sair-area").addEventListener("click", () => { sessao = null; area = null; formEntrar.reset(); ir("inicio"); });

  const NOME_STATUS = { ativa: "Ativa", pausada: "Pausada", atrasada: "Pix em atraso", cancelada: "Cancelada", sem_assinatura: "Sem doação mensal" };
  const NOME_COB = { pago: "Pago", recuperado: "Pago após lembrete", falhou: "Em atraso", pendente: "A vencer", cancelado: "Não cobrado" };

  function estrelas(n) {
    const cheias = Math.min(n, 5);
    return `<span class="estrelas" aria-label="${n} estrelas">${"★".repeat(cheias)}${"☆".repeat(5 - cheias)}</span>`;
  }
  function desenharArea() {
    if (!area) return;
    const d = area;
    $("#area-nome").textContent = d.primeiro_nome;
    const classe = { "Guardião Ouro": "ouro", "Guardião Prata": "prata", "Guardião Bronze": "bronze" }[d.nivel] || "inicial";
    $("#area-nivel").innerHTML = `
      <div class="medalha ${classe}" aria-hidden="true">${classe === "inicial" ? "🌱" : "🏅"}</div>
      <div><div class="nivel-nome">${esc(d.nivel)}</div>${estrelas(d.estrelas)}
        <p class="sub">${d.meses_pagos} ${d.meses_pagos === 1 ? "mês" : "meses"} de doação.
        ${d.status === "ativa" || d.status === "atrasada" ? `Faltam ${d.meses_para_proxima_estrela} para a próxima estrela.` : ""}</p>
        <p class="legenda-nivel">Uma estrela a cada 3 meses · 3 estrelas: Bronze · 4: Prata · 5: Ouro</p></div>`;

    const st = d.status;
    let acoes = "";
    if (st === "ativa" || st === "atrasada") acoes = `
        <div class="linha-pausa"><label for="meses-pausa">Precisa de um tempo?</label>
          <select id="meses-pausa"><option value="1">Pausar 1 mês</option><option value="2">Pausar 2 meses</option><option value="3">Pausar 3 meses</option></select>
          <button class="btn-contorno" type="button" id="btn-pausar">Pausar</button></div>
        <button class="link" type="button" id="btn-cancelar">Cancelar doação recorrente</button>`;
    if (st === "pausada") acoes = `<button class="btn-pilula" type="button" id="btn-retomar">Retomar agora</button>
        <button class="link" type="button" id="btn-cancelar">Cancelar doação recorrente</button>`;
    if (st === "cancelada") acoes = `<button class="btn-pilula" type="button" id="btn-reativar">Reativar como Guardião (R$ 85/mês)</button>`;
    $("#area-status").innerHTML = `
      <h2>Sua doação mensal</h2>
      <dl class="resumo">
        <div><dt>Situação</dt><dd><span class="selo-st ${st}">${NOME_STATUS[st] || st}</span></dd></div>
        ${d.valor ? `<div><dt>Valor</dt><dd>${fmt.brl(d.valor)} / mês</dd></div>` : ""}
        ${st === "pausada" ? `<div><dt>Volta em</dt><dd>${fmt.mesLongo(d.pausada_ate)}</dd></div>` : ""}
        ${d.proxima ? `<div><dt>Próximo Pix</dt><dd>${fmt.data(d.proxima)}</dd></div>` : ""}
        <div><dt>Guardião desde</dt><dd>${fmt.data(d.desde)}</dd></div>
        ${d.meio === "pix_direto" ? `<div><dt>Forma</dt><dd>Pix direto na conta do Instituto</dd></div>` : ""}
      </dl>
      <div class="acoes coluna">${acoes}</div>`;

    const at = $("#area-atraso");
    at.hidden = !d.atraso;
    if (d.atraso) at.innerHTML = `
      <div><strong>Seu Pix de ${fmt.mesLongo(d.atraso.competencia)} (${fmt.brl(d.atraso.valor)}) está em aberto.</strong>
      <p>Acontece. Regularize em um clique e siga com as crianças.</p></div>
      <button class="btn-pilula" type="button" id="btn-regularizar">Regularizar agora</button>`;

    const link = linkConvite(d.codigo_convite);
    $("#area-btn-indicar").href = whats(mensagemConvite(link));
    $("#area-indicacoes").textContent = d.indicacoes
      ? `Você já trouxe ${d.indicacoes} ${d.indicacoes === 1 ? "pessoa" : "pessoas"} para perto das crianças. Obrigado!`
      : "Mande uma mensagem pelo WhatsApp para quem você sabe que se importa.";

    $("#area-impacto").innerHTML = d.impacto.length
      ? d.impacto.map(i => `<li><strong>${fmt.mesLongo(i.competencia)}</strong><div>${esc(i.texto || "Notícia mensal de impacto enviada.").replace(/\n/g, "<br>")}</div></li>`).join("")
      : `<li class="vazio">A primeira notícia de impacto chega no fim do mês. 💚</li>`;
    $("#area-historico").innerHTML = d.historico.length
      ? `<thead><tr><th>Mês</th><th class="num">Valor</th><th>Situação</th></tr></thead><tbody>` +
        d.historico.map(h => `<tr><td>${fmt.mesLongo(h.competencia)}</td><td class="num">${fmt.brl(h.valor)}</td><td>${NOME_COB[h.status] || h.status}</td></tr>`).join("") + `</tbody>`
      : `<tbody><tr><td class="vazio">Seu primeiro Pix aparece aqui assim que for confirmado.</td></tr></tbody>`;
    $("#ano-recibo").textContent = new Date().getFullYear();

    const on = (sel, fn) => { const el = $(sel); if (el) el.addEventListener("click", fn); };
    on("#btn-pausar", () => acao("pausar", { p_meses: Number($("#meses-pausa").value) },
      m => `Doação pausada. Ela volta sozinha em ${fmt.mesLongo(m.pausada_ate)}.`));
    on("#btn-retomar", () => acao("retomar", {}, () => "Doação retomada. Obrigado por continuar!"));
    on("#btn-reativar", () => acao("reativar", {}, () => "Bem-vindo(a) de volta ao Clube!"));
    on("#btn-regularizar", () => acao("regularizar", {}, () => "Pix regularizado. Obrigado!"));
    on("#btn-cancelar", () => { $("#cr-motivo").value = ""; $("#dlg-cancelar").showModal(); });
  }
  $("#dlg-cancelar").addEventListener("close", () => {
    const v = $("#dlg-cancelar").returnValue;
    if (v === "cancelar") acao("cancelar", { p_motivo: $("#cr-motivo").value || null }, () => "Doação cancelada. Você pode reativar quando quiser.");
    if (v === "pausar") acao("pausar", { p_meses: 1 }, m => `Doação pausada por 1 mês. Volta em ${fmt.mesLongo(m.pausada_ate)}.`);
  });
  async function acao(nome, extra, texto) {
    const { data, error } = await sb.rpc("fn_area_acao", { p_telefone: sessao.telefone, p_cpf: sessao.cpf, p_acao: nome, ...extra });
    const msg = $("#msg-area");
    if (error || data.erro) { msg.innerHTML = `<div class="msg erro">${esc(error ? mensagemErro(error) : data.erro)}</div>`; return; }
    area = data; desenharArea();
    msg.innerHTML = `<div class="msg ok">${esc(texto(data))}</div>`;
    msg.scrollIntoView({ block: "nearest" });
  }

  // ---------- Recibo ----------
  $("#btn-recibo").addEventListener("click", async () => {
    const ano = new Date().getFullYear();
    const { data, error } = await sb.rpc("fn_area_recibo", { p_telefone: sessao.telefone, p_cpf: sessao.cpf, p_ano: ano });
    if (error || data.erro) return ($("#msg-area").innerHTML = `<div class="msg erro">${esc(error ? mensagemErro(error) : data.erro)}</div>`);
    $("#recibo-folha").innerHTML = `
      <div class="recibo-cab"><img src="img/logo-ebenezer.png" alt="" width="64" height="63">
        <div><strong>Instituto de Cultura e Lazer Ebenézer</strong><br>CNPJ 30.434.044/0001-90 · Jardim Ângela, São Paulo/SP</div></div>
      <h1>Recibo de doações ${data.ano}</h1>
      <p>Recebemos de <strong>${esc(data.nome)}</strong> as doações abaixo, feitas sem contrapartida, destinadas às atividades de atendimento às crianças do Instituto.</p>
      <table class="tabela-simples"><thead><tr><th>Data</th><th>Descrição</th><th class="num">Valor</th></tr></thead><tbody>
        ${data.itens.map(i => `<tr><td>${fmt.data(i.data)}</td><td>${esc(i.descricao)}</td><td class="num">${fmt.brl(i.valor)}</td></tr>`).join("") ||
          `<tr><td colspan="3" class="vazio">Nenhuma doação confirmada em ${data.ano}.</td></tr>`}
      </tbody><tfoot><tr><th colspan="2">Total</th><th class="num">${fmt.brl(data.total)}</th></tr></tfoot></table>
      <p class="nota-recibo">Doação direta a organização da sociedade civil, sem dedução de Imposto de Renda para pessoa física. Emitido em ${new Date().toLocaleDateString("pt-BR")}.</p>
      ${CLUBE_CONFIG.demonstracao ? `<p class="nota-recibo">Documento de demonstração, gerado com dados sintéticos.</p>` : ""}`;
    ir("recibo");
  });

  // tela inicial conforme o endereço (#cadastro etc.)
  ir(location.hash.slice(1) || "inicio", false);
})();
