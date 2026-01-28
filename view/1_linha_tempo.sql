-- ============================================================================
-- ARQUIVO: view/1_linha_tempo.sql
-- PROPÓSITO: View consolidada principal - linha do tempo das gestações
-- TABELA DESTINO: _view
-- ============================================================================
-- 
-- DESCRIÇÃO:
--   Este script cria a view consolidada final que combina todas as informações
--   das gestações, incluindo:
--   - Dados básicos da gestante e da gestação
--   - Condições médicas (diabetes, hipertensão, HIV, sífilis, etc.)
--   - Resumo de atendimentos (consultas, visitas ACS)
--   - Encaminhamentos (SISREG e SER)
--   - Prescrições (AAS, ácido fólico, carbonato de cálcio, anti-hipertensivos)
--   - Fatores de risco
--   - Eventos de parto
--
-- DEPENDÊNCIAS:
--   - Executar APÓS todos os scripts anteriores:
--     * 1_condicoes/1_gestacoes.sql
--     * 1_condicoes/2_gest_hipertensao.sql
--     * 2_atendimentos/1_atd_prenatal_aps.sql
--     * 2_atendimentos/2_visitas_acs_gestacao.sql
--     * 2_atendimentos/3_consultas_emergenciais.sql
--     * 2_atendimentos/4_encaminhamentos.sql
--   - rj-sms-sandbox.sub_pav_us._condicoes
--   - rj-sms-sandbox.sub_pav_us._atendimentos
--   - rj-sms-sandbox.sub_pav_us._cids_risco_gestacional_cat_encam
--   - rj-sms.saude_historico_clinico.paciente
--   - rj-sms.saude_historico_clinico.episodio_assistencial
--   - rj-sms.saude_estoque.movimento
--   - rj-sms.saude_dados_mestres.estabelecimento
--
-- FILTROS:
--   - fase_atual IN ('Gestação', 'Puerpério')
--
-- SAÍDA:
--   - Tabela `_view` com todas as informações consolidadas
--   - Aproximadamente 111 colunas
--
-- AUTOR: Monitor Gestante Team
-- ÚLTIMA ATUALIZAÇÃO: 2026-01
-- ============================================================================

CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_view_linha_tempo_consolidada`()

BEGIN

-- Criação da view consolidada principal
CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_us._view` AS

WITH 

-- Reutilização de CTEs das tabelas base
filtrado AS (
    SELECT * FROM `rj-sms-sandbox.sub_pav_us._condicoes`
),

-- ------------------------------------------------------------
-- CTE: pacientes_todos_cns
-- Agrega todos os CNS distintos para cada paciente
-- ------------------------------------------------------------
pacientes_todos_cns AS (
    SELECT 
        p.dados.id_paciente, 
        STRING_AGG(DISTINCT cns_individual, '; ' ORDER BY cns_individual) AS cns_string
    FROM
        `rj-sms.saude_historico_clinico.paciente` p
        LEFT JOIN UNNEST(p.cns) AS cns_individual
    WHERE
        cns_individual IS NOT NULL
        AND cns_individual != ''
    GROUP BY
        p.dados.id_paciente
),

-- ------------------------------------------------------------
-- CTE: condicoes_gestantes_raw
-- Coleta todas as condições (CIDs) e datas (reutilizada)
-- ------------------------------------------------------------
condicoes_gestantes_raw AS (
    SELECT ea.paciente.id_paciente, c.id AS cid, SAFE.PARSE_DATE (
            '%Y-%m-%d', SUBSTR(c.data_diagnostico, 1, 10)
        ) AS data_diagnostico, c.situacao
    FROM
        `rj-sms.saude_historico_clinico.episodio_assistencial` ea
        LEFT JOIN UNNEST (condicoes) c
    WHERE
        c.situacao IN ('ATIVO', 'RESOLVIDO')
        AND c.id IS NOT NULL
        AND c.data_diagnostico IS NOT NULL
        AND c.data_diagnostico != ''
),

-- ------------------------------------------------------------
-- CTE: categorias_risco_gestacional
-- Agrega categorias de risco distintas (reutilizada)
-- ------------------------------------------------------------
categorias_risco_gestacional AS (
    SELECT f.id_gestacao, STRING_AGG (
            DISTINCT r.categoria, '; '
            ORDER BY r.categoria
        ) AS categorias_risco,
        STRING_AGG(DISTINCT c.id, '; ' ORDER BY c.id) AS cid_alto_risco,
        STRING_AGG(DISTINCT r.Encaminhamento_Alto_Risco, '; ' ORDER BY r.Encaminhamento_Alto_Risco) AS encaminhamento_alto_risco,
        STRING_AGG(DISTINCT r.Justificativa_Condicao, '; ' ORDER BY r.Justificativa_Condicao) AS justificativa_condicao
    FROM
        filtrado f
        JOIN `rj-sms.saude_historico_clinico.episodio_assistencial` ea
        ON f.id_paciente = ea.paciente.id_paciente
        AND ea.entrada_data BETWEEN f.data_inicio AND COALESCE(
            f.data_fim_efetiva,
            CURRENT_DATE()
        )
        LEFT JOIN UNNEST (ea.condicoes) AS c
        JOIN `rj-sms-sandbox.sub_pav_us._cids_risco_gestacional_cat_encam` r
            ON c.id = r.cid
    WHERE
        c.id IS NOT NULL
    GROUP BY f.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: pacientes_info
-- Dados unificados do paciente (reutilizada)
-- ------------------------------------------------------------
pacientes_info AS (
 SELECT
   p_dedup.dados.id_paciente,
   p_dedup.cpf,
   p_dedup.cns,
   p_dedup.dados.nome,
   p_dedup.dados.data_nascimento,
   p_dedup.`equipe_saude_familia`[SAFE_OFFSET(0)].clinica_familia.id_cnes,
   DATE_DIFF(CURRENT_DATE(), p_dedup.dados.data_nascimento, YEAR) AS idade_atual,
   CASE
     WHEN DATE_DIFF(CURRENT_DATE(), p_dedup.dados.data_nascimento, YEAR) <= 15 THEN '≤15 anos'
     WHEN DATE_DIFF(CURRENT_DATE(), p_dedup.dados.data_nascimento, YEAR) <= 20 THEN '16-20 anos'
     WHEN DATE_DIFF(CURRENT_DATE(), p_dedup.dados.data_nascimento, YEAR) <= 30 THEN '21-30 anos'
     WHEN DATE_DIFF(CURRENT_DATE(), p_dedup.dados.data_nascimento, YEAR) <= 40 THEN '31-40 anos'
     ELSE '>40 anos'
   END AS faixa_etaria,
   p_dedup.dados.raca,
   p_dedup.dados.obito_indicador,
   p_dedup.dados.obito_data
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY dados.id_paciente ORDER BY cpf_particao DESC) AS rn
   FROM `rj-sms.saude_historico_clinico.paciente`
 ) p_dedup
 WHERE p_dedup.rn = 1
),

-- ------------------------------------------------------------
-- CTE: consultas_prenatal
-- Conta consultas de pré-natal (view)
-- ------------------------------------------------------------
consultas_prenatal AS (
    SELECT
        id_gestacao,
        COUNT(*) AS total_consultas_prenatal
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE tipo_atd = 'atd_prenatal'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: ultima_consulta_prenatal
-- Data da última consulta (view)
-- ------------------------------------------------------------
ultima_consulta_prenatal AS (
    SELECT
        id_gestacao,
        MAX(data_consulta) AS data_ultima_consulta
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE tipo_atd = 'atd_prenatal'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: visitas_acs_por_gestacao
-- Conta visitas do ACS (view)
-- ------------------------------------------------------------
visitas_acs_por_gestacao AS (
    SELECT
        id_gestacao,
        COUNT(*) AS total_visitas_acs
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE tipo_atd = 'visita_acs'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: ultima_visita_acs
-- Data da última visita do ACS (view)
-- ------------------------------------------------------------
ultima_visita_acs AS (
    SELECT
        id_gestacao,
        MAX(data_consulta) AS data_ultima_visita
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE tipo_atd = 'visita_acs'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: maior_pa_por_gestacao
-- Maior pressão arterial por gestação (view)
-- ------------------------------------------------------------
maior_pa_por_gestacao AS (
    SELECT *
    FROM (
            SELECT
                id_gestacao, pressao_sistolica, pressao_diastolica, data_consulta, ROW_NUMBER() OVER (
                    PARTITION BY id_gestacao
                    ORDER BY pressao_sistolica DESC, pressao_diastolica DESC
                ) AS rn
            FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
            WHERE
                pressao_sistolica IS NOT NULL
                AND pressao_diastolica IS NOT NULL
                AND tipo_atd = 'atd_prenatal'
        )
    WHERE rn = 1
),

-- ------------------------------------------------------------
-- CTE: condicoes_flags
-- Flags de condições médicas (reutilizada)
-- ------------------------------------------------------------
condicoes_flags AS (
    SELECT
        f.id_gestacao,
        -- Diabetes Prévio
        MAX(
            CASE
                WHEN (
                    cg.cid LIKE 'E1[0-4]%'
                    OR cg.cid LIKE 'O24[0-3]%'
                )
                AND cg.data_diagnostico < COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                ) THEN 1
                ELSE 0
            END
        ) AS diabetes_previo,
        -- Diabetes Gestacional
        MAX(
            CASE
                WHEN cg.cid = 'O244'
                AND cg.data_diagnostico BETWEEN f.data_inicio AND COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                )  THEN 1
                ELSE 0
            END
        ) AS diabetes_gestacional,
        -- Hipertensão Prévia
        MAX(
            CASE
                WHEN (
                    cg.cid LIKE 'I1[0-5]%'
                    OR cg.cid LIKE 'O10%'
                )
                AND cg.data_diagnostico < COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                ) THEN 1
                ELSE 0
            END
        ) AS hipertensao_previa,
        -- Pré-eclâmpsia
        MAX(
            CASE
                WHEN (
                    cg.cid LIKE 'O11%'
                    OR cg.cid LIKE 'O14%'
                )
                AND cg.data_diagnostico BETWEEN f.data_inicio AND COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                )  THEN 1
                ELSE 0
            END
        ) AS preeclampsia,
        -- HIV
        MAX(
            CASE
                WHEN (
                    cg.cid LIKE 'B2[0-4]%'
                    OR cg.cid = 'Z21'
                )
                AND cg.data_diagnostico <= COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                ) THEN 1
                ELSE 0
            END
        ) AS hiv,
        -- Sífilis
        MAX(
            CASE
                WHEN cg.cid LIKE 'A5[1-3]%'
                AND cg.data_diagnostico BETWEEN DATE_SUB(
                    f.data_inicio,
                    INTERVAL 30 DAY
                ) AND COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                )  THEN 1
                ELSE 0
            END
        ) AS sifilis,
        -- Tuberculose
        MAX(
            CASE
                WHEN cg.cid LIKE 'A1[5-9]%'
                AND cg.data_diagnostico BETWEEN DATE_SUB(
                    f.data_inicio,
                    INTERVAL 6 MONTH
                ) AND COALESCE(
                    f.data_fim_efetiva,
                    f.dpp,
                    CURRENT_DATE()
                )  THEN 1
                ELSE 0
            END
        ) AS tuberculose
    FROM
        filtrado f
        LEFT JOIN condicoes_gestantes_raw cg ON f.id_paciente = cg.id_paciente
    GROUP BY f.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: encaminhamentos_sisreg
-- Primeira solicitação SISREG por gestação
-- ------------------------------------------------------------
encaminhamentos_sisreg AS (
    SELECT *
    FROM (
        SELECT
            id_gestacao,
            data_consulta AS sisreg_primeira_data_solicitacao,
            desfecho_atendimento AS sisreg_primeira_status,
            desfecho_atendimento AS sisreg_primeira_situacao,
            motivo_atendimento AS sisreg_primeira_procedimento_nome,
            CAST(NULL AS STRING) AS sisreg_primeira_procedimento_id,
            cid_string AS sisreg_primeira_cid,
            estabelecimento AS sisreg_primeira_unidade_solicitante,
            profissional_nome AS sisreg_primeira_medico_solicitante,
            CAST(NULL AS STRING) AS sisreg_primeira_operador_solicitante,
            ROW_NUMBER() OVER (
                PARTITION BY id_gestacao 
                ORDER BY data_consulta ASC
            ) AS rn
        FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
        WHERE tipo_atd = 'encaminhamento'
        AND profissional_categoria = 'Médico'  -- SISREG tem médico
    )
    WHERE rn = 1
),

-- ------------------------------------------------------------
-- CTE: encaminhamentos_ser
-- Primeira solicitação SER por gestação
-- ------------------------------------------------------------
encaminhamentos_ser AS (
    SELECT *
    FROM (
        SELECT
            id_gestacao,
            CAST(NULL AS STRING) AS ser_classificacao_risco,
            motivo_atendimento AS ser_recurso_solicitado,
            desfecho_atendimento AS ser_estado_solicitacao,
            data_consulta AS ser_data_agendamento,
            CAST(NULL AS DATE) AS ser_data_execucao,
            estabelecimento AS ser_unidade_executante,
            cid_string AS ser_cid,
            CAST(NULL AS STRING) AS ser_descricao_cid,
            CAST(NULL AS STRING) AS ser_unidade_origem,
            ROW_NUMBER() OVER (
                PARTITION BY id_gestacao 
                ORDER BY data_consulta ASC
            ) AS rn
        FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
        WHERE tipo_atd = 'encaminhamento'
        AND profissional_categoria = 'Especialista'  -- SER tem especialista
    )
    WHERE rn = 1
),

-- ------------------------------------------------------------
-- CTE: encaminhamentos_consolidados
-- Status geral de encaminhamentos
-- ------------------------------------------------------------
encaminhamentos_consolidados AS (
    SELECT
        id_gestacao,
        CASE WHEN COUNT(*) > 0 THEN 'Sim' ELSE 'Não' END AS houve_encaminhamento,
        CASE 
            WHEN COUNT(CASE WHEN profissional_categoria = 'Médico' THEN 1 END) > 0 
            AND COUNT(CASE WHEN profissional_categoria = 'Especialista' THEN 1 END) > 0 
            THEN 'SISREG e SER'
            WHEN COUNT(CASE WHEN profissional_categoria = 'Médico' THEN 1 END) > 0 
            THEN 'SISREG'
            WHEN COUNT(CASE WHEN profissional_categoria = 'Especialista' THEN 1 END) > 0 
            THEN 'SER'
            ELSE 'Nenhum'
        END AS origem_encaminhamento,
        MIN(data_consulta) AS data_primeiro_encaminhamento,
        STRING_AGG(DISTINCT cid_string, '; ') AS cids_encaminhamento,
        STRING_AGG(DISTINCT motivo_atendimento, '; ') AS procedimentos_encaminhamento,
        STRING_AGG(DISTINCT desfecho_atendimento, '; ') AS status_encaminhamento
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE tipo_atd = 'encaminhamento'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: status_prescricoes
-- Status das prescrições (ácido fólico e carbonato de cálcio)
-- ------------------------------------------------------------
status_prescricoes AS (
    SELECT
        id_gestacao,
        MAX(
            CASE
                WHEN REGEXP_CONTAINS(LOWER(prescricoes), r'f[oó]lico') THEN 'sim'
                ELSE 'não'
            END
        ) AS prescricao_acido_folico,
        MAX(
            CASE
                WHEN REGEXP_CONTAINS(LOWER(prescricoes), r'c[aá]lcio') THEN 'sim'
                ELSE 'não'
            END
        ) AS prescricao_carbonato_calcio
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE tipo_atd = 'atd_prenatal'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: incluir_AP
-- Inclui área programática (reutilizada)
-- ------------------------------------------------------------
incluir_AP AS (
    SELECT pinfo.id_paciente, estab.area_programatica
    FROM
        pacientes_info pinfo
        LEFT JOIN `rj-sms.saude_historico_clinico.paciente` paciente
            ON pinfo.id_paciente = paciente.dados.id_paciente
        LEFT JOIN `rj-sms.saude_dados_mestres.estabelecimento` estab
            ON pinfo.id_cnes = estab.id_cnes
),

-- ------------------------------------------------------------
-- CTE: Urgencia_e_emergencia
-- Consultas de urgência/emergência (reutilizada)
-- ------------------------------------------------------------
Urgencia_e_emergencia AS (
    SELECT *
    FROM ( 
            SELECT f.id_gestacao, fapn.data_consulta, fapn.motivo_atendimento, fapn.estabelecimento,
                ROW_NUMBER() OVER (
                    PARTITION BY f.id_gestacao
                    ORDER BY fapn.data_consulta DESC
                ) as rn_ue
            FROM
                filtrado f
                LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` fapn
                    ON f.id_gestacao = fapn.id_gestacao
                    AND fapn.tipo_atd = 'consulta_emergencial'
                AND DATE(fapn.data_consulta) BETWEEN f.data_inicio AND COALESCE(
                    f.data_fim_efetiva, f.dpp, CURRENT_DATE()
                )
            WHERE
                fapn.id_gestacao IS NOT NULL
        )
    WHERE rn_ue = 1
),

-- ------------------------------------------------------------
-- CTE: prescricoes_antidiabeticos
-- Identifica prescrições de antidiabéticos
-- ------------------------------------------------------------
prescricoes_antidiabeticos AS (
    SELECT
        id_gestacao,
        MAX(
            CASE
                WHEN UPPER(prescricoes) LIKE '%METFORMINA%'
                OR UPPER(prescricoes) LIKE '%INSULINA%'
                OR UPPER(prescricoes) LIKE '%GLIBENCLAMIDA%'
                OR UPPER(prescricoes) LIKE '%GLICLAZIDA%' THEN 1
                ELSE 0
            END
        ) AS tem_antidiabetico,
        STRING_AGG(
            DISTINCT CASE
                WHEN UPPER(prescricoes) LIKE '%METFORMINA%' THEN 'METFORMINA'
                WHEN UPPER(prescricoes) LIKE '%INSULINA%' THEN 'INSULINA'
                WHEN UPPER(prescricoes) LIKE '%GLIBENCLAMIDA%' THEN 'GLIBENCLAMIDA'
                WHEN UPPER(prescricoes) LIKE '%GLICLAZIDA%' THEN 'GLICLAZIDA'
            END,
            '; '
        ) AS antidiabeticos_lista
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE prescricoes IS NOT NULL
    AND tipo_atd = 'atd_prenatal'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: classificacao_anti_hipertensivos_completa
-- Classifica anti-hipertensivos por adequação à gestação (expandida)
-- ------------------------------------------------------------
classificacao_anti_hipertensivos_completa AS (
    SELECT
        id_gestacao,
        -- Medicamentos individuais  
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%METILDOPA%' THEN 1 ELSE 0 END) AS tem_metildopa,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%HIDRALAZINA%' THEN 1 ELSE 0 END) AS tem_hidralazina,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%NIFEDIPINA%' THEN 1 ELSE 0 END) AS tem_nifedipina,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%HIDROCLOROTIAZIDA%' THEN 1 ELSE 0 END) AS tem_hidroclorotiazida,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%ANLODIPINA%' THEN 1 ELSE 0 END) AS tem_anlodipina,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%LOSARTANA%' THEN 1 ELSE 0 END) AS tem_losartana,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%ENALAPRIL%' THEN 1 ELSE 0 END) AS tem_enalapril,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%PROPRANOLOL%' THEN 1 ELSE 0 END) AS tem_propranolol,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%FUROSEMIDA%' THEN 1 ELSE 0 END) AS tem_furosemida,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%ATENOLOL%' THEN 1 ELSE 0 END) AS tem_atenolol,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%CAPTOPRIL%' THEN 1 ELSE 0 END) AS tem_captopril,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%CARVEDILOL%' THEN 1 ELSE 0 END) AS tem_carvedilol,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%VERAPAMIL%' THEN 1 ELSE 0 END) AS tem_verapamil,
        MAX(CASE WHEN UPPER(prescricoes) LIKE '%ESPIRONOLACTONA%' THEN 1 ELSE 0 END) AS tem_espironolactona
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
    WHERE prescricoes IS NOT NULL
    AND tipo_atd = 'atd_prenatal'
    GROUP BY id_gestacao
),

-- ------------------------------------------------------------
-- CTE: classificacao_final_anti_hipertensivos
-- Classificação final dos anti-hipertensivos por segurança
-- ------------------------------------------------------------
classificacao_final_anti_hipertensivos AS (
    SELECT
        id_gestacao,
        -- SEGUROS/ADEQUADOS na gestação
        CASE
            WHEN tem_metildopa = 1 OR tem_hidralazina = 1 OR tem_nifedipina = 1
            THEN 1 ELSE 0
        END AS tem_anti_hipertensivo_seguro,
        -- CONTRAINDICADOS/USO COM CAUTELA na gestação
        CASE
            WHEN tem_enalapril = 1 OR tem_captopril = 1 OR tem_losartana = 1
            OR tem_atenolol = 1 OR tem_propranolol = 1 OR tem_carvedilol = 1
            OR tem_anlodipina = 1 OR tem_verapamil = 1 OR tem_hidroclorotiazida = 1
            OR tem_furosemida = 1 OR tem_espironolactona = 1 
            THEN 1 ELSE 0
        END AS tem_anti_hipertensivo_contraindicado,
        -- Lista de medicamentos contraindicados
        STRING_AGG(DISTINCT
            CASE
                WHEN tem_enalapril = 1 THEN 'ENALAPRIL'
                WHEN tem_captopril = 1 THEN 'CAPTOPRIL'
                WHEN tem_losartana = 1 THEN 'LOSARTANA'
                WHEN tem_atenolol = 1 THEN 'ATENOLOL'
                WHEN tem_propranolol = 1 THEN 'PROPRANOLOL'
                WHEN tem_carvedilol = 1 THEN 'CARVEDILOL'
                WHEN tem_anlodipina = 1 THEN 'ANLODIPINA'
                WHEN tem_verapamil = 1 THEN 'VERAPAMIL'
                WHEN tem_hidroclorotiazida = 1 THEN 'HIDROCLOROTIAZIDA'
                WHEN tem_furosemida = 1 THEN 'FUROSEMIDA'
                WHEN tem_espironolactona = 1 THEN 'ESPIRONOLACTONA'
            END, '; '
        ) AS anti_hipertensivos_contraindicados
    FROM classificacao_anti_hipertensivos_completa
    GROUP BY
        id_gestacao, tem_metildopa, tem_hidralazina, tem_nifedipina,
        tem_enalapril, tem_captopril, tem_losartana, tem_atenolol,
        tem_propranolol, tem_carvedilol, tem_anlodipina, tem_verapamil,
        tem_hidroclorotiazida, tem_furosemida, tem_espironolactona
),

-- ------------------------------------------------------------
-- CTE: dispensacao_aparelho_pa
-- Identifica dispensação de aparelho de pressão arterial
-- ------------------------------------------------------------
dispensacao_aparelho_pa AS (
    SELECT
        f.id_gestacao,
        pi.cpf,
        MAX(
            CASE
                WHEN m.id_material = '65159513221' THEN 1
                ELSE 0
            END
        ) AS tem_aparelho_pa_dispensado,
        MIN(
            CASE
                WHEN m.id_material = '65159513221' THEN DATE(m.data_hora_evento)
            END
        ) AS data_primeira_dispensacao_pa,
        COUNT(
            CASE
                WHEN m.id_material = '65159513221' THEN 1
            END
        ) AS qtd_aparelhos_pa_dispensados
    FROM
        filtrado f
        JOIN pacientes_info pi ON f.id_paciente = pi.id_paciente
        LEFT JOIN `rj-sms.saude_estoque.movimento` m
            ON pi.cpf = m.consumo_paciente_cpf
        AND m.id_material = '65159513221'
        AND DATE(m.data_hora_evento) BETWEEN f.data_inicio AND COALESCE(
            f.data_fim_efetiva,
            CURRENT_DATE()
        )
    WHERE
        pi.cpf IS NOT NULL
        AND pi.cpf != ''
    GROUP BY
        f.id_gestacao,
        pi.cpf
),

-- ------------------------------------------------------------
-- CTE: fatores_risco_categorias
-- Extrai fatores de risco do campo categorias_risco
-- ------------------------------------------------------------
fatores_risco_categorias AS (
    SELECT
        f.id_gestacao,
        crg.categorias_risco,
        -- Doença renal (NEFROPATIAS)
        CASE
            WHEN UPPER(crg.categorias_risco) LIKE '%NEFROPATIAS%' THEN 1
            ELSE 0
        END AS doenca_renal_cat,
        -- Gravidez gemelar (GEMELARIDADE)
        CASE
            WHEN UPPER(crg.categorias_risco) LIKE '%GEMELARIDADE%' THEN 1
            ELSE 0
        END AS gravidez_gemelar_cat,
        -- Doença autoimune (COLAGENOSES)
        CASE
            WHEN UPPER(crg.categorias_risco) LIKE '%COLAGENOSES%' THEN 1
            ELSE 0
        END AS doenca_autoimune_cat
    FROM
        filtrado f
        LEFT JOIN categorias_risco_gestacional crg ON f.id_gestacao = crg.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: unnested_equipes
-- Prepara os dados de equipe, desaninhando o array `equipe_saude_familia`
-- ------------------------------------------------------------
unnested_equipes AS (
    SELECT
        p.dados.id_paciente AS id_paciente,
        eq.datahora_ultima_atualizacao,
        eq.nome AS equipe_nome,
        eq.clinica_familia.nome AS clinica_nome
    FROM
        `rj-sms.saude_historico_clinico.paciente` p
        LEFT JOIN UNNEST (p.equipe_saude_familia) AS eq
),

-- ------------------------------------------------------------
-- CTE: equipe_durante_gestacao
-- Identifica a equipe mais recente DURANTE o período da gestação
-- ------------------------------------------------------------
equipe_durante_gestacao AS (
    SELECT f.id_gestacao,
        eq.equipe_nome, eq.clinica_nome, ROW_NUMBER() OVER (
            PARTITION BY f.id_gestacao
            ORDER BY eq.datahora_ultima_atualizacao DESC
        ) AS rn
    FROM
        filtrado f
        LEFT JOIN unnested_equipes eq ON f.id_paciente = eq.id_paciente
        AND DATE(eq.datahora_ultima_atualizacao) <= COALESCE(
            f.data_fim_efetiva,
            CURRENT_DATE()
        )
),

-- ------------------------------------------------------------
-- CTE: equipe_anterior_gestacao
-- Identifica a equipe mais recente ANTES do início da gestação
-- ------------------------------------------------------------
equipe_anterior_gestacao AS (
    SELECT
        f.id_gestacao,
        eq.equipe_nome AS equipe_nome_anterior,
        ROW_NUMBER() OVER (
            PARTITION BY f.id_gestacao
            ORDER BY eq.datahora_ultima_atualizacao DESC
        ) AS rn
    FROM
        filtrado f
        LEFT JOIN unnested_equipes eq ON f.id_paciente = eq.id_paciente
        AND DATE(eq.datahora_ultima_atualizacao) < f.data_inicio
),

-- ------------------------------------------------------------
-- CTE: mudanca_equipe
-- Verifica se houve mudança de equipe
-- ------------------------------------------------------------
mudanca_equipe AS (
    SELECT
        d.id_gestacao,
        CASE
            WHEN COALESCE(d.equipe_nome, '') <> COALESCE(a.equipe_nome_anterior, '') THEN 1
            ELSE 0
        END AS mudanca_equipe_durante_pn
    FROM
        (SELECT id_gestacao, equipe_nome FROM equipe_durante_gestacao WHERE rn = 1) d
        LEFT JOIN (SELECT id_gestacao, equipe_nome_anterior FROM equipe_anterior_gestacao WHERE rn = 1) a 
        ON d.id_gestacao = a.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: eventos_parto
-- Identifica eventos de parto ou aborto
-- ------------------------------------------------------------
eventos_parto AS (
    SELECT
        ea.paciente.id_paciente,
        ea.entrada_data AS data_parto,
        ea.estabelecimento.nome AS estabelecimento_parto,
        ea.motivo_atendimento AS motivo_atencimento_parto,
        ea.desfecho_atendimento AS desfecho_atendimento_parto,
        CASE
            WHEN c.id LIKE 'O8[0-4]%'
            OR c.id LIKE 'Z37%'
            OR c.id LIKE 'Z39%' THEN 'Parto'
            WHEN c.id LIKE 'O0[0-4]%' THEN 'Aborto'
            ELSE 'Outro'
        END AS tipo_parto,
        c.id as cid_parto
    FROM
        `rj-sms.saude_historico_clinico.episodio_assistencial` ea
        LEFT JOIN UNNEST (ea.condicoes) AS c
    WHERE
        ea.entrada_data >= DATE '2021-01-01'
        AND LOWER(ea.prontuario.fornecedor) = 'vitai'
        AND (
            c.id LIKE 'O0[0-4]%'
            OR c.id LIKE 'O8[0-4]%'
            OR c.id LIKE 'Z37%'
            OR c.id LIKE 'Z38%'
            OR c.id LIKE 'Z39%'
        )
),

-- ------------------------------------------------------------
-- CTE: partos_associados
-- Associa o evento de parto/aborto mais próximo à data de fim efetiva da gestação
-- ------------------------------------------------------------
partos_associados AS (
    SELECT
        f.id_gestacao,
        ARRAY_AGG(
            STRUCT(e.data_parto, e.tipo_parto, e.estabelecimento_parto, e.motivo_atencimento_parto, e.desfecho_atendimento_parto)
            ORDER BY ABS(DATE_DIFF(e.data_parto, f.data_fim_efetiva, DAY))
            LIMIT 1
        )[OFFSET(0)] AS evento_parto_associado
    FROM filtrado f
    JOIN eventos_parto e
        ON f.id_paciente = e.id_paciente
        AND e.data_parto BETWEEN f.data_inicio AND DATE_ADD(COALESCE(f.data_fim_efetiva, f.dpp, CURRENT_DATE()), INTERVAL 15 DAY)
    GROUP BY f.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: final
-- Consulta final consolidada
-- ------------------------------------------------------------
final AS (
    SELECT
        f.id_paciente,
        pi.cpf,
        ptc.cns_string,
        pi.nome,
        pi.data_nascimento,
        DATE_DIFF (
            CURRENT_DATE(),
            pi.data_nascimento,
            YEAR
        ) AS idade_gestante,
        pi.faixa_etaria,
        pi.raca,
        f.numero_gestacao,
        f.id_gestacao,
        f.data_inicio,
        f.data_fim,
        f.data_fim_efetiva,
        f.dpp,
        f.fase_atual,
        f.trimestre_atual_gestacao AS trimestre,
        CASE
            WHEN f.fase_atual IN ('Gestação') THEN DATE_DIFF (
                CURRENT_DATE(),
                f.data_inicio,
                WEEK
            )
            ELSE NULL
        END AS IG_atual_semanas,
        CASE
            WHEN f.fase_atual IN ('Encerrada', 'Puerpério')
            AND f.data_fim_efetiva IS NOT NULL THEN DATE_DIFF (
                f.data_fim_efetiva,
                f.data_inicio,
                WEEK
            )
            ELSE NULL
        END AS IG_final_semanas,

    -- Condições básicas
    cf.diabetes_previo,
    cf.diabetes_gestacional,
    0 AS diabetes_nao_especificado, -- Campo de compatibilidade (se necessário, será implementado na CTE condicoes_flags)
    GREATEST(
        cf.diabetes_previo,
        cf.diabetes_gestacional
    ) AS diabetes_total,
    cf.hipertensao_previa,
    cf.preeclampsia,
    0 AS hipertensao_nao_especificada, -- Campo de compatibilidade (se necessário, será implementado na CTE condicoes_flags)
    GREATEST(
        cf.hipertensao_previa,
        cf.preeclampsia
    ) AS hipertensao_total,
    
    -- ========================================
    -- CAMPOS DE HIPERTENSÃO (DA TABELA _condicoes)
    -- Populados pelo script 2_gest_hipertensao.sql
    -- ========================================
    f.qtd_pas_alteradas,
    f.teve_pa_grave,
    f.total_medicoes_pa,
    f.percentual_pa_controlada,
    f.data_ultima_pa,
    f.ultima_sistolica,
    f.ultima_diastolica,
    f.ultima_pa_controlada,
    f.tem_anti_hipertensivo,
    f.tem_anti_hipertensivo_seguro,
    COALESCE(cfah.tem_anti_hipertensivo_contraindicado, 0) AS tem_anti_hipertensivo_contraindicado,
    f.anti_hipertensivos_seguros,
    cfah.anti_hipertensivos_contraindicados,
    -- Provável hipertensa sem diagnóstico (lógica simplificada)
    CASE
        WHEN (f.qtd_pas_alteradas >= 2 OR f.teve_pa_grave = 1 OR f.tem_anti_hipertensivo = 1)
        AND COALESCE(cf.hipertensao_previa, 0) = 0 AND COALESCE(cf.preeclampsia, 0) = 0 
        THEN 1 ELSE 0
    END AS provavel_hipertensa_sem_diagnostico,
    -- Encaminhamento HAS (baseado nos encaminhamentos gerais)
    CASE WHEN ec.houve_encaminhamento = 'Sim' THEN 1 ELSE 0 END AS tem_encaminhamento_has,
    ec.data_primeiro_encaminhamento AS data_primeiro_encaminhamento_has,
    ec.cids_encaminhamento AS cids_encaminhamento_has,
    -- AAS e aparelho PA
    f.tem_prescricao_aas,
    f.data_primeira_prescricao_aas,
    COALESCE(dap.tem_aparelho_pa_dispensado, 0) AS tem_aparelho_pa_dispensado,
    dap.data_primeira_dispensacao_pa,
    COALESCE(dap.qtd_aparelhos_pa_dispensados, 0) AS qtd_aparelhos_pa_dispensados,
    -- Antidiabéticos
    COALESCE(pad.tem_antidiabetico, 0) AS tem_antidiabetico,
    pad.antidiabeticos_lista,
    -- Fatores de risco
    COALESCE(frc.doenca_renal_cat, 0) AS doenca_renal_cat,
    COALESCE(frc.doenca_autoimune_cat, 0) AS doenca_autoimune_cat,
    COALESCE(frc.gravidez_gemelar_cat, 0) AS gravidez_gemelar_cat,
    -- Adequação AAS (campos simplificados para compatibilidade)
    CASE WHEN COALESCE(cf.hipertensao_previa, 0) = 1 OR COALESCE(cf.preeclampsia, 0) = 1 THEN 1 ELSE 0 END AS hipertensao_cronica_confirmada,
    CASE WHEN COALESCE(cf.diabetes_previo, 0) = 1 OR COALESCE(pad.tem_antidiabetico, 0) = 1 THEN 1 ELSE 0 END AS diabetes_previo_confirmado,
    (COALESCE(frc.doenca_renal_cat, 0) + COALESCE(frc.doenca_autoimune_cat, 0) + COALESCE(frc.gravidez_gemelar_cat, 0)) AS total_fatores_risco_pe,
    CASE WHEN f.tem_prescricao_aas = 1 THEN 1 ELSE 0 END AS tem_indicacao_aas,
    CASE WHEN f.tem_prescricao_aas = 1 THEN 'Adequado - Com AAS' ELSE 'Sem indicação' END AS adequacao_aas_pe,
    f.tem_obesidade,
    
    -- ========================================
    -- CAMPOS DE ENCAMINHAMENTOS
    -- ========================================
    -- Status geral de encaminhamentos
    ec.houve_encaminhamento,
    ec.origem_encaminhamento,
    CASE WHEN ec.houve_encaminhamento = 'Sim' THEN 'sim' ELSE 'não' END AS encaminhado_sisreg,
    
    -- Colunas do SISREG (primeira solicitação)
    esis.sisreg_primeira_data_solicitacao,
    esis.sisreg_primeira_status,
    esis.sisreg_primeira_situacao,
    esis.sisreg_primeira_procedimento_nome,
    esis.sisreg_primeira_procedimento_id,
    esis.sisreg_primeira_cid,
    esis.sisreg_primeira_unidade_solicitante,
    esis.sisreg_primeira_medico_solicitante,
    esis.sisreg_primeira_operador_solicitante,

    -- Colunas do SER (primeira solicitação)
    eser.ser_classificacao_risco,
    eser.ser_recurso_solicitado,
    eser.ser_estado_solicitacao,
    eser.ser_data_agendamento,
    eser.ser_data_execucao,
    eser.ser_unidade_executante,
    eser.ser_cid,
    eser.ser_descricao_cid,
    eser.ser_unidade_origem,
    
    -- Campos consolidados de encaminhamentos
    ec.data_primeiro_encaminhamento,
    ec.cids_encaminhamento,
    ec.procedimentos_encaminhamento,
    ec.status_encaminhamento,
    
    -- ========================================
    -- OUTRAS CONDIÇÕES
    -- ========================================
    cf.hiv,
    cf.sifilis,
    cf.tuberculose,
    crg.categorias_risco,
    crg.justificativa_condicao, 
    crg.encaminhamento_alto_risco as deve_encaminhar, 
    crg.cid_alto_risco,
    pa_max.pressao_sistolica AS max_pressao_sistolica,
    pa_max.pressao_diastolica AS max_pressao_diastolica,
    pa_max.data_consulta AS data_max_pa,
    
    -- ========================================
    -- CONSULTAS E ATENDIMENTOS
    -- ========================================
    COALESCE(cp.total_consultas_prenatal, 0) AS total_consultas_prenatal,
    COALESCE(sp.prescricao_acido_folico, 'não') AS prescricao_acido_folico,
    COALESCE(sp.prescricao_carbonato_calcio, 'não') AS prescricao_carbonato_calcio,
    CASE
        WHEN ucp.data_ultima_consulta IS NOT NULL THEN DATE_DIFF (
            CURRENT_DATE(),
            ucp.data_ultima_consulta,
            DAY
        )
        ELSE NULL
    END AS dias_desde_ultima_consulta,
    CASE
        WHEN ucp.data_ultima_consulta IS NOT NULL
        AND DATE_DIFF (
            CURRENT_DATE(),
            ucp.data_ultima_consulta,
            DAY
        ) >= 30 THEN 'sim'
        ELSE 'não'
    END AS mais_de_30_sem_atd,
    COALESCE(v_acs.total_visitas_acs, 0) AS total_visitas_acs,
    uv_acs.data_ultima_visita,
    CASE
        WHEN uv_acs.data_ultima_visita IS NOT NULL THEN DATE_DIFF (
            CURRENT_DATE(),
            uv_acs.data_ultima_visita,
            DAY
        )
        ELSE NULL
    END AS dias_desde_ultima_visita_acs,
    
    -- ========================================
    -- INFORMAÇÕES GERAIS
    -- ========================================
    pi.obito_indicador,
    pi.obito_data,
    iap.area_programatica,
    f.clinica_nome,
    f.equipe_nome,
    COALESCE(me.mudanca_equipe_durante_pn, 0) AS mudanca_equipe_durante_pn,
    -- Eventos de parto
    pa.evento_parto_associado.data_parto,
    pa.evento_parto_associado.tipo_parto,
    pa.evento_parto_associado.estabelecimento_parto,
    pa.evento_parto_associado.motivo_atencimento_parto,
    pa.evento_parto_associado.desfecho_atendimento_parto,
    CASE
        WHEN ue.data_consulta IS NOT NULL THEN 'sim'
        ELSE 'não'
    END AS Urg_Emrg,
    ue.data_consulta as ue_data_consulta,
    ue.motivo_atendimento as ue_motivo_atendimento,
    ue.estabelecimento as ue_nome_estabelecimento

    FROM
        filtrado f
        LEFT JOIN pacientes_info pi ON f.id_paciente = pi.id_paciente
        LEFT JOIN pacientes_todos_cns ptc ON f.id_paciente = ptc.id_paciente
        LEFT JOIN incluir_AP iap ON f.id_paciente = iap.id_paciente
        LEFT JOIN consultas_prenatal cp ON f.id_gestacao = cp.id_gestacao
        LEFT JOIN status_prescricoes sp ON f.id_gestacao = sp.id_gestacao
        LEFT JOIN ultima_consulta_prenatal ucp ON f.id_gestacao = ucp.id_gestacao
        LEFT JOIN visitas_acs_por_gestacao v_acs ON f.id_gestacao = v_acs.id_gestacao
        LEFT JOIN ultima_visita_acs uv_acs ON f.id_gestacao = uv_acs.id_gestacao
        LEFT JOIN maior_pa_por_gestacao pa_max ON f.id_gestacao = pa_max.id_gestacao
        LEFT JOIN categorias_risco_gestacional crg ON f.id_gestacao = crg.id_gestacao
        LEFT JOIN condicoes_flags cf ON f.id_gestacao = cf.id_gestacao
        LEFT JOIN encaminhamentos_consolidados ec ON f.id_gestacao = ec.id_gestacao
        LEFT JOIN encaminhamentos_sisreg esis ON f.id_gestacao = esis.id_gestacao
        LEFT JOIN encaminhamentos_ser eser ON f.id_gestacao = eser.id_gestacao
        LEFT JOIN Urgencia_e_emergencia ue ON f.id_gestacao = ue.id_gestacao
        -- Novos JOINs para CTEs adicionadas
        LEFT JOIN prescricoes_antidiabeticos pad ON f.id_gestacao = pad.id_gestacao
        LEFT JOIN classificacao_final_anti_hipertensivos cfah ON f.id_gestacao = cfah.id_gestacao
        LEFT JOIN dispensacao_aparelho_pa dap ON f.id_gestacao = dap.id_gestacao
        LEFT JOIN fatores_risco_categorias frc ON f.id_gestacao = frc.id_gestacao
        LEFT JOIN mudanca_equipe me ON f.id_gestacao = me.id_gestacao
        LEFT JOIN partos_associados pa ON f.id_gestacao = pa.id_gestacao
        -- CORREÇÃO: Filtro unificado - incluir tanto Gestação quanto Puerpério
        -- O filtro anterior era contraditório (linha 989 excluía Puerpério, linha 995 incluía)
        WHERE 
            f.fase_atual IN ('Gestação', 'Puerpério')
)

SELECT
    *
FROM final;

END;


