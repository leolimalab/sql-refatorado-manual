-- ============================================================================
-- ARQUIVO: atendimentos/1_atd_prenatal_aps.sql
-- PROPÓSITO: CTEs para atendimentos de pré-natal na Atenção Primária à Saúde
-- TABELA DESTINO: _atendimentos
-- ============================================================================

-- Sintaxe para criar ou substituir uma consulta salva (procedimento)
CREATE OR REPLACE PROCEDURE `rj-sms-sandbox.sub_pav_us.proced_atd_prenatal_aps`()

BEGIN

-- Criação da tabela de atendimentos
CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_us._atendimentos` AS

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
   nome,
   numero_gestacao,
   idade_gestante,
   data_inicio,
   data_fim,
   data_fim_efetiva,
   fase_atual
 FROM `rj-sms-sandbox.sub_pav_us._condicoes`
),

-- ------------------------------------------------------------
-- CTE: peso_filtrado
-- Peso dentro de -180 a +84 dias da data_inicio
-- ------------------------------------------------------------
peso_filtrado AS (
 SELECT
   mt.id_gestacao,
   mt.id_paciente,
   ea.entrada_data,
   ea.medidas.peso,
   DATE_DIFF(ea.entrada_data, mt.data_inicio, DAY) AS dias_diferenca
 FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
 JOIN marcadores_temporais mt
   ON ea.paciente.id_paciente = mt.id_paciente
 WHERE ea.medidas.peso IS NOT NULL
   AND ea.entrada_data BETWEEN DATE_SUB(mt.data_inicio, INTERVAL 180 DAY)
                           AND DATE_ADD(mt.data_inicio, INTERVAL 84 DAY)
),

-- ------------------------------------------------------------
-- CTE: peso_proximo_inicio
-- Peso mais próximo do início da gestação
-- ------------------------------------------------------------
peso_proximo_inicio AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY id_gestacao
            ORDER BY ABS(dias_diferenca)
          ) AS rn
   FROM peso_filtrado
 )
 WHERE rn = 1
),

-- ------------------------------------------------------------
-- CTE: alturas_filtradas
-- Alturas entre 1 ano antes e fim da gestação
-- ------------------------------------------------------------
alturas_filtradas AS (
 SELECT
   mt.id_gestacao,
   ea.paciente.id_paciente,
   ea.medidas.altura,
   DATE_DIFF(mt.data_inicio, ea.entrada_data, DAY) AS dias_antes_inicio,
   DATE_DIFF(ea.entrada_data, COALESCE(mt.data_fim_efetiva, CURRENT_DATE()), DAY) AS dias_apos_inicio
 FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
 JOIN marcadores_temporais mt
   ON ea.paciente.id_paciente = mt.id_paciente
 WHERE ea.medidas.altura IS NOT NULL
),

-- ------------------------------------------------------------
-- CTE: altura_preferencial
-- Altura moda preferencial (1 ano antes até início)
-- ------------------------------------------------------------
altura_preferencial AS (
 SELECT
   id_gestacao,
   id_paciente,
   CAST(altura AS FLOAT64) AS altura_cm,
   COUNT(*) AS freq,
   ROW_NUMBER() OVER (
     PARTITION BY id_gestacao
     ORDER BY COUNT(*) DESC
   ) AS rn
 FROM alturas_filtradas
 WHERE dias_antes_inicio <= 365 AND dias_apos_inicio <= 0
 GROUP BY id_gestacao, id_paciente, altura
),

-- ------------------------------------------------------------
-- CTE: altura_fallback
-- Altura moda como fallback
-- ------------------------------------------------------------
altura_fallback AS (
 SELECT
   id_gestacao,
   id_paciente,
   CAST(altura AS FLOAT64) AS altura_cm,
   COUNT(*) AS freq,
   ROW_NUMBER() OVER (
     PARTITION BY id_gestacao
     ORDER BY COUNT(*) DESC
   ) AS rn
 FROM alturas_filtradas
 GROUP BY id_gestacao, id_paciente, altura
),

-- ------------------------------------------------------------
-- CTE: altura_moda_completa
-- Combina altura_preferencial e altura_fallback
-- ------------------------------------------------------------
altura_moda_completa AS (
 SELECT * FROM altura_preferencial WHERE rn = 1
 UNION ALL
 SELECT * FROM altura_fallback
 WHERE id_gestacao NOT IN (SELECT id_gestacao FROM altura_preferencial WHERE rn = 1)
),

-- ------------------------------------------------------------
-- CTE: peso_altura_inicio
-- Junta peso + altura e calcula IMC
-- ------------------------------------------------------------
peso_altura_inicio AS (
 SELECT
   p.id_gestacao,
   p.id_paciente,
   p.peso,
   a.altura_cm / 100 AS altura_m,
   ROUND(p.peso / POW(a.altura_cm / 100, 2), 1) AS imc_inicio,
   CASE
     WHEN ROUND(p.peso / POW(a.altura_cm / 100, 2), 1) < 18 THEN 'Baixo peso'
     WHEN ROUND(p.peso / POW(a.altura_cm / 100, 2), 1) < 25 THEN 'Eutrófico'
     WHEN ROUND(p.peso / POW(a.altura_cm / 100, 2), 1) < 30 THEN 'Sobrepeso'
     ELSE 'Obesidade'
   END AS classificacao_imc_inicio
 FROM peso_proximo_inicio p
 JOIN altura_moda_completa a ON p.id_gestacao = a.id_gestacao
),

-- ------------------------------------------------------------
-- CTE: atendimentos_filtrados
-- Atendimentos de pré-natal APS
-- ------------------------------------------------------------
atendimentos_filtrados AS (
SELECT
  ea.id_hci,
  ea.paciente.id_paciente,
  ea.entrada_data,
  ea.estabelecimento.nome AS estabelecimento,
  ea.estabelecimento.estabelecimento_tipo,
  ea.profissional_saude_responsavel.nome AS profissional_nome,
  ea.profissional_saude_responsavel.especialidade AS profissional_categoria,
  ANY_VALUE(ea.medidas.altura) AS altura,
  ANY_VALUE(ea.medidas.peso) AS peso,
  ANY_VALUE(ea.medidas.imc) AS imc,
  ANY_VALUE(ea.medidas.pressao_sistolica) AS pressao_sistolica,
  ANY_VALUE(ea.medidas.pressao_diastolica) AS pressao_diastolica,
  ANY_VALUE(ea.motivo_atendimento) AS motivo_atendimento,
  ANY_VALUE(ea.desfecho_atendimento) AS desfecho_atendimento,
  STRING_AGG(c.id, ', ' ORDER BY c.id) AS cid_string

FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
LEFT JOIN UNNEST(ea.condicoes) AS c
WHERE ea.subtipo = 'Atendimento SOAP'
AND LOWER(ea.prontuario.fornecedor) = 'vitacare'
AND ea.profissional_saude_responsavel.especialidade IN (
    'Médico da estratégia de saúde da família',
    'Enfermeiro da estratégia saúde da família',
    'Enfermeiro - Modelo B',
    'Médico Clínico',
    'Médico Ginecologista e Obstetra - NASF',
    'Médico Ginecologista - Modelo B',
    'Médico Clinico - Modelo B',
    'Enfermeiro obstétrico',
    'Enfermeiro',
    'Enfermeiro Obstetrico - Nasf',
    'Médico Generalista',
    'Médico de Família e Comunidade'
  )
  GROUP BY 1,2,3,4,5,6,7
),

-- ------------------------------------------------------------
-- CTE: atendimentos_gestacao
-- Join com gestação e cálculo de IG
-- ------------------------------------------------------------
atendimentos_gestacao AS (
 SELECT
   af.*,
   mt.id_gestacao,
   mt.data_inicio,
   mt.data_fim_efetiva,
   mt.fase_atual,
   DATE_DIFF(af.entrada_data, mt.data_inicio, WEEK) AS ig_consulta,
   CASE
     WHEN DATE_DIFF(af.entrada_data, mt.data_inicio, WEEK) <= 13 THEN 1
     WHEN DATE_DIFF(af.entrada_data, mt.data_inicio, WEEK) <= 27 THEN 2
     ELSE 3
   END AS trimestre_consulta
 FROM atendimentos_filtrados af
 JOIN marcadores_temporais mt
   ON af.id_paciente = mt.id_paciente
  AND af.entrada_data BETWEEN mt.data_inicio AND COALESCE(mt.data_fim_efetiva, CURRENT_DATE())
),

-- ------------------------------------------------------------
-- CTE: prescricoes_aggregadas
-- Agrega prescrições por id_hci
-- ------------------------------------------------------------
prescricoes_aggregadas AS (
 SELECT
   ea.id_hci,
   STRING_AGG(p.nome, ', ') AS prescricoes
 FROM `rj-sms.saude_historico_clinico.episodio_assistencial` ea
    LEFT JOIN UNNEST(ea.prescricoes) AS p
 WHERE ea.subtipo = 'Atendimento SOAP'
   AND LOWER(ea.prontuario.fornecedor) = 'vitacare'
 GROUP BY ea.id_hci
),

-- ------------------------------------------------------------
-- CTE: consultas_enriquecidas
-- Final com cálculos de ganho de peso e IMC
-- ------------------------------------------------------------
consultas_enriquecidas AS (
 SELECT
   ag.*,
   presc.prescricoes,
   ROW_NUMBER() OVER (PARTITION BY ag.id_gestacao ORDER BY ag.entrada_data) AS numero_consulta,
  
   pai.peso AS peso_inicio,
   pai.altura_m,
   pai.imc_inicio,
   pai.classificacao_imc_inicio,

   ag.peso - pai.peso AS ganho_peso_acumulado,
   ROUND(ag.peso / POW(pai.altura_m, 2), 1) AS imc_consulta,
   
   -- Adicionar coluna tipo_atd conforme regra
   'atd_prenatal' AS tipo_atd

 FROM atendimentos_gestacao ag
 LEFT JOIN prescricoes_aggregadas presc ON ag.id_hci = presc.id_hci
 LEFT JOIN peso_altura_inicio pai ON ag.id_gestacao = pai.id_gestacao
)

-- Resultado final da tabela _atendimentos
SELECT
 id_gestacao,
 id_paciente,
 entrada_data AS data_consulta,
 numero_consulta,
 ig_consulta,
 trimestre_consulta,
 fase_atual,
 tipo_atd,

 peso_inicio,
 altura_m AS altura_inicio,
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

FROM consultas_enriquecidas
WHERE fase_atual = 'Gestação'
ORDER BY data_consulta DESC;

END;
