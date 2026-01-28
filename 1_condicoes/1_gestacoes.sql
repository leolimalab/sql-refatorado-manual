-- ============================================================================
-- ARQUIVO: 1_condicoes/1_gestacoes.sql
-- PROPÓSITO: CTEs básicas para identificação e gestão de gestações
-- TABELA DESTINO: _condicoes
-- ============================================================================
-- 
-- DESCRIÇÃO:
--   Este script identifica gestações a partir de eventos clínicos (CIDs Z32.1, 
--   Z34%, Z35%) e cria a tabela base de condições. Os eventos são agrupados
--   por paciente com janela de 60 dias para identificar gestações distintas.
--
-- DEPENDÊNCIAS:
--   - rj-sms.saude_historico_clinico.paciente
--   - rj-sms.saude_historico_clinico.episodio_assistencial
--
-- SAÍDA:
--   - Tabela `_condicoes` com dados básicos de cada gestação
--   - Colunas de hipertensão são inicializadas com valores default (NULL/0)
--     e serão populadas pelo script 2_gest_hipertensao.sql
--
-- AUTOR: Monitor Gestante Team
-- ÚLTIMA ATUALIZAÇÃO: 2026-01
-- ============================================================================

CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`()

BEGIN

-- Criação da tabela de condições de gestação
CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_us._condicoes` AS

WITH

    -- ------------------------------------------------------------
    -- CTE: cadastro_paciente
    -- Recuperando dados básicos do paciente
    -- ------------------------------------------------------------
    cadastro_paciente AS (
        SELECT
            dados.id_paciente,
            dados.nome,
            DATE_DIFF (
                CURRENT_DATE(),
                dados.data_nascimento,
                YEAR
            ) AS idade_gestante
        FROM `rj-sms.saude_historico_clinico.paciente`        
    ),

    -- ------------------------------------------------------------
    -- CTE: eventos_brutos
    -- Seleciona eventos clínicos brutos que podem indicar início ou fim de gestação
    -- Filtra por CIDs específicos (Z32.1, Z34, Z35)
    -- ------------------------------------------------------------
    eventos_brutos AS (
        SELECT
            id_hci,
            paciente.id_paciente AS id_paciente,
            paciente_cpf as cpf,
            cp.nome,
            cp.idade_gestante,
            c.id AS cid,
            c.situacao AS situacao_cid,
            SAFE.PARSE_DATE (
                '%Y-%m-%d',
                SUBSTR(c.data_diagnostico, 1, 10)
            ) AS data_evento,
            CASE
                WHEN c.id = 'Z321'
                OR c.id LIKE 'Z34%'
                OR c.id LIKE 'Z35%' THEN 'gestacao'
                ELSE NULL
            END AS tipo_evento
        FROM
            `rj-sms.saude_historico_clinico.episodio_assistencial`
            LEFT JOIN UNNEST (condicoes) c
            INNER JOIN cadastro_paciente cp ON paciente.id_paciente = cp.id_paciente
        WHERE
            c.data_diagnostico IS NOT NULL
            AND c.data_diagnostico != ''
            AND c.situacao IN ('ATIVO', 'RESOLVIDO')
            AND (
                c.id = 'Z321'
                OR c.id LIKE 'Z34%'
                OR c.id LIKE 'Z35%'
            )
            AND paciente.id_paciente IS NOT NULL
    ),

    -- ------------------------------------------------------------
    -- CTE: inicios_brutos
    -- Filtra eventos de início de gestação (situacao = 'ATIVO')
    -- ------------------------------------------------------------
    inicios_brutos AS (
        SELECT *
        FROM eventos_brutos
        WHERE
            tipo_evento = 'gestacao'
            AND situacao_cid = 'ATIVO'
    ),

    -- ------------------------------------------------------------
    -- CTE: finais
    -- Filtra eventos de fim de gestação (situacao = 'RESOLVIDO')
    -- ------------------------------------------------------------
    finais AS (
        SELECT *
        FROM eventos_brutos
        WHERE
            tipo_evento = 'gestacao'
            AND situacao_cid = 'RESOLVIDO'
    ),

    -- ------------------------------------------------------------
    -- CTE: inicios_com_grupo
    -- Prepara dados para agrupar eventos de início próximos
    -- ------------------------------------------------------------
    inicios_com_grupo AS (
        SELECT
            *,
            LAG(data_evento) OVER (
                PARTITION BY id_paciente
                ORDER BY data_evento
            ) AS data_anterior,
            CASE
                WHEN LAG(data_evento) OVER (
                    PARTITION BY id_paciente
                    ORDER BY data_evento
                ) IS NULL THEN 1
                WHEN DATE_DIFF (
                    data_evento,
                    LAG(data_evento) OVER (
                        PARTITION BY id_paciente
                        ORDER BY data_evento
                    ),
                    DAY
                ) >= 60 THEN 1
                ELSE 0
            END AS nova_ocorrencia_flag
        FROM inicios_brutos
    ),

    -- ------------------------------------------------------------
    -- CTE: grupos_inicios
    -- Cria grupo_id para eventos de início da mesma gestação
    -- ------------------------------------------------------------
    grupos_inicios AS (
        SELECT *, SUM(nova_ocorrencia_flag) OVER (
                PARTITION BY id_paciente
                ORDER BY data_evento
            ) AS grupo_id
        FROM inicios_com_grupo
    ),

    -- ------------------------------------------------------------
    -- CTE: inicios_deduplicados
    -- Seleciona evento mais recente dentro de cada grupo
    -- ------------------------------------------------------------
    inicios_deduplicados AS (
        SELECT *
        FROM (
                SELECT *, ROW_NUMBER() OVER (
                        PARTITION BY id_paciente, grupo_id
                        ORDER BY data_evento DESC
                    ) AS rn
                FROM grupos_inicios
            )
        WHERE rn = 1
    ),

    -- ------------------------------------------------------------
    -- CTE: gestacoes_unicas
    -- Define gestações únicas com data de início e fim
    -- ------------------------------------------------------------
    gestacoes_unicas AS (
        SELECT
            i.id_hci,
            i.id_paciente,
            i.cpf,
            i.nome,
            i.idade_gestante,
            i.data_evento AS data_inicio,
            (
                SELECT MIN(f.data_evento)
                FROM finais f
                WHERE
                    f.id_paciente = i.id_paciente
                    AND f.data_evento > i.data_evento
            ) AS data_fim,
            ROW_NUMBER() OVER (
                PARTITION BY i.id_paciente
                ORDER BY i.data_evento
            ) AS numero_gestacao,
            CONCAT(
                i.id_paciente,
                '-',
                CAST(
                    ROW_NUMBER() OVER (
                        PARTITION BY i.id_paciente
                        ORDER BY i.data_evento
                    ) AS STRING
                )
            ) AS id_gestacao
        FROM inicios_deduplicados i
    ),

    -- ------------------------------------------------------------
    -- CTE: gestacoes_com_status
    -- Calcula data_fim_efetiva e DPP
    -- ------------------------------------------------------------
    gestacoes_com_status AS (
        SELECT
            *,
            CASE
                WHEN data_fim IS NOT NULL THEN data_fim
                WHEN DATE_ADD(data_inicio, INTERVAL 300 DAY) <= CURRENT_DATE() THEN DATE_ADD(data_inicio, INTERVAL 300 DAY)
                ELSE NULL
            END AS data_fim_efetiva,
            DATE_ADD(data_inicio, INTERVAL 40 WEEK) AS dpp
        FROM gestacoes_unicas
    ),

    -- ------------------------------------------------------------
    -- CTE: filtrado
    -- Define fase_atual, trimestre_atual_gestacao e faixa_etaria
    -- Nota: idade_gestante já foi calculada na CTE cadastro_paciente
    -- ------------------------------------------------------------
    filtrado AS (
        SELECT
            gcs.*,
            -- Determina a fase atual da gestação
            CASE
                WHEN gcs.data_fim IS NULL
                AND DATE_ADD(gcs.data_inicio, INTERVAL 300 DAY) > CURRENT_DATE() THEN 'Gestação'
                WHEN gcs.data_fim IS NOT NULL
                AND DATE_DIFF(CURRENT_DATE(), gcs.data_fim, DAY) <= 45 THEN 'Puerpério'
                ELSE 'Encerrada'
            END AS fase_atual,
            -- Determina o trimestre atual (só faz sentido para gestações ativas)
            CASE
                WHEN DATE_DIFF(CURRENT_DATE(), gcs.data_inicio, WEEK) <= 13 THEN '1º trimestre'
                WHEN DATE_DIFF(CURRENT_DATE(), gcs.data_inicio, WEEK) BETWEEN 14 AND 27 THEN '2º trimestre'
                WHEN DATE_DIFF(CURRENT_DATE(), gcs.data_inicio, WEEK) >= 28 THEN '3º trimestre'
                ELSE 'Data inválida ou encerrada'
            END AS trimestre_atual_gestacao,
            -- Faixa etária baseada na idade atual da gestante
            -- CORREÇÃO: Usar idade_gestante diretamente (já calculada corretamente)
            CASE
                WHEN gcs.idade_gestante <= 15 THEN '≤15 anos'
                WHEN gcs.idade_gestante <= 20 THEN '16-20 anos'
                WHEN gcs.idade_gestante <= 30 THEN '21-30 anos'
                WHEN gcs.idade_gestante <= 40 THEN '31-40 anos'
                ELSE '>40 anos'
            END AS faixa_etaria
        FROM gestacoes_com_status gcs
    ),

    -- ------------------------------------------------------------
    -- CTE: unnested_equipes
    -- Desaninha array equipe_saude_familia
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
    -- Identifica equipe mais recente durante a gestação
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
    -- CTE: equipe_durante_final
    -- Filtra equipe mais recente (rn = 1)
    -- ------------------------------------------------------------
    equipe_durante_final AS (
        SELECT
            id_gestacao,
            equipe_nome,
            clinica_nome
        FROM equipe_durante_gestacao
        WHERE rn = 1
    )

-- Resultado final da tabela _condicoes (incluindo colunas para hipertensão)
SELECT
    filtrado.id_hci,
    filtrado.id_gestacao,
    filtrado.id_paciente,
    filtrado.cpf,
    filtrado.nome,
    filtrado.idade_gestante,
    filtrado.numero_gestacao,
    filtrado.data_inicio,
    filtrado.data_fim,
    filtrado.data_fim_efetiva,
    filtrado.dpp,
    filtrado.fase_atual,
    filtrado.trimestre_atual_gestacao,
    filtrado.faixa_etaria,
    edf.equipe_nome,
    edf.clinica_nome,
    -- Colunas de hipertensão (valores iniciais NULL/0)
    0 AS qtd_pas_alteradas,
    0 AS teve_pa_grave,
    0 AS total_medicoes_pa,
    CAST(NULL AS FLOAT64) AS percentual_pa_controlada,
    CAST(NULL AS DATE) AS data_ultima_pa,
    CAST(NULL AS INT64) AS ultima_sistolica,
    CAST(NULL AS INT64) AS ultima_diastolica,
    0 AS ultima_pa_controlada,
    0 AS tem_anti_hipertensivo,
    0 AS tem_anti_hipertensivo_seguro,
    CAST(NULL AS STRING) AS anti_hipertensivos_seguros,
    0 AS tem_prescricao_aas,
    CAST(NULL AS DATE) AS data_primeira_prescricao_aas,
    0 AS tem_obesidade
FROM filtrado
    LEFT JOIN equipe_durante_final edf ON filtrado.id_gestacao = edf.id_gestacao;

END;
