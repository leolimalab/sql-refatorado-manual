-- ============================================================================
-- SCRIPT DE EXECUÇÃO COMPLETA - MONITOR GESTANTE REFATORADO
-- ============================================================================
-- Este script executa todos os procedimentos na ordem correta
-- para gerar as tabelas reorganizadas do Monitor Gestante
-- ============================================================================

-- INÍCIO DA EXECUÇÃO
SELECT 'INICIANDO REORGANIZAÇÃO SQL MONITOR GESTANTE' as status;

-- ============================================================================
-- FASE 1: CONDIÇÕES BASE (APENAS GESTAÇÕES)
-- ============================================================================

SELECT 'FASE 1: Executando condições base - gestações...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_condicoes_gestacoes`();
SELECT 'CONCLUÍDO: Tabela _condicoes criada' as status;

-- ============================================================================
-- FASE 2: ATENDIMENTOS
-- ============================================================================

SELECT 'FASE 2: Executando atendimentos pré-natal APS...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_prenatal_aps`();
SELECT 'CONCLUÍDO: Tabela _atendimentos criada com dados pré-natal' as status;

SELECT 'FASE 2: Adicionando visitas ACS...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_visitas_acs_gestacao`();
SELECT 'CONCLUÍDO: Visitas ACS adicionadas à _atendimentos' as status;

SELECT 'FASE 2: Adicionando consultas emergenciais...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_consultas_emergenciais`();
SELECT 'CONCLUÍDO: Consultas emergenciais adicionadas à _atendimentos' as status;

SELECT 'FASE 2: Adicionando encaminhamentos...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_encaminhamentos`();
SELECT 'CONCLUÍDO: Encaminhamentos adicionados à _atendimentos' as status;

-- ============================================================================
-- FASE 2.5: COMPLEMENTAR CONDIÇÕES COM HIPERTENSÃO
-- ============================================================================

SELECT 'FASE 2.5: Executando condições - hipertensão gestacional...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_hipertensao_gestacional`();
SELECT 'CONCLUÍDO: Dados de hipertensão adicionados à _condicoes' as status;

-- ============================================================================
-- FASE 3: VIEW CONSOLIDADA
-- ============================================================================

SELECT 'FASE 3: Gerando view consolidada final...' as status;
CALL `rj-sms-sandbox.sub_pav_us.proced_view_linha_tempo_consolidada`();
SELECT 'CONCLUÍDO: View consolidada _view criada' as status;

-- ============================================================================
-- VALIDAÇÃO FINAL
-- ============================================================================

SELECT 'EXECUTANDO VALIDAÇÃO FINAL...' as status;

-- Contagem de registros por tabela
SELECT 'VALIDAÇÃO: Contando registros nas tabelas geradas...' as status;

SELECT 
    'CONDICOES' as tabela,
    COUNT(*) as total_registros,
    COUNT(DISTINCT id_gestacao) as gestacoes_unicas,
    COUNT(DISTINCT id_paciente) as pacientes_unicos
FROM `rj-sms-sandbox.sub_pav_us._condicoes`;

SELECT 
    'ATENDIMENTOS' as tabela,
    COUNT(*) as total_registros,
    COUNT(DISTINCT id_gestacao) as gestacoes_com_atendimentos,
    COUNT(DISTINCT tipo_atd) as tipos_atendimento
FROM `rj-sms-sandbox.sub_pav_us._atendimentos`;

SELECT 
    'VIEW_CONSOLIDADA' as tabela,
    COUNT(*) as total_registros,
    COUNT(DISTINCT id_gestacao) as gestacoes_na_view,
    COUNT(DISTINCT fase_atual) as fases_gestacao
FROM `rj-sms-sandbox.sub_pav_us._view`;

-- Verificação por tipo de atendimento
SELECT 
    'TIPOS_ATENDIMENTO' as categoria,
    tipo_atd,
    COUNT(*) as quantidade
FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
GROUP BY tipo_atd
ORDER BY quantidade DESC;

-- Verificação por fase da gestação
SELECT 
    'FASES_GESTACAO' as categoria,
    fase_atual,
    COUNT(*) as quantidade
FROM `rj-sms-sandbox.sub_pav_us._view`
GROUP BY fase_atual
ORDER BY quantidade DESC;

-- ============================================================================
-- CONCLUSÃO
-- ============================================================================

SELECT 'REORGANIZAÇÃO SQL CONCLUÍDA COM SUCESSO!' as status;
SELECT CURRENT_DATETIME() as data_conclusao;

SELECT 'TABELAS GERADAS:' as resultado;
SELECT '1. _condicoes - Gestações e condições médicas' as tabela_1;
SELECT '2. _atendimentos - Todos os tipos de atendimentos' as tabela_2;  
SELECT '3. _view - View consolidada final (linha do tempo)' as tabela_3;

SELECT 'ARQUIVOS FONTE REORGANIZADOS:' as origem;
SELECT '- condicoes/1_gestacoes.sql' as arquivo_1;
SELECT '- condicoes/2_gest_hipertensao.sql' as arquivo_2;
SELECT '- atendimentos/1_atd_prenatal_aps.sql' as arquivo_3;
SELECT '- atendimentos/2_visitas_acs_gestacao.sql' as arquivo_4;
SELECT '- atendimentos/3_consultas_emergenciais.sql' as arquivo_5;
SELECT '- atendimentos/4_encaminhamentos.sql' as arquivo_6;
SELECT '- view/1_linha_tempo.sql' as arquivo_7;

-- FIM DA EXECUÇÃO


