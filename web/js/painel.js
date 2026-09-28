// Painel do voluntário. Lê as views do banco e chama as funções do fluxo.
// Nenhuma regra de negócio mora aqui: a tela só exibe e aciona o banco.
(function () {
  const $ = s => document.querySelector(s);
  const DEMO = CLUBE_CONFIG.demonstracao;
  const estado = { guardioes: [], metricas: [], parametros: {}, origens: [] };

  // ------------------------------------------------------------ utilidades de tela
  function aviso(tipo, texto) {
    const el = $("#painel-msg");
    el.innerHTML = `<div class="msg ${tipo}">${esc(texto)}</div>`;
    if (tipo !== "erro") setTimeout(() => { if (el.textContent.includes(texto)) el.innerHTML = ""; }, 6000);
  }
  async function consulta(promessa) {
    const { data, error } = await promessa;
    if (error) { aviso("erro", mensagemErro(error)); throw error; }
    return data;
  }
  const selo = (classe, texto) => `<span class="selo ${esc(classe)}">${esc(texto)}</span>`;
  const NOME_SIT = { ativo: "Ativo", em_risco: "Em risco", cancelado: "Cancelado" };
  const NOME_COB = { pendente: "Pendente", pago: "Pago", falhou: "Falhou", recuperado: "Recuperado", cancelado: "Cancelado" };
  const NOME_COM = { boas_vindas: "Boas-vindas", agradecimento: "Agradecimento pelo Pix", recuperacao: "Lembrete de Pix em atraso",
                     impacto_mensal: "Notícia mensal de impacto", cancelamento: "Confirmação de cancelamento" };
  const whats = tel => { const d = String(tel || "").replace(/\D/g, ""); return d ? `https://wa.me/55${d}` : null; };
  const idEvento = () => "evt_painel_" + (crypto.randomUUID ? crypto.randomUUID().replace(/-/g, "") : Date.now());

  // Botão de ação destrutiva em dois cliques (sem janela de confirmação do navegador)
  function doisCliques(btn, rotuloConfirma, acao) {
    btn.addEventListener("click", async () => {
      if (btn.dataset.armado !== "1") {
        btn.dataset.armado = "1"; btn.dataset.orig = btn.textContent; btn.textContent = rotuloConfirma;
        setTimeout(() => { if (btn.dataset.armado === "1") { btn.dataset.armado = ""; btn.textContent = btn.dataset.orig; } }, 4000);
        return;
      }
      btn.dataset.armado = ""; btn.disabled = true;
      try { await acao(); } finally { btn.disabled = false; btn.textContent = btn.dataset.orig; }
    });
  }

  // ------------------------------------------------------------ gráfico de barras (SVG, série única)
  function grafico(el, dados, opcoes) {
    el.querySelectorAll("svg, .dica, table.sr-only").forEach(n => n.remove());
    const W = 560, H = 220, m = { t: 12, r: 8, b: 26, l: 52 };
    const iw = W - m.l - m.r, ih = H - m.t - m.b;
    const maxDado = Math.max(...dados.map(d => d.val), opcoes.meta ? opcoes.meta.val : 0) * 1.1 || 1;
    const passo = Math.pow(10, Math.floor(Math.log10(maxDado / 4)));
    const tick = [1, 2, 2.5, 5, 10].map(k => k * passo).find(t => maxDado / t <= 5);
    const topo = Math.ceil(maxDado / tick) * tick;
    const y = v => m.t + ih - (v / topo) * ih;
    const bw = iw / dados.length, larg = Math.max(4, Math.min(28, bw * .62));
    let s = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(opcoes.titulo)}">`;
    s += `<g class="grade eixo">`;
    for (let v = 0; v <= topo; v += tick) s += `<line x1="${m.l}" x2="${W - m.r}" y1="${y(v)}" y2="${y(v)}"/><text x="${m.l - 8}" y="${y(v) + 4}" text-anchor="end">${esc(opcoes.fmtEixo(v))}</text>`;
    s += `</g><g>`;
    dados.forEach((d, i) => {
      const x = m.l + bw * i + (bw - larg) / 2, h = Math.max(0, y(0) - y(d.val));
      // barra com topo arredondado de 4px e base reta no eixo
      const r = Math.min(4, larg / 2, h);
      s += `<path class="barra" data-i="${i}" d="M${x},${y(0)} V${y(d.val) + r} q0,-${r} ${r},-${r} H${x + larg - r} q${r},0 ${r},${r} V${y(0)} Z"/>`;
      s += `<rect data-i="${i}" x="${m.l + bw * i}" y="${m.t}" width="${bw}" height="${ih}" fill="transparent"/>`;
      if (i % Math.ceil(dados.length / 12) === 0) s += `<text class="eixo" x="${x + larg / 2}" y="${H - 8}" text-anchor="middle" fill="#6b7670" font-size="11">${esc(d.rot)}</text>`;
    });
    s += `</g>`;
    if (opcoes.meta) s += `<g class="meta"><line x1="${m.l}" x2="${W - m.r}" y1="${y(opcoes.meta.val)}" y2="${y(opcoes.meta.val)}"/><text x="${m.l + 6}" y="${y(opcoes.meta.val) - 6}" text-anchor="start">${esc(opcoes.meta.rot)}</text></g>`;
    s += `</svg>`;
    el.insertAdjacentHTML("beforeend", s);
    const dica = document.createElement("div"); dica.className = "dica"; el.appendChild(dica);
    const svg = el.querySelector("svg");
    svg.addEventListener("mousemove", ev => {
      const i = ev.target.dataset && ev.target.dataset.i; if (i === undefined) return;
      svg.querySelectorAll(".barra").forEach(b => b.classList.toggle("ativa", b.dataset.i === i));
      const caixa = el.getBoundingClientRect(), barra = svg.querySelector(`.barra[data-i="${i}"]`).getBoundingClientRect();
      dica.textContent = dados[i].dica; dica.style.left = (barra.left - caixa.left + barra.width / 2) + "px";
      dica.style.top = (barra.top - caixa.top) + "px"; dica.classList.add("vis");
    });
    svg.addEventListener("mouseleave", () => { dica.classList.remove("vis"); svg.querySelectorAll(".barra").forEach(b => b.classList.remove("ativa")); });
    // versão em tabela para leitores de tela
    el.insertAdjacentHTML("beforeend", `<table class="sr-only"><caption>${esc(opcoes.titulo)}</caption>${dados.map(d => `<tr><th>${esc(d.rot)}</th><td>${esc(d.dica)}</td></tr>`).join("")}</table>`);
  }

  // ------------------------------------------------------------ RESUMO
  async function carregarResumo() {
    const [resumo, metricas, params] = await Promise.all([
      consulta(sb.from("vw_painel_resumo").select("*").maybeSingle()),
      consulta(sb.from("vw_metricas_mensais").select("*").order("mes")),
      consulta(sb.from("parametro").select("chave,valor"))
    ]);
    estado.metricas = metricas;
    params.forEach(p => estado.parametros[p.chave] = Number(p.valor));
    const P = estado.parametros, r = resumo || {};
    const metaG = P.meta_guardioes || 100, metaR = P.meta_recorrencia_mensal || 20000;
    const custeioMes = (P.custeio_anual_2025 || 0) / 12;

    $("#resumo-ref").textContent = r.ultimo_mes_fechado
      ? `Último mês fechado: ${fmt.mesLongo(r.ultimo_mes_fechado)}${DEMO ? " · dados sintéticos de 12 meses de operação" : ""}` : "Ainda não há mês fechado.";

    const kpi = (rot, val, sub, progresso) => `<div class="kpi"><div class="rot">${esc(rot)}</div><div class="val">${esc(val)}</div>
      <div class="sub">${esc(sub)}</div>${progresso != null ? `<div class="barra-meta" role="progressbar" aria-valuenow="${Math.round(progresso * 100)}" aria-valuemin="0" aria-valuemax="100"><div style="width:${Math.min(100, progresso * 100)}%"></div></div>` : ""}</div>`;
    $("#kpis").innerHTML =
      kpi("Guardiões ativos", fmt.int(r.guardioes_ativos), `Meta: ${fmt.int(metaG)} (${fmt.pct((r.guardioes_ativos || 0) / metaG)})`, (r.guardioes_ativos || 0) / metaG) +
      kpi("Receita recorrente do mês", fmt.brl0(r.receita_recorrente_mes), `Meta mensal: ${fmt.brl0(metaR)}`, (r.receita_recorrente_mes || 0) / metaR) +
      kpi("Cobertura do custeio", fmt.pct(r.cobertura_custeio_2025), `Receita anualizada sobre o custeio realizado em 2025 (${fmt.brl0(P.custeio_anual_2025)})`, r.cobertura_custeio_2025) +
      kpi("Ticket médio", fmt.brl(r.ticket_medio), "Por Guardião pagante no mês") +
      kpi("Churn do mês", fmt.pct(r.churn_mes), "Cancelamentos sobre a base do início do mês. Plano: até 2%") +
      kpi("Em risco agora", fmt.int(r.guardioes_em_risco), "Com Pix vencido e não pago");

    const ult = metricas.slice(-13);
    grafico($("#graf-base"), ult.map(d => ({ rot: fmt.mes(d.mes), val: d.ativos_fim, dica: `${fmt.mesLongo(d.mes)}: ${fmt.int(d.ativos_fim)} Guardiões` })),
      { titulo: "Guardiões ativos no fim de cada mês", fmtEixo: v => fmt.int(v), meta: { val: metaG, rot: `meta ${metaG}` } });
    grafico($("#graf-receita"), ult.map(d => ({ rot: fmt.mes(d.mes), val: Number(d.receita), dica: `${fmt.mesLongo(d.mes)}: ${fmt.brl0(d.receita)}` })),
      { titulo: "Receita recorrente por mês", fmtEixo: v => v >= 1000 ? `R$ ${fmt.int(v / 1000)} mil` : fmt.brl0(v), meta: { val: custeioMes, rot: `custeio 2025: ${fmt.brl0(custeioMes)}/mês` } });

    $("#tab-metricas").innerHTML = `<thead><tr><th>Mês</th><th class="num">Início</th><th class="num">Novos</th><th class="num">Cancelados</th>
      <th class="num">Fim</th><th class="num">Receita</th><th class="num">Pagantes</th><th class="num">Recuperadas</th><th class="num">Em aberto</th>
      <th class="num">Ticket</th><th class="num">Churn</th></tr></thead><tbody>` +
      metricas.slice().reverse().map(d => `<tr><td>${fmt.mesLongo(d.mes)}</td><td class="num">${fmt.int(d.ativos_inicio)}</td><td class="num">${fmt.int(d.novos)}</td>
        <td class="num">${fmt.int(d.cancelados)}</td><td class="num">${fmt.int(d.ativos_fim)}</td><td class="num">${fmt.brl0(d.receita)}</td>
        <td class="num">${fmt.int(d.pagantes)}</td><td class="num">${fmt.int(d.recuperadas)}</td><td class="num">${fmt.int(d.em_aberto)}</td>
        <td class="num">${fmt.brl(d.ticket_medio)}</td><td class="num">${fmt.pct(d.churn)}</td></tr>`).join("") + `</tbody>`;
  }

  function exportarCSV() {
    const cols = ["mes", "ativos_inicio", "novos", "cancelados", "ativos_fim", "receita", "pagantes", "recuperadas", "em_aberto", "ticket_medio", "churn"];
    const num = v => v == null ? "" : String(v).replace(".", ",");
    const linhas = [cols.join(";")].concat(estado.metricas.map(d => cols.map(c => c === "mes" ? d.mes : num(d[c])).join(";")));
    const blob = new Blob(["﻿" + linhas.join("\r\n")], { type: "text/csv;charset=utf-8" });
    const a = document.createElement("a"); a.href = URL.createObjectURL(blob);
    a.download = `clube-guardioes-metricas-${new Date().toISOString().slice(0, 10)}.csv`; a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  }

  // ------------------------------------------------------------ ALERTA
  async function carregarAlerta() {
    const linhas = await consulta(sb.from("vw_alerta_churn").select("*"));
    const b = $("#badge-alerta"); b.hidden = !linhas.length; b.textContent = linhas.length;
    if (!linhas.length) { $("#tab-alerta").innerHTML = `<tbody><tr><td class="vazio">Nenhum Guardião em risco. Tudo em dia.</td></tr></tbody>`; return; }
    $("#tab-alerta").innerHTML = `<thead><tr><th>Prioridade</th><th>Guardião</th><th>Contato</th><th class="num">Valor</th><th>Mês</th>
      <th>Vencimento</th><th class="num">Tentativas</th></tr></thead><tbody>` +
      linhas.map(l => {
        const w = whats(l.telefone);
        const texto = encodeURIComponent(`Olá, ${l.nome.split(" ")[0]}! Aqui é do Instituto Ebenézer. Vimos que o Pix do Clube Guardiões de ${fmt.mesLongo(l.competencia)} ainda não foi pago. Posso te ajudar?`);
        return `<tr><td>${selo(l.prioridade, l.prioridade === "alta" ? "Alta" : "Média")}</td><td>${esc(l.nome)}</td>
          <td>${w ? `<a href="${w}?text=${texto}" target="_blank" rel="noopener">WhatsApp</a>` : "–"} · <a href="mailto:${esc(l.email)}">e-mail</a></td>
          <td class="num">${fmt.brl(l.valor_mensal)}</td><td>${fmt.mesLongo(l.competencia)}</td><td>${fmt.data(l.vencimento)}</td>
          <td class="num">${l.tentativas} de ${estado.parametros.tentativas_ate_cancelar || 3}</td></tr>`;
      }).join("") + `</tbody>`;
  }

  // ------------------------------------------------------------ GUARDIÕES
  async function carregarGuardioes() {
    estado.guardioes = await consulta(sb.from("vw_situacao_guardiao").select("*").order("nome").limit(5000));
    const sel = $("#filtro-origem"), atual = sel.value;
    sel.innerHTML = `<option value="">Todos</option>` + estado.origens.map(o => `<option>${esc(o)}</option>`).join("");
    sel.value = atual;
    desenharGuardioes();
  }
  function desenharGuardioes() {
    const q = $("#busca").value.trim().toLowerCase(), sit = $("#filtro-sit").value, org = $("#filtro-origem").value;
    const lista = estado.guardioes.filter(g => (!q || g.nome.toLowerCase().includes(q) || g.email.includes(q)) &&
      (!sit || g.situacao === sit) && (!org || g.origem === org));
    $("#contagem-guardioes").textContent = `${fmt.int(lista.length)} de ${fmt.int(estado.guardioes.length)} Guardiões`;
    const vis = lista.slice(0, 300);
    $("#tab-guardioes").innerHTML = `<thead><tr><th>Nome</th><th>Situação</th><th class="num">Valor mensal</th><th>Canal</th><th>Desde</th><th></th></tr></thead><tbody>` +
      (vis.length ? vis.map(g => `<tr><td><a href="#" data-detalhe="${g.guardiao_id}">${esc(g.nome)}</a><div class="ajuda">${esc(g.email)}</div></td>
        <td>${selo(g.situacao, NOME_SIT[g.situacao])}${g.motivo_cancelamento ? `<div class="ajuda">${g.motivo_cancelamento === "inadimplencia" ? "por inadimplência" : "a pedido"} em ${fmt.data(g.cancelada_em)}</div>` : ""}</td>
        <td class="num">${fmt.brl(g.valor_mensal)}</td><td>${esc(g.origem)}</td><td>${fmt.data(g.iniciada_em)}</td>
        <td>${g.status_assinatura === "ativa" ? `<button class="btn perigo peq" data-cancelar="${g.assinatura_id}">Cancelar</button>` : ""}</td></tr>`).join("")
        : `<tr><td colspan="6" class="vazio">Nenhum Guardião encontrado.</td></tr>`) +
      (lista.length > vis.length ? `<tr><td colspan="6" class="vazio">Mostrando os primeiros 300. Use a busca para refinar.</td></tr>` : "") + `</tbody>`;
    document.querySelectorAll("[data-cancelar]").forEach(b => doisCliques(b, "Confirmar cancelamento", async () => {
      await consulta(sb.rpc("fn_cancelar", { p_assinatura: b.dataset.cancelar, p_motivo: "voluntario" }));
      aviso("ok", "Assinatura cancelada a pedido do Guardião. A mensagem de confirmação foi registrada.");
      await Promise.all([carregarGuardioes(), carregarResumo(), carregarAlerta()]);
    }));
  }

  async function detalheGuardiao(id) {
    const g = estado.guardioes.find(x => x.guardiao_id === id); if (!g) return;
    $("#dlg-g-titulo").textContent = g.nome;
    $("#dlg-g-corpo").innerHTML = `<p class="vazio">Carregando...</p>`;
    $("#dlg-guardiao").showModal();
    const assin = await consulta(sb.from("assinatura").select("id,valor_mensal,dia_vencimento,status,iniciada_em,cancelada_em,motivo_cancelamento").eq("guardiao_id", id).order("iniciada_em"));
    const [cobs, coms] = await Promise.all([
      consulta(sb.from("cobranca").select("competencia,valor,vencimento,status,tentativas,pago_em").in("assinatura_id", assin.map(a => a.id)).order("competencia", { ascending: false })),
      consulta(sb.from("comunicacao").select("tipo,canal,enviada_em,competencia").eq("guardiao_id", id).order("enviada_em", { ascending: false }))
    ]);
    const pago = cobs.filter(c => ["pago", "recuperado"].includes(c.status)).reduce((s, c) => s + Number(c.valor), 0);
    $("#dlg-g-corpo").innerHTML = `
      <p style="margin-top:0">${selo(g.situacao, NOME_SIT[g.situacao])} · ${esc(g.email)} · ${esc(g.telefone || "sem telefone")} · canal: ${esc(g.origem)}</p>
      <div class="kpis"><div class="kpi"><div class="rot">Total doado</div><div class="val">${fmt.brl0(pago)}</div></div>
        <div class="kpi"><div class="rot">Pix pagos</div><div class="val">${cobs.filter(c => ["pago", "recuperado"].includes(c.status)).length}</div></div>
        <div class="kpi"><div class="rot">Assinaturas</div><div class="val">${assin.length}</div><div class="sub">${assin.map(a => `${fmt.brl(a.valor_mensal)} desde ${fmt.data(a.iniciada_em)}`).join("<br>")}</div></div></div>
      <h3 style="font-size:.95rem">Cobranças</h3>
      <div class="tabela-wrap"><table><thead><tr><th>Mês</th><th>Vencimento</th><th class="num">Valor</th><th>Status</th><th>Pago em</th></tr></thead><tbody>
        ${cobs.map(c => `<tr><td>${fmt.mesLongo(c.competencia)}</td><td>${fmt.data(c.vencimento)}</td><td class="num">${fmt.brl(c.valor)}</td>
          <td>${selo(c.status, NOME_COB[c.status])}${c.tentativas ? ` <span class="ajuda">${c.tentativas} tentativa(s)</span>` : ""}</td><td>${fmt.dataHora(c.pago_em)}</td></tr>`).join("") || `<tr><td colspan="5" class="vazio">Sem cobranças ainda.</td></tr>`}
      </tbody></table></div>
      <h3 style="font-size:.95rem;margin-top:1rem">Régua de relacionamento</h3>
      <ul class="linha-tempo">${coms.map(m => `<li><time>${fmt.dataHora(m.enviada_em)}</time><span>${esc(NOME_COM[m.tipo] || m.tipo)}${m.competencia ? ` · ${fmt.mesLongo(m.competencia)}` : ""} <span class="ajuda">(${esc(m.canal)})</span></span></li>`).join("")}</ul>`;
  }

  async function registrarAdesao(ev) {
    ev.preventDefault();
    const msg = $("#a-msg");
    const { error } = await sb.rpc("fn_aderir_publico", {
      p_nome: $("#a-nome").value.trim(), p_email: $("#a-email").value.trim(), p_telefone: $("#a-tel").value.trim() || null,
      p_origem: $("#a-origem").value, p_valor: Number($("#a-valor").value), p_dia: Number($("#a-dia").value), p_consentimento: $("#a-consent").checked
    });
    if (error) { msg.innerHTML = `<div class="msg erro">${esc(mensagemErro(error))}</div>`; return; }
    msg.innerHTML = ""; ev.target.reset(); $("#dlg-adesao").close();
    aviso("ok", "Adesão registrada. Mensagem de boas-vindas enviada.");
    await Promise.all([carregarGuardioes(), carregarResumo(), carregarCanais()]);
  }

  // ------------------------------------------------------------ CANAIS
  async function carregarCanais() {
    const linhas = await consulta(sb.from("vw_origem_resultado").select("*"));
    estado.origens = linhas.map(l => l.origem).sort((a, b) => a.localeCompare(b, "pt-BR"));
    $("#a-origem").innerHTML = estado.origens.map(o => `<option ${o === "QR Code na comunidade" ? "selected" : ""}>${esc(o)}</option>`).join("");
    const tot = linhas.reduce((s, l) => s + Number(l.ativos), 0) || 1;
    $("#tab-canais").innerHTML = `<thead><tr><th>Canal</th><th class="num">Guardiões captados</th><th class="num">Ainda ativos</th>
      <th class="num">Retenção</th><th class="num">Receita mensal ativa</th><th class="num">Participação na base</th></tr></thead><tbody>` +
      linhas.map(l => `<tr><td>${esc(l.origem)}</td><td class="num">${fmt.int(l.guardioes)}</td><td class="num">${fmt.int(l.ativos)}</td>
        <td class="num">${l.guardioes ? fmt.pct(l.ativos / l.guardioes) : "–"}</td><td class="num">${fmt.brl0(l.receita_mensal_ativa)}</td>
        <td class="num">${fmt.pct(l.ativos / tot)}</td></tr>`).join("") + `</tbody>`;
  }

  // ------------------------------------------------------------ OPERAÇÃO DO MÊS
  const competencia = () => $("#competencia").value + "-01";
  let versaoMes = 0;   // só a consulta mais recente desenha a tabela
  async function carregarMes() {
    const minha = ++versaoMes;
    const comp = competencia();
    let q = sb.from("vw_cobrancas_mes").select("*").eq("competencia", comp).order("vencimento").order("nome").limit(5000);
    if ($("#filtro-cob").value) q = q.eq("status", $("#filtro-cob").value);
    const [linhas, todas] = await Promise.all([consulta(q), consulta(sb.from("vw_cobrancas_mes").select("status,valor").eq("competencia", comp).limit(5000))]);
    if (minha !== versaoMes) return;
    const soma = st => todas.filter(c => st.includes(c.status)).reduce((s, c) => s + Number(c.valor), 0);
    const cont = st => todas.filter(c => st.includes(c.status)).length;
    $("#kpis-mes").innerHTML = [
      ["Cobranças do mês", fmt.int(todas.length), `Previsto: ${fmt.brl0(soma(["pendente", "pago", "falhou", "recuperado"]))}`],
      ["Pagas", fmt.int(cont(["pago", "recuperado"])), `Recebido: ${fmt.brl0(soma(["pago", "recuperado"]))}`],
      ["Recuperadas", fmt.int(cont(["recuperado"])), "Pagas depois do lembrete"],
      ["Em aberto", fmt.int(cont(["pendente", "falhou"])), `${fmt.int(cont(["falhou"]))} com atraso`]
    ].map(([r, v, s]) => `<div class="kpi"><div class="rot">${r}</div><div class="val">${v}</div><div class="sub">${s}</div></div>`).join("");
    if (!linhas.length) {
      $("#tab-cobrancas").innerHTML = `<tbody><tr><td class="vazio">${todas.length ? "Nenhuma cobrança com esse status." : "Nenhuma cobrança neste mês. Use o passo 1 para gerar."}</td></tr></tbody>`;
      return;
    }
    $("#tab-cobrancas").innerHTML = `<thead><tr><th>Guardião</th><th>Vencimento</th><th class="num">Valor</th><th>Status</th><th>Pago em</th>${DEMO ? "<th>Simular aviso da Asaas</th>" : ""}</tr></thead><tbody>` +
      linhas.map(c => `<tr><td>${esc(c.nome)}</td><td>${fmt.data(c.vencimento)}</td><td class="num">${fmt.brl(c.valor)}</td>
        <td>${selo(c.status, NOME_COB[c.status])}${c.tentativas ? ` <span class="ajuda">${c.tentativas} tentativa(s)</span>` : ""}${c.status_assinatura === "cancelada" ? ` <span class="ajuda">assinatura encerrada</span>` : ""}</td><td>${fmt.dataHora(c.pago_em)}</td>
        ${DEMO ? `<td>${["pendente", "falhou"].includes(c.status) && c.status_assinatura === "ativa" ? `<button class="btn sec peq" data-evento="PAYMENT_RECEIVED" data-cob="${c.cobranca_id}">Pix pago</button>
          <button class="btn perigo peq" data-evento="PAYMENT_OVERDUE" data-cob="${c.cobranca_id}">Pix vencido</button>` : ""}</td>` : ""}</tr>`).join("") + `</tbody>`;
    document.querySelectorAll("[data-evento]").forEach(b => b.addEventListener("click", async () => {
      b.disabled = true;
      const r = await consulta(sb.rpc("fn_processar_evento", { p_id_evento: idEvento(), p_cobranca: b.dataset.cob, p_tipo: b.dataset.evento }));
      const txt = { pago: "Pagamento registrado e agradecimento enviado.", recuperado: "Pagamento recuperado e agradecimento enviado.",
        falhou: "Atraso registrado e lembrete enviado. O Guardião entrou no alerta de churn.",
        cancelado_por_inadimplencia: "Terceira falha seguida: assinatura cancelada por inadimplência." }[r] || `Resultado: ${r}`;
      aviso(r === "cancelado_por_inadimplencia" ? "info" : "ok", txt);
      await Promise.all([carregarMes(), carregarAlerta(), carregarResumo()]);
    }));
  }

  async function acaoMes(btn, rpc, args, texto) {
    btn.disabled = true;
    try {
      const r = await consulta(sb.rpc(rpc, args));
      aviso("ok", texto(r));
      await Promise.all([carregarMes(), carregarAlerta(), carregarResumo(), carregarGuardioes()]);
    } finally { btn.disabled = false; }
  }

  // ------------------------------------------------------------ navegação e sessão
  function abrirAba(nome) {
    document.querySelectorAll("[role=tab]").forEach(b => b.setAttribute("aria-selected", String(b.dataset.aba === nome)));
    document.querySelectorAll(".aba").forEach(s => s.hidden = s.id !== `aba-${nome}`);
    history.replaceState(null, "", `#${nome}`);
  }

  async function iniciarPainel(sessao) {
    const { data: ok, error } = await sb.rpc("eh_voluntario");
    if (error || !ok) {
      await sb.auth.signOut();
      mostrarLogin("Seu usuário não está cadastrado como voluntário do Clube. Fale com a coordenação do Instituto.");
      return;
    }
    $("#tela-login").hidden = true; $("#tela-painel").hidden = false;
    $("#quem-email").textContent = sessao.user.email;
    if (!DEMO) $("#acao-simular").hidden = true;
    const ult = (await consulta(sb.from("cobranca").select("competencia").order("competencia", { ascending: false }).limit(1)))[0];
    const hoje = new Date().toISOString().slice(0, 7);
    let padrao = hoje;
    // Na demonstração, abre no mês seguinte ao último com cobranças, para simular um novo mês de operação
    if (DEMO && ult) { const [a, m] = ult.competencia.split("-").map(Number); padrao = m === 12 ? `${a + 1}-01` : `${a}-${String(m + 1).padStart(2, "0")}`; }
    $("#competencia").value = padrao;
    await carregarCanais();
    await Promise.all([carregarResumo(), carregarAlerta(), carregarGuardioes(), carregarMes()]);
    abrirAba((location.hash || "#resumo").slice(1).replace(/[^a-z]/g, "") || "resumo");
  }

  function mostrarLogin(msg) {
    $("#tela-painel").hidden = true; $("#tela-login").hidden = false;
    $("#login-msg").innerHTML = msg ? `<div class="msg erro">${esc(msg)}</div>` : "";
  }

  document.addEventListener("DOMContentLoaded", async () => {
    document.querySelectorAll("[role=tab]").forEach(b => b.addEventListener("click", () => abrirAba(b.dataset.aba)));
    document.querySelectorAll("[data-fechar]").forEach(b => b.addEventListener("click", () => b.closest("dialog").close()));
    $("#btn-exportar").addEventListener("click", exportarCSV);
    ["#busca", "#filtro-sit", "#filtro-origem"].forEach(s => $(s).addEventListener("input", desenharGuardioes));
    $("#tab-guardioes").addEventListener("click", ev => { const a = ev.target.closest("[data-detalhe]"); if (a) { ev.preventDefault(); detalheGuardiao(a.dataset.detalhe); } });
    $("#btn-nova-adesao").addEventListener("click", () => $("#dlg-adesao").showModal());
    $("#form-adesao-painel").addEventListener("submit", registrarAdesao);
    $("#competencia").addEventListener("change", carregarMes);
    $("#filtro-cob").addEventListener("change", carregarMes);
    $("#btn-gerar").addEventListener("click", ev => acaoMes(ev.currentTarget, "fn_gerar_cobrancas", { p_competencia: competencia() },
      n => n ? `${fmt.int(n)} cobranças geradas para ${fmt.mesLongo(competencia())}.` : "As cobranças deste mês já existiam. Nada foi duplicado."));
    $("#btn-simular").addEventListener("click", ev => acaoMes(ev.currentTarget, "fn_simular_gateway", { p_competencia: competencia() },
      r => { const t = Object.entries(r || {}); return t.length ? "Avisos da Asaas processados: " + t.map(([k, v]) => `${v} ${{ pago: "pagos", recuperado: "recuperados", falhou: "em atraso", cancelado_por_inadimplencia: "cancelados por inadimplência" }[k] || k}`).join(", ") + "." : "Não havia cobranças em aberto neste mês."; }));
    $("#btn-impacto").addEventListener("click", ev => acaoMes(ev.currentTarget, "fn_enviar_impacto_mensal", { p_competencia: competencia() },
      n => n ? `Notícia de ${fmt.mesLongo(competencia())} enviada a ${fmt.int(n)} Guardiões.` : "A notícia deste mês já tinha sido enviada. Ninguém recebeu duas vezes."));
    $("#btn-sair").addEventListener("click", async () => { await sb.auth.signOut(); mostrarLogin(); });

    $("#form-login").addEventListener("submit", async ev => {
      ev.preventDefault();
      const { data, error } = await sb.auth.signInWithPassword({ email: $("#login-email").value.trim(), password: $("#login-senha").value });
      if (error) return mostrarLogin(mensagemErro(error));
      await iniciarPainel(data.session);
    });

    const { data } = await sb.auth.getSession();
    if (data.session) await iniciarPainel(data.session); else mostrarLogin();
  });
})();
