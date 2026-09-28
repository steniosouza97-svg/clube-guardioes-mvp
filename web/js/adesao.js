// Página pública de adesão. Chama a única função liberada ao visitante: fn_aderir_publico.
(function () {
  // A origem vem do link usado para chegar aqui (QR Code, Instagram...), para medir cada canal.
  const ORIGENS = {
    qr: "QR Code na comunidade", instagram: "Instagram", whatsapp: "WhatsApp",
    indicacao: "Indicação de Guardião", criancas: "Campanha Dia das Crianças",
    natal: "Campanha de Natal", site: "Site institucional"
  };
  const origem = ORIGENS[new URLSearchParams(location.search).get("origem")] || "Site institucional";

  const form = document.getElementById("form-adesao");
  const outro = document.getElementById("campo-outro");
  const res = document.getElementById("resultado");
  const btn = document.getElementById("btn-aderir");

  form.querySelectorAll("input[name=valor]").forEach(r =>
    r.addEventListener("change", () => { outro.hidden = r.value !== "outro" || !r.checked; }));

  function mostrar(tipo, html) { res.innerHTML = `<div class="msg ${tipo}">${html}</div>`; }

  form.addEventListener("submit", async ev => {
    ev.preventDefault();
    const escolhido = form.querySelector("input[name=valor]:checked").value;
    const valor = escolhido === "outro" ? Number(document.getElementById("valor-outro").value) : Number(escolhido);
    const nome = document.getElementById("nome").value.trim();
    const email = document.getElementById("email").value.trim();
    const telefone = document.getElementById("telefone").value.trim();
    const consent = document.getElementById("consent").checked;

    if (nome.length < 2) return mostrar("erro", "Informe seu nome.");
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return mostrar("erro", "Confira o e-mail informado.");
    if (!valor || valor < 10 || valor > 5000) return mostrar("erro", "Escolha um valor mensal entre R$ 10 e R$ 5.000.");
    if (!consent) return mostrar("erro", "Para aderir, é preciso autorizar o uso dos seus dados.");

    btn.disabled = true; btn.textContent = "Registrando...";
    const { error } = await sb.rpc("fn_aderir_publico", {
      p_nome: nome, p_email: email, p_telefone: telefone || null, p_origem: origem,
      p_valor: valor, p_dia: Number(document.getElementById("dia").value), p_consentimento: consent
    });
    btn.disabled = false; btn.textContent = "Quero doar todo mês";

    if (error) return mostrar("erro", esc(mensagemErro(error)));
    form.reset(); outro.hidden = true;
    mostrar("ok", `<strong>Bem-vindo ao Clube, ${esc(nome.split(" ")[0])}!</strong><br>
      Sua doação de ${fmt.brl(valor)} por mês foi registrada. ` +
      (CLUBE_CONFIG.demonstracao
        ? "Em produção, você receberia agora, por WhatsApp e e-mail, o Pix do primeiro mês enviado pela Asaas."
        : "Você vai receber no WhatsApp e no e-mail o Pix do primeiro mês."));
  });
})();
