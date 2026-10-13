# Operação e manutenção do Clube

Clube Guardiões do Futuro | Instituto Ebenézer | MVP funcional, semana 10

Rotina de quem opera o Clube depois da entrega, como publicar a interface, como zerar a demonstração, a passagem ao Instituto e o caminho para a produção. A instalação está no [guia de instalação e validação](../INSTALACAO.md).

## Publicar a interface

A pasta `web/` é estática. Neste repositório, a rotina `.github/workflows/publicar_interface.yml` publica a pasta no GitHub Pages a cada alteração (configuração única: Settings > Pages > Source: GitHub Actions).

Alternativa sem GitHub: em app.netlify.com/drop, arrastar a pasta `web/`.

Depois de publicar, gerar os links de cada canal para medir a aquisição:

| Canal | Link |
|---|---|
| QR Code na comunidade | `.../index.html?origem=qr` |
| Instagram | `.../index.html?origem=instagram` |
| WhatsApp | `.../index.html?origem=whatsapp` |
| Indicação de Guardião | `.../index.html?origem=indicacao` |
| Campanha Dia das Crianças | `.../index.html?origem=criancas` |
| Campanha de Natal | `.../index.html?origem=natal` |

## Zerar a demonstração

Antes de cada ensaio ou gravação, no SQL Editor do Supabase:

```sql
truncate evento_gateway, comunicacao, cobranca, assinatura, doacao_unica, tentativa_acesso, impacto_mensal, guardiao restart identity;
select fn_gerar_dados_sinteticos();
```

O resultado deve ser "305 Guardiões (271 ativos, 4 pausados)", com 48 doações únicas. Voluntários, logins e a chave do CPF são preservados. Na demonstração, o e-mail é opcional; se preencher, use `@example.com`. Use CPFs fictícios válidos, por exemplo `600.000.001-40`, `600.000.002-21` ou `600.000.003-02`.

## Operação depois da semana 10

Quem opera: a pessoa dedicada ao Clube. Competência necessária: usar o painel e a Asaas; não exige programação. O plano de captação cresce em três fases, conforme o modelo financeiro do business case:

| Fase | Período | Horas por mês | Captação / retenção | Novos Guardiões por mês | Churn esperado |
|---|---|---|---|---|---|
| 1. Implantação e ajuste | fev a jul/2027 | 80 | 56 h / 24 h | 5 a 10, mais 5 pontuais convertidos | até 3% |
| 2. Tração | ago/2027 a jul/2028 | 80 | 56 h / 24 h | 12 a 15 | até 2,5% |
| 3. Maturidade | ago/2028 a jan/2030 | 120 (segundo voluntário de 40 h, focado em retenção) | 72 h / 48 h | 18 | até 2% |

Passagem de fase: da 1 para a 2, 40 pontuais contatados, 80% dos 35 migrados para a Asaas e churn até 3%; da 2 para a 3, pelo menos 12 novos por mês em 3 meses seguidos e base acima de 200. Gatilhos de revisão: churn acima de 4% ao mês, base abaixo de 130 Guardiões no mês 12 (jan/2028) e custo de notificação acima de R$ 300 por mês. Os números de acompanhamento estão no **Resumo** e em **Canais** do painel.

| Frequência | Tarefa | Onde |
|---|---|---|
| Diária (10 min) | Aba **Alerta de churn**: contatar pelo WhatsApp os Guardiões de prioridade alta e clicar em **Registrar contato**. Pedido de pausa por WhatsApp: botão **Pausar 1 mês** na aba Guardiões (ou **Retomar**) | Painel |
| Semanal | Registrar adesões presenciais; acompanhar **Canais** (o uso semanal também mantém o Supabase ativo) | Painel |
| Mensal | **Doações únicas**: acompanhar a aba e convidar quem doou a virar Guardião. **Atividades**: registrar o que cada atividade sustentou no mês. **Operação do mês**: gerar cobranças (só no MVP), enviar a notícia de impacto; conferir no extrato o Pix direto de quem ainda não migrou e marcar "Recebido no extrato" ou "Não recebido"; **Resumo**: baixar o CSV para a prestação de contas | Painel e extrato bancário |
| Jan a mar/2027 | Convidar cada Guardião da base atual a migrar para a Asaas; quem aceitar, botão **Migrar para Asaas** na aba Guardiões. Meta: 80% migrados (indicador "Base ainda em Pix direto" no Resumo) | Painel e WhatsApp |
| Mensal | Comparar novos Guardiões e churn do mês com a curva da fase (tabela acima) | Painel, aba Resumo |
| Trimestral | Rodar os testes; revisar parâmetros e decidir a passagem de fase com a diretoria | SQL Editor e painel |

**Base atual (modelo híbrido, DT-15):** os Guardiões que já doam por Pix direto são cadastrados no painel marcando "Já doa por Pix direto" na adesão presencial. Não trocam a forma de pagar e recebem a mesma comunicação.

Parâmetros de negócio (valor do Guardião, pausa máxima, meses por estrela, metas, custeio de referência, taxas, limite de tentativas) ficam na tabela `parametro` e mudam sem mexer em código.

**Se o Supabase pausar:** entrar no painel do Supabase e clicar em *Restore project*. O projeto pode ser restaurado em até um ano, sem perda de dados. A rotina `manter_ativo.yml` reduz o risco de pausa, mas não o elimina: confira o projeto antes de cada demonstração.

**Se o banco for perdido:** recriar com os arquivos de `db/` (exceto o 05) e reimportar clientes, assinaturas e cobranças pela API da Asaas.

## Passagem para o Instituto

O projeto de demonstração foi criado na conta Supabase do grupo. Para a operação real:

1. O Instituto cria sua própria conta no Supabase, com e-mail institucional.
2. Transfere-se o projeto para a organização do Instituto (Supabase: *Project Settings > General > Transfer project*) ou recria-se o projeto seguindo o [guia de instalação](../INSTALACAO.md), sem o arquivo 05.
3. A pessoa dedicada é cadastrada como voluntária (seção 5 do [guia de instalação](../INSTALACAO.md)).

## Passo para produção (fora do escopo do MVP)

Uma Edge Function do Supabase recebe o webhook da Asaas, valida o token configurado na Asaas e chama `fn_processar_evento` com a chave de serviço. A cobrança mensal passa a ser criada pela assinatura da Asaas (evento `PAYMENT_CREATED`), e `fn_gerar_cobrancas` e o simulador deixam de ser usados. A página de adesão passa a encaminhar para o checkout da Asaas, e a doação única é confirmada pelo webhook (`fn_processar_doacao_unica`). Em `web/config.js`, `demonstracao: false` esconde o aviso, o simulador e o Guardião de demonstração; no banco, `parametro.modo_demonstracao = 0` desliga a confirmação de doação sem a Asaas. A entrada na Minha Área por WhatsApp e CPF deve ser trocada por código de uso único enviado ao WhatsApp (ou link mágico por e-mail) antes de operar com doadores reais. Detalhes em [DT-04](decisoes_tecnicas.md).
