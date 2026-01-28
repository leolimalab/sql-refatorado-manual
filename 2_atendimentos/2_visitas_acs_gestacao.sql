-- ============================================================================
-- ARQUIVO: 2_atendimentos/2_visitas_acs_gestacao.sql
-- PROPÓSITO: CTEs para visitas domiciliares do ACS durante gestação
-- TABELA DESTINO: _atendimentos (INSERT)
-- ============================================================================
-- 
-- DESCRIÇÃO:
--   Este script adiciona as visitas domiciliares realizadas pelo Agente
--   Comunitário de Saúde (ACS) à tabela _atendimentos.
--
-- DEPENDÊNCIAS:
--   - Executar APÓS 1_atd_prenatal_aps.sql (cria _atendimentos)
--   - rj-sms-sandbox.sub_pav_us._condicoes
--   - rj-sms-sandbox.sub_pav_us._atendimentos
--   - rj-sms.saude_historico_clinico.episodio_assistencial
--
-- FILTROS:
--   - Fornecedor: 'vitacare'
--   - Especialidade: 'Agente comunitário de saúde'
--   - Subtipo: 'Visita Domiciliar'
--
-- SAÍDA:
--   - tipo_atd = 'visita_acs'
--   - Campos clínicos (peso, PA, etc.) são NULL para visitas ACS
--
-- AUTOR: Monitor Gestante Team
-- ÚLTIMA ATUALIZAÇÃO: 2026-01
-- ============================================================================

CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_atd_visitas_acs`()

BEGIN

-- Inserção na tabela de atendimentos (visitas ACS)
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
   clinica_nome AS unidade_APS_PN,
   equipe_nome AS equipe_PN_APS
 FROM `rj-sms-sandbox.sub_pav_us._condicoes`
),

-- ------------------------------------------------------------
-- CTE: visitas_com_join
-- Visitas domiciliares do ACS durante gestação
-- ------------------------------------------------------------
visitas_com_join AS (
 SELECT
   ea.id_hci,
   ea.paciente.id_paciente,
   ea.entrada_data,
   ea.estabelecimento.nome AS nome_estabelecimento,
   ea.profissional_saude_responsavel.nome AS nome_profissional,
   mt.id_gestacao,
   mt.cpf,
   mt.nome_gestante,
   mt.numero_gestacao,
   mt.idade_gestante,
   mt.data_inicio,
   mt.data_fim,
   mt.data_fim_efetiva,
   -- Adicionar coluna tipo_atd conforme regra
   'visita_acs' AS tipo_atd
 FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
 JOIN marcadores_temporais mt
   ON ea.paciente.id_paciente = mt.id_paciente
   AND ea.entrada_data BETWEEN mt.data_inicio AND COALESCE(mt.data_fim_efetiva, CURRENT_DATE())
 WHERE ea.prontuario.fornecedor = 'vitacare'
   AND ea.profissional_saude_responsavel.especialidade = 'Agente comunitário de saúde'
   AND ea.subtipo = 'Visita Domiciliar'
)

-- Resultado para inserção na tabela _atendimentos
SELECT 
    id_gestacao,
    id_paciente,
    entrada_data AS data_consulta,
    ROW_NUMBER() OVER (
        PARTITION BY id_gestacao
        ORDER BY entrada_data
    ) AS numero_consulta,
    DATE_DIFF(entrada_data, data_inicio, WEEK) AS ig_consulta,
    CASE
        WHEN DATE_DIFF(entrada_data, data_inicio, WEEK) <= 13 THEN 1
        WHEN DATE_DIFF(entrada_data, data_inicio, WEEK) <= 27 THEN 2
        ELSE 3
    END AS trimestre_consulta,
    CASE
        WHEN data_fim_efetiva IS NULL
        AND DATE_ADD(data_inicio, INTERVAL 300 DAY) > CURRENT_DATE() THEN 'Gestação'
        WHEN data_fim_efetiva IS NOT NULL
        AND DATE_DIFF (CURRENT_DATE(), data_fim_efetiva, DAY) <= 45 THEN 'Puerpério'
        ELSE 'Encerrada'
    END AS fase_atual,
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
    'Visita domiciliar' AS motivo_atendimento,
    CAST(NULL AS STRING) AS cid_string,
    'Realizada' AS desfecho_atendimento,
    CAST(NULL AS STRING) AS prescricoes,
    nome_estabelecimento AS estabelecimento,
    nome_profissional AS profissional_nome,
    'Agente comunitário de saúde' AS profissional_categoria
FROM visitas_com_join
ORDER BY id_gestacao, entrada_data;

END;
