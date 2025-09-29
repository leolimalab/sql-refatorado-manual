-- ============================================================================
-- ARQUIVO: atendimentos/4_encaminhamentos.sql
-- PROPÓSITO: CTEs para encaminhamentos SISREG e SER durante gestação
-- TABELA DESTINO: _atendimentos (complementa)
-- ============================================================================

-- Sintaxe para criar ou substituir uma consulta salva (procedimento)
CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_atd_encaminhamentos`()

BEGIN

-- Inserção na tabela de atendimentos (encaminhamentos)
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
-- CTE: gestacoes_definidas
-- Seleciona gestações ativas
-- ------------------------------------------------------------
gestacoes_definidas AS (
    SELECT
        id_gestacao,
        id_paciente,
        cpf,
        data_inicio,
        data_fim_efetiva
    FROM `rj-sms-sandbox.sub_pav_us._condicoes`
    WHERE fase_atual = 'Gestação'
),

-- ------------------------------------------------------------
-- CTE: paciente_identificadores
-- Lista de identificadores (CPF e CNS) das gestantes
-- ------------------------------------------------------------
paciente_identificadores AS (
    SELECT
        g.id_paciente,
        p.cpf,
        cns_paciente
    FROM gestacoes_definidas g
    JOIN `rj-sms.saude_historico_clinico.paciente` p ON g.id_paciente = p.dados.id_paciente
    LEFT JOIN UNNEST(p.cns) AS cns_paciente
    QUALIFY ROW_NUMBER() OVER(PARTITION BY g.id_paciente, cns_paciente) = 1
),

-- ------------------------------------------------------------
-- CTE: sisreg_pre_filtrado
-- Pré-filtra dados do SISREG
-- ------------------------------------------------------------
sisreg_pre_filtrado AS (
    SELECT
        pi.id_paciente,
        pi.cpf,
        s.*
    FROM `rj-sms.brutos_sisreg_api.solicitacoes` s
    JOIN paciente_identificadores pi
    ON (s.paciente_cpf = pi.cpf AND pi.cpf IS NOT NULL AND pi.cpf != '')
    OR (s.paciente_cns = pi.cns_paciente AND pi.cns_paciente IS NOT NULL AND pi.cns_paciente != '')
    WHERE s.procedimento_id IN ('0703844','0703886','0737024','0710301','0710128')
),

-- ------------------------------------------------------------
-- CTE: ser_pre_filtrado
-- Pré-filtra dados do SER
-- ------------------------------------------------------------
ser_pre_filtrado AS (
    SELECT
        pi.id_paciente,
        pi.cpf,
        ser.*
    FROM `rj-sms-sandbox.sub_pav_us.BD SER PRÉ NATAL 2024_2025AGO` ser
    JOIN paciente_identificadores pi
    ON CAST(ser.cns AS STRING) = pi.cns_paciente AND pi.cns_paciente IS NOT NULL
),

-- ------------------------------------------------------------
-- CTE: encaminhamento_SISREG
-- Associa encaminhamentos SISREG às gestações
-- ------------------------------------------------------------
encaminhamento_SISREG AS (
    SELECT
        g.id_gestacao,
        g.id_paciente,
        DATE(s.data_solicitacao) AS data_solicitacao,
        s.solicitacao_status,
        s.solicitacao_situacao,
        s.procedimento,
        s.procedimento_id,
        s.unidade_solicitante,
        s.medico_solicitante,
        s.operador_solicitante_nome,
        s.cid_id,
        'encaminhamento' AS tipo_atd,
        ROW_NUMBER() OVER (PARTITION BY g.id_gestacao ORDER BY s.data_solicitacao ASC) as rn_solicitacao
    FROM gestacoes_definidas g
    JOIN sisreg_pre_filtrado s ON g.id_paciente = s.id_paciente
    WHERE DATE(s.data_solicitacao) BETWEEN g.data_inicio AND COALESCE(g.data_fim_efetiva, CURRENT_DATE())
),

-- ------------------------------------------------------------
-- CTE: encaminhamento_SER
-- Associa encaminhamentos SER às gestações
-- ------------------------------------------------------------
encaminhamento_SER AS (
    SELECT
        g.id_gestacao,
        g.id_paciente,
        CAST(s.Dt_agendamento AS DATE) AS Dt_agendamento,
        CAST(s.Dt_execucao AS DATE) AS Dt_execucao,
        s.classificacao_risco,
        s.Recurso_Solicitado,
        s.Estado_Solicitacao,
        s.Codigo_cid,
        s.Descricao_cid,
        s.UnidadeExecutante,
        s.Unidade_Origem,
        'encaminhamento' AS tipo_atd,
        ROW_NUMBER() OVER (PARTITION BY g.id_gestacao ORDER BY CAST(s.Dt_Solicitacao AS DATE) ASC) as rn_solicitacao
    FROM gestacoes_definidas g
    JOIN ser_pre_filtrado s ON g.id_paciente = s.id_paciente
    WHERE CAST(s.Dt_Solicitacao AS DATE) BETWEEN g.data_inicio AND COALESCE(g.data_fim_efetiva, CURRENT_DATE())
)

-- Resultado consolidado para inserção na tabela _atendimentos
SELECT
    id_gestacao,
    id_paciente,
    data_solicitacao AS data_consulta,
    ROW_NUMBER() OVER (PARTITION BY id_gestacao ORDER BY data_solicitacao) AS numero_consulta,
    CAST(NULL AS INT64) AS ig_consulta,
    CAST(NULL AS INT64) AS trimestre_consulta,
    'Gestação' AS fase_atual,
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
    procedimento AS motivo_atendimento,
    cid_id AS cid_string,
    solicitacao_situacao AS desfecho_atendimento,
    CAST(NULL AS STRING) AS prescricoes,
    unidade_solicitante AS estabelecimento,
    medico_solicitante AS profissional_nome,
    'Médico' AS profissional_categoria
FROM encaminhamento_SISREG
WHERE rn_solicitacao = 1

UNION ALL

SELECT
    id_gestacao,
    id_paciente,
    Dt_agendamento AS data_consulta,
    ROW_NUMBER() OVER (PARTITION BY id_gestacao ORDER BY Dt_agendamento) AS numero_consulta,
    CAST(NULL AS INT64) AS ig_consulta,
    CAST(NULL AS INT64) AS trimestre_consulta,
    'Gestação' AS fase_atual,
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
    Recurso_Solicitado AS motivo_atendimento,
    Codigo_cid AS cid_string,
    Estado_Solicitacao AS desfecho_atendimento,
    CAST(NULL AS STRING) AS prescricoes,
    UnidadeExecutante AS estabelecimento,
    CAST(NULL AS STRING) AS profissional_nome,
    'Especialista' AS profissional_categoria
FROM encaminhamento_SER
WHERE rn_solicitacao = 1

ORDER BY id_gestacao, data_consulta;

END;
