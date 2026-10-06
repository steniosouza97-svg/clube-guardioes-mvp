"""Captura as telas do MVP em celular, tablet e computador e confere que nenhuma tem rolagem lateral.
Requer a réplica local no ar (tests/e2e/rodar_e2e.sh sobe o banco, o PostgREST e o servidor)."""
from playwright.sync_api import sync_playwright
B="http://localhost:8080"; import os; O=os.path.join(os.path.dirname(__file__), "..", "..", "evidencias", "responsivo") + "/"
SIZES=[("celular",390,844,True),("tablet",768,1024,True),("computador",1440,900,False)]
HIDE=".aviso-demo{display:none!important}"
res=[]
with sync_playwright() as p:
    nav=p.chromium.launch(executable_path=os.environ.get('CHROMIUM') or None)
    for nome,w,h,mob in SIZES:
        ctx=nav.new_context(viewport={"width":w,"height":h},device_scale_factor=2,is_mobile=mob,has_touch=mob,locale="pt-BR"); pg=ctx.new_page()
        def chk(tela):
            sw=pg.evaluate("document.documentElement.scrollWidth"); iw=pg.evaluate("window.innerWidth")
            res.append((tela,nome,w,sw<=iw,sw))
        pg.goto(B+"/index.html"); pg.wait_for_timeout(500); chk("Página de adesão"); pg.screenshot(path=f"{O}adesao_{nome}.png")
        pg.locator(".vitrine a",has_text="Quero participar").click(); pg.wait_for_timeout(300)
        pg.evaluate("document.querySelector('#tela-cadastro').scrollIntoView()"); chk("Cadastro"); pg.screenshot(path=f"{O}cadastro_{nome}.png")
        pg.goto(B+"/index.html"); pg.click(".nav-topo a:has-text('Minha Área')"); pg.click("#btn-entrar-demo"); pg.wait_for_selector("#tela-area",state="visible"); pg.wait_for_timeout(600)
        pg.evaluate("document.querySelector('#tela-area').scrollIntoView()"); chk("Minha Área"); pg.screenshot(path=f"{O}minha_area_{nome}.png")
        pg.goto(B+"/painel.html"); pg.fill("#login-email","voluntario@example.com"); pg.fill("#login-senha","senha-teste")
        pg.locator("button[type=submit], button:has-text('Entrar')").first.click(); pg.wait_for_timeout(4000); pg.add_style_tag(content=HIDE)
        chk("Painel"); pg.screenshot(path=f"{O}painel_{nome}.png")
        ctx.close()
    nav.close()
falhas = [r for r in res if not r[3]]
for r in res: print(("PASS" if r[3] else "FALHA"), f"{r[0]} no {r[1]} ({r[2]} px): largura do conteúdo {r[4]} px")
raise SystemExit(1 if falhas else 0)
