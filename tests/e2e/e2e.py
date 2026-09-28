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
    pg.click("text=Quero doar todo mês")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("nome")
    pg.fill("#nome", "Maria Demonstração"); pg.fill("#email", "maria.demo@example.com"); pg.fill("#telefone", "(11) 98888-7777")
    pg.fill("#cpf", CPF_MARIA[:10] + str((int(CPF_MARIA[10]) + 1) % 10))
    pg.click("text=Quero doar todo mês")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("CPF")
    pg.fill("#cpf", ""); pg.type("#cpf", CPF_MARIA)
    assert pg.input_value("#cpf") == f"{CPF_MARIA[:3]}.{CPF_MARIA[3:6]}.{CPF_MARIA[6:9]}-{CPF_MARIA[9:]}", pg.input_value("#cpf")
    pg.click("text=Quero doar todo mês")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("autorizar")
    ok("E01 formulário valida nome, CPF (dígito verificador, com máscara) e exige consentimento LGPD")
    pg.check("#consent"); pg.locator("label.faixa", has_text="Outro").click(); pg.fill("#valor-outro", "150")
    pg.select_option("#dia", "15"); pg.click("text=Quero doar todo mês")
    expect(pg.locator("#resultado .msg.ok")).to_contain_text("Bem-vindo ao Clube, Maria")
    pg.screenshot(path="evidencias/e2e/02_adesao_confirmada.png", full_page=True)
    assert sql("select o.nome||'|'||a.valor_mensal||'|'||a.dia_vencimento from guardiao g join origem o on o.id=g.origem_id join assinatura a on a.guardiao_id=g.id where g.email='maria.demo@example.com'") == "QR Code na comunidade|150.00|15"
    assert sql(f"select count(*) from guardiao g where g::text like '%{CPF_MARIA}%' or g::text like '%{CPF_MARIA[:3]}.{CPF_MARIA[3:6]}%'") == "0", "CPF gravado em texto aberto"
    assert len(sql("select cpf_hash from guardiao where email='maria.demo@example.com'")) == 64
    ok("E02 adesão pública grava Guardião com valor, dia, canal (QR Code) e CPF só cifrado")
    pg.fill("#nome", "Maria Outro Email"); pg.fill("#email", "maria.outro@example.com"); pg.type("#cpf", CPF_MARIA); pg.check("#consent")
    pg.click("text=Quero doar todo mês")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("Este CPF já é de um Guardião ativo")
    pg.fill("#nome", "Maria Demonstração"); pg.fill("#email", "MARIA.DEMO@example.com"); pg.fill("#cpf", ""); pg.type("#cpf", CPF_OUTRO); pg.check("#consent")
    pg.click("text=Quero doar todo mês")
    expect(pg.locator("#resultado .msg.erro")).to_contain_text("outro CPF")
    ok("E03 mesmo CPF com outro e-mail é recusado; e-mail já usado não aceita outro CPF")

    # ---------------- E04 acesso ao painel
    pg.goto(f"{BASE}/painel.html")
    pg.fill("#login-email", "voluntario@example.com"); pg.fill("#login-senha", "errada"); pg.click("button:has-text('Entrar')")
    expect(pg.locator("#login-msg")).to_contain_text("incorretos")
    pg.fill("#login-email", "curioso@example.com"); pg.fill("#login-senha", "senha-teste"); pg.click("button:has-text('Entrar')")
    expect(pg.locator("#login-msg")).to_contain_text("não está cadastrado como voluntário")
    ok("E04 senha errada e conta sem cadastro de voluntário não entram no painel")
    pg.fill("#login-email", "voluntario@example.com"); pg.fill("#login-senha", "senha-teste"); pg.click("button:has-text('Entrar')")
    expect(pg.locator("#tela-painel")).to_be_visible()
    expect(pg.locator("#kpis .kpi")).to_have_count(7)
    pg.wait_for_timeout(300)
    pg.screenshot(path="evidencias/e2e/03_painel_resumo.png", full_page=True)
    ativos_tela = pg.locator("#kpis .kpi").first.locator(".val").inner_text()
    ativos_db = sql("select count(*) from assinatura where status='ativa'")
    assert ativos_tela.replace(".", "") == ativos_db, (ativos_tela, ativos_db)
    ok(f"E05 voluntário entra; resumo mostra {ativos_tela} Guardiões ativos, igual ao banco")
    with pg.expect_download() as d: pg.click("#btn-exportar")
    arq = d.value.path(); linhas = open(arq, encoding="utf-8-sig").read().splitlines()
    assert linhas[0].startswith("mes;ativos_inicio") and len(linhas) >= 13
    ok(f"E06 exportação CSV para prestação de contas com {len(linhas)-1} meses")

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

    # ---------------- E13 notícia de impacto
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
    pg.fill("#a-valor", "60"); pg.select_option("#a-origem", "Campanha Dia das Crianças"); pg.check("#a-consent")
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
