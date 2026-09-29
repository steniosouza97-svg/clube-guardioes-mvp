-- =====================================================================
-- 04_dados_referencia.sql: dados reais de configuração (não sintéticos)
-- Carregar também em produção.
-- =====================================================================

insert into parametro (chave, valor, descricao) values
    ('custeio_anual_2025',      146668.38, 'Despesa total realizada em 2025, DRE assinado. Base do indicador de cobertura do custeio.'),
    ('meta_guardioes',          100,       'Meta institucional de Guardiões do Plano de Captação 2026.'),
    ('meta_recorrencia_mensal', 20000,     'Meta mensal de recorrência PF, Eixo 1 do Plano de Captação 2026.'),
    ('tentativas_ate_cancelar', 3,         'Falhas de cobrança seguidas até cancelar a assinatura por inadimplência.'),
    ('custo_pix',               1.99,      'Taxa Asaas por Pix recebido (tabela pública).'),
    ('custo_mensagem_whatsapp', 0.55,      'Taxa Asaas por mensagem WhatsApp da régua (tabela pública).'),
    ('valor_guardiao',          85,        'Doação mensal do Guardião do Começo (decisão de 29/09). Doação única aceita qualquer valor.'),
    ('meses_por_estrela',       3,         'Gamificação: o Guardião ganha uma estrela a cada 3 meses de doação paga.'),
    ('pausa_maxima_meses',      3,         'Pausa da doação mensal: de 1 a 3 meses, depois volta sozinha.'),
    ('modo_demonstracao',       1,         '1 = ambiente de demonstração ("Já paguei" confirma a doação única sem a Asaas). 0 em produção.');

insert into origem (nome, tipo) values
    ('Base Pix manual',             'base_existente'),
    ('Conversão de doador pontual', 'doador_pontual'),
    ('QR Code na comunidade',       'qr_code'),
    ('Instagram',                   'instagram'),
    ('WhatsApp',                    'whatsapp'),
    ('Indicação de Guardião',       'indicacao'),
    ('Campanha Dia das Crianças',   'campanha'),
    ('Campanha de Natal',           'campanha'),
    ('Site institucional',          'site');

-- Atividades da rotina das crianças (as mesmas do protótipo da semana 5)
insert into atividade (nome, descricao) values
    ('Contraturno Escolar',     'Refeições e apoio às tarefas escolares, de segunda a sexta.'),
    ('Laboratório de Sonhos',   'Oficinas criativas e culturais.'),
    ('Vivências Terapêuticas',  'Acompanhamento terapêutico em grupo.');
