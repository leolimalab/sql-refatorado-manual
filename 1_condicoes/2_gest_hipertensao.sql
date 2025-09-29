-- ============================================================================
-- ARQUIVO: condicoes/2_gest_hipertensao.sql
-- PROPÓSITO: CTEs específicas para hipertensão na gestação
-- TABELA DESTINO: _condicoes (complementa)
-- ============================================================================

-- Sintaxe para criar ou substituir uma consulta salva (procedimento)
CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_cond_hipertensao_gestacional`()

BEGIN

-- Atualização da tabela de condições com dados de hipertensão
-- (Este procedimento deve ser executado após 1_gestacoes.sql)

-- Criação de tabela temporária para análise de hipertensão
CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_us._temp_hipertensao` AS

WITH

-- Reutilizando dados base das gestações
filtrado AS (
    SELECT * FROM `rj-sms-sandbox.sub_pav_us._condicoes`
),

-- ------------------------------------------------------------
-- CTE: analise_pressao_arterial
-- Análise detalhada das medições de PA
-- ------------------------------------------------------------
analise_pressao_arterial AS (
    SELECT
        f.id_gestacao,
        fapn.data_consulta,
        CAST(fapn.pressao_sistolica AS INT64) AS pressao_sistolica,
        CAST(fapn.pressao_diastolica AS INT64) AS pressao_diastolica,
        -- PA alterada (≥140/90)
        CASE
            WHEN CAST(fapn.pressao_sistolica AS INT64) >= 140
            OR CAST(fapn.pressao_diastolica AS INT64) >= 90 THEN 1
            ELSE 0
        END AS pa_alterada,
        -- PA grave (>160/110)
        CASE
            WHEN CAST(fapn.pressao_sistolica AS INT64) > 160
            OR CAST(fapn.pressao_diastolica AS INT64) > 110 THEN 1
            ELSE 0
        END AS pa_grave,
        -- PA controlada (<140/90)
        CASE
            WHEN CAST(fapn.pressao_sistolica AS INT64) < 140
            AND CAST(fapn.pressao_diastolica AS INT64) < 90 THEN 1
            ELSE 0
        END AS pa_controlada
    FROM
        filtrado f
        LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` fapn
        ON f.id_gestacao = fapn.id_gestacao
        AND fapn.tipo_atd = 'atd_prenatal'
    WHERE
        fapn.pressao_sistolica IS NOT NULL
        AND fapn.pressao_diastolica IS NOT NULL
),

-- ------------------------------------------------------------
-- CTE: resumo_controle_pressorico
-- Resume controle pressórico por gestação
-- ------------------------------------------------------------
resumo_controle_pressorico AS (
    SELECT
        id_gestacao,
        -- Quantidade de PAs alteradas
        COUNT(
            CASE
                WHEN pa_alterada = 1 THEN 1
            END
        ) AS qtd_pas_alteradas,
        -- Se teve PA grave
        MAX(pa_grave) AS teve_pa_grave,
        -- Total de medições
        COUNT(*) AS total_medicoes_pa,
        -- Percentual de atendimentos com controle (<140x90)
        ROUND(
            COUNT(
                CASE
                    WHEN pa_controlada = 1 THEN 1
                END
            ) * 100.0 / COUNT(*),
            1
        ) AS percentual_pa_controlada
    FROM analise_pressao_arterial
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: ultima_pa_aferida
-- Última PA aferida
-- ------------------------------------------------------------
ultima_pa_aferida AS (
    SELECT *
    FROM (
            SELECT
                id_gestacao, 
                data_consulta AS data_ultima_pa, 
                pressao_sistolica AS ultima_sistolica,  -- já convertido para INT64 no CTE anterior
                pressao_diastolica AS ultima_diastolica,  -- já convertido para INT64 no CTE anterior
                pa_controlada AS ultima_pa_controlada, 
                ROW_NUMBER() OVER (
                    PARTITION BY id_gestacao
                    ORDER BY data_consulta DESC
                ) AS rn
            FROM analise_pressao_arterial
        )
    WHERE rn = 1
),

-- ------------------------------------------------------------
-- CTE: prescricoes_anti_hipertensivos
-- Identifica prescrições de anti-hipertensivos
-- ------------------------------------------------------------
prescricoes_anti_hipertensivos AS (
    SELECT
        f.id_gestacao,
        -- Medicamentos individuais
        MAX(
            CASE
                WHEN UPPER(fapn.prescricoes) LIKE '%METILDOPA%' THEN 1
                ELSE 0
            END
        ) AS tem_metildopa,
        MAX(
            CASE
                WHEN UPPER(fapn.prescricoes) LIKE '%HIDRALAZINA%' THEN 1
                ELSE 0
            END
        ) AS tem_hidralazina,
        MAX(
            CASE
                WHEN UPPER(fapn.prescricoes) LIKE '%NIFEDIPINA%' THEN 1
                ELSE 0
            END
        ) AS tem_nifedipina,
        -- Flag geral de anti-hipertensivo
        MAX(
            CASE
                WHEN UPPER(fapn.prescricoes) LIKE '%METILDOPA%'
                OR UPPER(fapn.prescricoes) LIKE '%HIDRALAZINA%'
                OR UPPER(fapn.prescricoes) LIKE '%NIFEDIPINA%'
                OR UPPER(fapn.prescricoes) LIKE '%HIDROCLOROTIAZIDA%'
                OR UPPER(fapn.prescricoes) LIKE '%ANLODIPINA%'
                OR UPPER(fapn.prescricoes) LIKE '%LOSARTANA%'
                OR UPPER(fapn.prescricoes) LIKE '%ENALAPRIL%' THEN 1
                ELSE 0
            END
        ) AS tem_anti_hipertensivo
    FROM
        filtrado f
        LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` fapn
        ON f.id_gestacao = fapn.id_gestacao
        AND fapn.tipo_atd = 'atd_prenatal'
    WHERE
        fapn.prescricoes IS NOT NULL
        AND fapn.prescricoes != ''
    GROUP BY f.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: classificacao_anti_hipertensivos
-- Classifica anti-hipertensivos por adequação à gestação
-- ------------------------------------------------------------
classificacao_anti_hipertensivos AS (
 SELECT
   pah.id_gestacao,
   pah.tem_anti_hipertensivo,
   -- SEGUROS/ADEQUADOS na gestação
   CASE
     WHEN pah.tem_metildopa = 1
       OR pah.tem_hidralazina = 1
       OR pah.tem_nifedipina = 1
     THEN 1 ELSE 0
   END AS tem_anti_hipertensivo_seguro,

   -- Listas de medicamentos seguros
   STRING_AGG(DISTINCT
     CASE
       WHEN pah.tem_metildopa = 1 THEN 'METILDOPA'
       WHEN pah.tem_hidralazina = 1 THEN 'HIDRALAZINA'
       WHEN pah.tem_nifedipina = 1 THEN 'NIFEDIPINA'
     END, '; '
   ) AS anti_hipertensivos_seguros

 FROM prescricoes_anti_hipertensivos pah
 GROUP BY
   pah.id_gestacao,
   pah.tem_anti_hipertensivo,
   pah.tem_metildopa,
   pah.tem_hidralazina,
   pah.tem_nifedipina
),

-- ------------------------------------------------------------
-- CTE: prescricao_aas
-- Identifica prescrição de AAS
-- ------------------------------------------------------------
prescricao_aas AS (
    SELECT
        f.id_gestacao,
        MAX(
            CASE
                WHEN UPPER(fapn.prescricoes) LIKE '%ACIDO ACETILSALICILICO%' THEN 1
                ELSE 0
            END
        ) AS tem_prescricao_aas,
        -- Data da primeira prescrição
        MIN(
            CASE
                WHEN UPPER(fapn.prescricoes) LIKE '%ACIDO ACETILSALICILICO%' THEN fapn.data_consulta
            END
        ) AS data_primeira_prescricao_aas
    FROM
        filtrado f
        LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` fapn
        ON f.id_gestacao = fapn.id_gestacao
        AND fapn.tipo_atd = 'atd_prenatal'
    WHERE
        fapn.prescricoes IS NOT NULL
    GROUP BY f.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: obesidade_gestante
-- Identifica obesidade por IMC
-- ------------------------------------------------------------
obesidade_gestante AS (
  SELECT
    f.id_gestacao,
    MAX(
      CASE
        WHEN SAFE_CAST(fapn.imc_consulta AS FLOAT64) > 30.0
          OR SAFE_CAST(fapn.imc_inicio AS FLOAT64) >= 30.0
        THEN 1 ELSE 0
      END
    ) AS tem_obesidade
  FROM filtrado f
  LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` fapn
    ON f.id_gestacao = fapn.id_gestacao
    AND fapn.tipo_atd = 'atd_prenatal'
  GROUP BY f.id_gestacao
),

-- Consolidação final dos dados de hipertensão
hipertensao_consolidada AS (
    SELECT
        f.id_gestacao,
        -- Dados de controle pressórico
        COALESCE(rcp.qtd_pas_alteradas, 0) AS qtd_pas_alteradas,
        COALESCE(rcp.teve_pa_grave, 0) AS teve_pa_grave,
        COALESCE(rcp.total_medicoes_pa, 0) AS total_medicoes_pa,
        rcp.percentual_pa_controlada,
        upa.data_ultima_pa,
        CAST(COALESCE(upa.ultima_sistolica, 0) AS INT64) AS ultima_sistolica,
        CAST(COALESCE(upa.ultima_diastolica, 0) AS INT64) AS ultima_diastolica,
        COALESCE(upa.ultima_pa_controlada, 0) AS ultima_pa_controlada,
        -- Medicamentos
        COALESCE(cah.tem_anti_hipertensivo, 0) AS tem_anti_hipertensivo,
        COALESCE(cah.tem_anti_hipertensivo_seguro, 0) AS tem_anti_hipertensivo_seguro,
        cah.anti_hipertensivos_seguros,
        -- AAS e obesidade
        COALESCE(paas.tem_prescricao_aas, 0) AS tem_prescricao_aas,
        paas.data_primeira_prescricao_aas,
        COALESCE(og.tem_obesidade, 0) AS tem_obesidade
    FROM filtrado f
    LEFT JOIN resumo_controle_pressorico rcp ON f.id_gestacao = rcp.id_gestacao
    LEFT JOIN ultima_pa_aferida upa ON f.id_gestacao = upa.id_gestacao
    LEFT JOIN classificacao_anti_hipertensivos cah ON f.id_gestacao = cah.id_gestacao
    LEFT JOIN prescricao_aas paas ON f.id_gestacao = paas.id_gestacao
    LEFT JOIN obesidade_gestante og ON f.id_gestacao = og.id_gestacao
)

SELECT * FROM hipertensao_consolidada;

-- As colunas de hipertensão já existem na tabela _condicoes (criadas em 1_gestacoes.sql)

-- Atualizar tabela principal _condicoes com dados de hipertensão
UPDATE `rj-sms-sandbox.sub_pav_us._condicoes` AS base
SET 
    base.qtd_pas_alteradas = temp.qtd_pas_alteradas,
    base.teve_pa_grave = temp.teve_pa_grave,
    base.total_medicoes_pa = temp.total_medicoes_pa,
    base.percentual_pa_controlada = temp.percentual_pa_controlada,
    base.data_ultima_pa = temp.data_ultima_pa,
    base.ultima_sistolica = temp.ultima_sistolica,
    base.ultima_diastolica = temp.ultima_diastolica,
    base.ultima_pa_controlada = temp.ultima_pa_controlada,
    base.tem_anti_hipertensivo = temp.tem_anti_hipertensivo,
    base.tem_anti_hipertensivo_seguro = temp.tem_anti_hipertensivo_seguro,
    base.anti_hipertensivos_seguros = temp.anti_hipertensivos_seguros,
    base.tem_prescricao_aas = temp.tem_prescricao_aas,
    base.data_primeira_prescricao_aas = temp.data_primeira_prescricao_aas,
    base.tem_obesidade = temp.tem_obesidade
FROM `rj-sms-sandbox.sub_pav_us._temp_hipertensao` AS temp
WHERE base.id_gestacao = temp.id_gestacao;

-- Limpar tabela temporária
DROP TABLE `rj-sms-sandbox.sub_pav_us._temp_hipertensao`;

END;
