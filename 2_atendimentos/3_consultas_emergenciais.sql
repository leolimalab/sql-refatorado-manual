-- ============================================================================
-- ARQUIVO: 2_atendimentos/3_consultas_emergenciais.sql
-- PROPÓSITO: CTEs para consultas de urgência/emergência durante gestação
-- TABELA DESTINO: _atendimentos (INSERT)
-- ============================================================================
-- 
-- DESCRIÇÃO:
--   Este script adiciona as consultas de urgência/emergência à tabela 
--   _atendimentos. Estas consultas são importantes para identificar
--   complicações durante a gestação.
--
-- DEPENDÊNCIAS:
--   - Executar APÓS 1_atd_prenatal_aps.sql (cria _atendimentos)
--   - rj-sms-sandbox.sub_pav_us._condicoes
--   - rj-sms-sandbox.sub_pav_us._atendimentos
--   - rj-sms.saude_historico_clinico.episodio_assistencial
--
-- FILTROS:
--   - Fornecedor: 'vitai' (sistema de emergência)
--   - Subtipo: 'Emergência'
--
-- SAÍDA:
--   - tipo_atd = 'consulta_emergencial'
--   - Inclui CIDs agrupados dos atendimentos de emergência
--
-- AUTOR: Monitor Gestante Team
-- ÚLTIMA ATUALIZAÇÃO: 2026-01
-- ============================================================================

CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_atd_consultas_emergenciais`()

BEGIN

-- Inserção na tabela de atendimentos (consultas emergenciais)
INSERT INTO `rj-sms-sandbox.sub_pav_us._atendimentos` (
    id_gestacao,
    id_paciente,
    data_consulta,
    numero_consulta,
    ig_consulta,
    trimestre_consulta,
    fase_atual,
    tipo_atd,
    peso_inicio,
    altura_inicio,
    imc_inicio,
    classificacao_imc_inicio,
    peso,
    imc_consulta,
    ganho_peso_acumulado,
    pressao_sistolica,
    pressao_diastolica,
    motivo_atendimento,
    cid_string,
    desfecho_atendimento,
    prescricoes,
    estabelecimento,
    profissional_nome,
    profissional_categoria
)

WITH 

-- ------------------------------------------------------------
-- CTE: marcadores_temporais
-- Dados temporais das gestações (reutiliza de _condicoes)
-- ------------------------------------------------------------
marcadores_temporais AS (
    SELECT
        id_gestacao,
        id_paciente,
        cpf,
        nome AS nome_gestante,
        numero_gestacao,
        idade_gestante,
        data_inicio,
        data_fim,
        data_fim_efetiva,
        fase_atual,
        clinica_nome AS unidade_APS_PN,
        equipe_nome AS equipe_PN_APS
    FROM `rj-sms-sandbox.sub_pav_us._condicoes`
),

-- ------------------------------------------------------------
-- CTE: cids_agrupados
-- Agrupa CIDs de emergência por id_hci
-- ------------------------------------------------------------
cids_agrupados AS (
    SELECT
        ea.id_hci,
        STRING_AGG(DISTINCT c.id ORDER BY c.id) AS cids_emergencia,
        STRING_AGG(DISTINCT c.descricao ORDER BY c.descricao) AS descricoes_cids_emergencia
    FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
        LEFT JOIN UNNEST(ea.condicoes) AS c
    WHERE ea.prontuario.fornecedor = 'vitai'
        AND ea.subtipo = 'Emergência'
        AND c.id IS NOT NULL
    GROUP BY ea.id_hci
),

-- ------------------------------------------------------------
-- CTE: atendimentos_ue_com_join
-- Atendimentos de urgência/emergência associados às gestações
-- ------------------------------------------------------------
atendimentos_ue_com_join AS (
    SELECT
        ea.id_hci,
        ea.paciente.id_paciente,
        ea.entrada_data AS data_consulta,
        ea.estabelecimento.nome AS nome_estabelecimento,
        ea.profissional_saude_responsavel.nome AS nome_profissional,
        ea.profissional_saude_responsavel.especialidade AS especialidade_profissional,
        ea.motivo_atendimento,
        ea.desfecho_atendimento,
        mt.id_gestacao,
        mt.cpf,
        mt.nome_gestante,
        mt.numero_gestacao,
        mt.idade_gestante,
        mt.data_inicio,
        mt.data_fim,
        mt.data_fim_efetiva,
        mt.fase_atual,
        cids.cids_emergencia,
        'consulta_emergencial' AS tipo_atd
    FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
    JOIN marcadores_temporais mt
        ON ea.paciente.id_paciente = mt.id_paciente
        AND ea.entrada_data BETWEEN mt.data_inicio AND COALESCE(mt.data_fim_efetiva, CURRENT_DATE())
    LEFT JOIN cids_agrupados cids ON ea.id_hci = cids.id_hci
    WHERE ea.prontuario.fornecedor = 'vitai'
        AND ea.subtipo = 'Emergência'
)

-- Resultado para inserção na tabela _atendimentos
SELECT
    id_gestacao,
    id_paciente,
    data_consulta,
    ROW_NUMBER() OVER (
        PARTITION BY id_gestacao
        ORDER BY data_consulta
    ) AS numero_consulta,
    DATE_DIFF(data_consulta, data_inicio, WEEK) AS ig_consulta,
    CASE
        WHEN DATE_DIFF(data_consulta, data_inicio, WEEK) <= 13 THEN 1
        WHEN DATE_DIFF(data_consulta, data_inicio, WEEK) <= 27 THEN 2
        ELSE 3
    END AS trimestre_consulta,
    fase_atual,
    tipo_atd,
    CAST(NULL AS FLOAT64) AS peso_inicio,
    CAST(NULL AS FLOAT64) AS altura_inicio,
    CAST(NULL AS FLOAT64) AS imc_inicio,
    CAST(NULL AS STRING) AS classificacao_imc_inicio,
    CAST(NULL AS FLOAT64) AS peso,
    CAST(NULL AS FLOAT64) AS imc_consulta,
    CAST(NULL AS FLOAT64) AS ganho_peso_acumulado,
    CAST(NULL AS FLOAT64) AS pressao_sistolica,
    CAST(NULL AS FLOAT64) AS pressao_diastolica,
    motivo_atendimento,
    cids_emergencia AS cid_string,
    desfecho_atendimento,
    CAST(NULL AS STRING) AS prescricoes,
    nome_estabelecimento AS estabelecimento,
    nome_profissional AS profissional_nome,
    especialidade_profissional AS profissional_categoria
FROM atendimentos_ue_com_join
ORDER BY id_gestacao, data_consulta;

END;
