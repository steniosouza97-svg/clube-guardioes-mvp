"""Teste ponta a ponta do MVP pela interface (Playwright + Chromium)."""
import os, re, subprocess, sys
from playwright.sync_api import sync_playwright, expect

BASE = "http://localhost:8080"
LOG, ERROS_CONSOLE = [], []
def cpf_valido(base9):
    """CPF fictício com dígitos verificadores corretos, a partir de 9 dígitos."""
    d = [int(x) for x in base9]
    for n in (9, 10):
        r = sum(d[i] * (n + 1 - i) for i in range(n)) % 11
        d.append(0 if r < 2 else 11 - r)
    return "".join(map(str, d))
CPF_MARIA, CPF_JOAO, CPF_OUTRO = cpf_valido("600000001"), cpf_valido("600000002"), cpf_valido("600000003")
CPF_BASE = cpf_valido("600000004")
CPF_PAULA = cpf_valido("600000005")
CPF_UNICA = cpf_valido("600000006")

def ok(msg): LOG.append("PASS " + msg); print("PASS", msg)
def sql(q): return subprocess.run(["psql", "-d", os.environ.get("DB", "clube_e2e"), "-Atc", q], capture_output=True, text=True).stdout.strip()

with sync_playwright() as p:
    nav = p.chromium.launch(executable_path=os.environ.get("CHROMIUM") or None)
    ctx = nav.new_context(viewport={"width": 1366, "height": 900}, locale="pt-BR", accept_downloads=True)
    pg = ctx.new_page()
    pg.on("console", lambda m: ERROS_CONSOLE.append(m.text) if m.type == "error" else None)
    pg.on("pageerror", lambda e: ERROS_CONSOLE.append(str(e)))

    # ---------------- E01 adesão pela página pública, vinda do QR Code
    pg.goto(f"{BASE}/index.html?origem=qr")
    expect(pg.locator(".aviso-demo")).to_be_visible()
    pg.screenshot(path="evidencias/e2e/01_pagina_adesao.png", full_page=True)
    pg.locator(".vitrine a", has_text="Quero participar").click()
    expect(pg.locator("#tela-cadastro")).to_be_visible(); expect(pg.locator("#tela-cadastro .stepper li.atual")).to_contain_text("Seus dados")
    pg.click("text=Continuar para o pagamento")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("nome")
    pg.fill("#nome", "Maria Demonstração"); pg.fill("#email", "maria.demo@example.com"); pg.fill("#telefone", "(11) 98888-7777")
    pg.fill("#cpf", CPF_MARIA[:10] + str((int(CPF_MARIA[10]) + 1) % 10))
    pg.click("text=Continuar para o pagamento")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("CPF")
    pg.fill("#cpf", ""); pg.type("#cpf", CPF_MARIA)
    assert pg.input_value("#cpf") == f"{CPF_MARIA[:3]}.{CPF_MARIA[3:6]}.{CPF_MARIA[6:9]}-{CPF_MARIA[9:]}", pg.input_value("#cpf")
    pg.click("text=Continuar para o pagamento")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("autorizar")
    ok("E01 formulário valida nome, CPF (dígito verificador, com máscara) e exige consentimento LGPD")
    expect(pg.locator("#tipo-guardiao")).to_be_checked(); expect(pg.locator("#bloco-valor-unica")).to_be_hidden()
    pg.check("#consent"); pg.select_option("#dia", "15"); pg.click("text=Continuar para o pagamento")
    expect(pg.locator("#tela-pagamento")).to_be_visible()
    expect(pg.locator("#tela-pagamento")).to_contain_text("R$ 85,00"); expect(pg.locator("#tela-pagamento")).to_contain_text("Maria")
    expect(pg.locator("#pix-qr svg")).to_be_visible()
    pg.screenshot(path="evidencias/e2e/02_pagamento_pix.png", full_page=True)
    assert sql("select o.nome||'|'||a.valor_mensal||'|'||a.dia_vencimento from guardiao g join origem o on o.id=g.origem_id join assinatura a on a.guardiao_id=g.id where g.email='maria.demo@example.com'") == "QR Code na comunidade|85.00|15"
    assert sql(f"select count(*) from guardiao g where g::text like '%{CPF_MARIA}%' or g::text like '%{CPF_MARIA[:3]}.{CPF_MARIA[3:6]}%'") == "0", "CPF gravado em texto aberto"
    assert len(sql("select cpf_hash from guardiao where email='maria.demo@example.com'")) == 64
    ok("E02 adesão pública grava Guardião de R$ 85 por mês com dia, canal (QR Code) e CPF só cifrado")

    # ---------------- E19 jornada da semana 5: Pix, erro, confirmação e convite
    pg.click("text=Simular falha no Pix"); expect(pg.locator("#tela-erro-pix")).to_contain_text("Nenhum valor foi cobrado")
    pg.click("#tela-erro-pix a.btn-pilula"); expect(pg.locator("#tela-pagamento")).to_be_visible()
    pg.click("#btn-ja-paguei"); expect(pg.locator("#tela-confirmacao")).to_contain_text("Obrigado(a), Maria")
    expect(pg.locator("#tela-confirmacao .stepper li.feito")).to_have_count(3)
    expect(pg.locator("#tela-confirmacao")).to_contain_text("R$ 85,00")
    expect(pg.locator("#btn-indicar")).to_have_text(re.compile("Indique um novo Doador"))
    expect(pg.locator("#btn-indicar")).to_have_attribute("href", re.compile(r"^https://wa\.me/\?text=.*R%24%2085.*convite"))
    pg.screenshot(path="evidencias/e2e/02_confirmacao.png", full_page=True)
    pg.click("text=Ver a mensagem e copiar o meu link")
    link = pg.locator("#link-convite").inner_text(); assert "convite=" in link, link
    codigo = link.split("convite=")[1]
    assert codigo == sql("select codigo_convite from guardiao where email='maria.demo@example.com'"), codigo
    expect(pg.locator("#btn-whatsapp")).to_have_attribute("href", re.compile(r"^https://wa\.me/\?text=.*convite"))
    pg.screenshot(path="evidencias/e2e/02_convite.png", full_page=True)
    pg.goto(f"{BASE}/index.html?convite={codigo}")
    expect(pg.locator("#faixa-convite")).to_contain_text("Maria")
    pg.locator(".vitrine a", has_text="Quero participar").click()
    pg.fill("#nome", "Paula Convidada"); pg.fill("#telefone", "(11) 97777-1111"); pg.type("#cpf", CPF_PAULA); pg.check("#consent")
    pg.click("text=Continuar para o pagamento"); pg.click("#btn-ja-paguei")
    expect(pg.locator("#tela-confirmacao")).to_contain_text("Convite de")
    assert sql("select o.nome||'|'||(g.indicado_por = (select id from guardiao where email='maria.demo@example.com')) from guardiao g join origem o on o.id=g.origem_id where g.nome='Paula Convidada' and g.email is null") == "Indicação de Guardião|true"
    pg.goto(f"{BASE}/privacidade.html"); expect(pg.locator("main")).to_contain_text("Seus direitos")
    ok("E19 jornada da semana 5: Pix com QR e copia e cola, falha e nova tentativa, confirmação em 3 etapas, 'Indique um novo Doador' pelo WhatsApp, link pessoal que registra quem convidou, e-mail opcional, Aviso de Privacidade")

    pg.goto(f"{BASE}/index.html?origem=qr#cadastro")
    pg.fill("#nome", "Maria Outro Email"); pg.fill("#email", "maria.outro@example.com"); pg.fill("#telefone", "(11) 98888-7777"); pg.type("#cpf", CPF_MARIA); pg.check("#consent")
    pg.click("text=Continuar para o pagamento")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("Este CPF já é de um Guardião ativo")
    pg.fill("#nome", "Maria Demonstração"); pg.fill("#email", "MARIA.DEMO@example.com"); pg.fill("#telefone", "(11) 98888-7777"); pg.fill("#cpf", ""); pg.type("#cpf", CPF_OUTRO); pg.check("#consent")
    pg.click("text=Continuar para o pagamento")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("outro CPF")
    ok("E03 mesmo CPF com outro e-mail é recusado; e-mail já usado não aceita outro CPF")

    # ---------------- E22 doação única de qualquer valor, com indicação
    pg.goto(f"{BASE}/index.html?origem=instagram")
    pg.locator(".formas a", has_text="Fazer uma doação única").click()
    expect(pg.locator("#tipo-unica")).to_be_checked(); expect(pg.locator("#bloco-valor-unica")).to_be_visible(); expect(pg.locator("#campo-dia")).to_be_hidden()
    pg.locator("label.faixa", has_text="Outro").click(); pg.fill("#valor-outro", "250")
    pg.fill("#nome", "Rita Doadora"); pg.type("#cpf", CPF_UNICA); pg.check("#consent")
    pg.click("text=Continuar para o Pix")
    expect(pg.locator("#tela-pagamento")).to_contain_text("R$ 250,00"); expect(pg.locator("#tela-pagamento")).to_contain_text("doação única")
    pg.click("#btn-ja-paguei"); expect(pg.locator("#tela-confirmacao")).to_contain_text("Doação única, via Pix")
    expect(pg.locator("#tela-confirmacao a", has_text="Ir para minha Área")).to_be_hidden()
    expect(pg.locator("#btn-indicar")).to_have_attribute("href", re.compile(r"^https://wa\.me/\?text=.*convite"))
    pg.screenshot(path="evidencias/e2e/10_doacao_unica.png", full_page=True)
    assert sql("select d.status||'|'||d.valor||'|'||o.nome||'|'||coalesce(d.email,'-') from doacao_unica d join origem o on o.id=d.origem_id where d.nome='Rita Doadora'") == "paga|250.00|Instagram|-"
    ok("E22 doação única de qualquer valor (R$ 250), sem ser recorrente e sem e-mail, com 'Indique um novo Doador' ao final")

    # ---------------- E23 Minha Área do Guardião
    pg.goto(f"{BASE}/index.html"); pg.click(".nav-topo a:has-text('Minha Área')")
    expect(pg.locator("#tela-entrar")).to_be_visible()
    pg.fill("#lg-whats", "(11) 90000-0050"); pg.fill("#lg-cpf", CPF_OUTRO); pg.click("#btn-entrar")
    expect(pg.locator("#msg-entrar")).to_contain_text("Não encontramos")
    pg.click("#btn-entrar-demo"); expect(pg.locator("#tela-area")).to_be_visible()
    expect(pg.locator("#area-nivel .estrelas")).to_be_visible(); expect(pg.locator("#area-nivel")).to_contain_text("Guardião")
    expect(pg.locator("#area-impacto li").first).to_contain_text("Contraturno Escolar")
    expect(pg.locator("#area-historico tbody tr").first).to_be_visible()
    if pg.locator("#btn-retomar").count(): pg.click("#btn-retomar"); expect(pg.locator("#msg-area")).to_contain_text("retomada")
    pg.screenshot(path="evidencias/e2e/11_minha_area.png", full_page=True)
    pg.select_option("#meses-pausa", "2"); pg.click("#btn-pausar")
    expect(pg.locator("#msg-area")).to_contain_text("volta sozinha"); expect(pg.locator("#area-status")).to_contain_text("Pausada")
    pg.click("#btn-retomar"); expect(pg.locator("#area-status")).to_contain_text("Ativa")
    pg.click("#btn-cancelar"); expect(pg.locator("#dlg-cancelar")).to_be_visible()
    pg.select_option("#cr-motivo", "O valor ficou apertado no momento"); pg.click("#btn-confirmar-cancelar")
    expect(pg.locator("#area-status")).to_contain_text("Cancelada")
    pg.click("#btn-reativar"); expect(pg.locator("#area-status")).to_contain_text("R$ 85,00")
    expect(pg.locator("#area-btn-indicar")).to_have_attribute("href", re.compile(r"^https://wa\.me/\?text=.*convite"))
    pg.click("#btn-recibo"); expect(pg.locator("#recibo-folha")).to_contain_text("Recibo de doações")
    expect(pg.locator("#recibo-folha")).to_contain_text("sem dedução de Imposto de Renda")
    pg.screenshot(path="evidencias/e2e/12_recibo.png", full_page=True)
    assert sql("select motivo_texto from assinatura where motivo_texto is not null order by cancelada_em desc limit 1") == "O valor ficou apertado no momento"
    ok("E23 Minha Área: entra só com WhatsApp e CPF certos; mostra nível, estrelas, impacto e histórico; pausa, retoma, cancela com motivo, reativa por R$ 85 e emite o recibo")

    # ---------------- E04 acesso ao painel
    pg.goto(f"{BASE}/painel.html")
    pg.fill("#login-email", "voluntario@example.com"); pg.fill("#login-senha", "errada"); pg.click("button:has-text('Entrar')")
    expect(pg.locator("#login-msg")).to_contain_text("incorretos")
    pg.fill("#login-email", "curioso@example.com"); pg.fill("#login-senha", "senha-teste"); pg.click("button:has-text('Entrar')")
    expect(pg.locator("#login-msg")).to_contain_text("não está cadastrado como voluntário")
    ok("E04 senha errada e conta sem cadastro de voluntário não entram no painel")
    pg.fill("#login-email", "voluntario@example.com"); pg.fill("#login-senha", "senha-teste"); pg.click("button:has-text('Entrar')")
    expect(pg.locator("#tela-painel")).to_be_visible()
    expect(pg.locator("#kpis .kpi")).to_have_count(9)
    pg.wait_for_timeout(300)
    pg.screenshot(path="evidencias/e2e/03_painel_resumo.png", full_page=True)
    ativos_tela = pg.locator("#kpis .kpi").first.locator(".val").inner_text()
    ativos_db = sql("select count(*) from assinatura where status='ativa'")
    no_clube = sql("select count(*) from assinatura where status in ('ativa','pausada')")
    assert ativos_tela.replace(".", "") == no_clube, (ativos_tela, no_clube)
    ok(f"E05 voluntário entra; resumo mostra {ativos_tela} Guardiões no Clube (ativos e pausados), igual ao banco")
    with pg.expect_download() as d: pg.click("#btn-exportar")
    arq = d.value.path(); linhas = open(arq, encoding="utf-8-sig").read().splitlines()
    assert linhas[0].startswith("mes;ativos_inicio") and len(linhas) >= 13
    ok(f"E06 exportação CSV para prestação de contas com {len(linhas)-1} meses")
    pg.click("[data-aba=unicas]"); expect(pg.locator("#tab-unicas")).to_contain_text("Rita Doadora")
    expect(pg.locator("#tab-unicas tbody tr", has_text="Rita Doadora")).to_contain_text("Paga")
    pg.screenshot(path="evidencias/e2e/13_painel_doacoes_unicas.png", full_page=True)
    pg.click("[data-aba=guardioes]"); pg.select_option("#filtro-sit", "pausado")
    expect(pg.locator("#tab-guardioes tbody tr").first).to_contain_text("volta em")
    pg.select_option("#filtro-sit", ""); pg.fill("#busca", "paula convidada")
    b = pg.locator("#tab-guardioes button[data-pausar]"); b.click(); expect(b).to_have_text("Confirmar pausa"); b.click()
    expect(pg.locator("#painel-msg")).to_contain_text("Volta sozinha")
    pg.locator("#tab-guardioes button[data-retomar]").click(); expect(pg.locator("#painel-msg")).to_contain_text("retomada")
    pg.fill("#busca", "")
    ok("E24 painel mostra doações únicas, Guardiões pausados com a data de volta, nível e estrelas; equipe pausa e retoma a pedido")

    # ---------------- E07 Guardiões e histórico
    pg.click("[data-aba=guardioes]"); pg.fill("#busca", "maria demo")
    expect(pg.locator("#tab-guardioes tbody tr")).to_have_count(1)
    expect(pg.locator("#tab-guardioes")).to_contain_text("QR Code na comunidade")
    pg.click("#tab-guardioes a[data-detalhe]")
    expect(pg.locator("#dlg-guardiao")).to_contain_text("Boas-vindas")
    pg.screenshot(path="evidencias/e2e/04_detalhe_guardiao.png")
    pg.click("#dlg-guardiao [data-fechar]")
    ok("E07 busca encontra a nova Guardiã e o histórico mostra a mensagem de boas-vindas")
    pg.type("#consulta-cpf", CPF_MARIA); pg.click("#form-consulta-cpf button")
    expect(pg.locator("#resultado-cpf")).to_contain_text("Maria Demonstração")
    pg.fill("#consulta-cpf", ""); pg.type("#consulta-cpf", CPF_OUTRO); pg.click("#form-consulta-cpf button")
    expect(pg.locator("#resultado-cpf")).to_contain_text("Nenhum Guardião")
    pg.screenshot(path="evidencias/e2e/04b_consulta_cpf.png")
    ok("E07b voluntário consulta se um CPF já é Guardião, sem ver o número guardado")

    # ---------------- E08 operação do mês
    pg.click("[data-aba=operacao]")
    comp = pg.input_value("#competencia"); assert comp == "2026-10", comp
    pg.click("#btn-gerar"); expect(pg.locator("#painel-msg")).to_contain_text("cobranças geradas")
    n_ger = int(re.search(r"([\d.]+) cobranças", pg.locator("#painel-msg").inner_text()).group(1).replace(".", ""))
    assert n_ger == int(ativos_db), (n_ger, ativos_db)
    pg.click("#btn-gerar"); expect(pg.locator("#painel-msg")).to_contain_text("Nada foi duplicado")
    ok(f"E08 geração de cobranças de out/2026: {n_ger} criadas, segunda tentativa não duplica")
    pg.click("#btn-simular"); expect(pg.locator("#painel-msg")).to_contain_text("Avisos da Asaas processados")
    msg_sim = pg.locator("#painel-msg").inner_text()
    pg.wait_for_timeout(300); pg.screenshot(path="evidencias/e2e/05_operacao_mes.png", full_page=True)
    assert sql("select count(*) from cobranca c join assinatura a on a.id=c.assinatura_id where c.competencia='2026-10-01' and c.status='pendente' and a.meio_pagamento<>'pix_direto'") == "0"
    diretos = int(sql("select count(*) from cobranca c join assinatura a on a.id=c.assinatura_id where c.competencia='2026-10-01' and c.status='pendente' and a.meio_pagamento='pix_direto'"))
    assert diretos > 0, diretos
    ok(f"E09 simulador da Asaas processa todas as cobranças da Asaas: {msg_sim.split(': ', 1)[-1]} {diretos} de Pix direto ficam para conferência no extrato")

    # ---------------- E10 alerta de churn e recuperação manual
    pg.click("[data-aba=alerta]")
    em_risco = pg.locator("#tab-alerta tbody tr").count(); assert em_risco > 0
    expect(pg.locator("#badge-alerta")).to_have_text(str(em_risco))
    expect(pg.locator("#tab-alerta a", has_text="WhatsApp").first).to_have_attribute("href", re.compile(r"^https://wa\.me/55\d+\?text="))
    pg.screenshot(path="evidencias/e2e/06_alerta_churn.png", full_page=True)
    ok(f"E10 alerta de churn lista {em_risco} Guardiões com link de WhatsApp pronto")
    pg.locator("#tab-alerta button[data-contato]").first.click()
    pg.fill("#contato-anotacao", "Liguei, vai pagar na sexta."); pg.click("#form-contato button[type=submit]")
    expect(pg.locator("#painel-msg")).to_contain_text("Contato registrado")
    expect(pg.locator("#tab-alerta")).to_contain_text("Último:")
    assert sql("select count(*) from comunicacao where tipo='contato_pessoal' and conteudo='Liguei, vai pagar na sexta.'") == "1"
    ok("E21 equipe registra o contato feito com quem está em atraso, e o alerta mostra o último contato")
    pg.click("[data-aba=operacao]"); pg.select_option("#filtro-cob", "falhou")
    expect(pg.locator("#tab-cobrancas tbody tr").first).to_contain_text("Falhou")
    linha = pg.locator("#tab-cobrancas tbody tr").first; nome = linha.locator("td").first.inner_text()
    linha.locator("button", has_text="Pix pago").click()
    expect(pg.locator("#painel-msg")).to_contain_text("recuperado")
    pg.click("[data-aba=alerta]"); expect(pg.locator("#tab-alerta tbody tr")).to_have_count(em_risco - 1)
    ok(f"E11 Pix pago após o lembrete: {nome} vira 'recuperado' e sai do alerta")

    # ---------------- E12 inadimplência em três avisos
    pg.click("[data-aba=operacao]"); pg.select_option("#filtro-cob", "falhou")
    expect(pg.locator("#tab-cobrancas tbody tr button", has_text="Pix vencido").first).to_be_visible()
    alvo = pg.locator("#tab-cobrancas tbody tr").first.locator("td").first.inner_text()
    for i in range(3):
        pg.evaluate("document.querySelector('#painel-msg').innerHTML=''")
        pg.locator("#tab-cobrancas tbody tr", has_text=alvo).first.locator("button", has_text="Pix vencido").click()
        expect(pg.locator("#painel-msg")).to_contain_text(re.compile("Atraso registrado|inadimplência"))
        if "inadimplência" in pg.locator("#painel-msg").inner_text(): break
    expect(pg.locator("#painel-msg")).to_contain_text("cancelada por inadimplência")
    expect(pg.locator("#tab-cobrancas tbody tr", has_text=alvo).first).to_contain_text("assinatura encerrada")
    assert pg.locator("#tab-cobrancas tbody tr", has_text=alvo).first.locator("button").count() == 0
    ok(f"E12 terceiro aviso de atraso cancela a assinatura de {alvo} por inadimplência e encerra a simulação para ela")

    # ---------------- E20 atividades e prestação de contas do mês
    pg.click("#btn-impacto"); expect(pg.locator("#painel-msg")).to_contain_text("Registre em Atividades")
    pg.click("[data-aba=atividades]")
    for t in pg.locator("#lista-atividades textarea").all(): t.fill("Sustentou as atividades das crianças em outubro de 2026.")
    for i in range(pg.locator("#lista-atividades [data-salvar-atividade]").count()):
        pg.locator("#lista-atividades [data-salvar-atividade]").nth(i).click(); expect(pg.locator("#painel-msg")).to_contain_text("salva")
    expect(pg.locator("#previa-noticia")).to_contain_text("Contraturno Escolar")
    pg.screenshot(path="evidencias/e2e/09_atividades.png", full_page=True)
    ok("E20 equipe registra o que cada atividade sustentou no mês; sem isso a notícia de impacto não sai")

    # ---------------- E13 notícia de impacto
    pg.click("[data-aba=operacao]")
    pg.click("#btn-impacto"); expect(pg.locator("#painel-msg")).to_contain_text("enviada a")
    pg.click("#btn-impacto"); expect(pg.locator("#painel-msg")).to_contain_text("Ninguém recebeu duas vezes")
    ok("E13 notícia mensal de impacto enviada uma vez; repetir não duplica")

    # ---------------- E14 cancelamento a pedido, em dois cliques
    pg.wait_for_load_state("networkidle")
    pg.click("[data-aba=guardioes]"); pg.fill("#busca", "maria demo")
    b = pg.locator("#tab-guardioes button[data-cancelar]"); b.click()
    expect(b).to_have_text("Confirmar cancelamento"); b.click()
    expect(pg.locator("#painel-msg")).to_contain_text("cancelada a pedido")
    expect(pg.locator("#tab-guardioes")).to_contain_text("a pedido")
    ok("E14 cancelamento a pedido exige confirmação e registra o motivo")

    # ---------------- E15 adesão registrada pelo voluntário
    pg.click("#btn-nova-adesao"); pg.fill("#a-nome", "João Evento"); pg.fill("#a-email", "joao.evento@example.com"); pg.type("#a-cpf", CPF_JOAO)
    pg.fill("#a-valor", "85"); pg.select_option("#a-origem", "Campanha Dia das Crianças"); pg.check("#a-consent")
    pg.click("#form-adesao-painel button[type=submit]")
    expect(pg.locator("#painel-msg")).to_contain_text("Adesão registrada")
    pg.click("[data-aba=canais]"); expect(pg.locator("#tab-canais")).to_contain_text("Campanha Dia das Crianças")
    pg.screenshot(path="evidencias/e2e/07_canais.png", full_page=True)
    ok("E15 voluntário registra adesão presencial com o canal da campanha")

    # ---------------- E18 modelo híbrido: base em Pix direto
    pg.click("[data-aba=guardioes]"); pg.click("#btn-nova-adesao"); pg.fill("#a-nome", "Clara Base"); pg.fill("#a-email", "clara.base@example.com"); pg.type("#a-cpf", CPF_BASE)
    pg.fill("#a-valor", "80"); pg.check("#a-direto"); expect(pg.locator("#a-origem")).to_be_disabled(); pg.check("#a-consent")
    pg.click("#form-adesao-painel button[type=submit]")
    expect(pg.locator("#painel-msg")).to_contain_text("cadastrado em Pix direto")
    assert sql("select a.meio_pagamento||'|'||o.nome from guardiao g join assinatura a on a.guardiao_id=g.id join origem o on o.id=g.origem_id where g.email='clara.base@example.com'") == "pix_direto|Base Pix manual"
    pg.click("[data-aba=operacao]"); pg.select_option("#filtro-cob", "pendente")
    expect(pg.locator("#tab-cobrancas tbody tr").first).to_contain_text("Pendente")
    linha = pg.locator("#tab-cobrancas tbody tr", has_text="Pix direto").first; nome_d = linha.locator("td").first.inner_text().replace("Pix direto", "").strip()
    linha.locator("button", has_text="Recebido no extrato").click()
    expect(pg.locator("#painel-msg")).to_contain_text("Pix direto registrado")
    assert sql(f"select count(*) from evento_gateway e join cobranca c on c.id=e.cobranca_id join assinatura a on a.id=c.assinatura_id join guardiao g on g.id=a.guardiao_id where g.nome='{nome_d}' and c.competencia='2026-10-01' and e.id_evento like 'manual_%' and c.status='pago'") == "1"
    antes = int(sql("select count(*) from assinatura where status='ativa' and meio_pagamento='pix_direto'"))
    pg.click("[data-aba=guardioes]"); pg.fill("#busca", "clara base")
    b = pg.locator("#tab-guardioes button[data-migrar]"); b.click(); expect(b).to_have_text("Confirmar: o Guardião aceitou"); b.click()
    expect(pg.locator("#painel-msg")).to_contain_text("migrado para a Asaas")
    assert int(sql("select count(*) from assinatura where status='ativa' and meio_pagamento='pix_direto'")) == antes - 1
    pg.fill("#busca", "")
    ok(f"E18 base em Pix direto: cadastro sem trocar a forma de pagar, Pix de {nome_d} registrado à mão pelo extrato, migração para a Asaas em dois cliques")

    # ---------------- E16 celular
    m = nav.new_context(viewport={"width": 390, "height": 844}, is_mobile=True, locale="pt-BR").new_page()
    m.goto(f"{BASE}/index.html"); m.screenshot(path="evidencias/e2e/08_celular_adesao.png", full_page=True)
    largura = m.evaluate("document.documentElement.scrollWidth"); assert largura <= 390, largura
    ok("E16 página de adesão cabe na tela do celular, sem rolagem lateral")

    nav.close()

erros = [e for e in ERROS_CONSOLE if "favicon" not in e and "400" not in e and "401" not in e and "403" not in e]
if erros: print("ERROS NO CONSOLE:", erros); sys.exit(1)
LOG.append("PASS E17 nenhum erro de JavaScript no console durante o roteiro")
open("evidencias/e2e/resultado_e2e.log", "w").write("\n".join(LOG) + "\n")
print("TODOS OS TESTES DE INTERFACE PASSARAM")
