# ✅ Monitor Gestante - Checklist de Validação

**Lista completa de verificações para garantir qualidade e integridade dos dados**

---

## 🎯 Validação Pré-Execução

### **☑️ Verificações de Ambiente**
```sql
-- ✅ 1. Verificar acesso às tabelas base
SELECT 'Acesso verificado' as status, COUNT(*) as registros
FROM `rj-sms.saude_historico_clinico.episodio_assistencial`
WHERE DATE(data_inicio) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- ✅ 2. Verificar espaço no projeto
SELECT
    SUM(size_bytes) / 1024 / 1024 / 1024 as espaco_usado_gb,
    100 as limite_gb,
    ROUND((SUM(size_bytes) / 1024 / 1024 / 1024) * 100 / 100, 2) as percentual_usado
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLE_STORAGE`;

-- ✅ 3. Verificar jobs em execução
SELECT COUNT(*) as jobs_ativos
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE state = 'RUNNING';
```

**Critérios de Aprovação:**
- [ ] Acesso liberado a todas as tabelas base (episodio_assistencial, paciente, condicao_diagnostico)
- [ ] Espaço usado < 80% do limite do projeto
- [ ] Máximo 2 jobs ativos em paralelo
- [ ] Permissões de escrita confirmadas no schema sub_pav_us

---

## 🔄 Validação Durante Execução

### **☑️ Monitoramento de Progresso**

#### **FASE 1: Condições Base**
```sql
-- Após execução de proced_cond_gestacoes
SELECT
    'FASE 1 - CONDIÇÕES' as fase,
    COUNT(*) as total_gestacoes,
    COUNT(DISTINCT id_paciente) as pacientes_unicos,
    MIN(data_inicio) as primeira_gestacao,
    MAX(data_inicio) as ultima_gestacao
FROM `rj-sms-sandbox.sub_pav_us._condicoes`;
```

**Critérios de Aprovação:**
- [ ] Total de gestações > 0
- [ ] Pacientes únicos > 0
- [ ] Datas coerentes (não futuras, não muito antigas)
- [ ] Sem erros no log de execução

#### **FASE 2: Atendimentos**
```sql
-- Após cada procedimento de atendimento
SELECT
    tipo_atd,
    COUNT(*) as total,
    COUNT(DISTINCT id_gestacao) as gestacoes_distintas,
    MIN(data_atd) as primeira_data,
    MAX(data_atd) as ultima_data
FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
GROUP BY tipo_atd
ORDER BY total DESC;
```

**Critérios de Aprovação:**
- [ ] Pelo menos 4 tipos de atendimento (atd_prenatal, visita_acs, consulta_emergencial, encaminhamento)
- [ ] Distribuição equilibrada entre tipos
- [ ] Datas de atendimento coerentes
- [ ] Gestações distintas > 0 para cada tipo

#### **FASE 3: View Final**
```sql
-- Após procedimento da view consolidada
SELECT
    'VIEW FINAL' as tabela,
    COUNT(*) as total_registros,
    COUNT(DISTINCT id_gestacao) as gestacoes_unicas,
    COUNT(DISTINCT id_paciente) as pacientes_unicos
FROM `rj-sms-sandbox.sub_pav_us._view`;
```

**Critérios de Aprovação:**
- [ ] Total de registros = Total de gestações únicas
- [ ] Gestações únicas > 0
- [ ] Pacientes únicos > 0
- [ ] Relação gestações/pacientes coerente (≤ 5 gestações por paciente)

---

## 🏥 Validação de Qualidade Médica

### **☑️ Valores Clínicos**

#### **Pressão Arterial**
```sql
-- Validação de pressão arterial
WITH pressao_validacao AS (
    SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN pressao_sistolica BETWEEN 80 AND 250 THEN 1 END) as sistolica_valida,
        COUNT(CASE WHEN pressao_diastolica BETWEEN 50 AND 150 THEN 1 END) as diastolica_valida,
        COUNT(CASE WHEN pressao_sistolica >= 140 OR pressao_diastolica >= 90 THEN 1 END) as hipertensas
    FROM `rj-sms-sandbox.sub_pav_us._view`
    WHERE pressao_sistolica IS NOT NULL AND pressao_diastolica IS NOT NULL
)

SELECT
    total,
    sistolica_valida,
    diastolica_valida,
    hipertensas,
    ROUND(sistolica_valida * 100.0 / total, 2) as perc_sistolica_valida,
    ROUND(diastolica_valida * 100.0 / total, 2) as perc_diastolica_valida,
    ROUND(hipertensas * 100.0 / total, 2) as perc_hipertensas
FROM pressao_validacao;
```

**Critérios de Aprovação:**
- [ ] ≥ 95% das pressões sistólicas entre 80-250 mmHg
- [ ] ≥ 95% das pressões diastólicas entre 50-150 mmHg
- [ ] 5-20% de gestantes hipertensas (epidemiologicamente esperado)
- [ ] Pressão sistólica sempre > pressão diastólica

#### **IMC e Dados Antropométricos**
```sql
-- Validação de IMC
WITH imc_validacao AS (
    SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN imc_atual BETWEEN 12 AND 50 THEN 1 END) as imc_valido,
        COUNT(CASE WHEN imc_atual < 18.5 THEN 1 END) as baixo_peso,
        COUNT(CASE WHEN imc_atual BETWEEN 18.5 AND 24.9 THEN 1 END) as normal,
        COUNT(CASE WHEN imc_atual BETWEEN 25 AND 29.9 THEN 1 END) as sobrepeso,
        COUNT(CASE WHEN imc_atual >= 30 THEN 1 END) as obesidade
    FROM `rj-sms-sandbox.sub_pav_us._view`
    WHERE imc_atual IS NOT NULL
)

SELECT
    total,
    imc_valido,
    ROUND(imc_valido * 100.0 / total, 2) as perc_imc_valido,
    ROUND(baixo_peso * 100.0 / total, 2) as perc_baixo_peso,
    ROUND(normal * 100.0 / total, 2) as perc_normal,
    ROUND(sobrepeso * 100.0 / total, 2) as perc_sobrepeso,
    ROUND(obesidade * 100.0 / total, 2) as perc_obesidade
FROM imc_validacao;
```

**Critérios de Aprovação:**
- [ ] ≥ 98% dos IMCs entre 12-50
- [ ] Distribuição aproximada: Normal (40-60%), Sobrepeso (20-35%), Obesidade (15-25%)
- [ ] Baixo peso < 10%

#### **Idade Gestacional**
```sql
-- Validação de idade gestacional
SELECT
    fase_atual,
    COUNT(*) as total,
    MIN(semanas_gestacao) as min_semanas,
    MAX(semanas_gestacao) as max_semanas,
    AVG(semanas_gestacao) as media_semanas,
    COUNT(CASE WHEN semanas_gestacao > 42 THEN 1 END) as pos_termo
FROM `rj-sms-sandbox.sub_pav_us._view`
WHERE semanas_gestacao IS NOT NULL
GROUP BY fase_atual;
```

**Critérios de Aprovação:**
- [ ] Gestação ativa: 4-42 semanas
- [ ] Puerpério: 37-45 semanas (incluindo pós-parto)
- [ ] Encerrada: qualquer valor válido
- [ ] < 2% com mais de 42 semanas na fase "Gestação"

### **☑️ Classificações CID**

#### **Códigos de Gestação**
```sql
-- Validação de códigos CID gestacionais
WITH cid_gestacao AS (
    SELECT
        SUBSTR(c.situacao, 1, 4) as cid_grupo,
        COUNT(*) as total
    FROM `rj-sms-sandbox.sub_pav_us._condicoes` co
    INNER JOIN `rj-sms.saude_historico_clinico.condicao_diagnostico` c
        ON co.id_gestacao = c.id_hci -- Aproximação para validação
    WHERE c.situacao LIKE 'Z32%' OR c.situacao LIKE 'Z34%' OR c.situacao LIKE 'Z35%'
    GROUP BY SUBSTR(c.situacao, 1, 4)
    ORDER BY total DESC
)

SELECT * FROM cid_gestacao;
```

**Critérios de Aprovação:**
- [ ] Presença de códigos Z32.1 (gestação confirmada)
- [ ] Presença de códigos Z34.* (supervisão normal)
- [ ] Presença de códigos Z35.* (alto risco)
- [ ] Distribuição coerente entre normal/alto risco

#### **Condições Específicas**
```sql
-- Validação de condições específicas
SELECT
    'Hipertensão Gestacional' as condicao,
    COUNT(*) as total_gestacoes,
    COUNT(CASE WHEN hipertensao_gestacional = 1 THEN 1 END) as com_condicao,
    ROUND(COUNT(CASE WHEN hipertensao_gestacional = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as prevalencia_perc
FROM `rj-sms-sandbox.sub_pav_us._condicoes`

UNION ALL

SELECT
    'Diabetes Gestacional' as condicao,
    COUNT(*) as total_gestacoes,
    COUNT(CASE WHEN diabetes_gestacional = 1 THEN 1 END) as com_condicao,
    ROUND(COUNT(CASE WHEN diabetes_gestacional = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as prevalencia_perc
FROM `rj-sms-sandbox.sub_pav_us._condicoes`;
```

**Critérios de Aprovação:**
- [ ] Hipertensão gestacional: 5-15% (epidemiologicamente esperado)
- [ ] Diabetes gestacional: 3-10% (epidemiologicamente esperado)
- [ ] Valores não nulos (0 ou 1, nunca NULL para campos calculados)

---

## 📊 Validação de Cobertura Assistencial

### **☑️ Cobertura Pré-Natal**

#### **Adequação do Pré-Natal**
```sql
-- Análise de adequação do pré-natal
WITH prenatal_adequacao AS (
    SELECT
        v.id_gestacao,
        v.semanas_gestacao,
        COUNT(CASE WHEN a.tipo_atd = 'atd_prenatal' THEN 1 END) as consultas_prenatal,
        MIN(CASE WHEN a.tipo_atd = 'atd_prenatal' THEN a.data_atd END) as primeira_consulta,
        MAX(CASE WHEN a.tipo_atd = 'atd_prenatal' THEN a.data_atd END) as ultima_consulta
    FROM `rj-sms-sandbox.sub_pav_us._view` v
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
        ON v.id_gestacao = a.id_gestacao
    WHERE v.fase_atual IN ('Gestação', 'Puerpério', 'Encerrada')
    GROUP BY v.id_gestacao, v.semanas_gestacao
)

SELECT
    COUNT(*) as total_gestacoes,
    COUNT(CASE WHEN consultas_prenatal = 0 THEN 1 END) as sem_prenatal,
    COUNT(CASE WHEN consultas_prenatal BETWEEN 1 AND 3 THEN 1 END) as prenatal_insuficiente,
    COUNT(CASE WHEN consultas_prenatal BETWEEN 4 AND 6 THEN 1 END) as prenatal_adequado,
    COUNT(CASE WHEN consultas_prenatal >= 7 THEN 1 END) as prenatal_completo,
    ROUND(COUNT(CASE WHEN consultas_prenatal >= 6 THEN 1 END) * 100.0 / COUNT(*), 2) as perc_adequado_total
FROM prenatal_adequacao;
```

**Critérios de Aprovação:**
- [ ] < 5% sem pré-natal
- [ ] ≥ 60% com pré-natal adequado (≥6 consultas)
- [ ] ≥ 30% com pré-natal completo (≥7 consultas)
- [ ] Distribuição coerente com diretrizes MS

#### **Cobertura por ACS**
```sql
-- Análise de cobertura de visitas domiciliares
WITH visitas_acs AS (
    SELECT
        v.id_gestacao,
        COUNT(CASE WHEN a.tipo_atd = 'visita_acs' THEN 1 END) as visitas_acs
    FROM `rj-sms-sandbox.sub_pav_us._view` v
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
        ON v.id_gestacao = a.id_gestacao
    WHERE v.fase_atual IN ('Gestação', 'Puerpério')
    GROUP BY v.id_gestacao
)

SELECT
    COUNT(*) as total_gestacoes,
    COUNT(CASE WHEN visitas_acs = 0 THEN 1 END) as sem_visitas,
    COUNT(CASE WHEN visitas_acs BETWEEN 1 AND 2 THEN 1 END) as visitas_minimas,
    COUNT(CASE WHEN visitas_acs >= 3 THEN 1 END) as visitas_adequadas,
    ROUND(COUNT(CASE WHEN visitas_acs >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) as perc_com_visitas
FROM visitas_acs;
```

**Critérios de Aprovação:**
- [ ] < 20% sem visitas domiciliares
- [ ] ≥ 50% com pelo menos 2 visitas
- [ ] ≥ 30% com 3 ou mais visitas
- [ ] Coerente com estratégia ESF

### **☑️ Emergências e Intercorrências**

#### **Perfil de Emergências**
```sql
-- Análise de consultas emergenciais
WITH emergencias AS (
    SELECT
        v.id_gestacao,
        v.fase_atual,
        COUNT(CASE WHEN a.tipo_atd = 'consulta_emergencial' THEN 1 END) as emergencias,
        STRING_AGG(DISTINCT a.cid_principal) as cids_emergencia
    FROM `rj-sms-sandbox.sub_pav_us._view` v
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
        ON v.id_gestacao = a.id_gestacao
    GROUP BY v.id_gestacao, v.fase_atual
)

SELECT
    fase_atual,
    COUNT(*) as total_gestacoes,
    COUNT(CASE WHEN emergencias > 0 THEN 1 END) as com_emergencias,
    COUNT(CASE WHEN emergencias >= 3 THEN 1 END) as multiplas_emergencias,
    ROUND(COUNT(CASE WHEN emergencias > 0 THEN 1 END) * 100.0 / COUNT(*), 2) as perc_com_emergencias
FROM emergencias
GROUP BY fase_atual;
```

**Critérios de Aprovação:**
- [ ] 10-25% das gestações com pelo menos 1 emergência
- [ ] < 5% com múltiplas emergências (≥3)
- [ ] Puerpério com menor percentual que gestação ativa
- [ ] CIDs coerentes com emergências obstétricas

---

## 🔍 Validação de Integridade Referencial

### **☑️ Consistência entre Tabelas**

#### **Gestações x Atendimentos**
```sql
-- Verificar integridade referencial
WITH integridade AS (
    SELECT
        'Gestações com atendimentos' as categoria,
        COUNT(DISTINCT c.id_gestacao) as total_condicoes,
        COUNT(DISTINCT a.id_gestacao) as total_atendimentos,
        COUNT(DISTINCT CASE WHEN a.id_gestacao IS NOT NULL THEN c.id_gestacao END) as gestacoes_com_atendimentos
    FROM `rj-sms-sandbox.sub_pav_us._condicoes` c
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
        ON c.id_gestacao = a.id_gestacao
)

SELECT
    *,
    ROUND(gestacoes_com_atendimentos * 100.0 / total_condicoes, 2) as perc_gestacoes_com_atendimentos
FROM integridade;
```

**Critérios de Aprovação:**
- [ ] ≥ 80% das gestações têm pelo menos 1 atendimento
- [ ] Nenhuma gestação órfã em atendimentos
- [ ] Nenhum atendimento órfão (sem gestação correspondente)

#### **View Final x Tabelas Base**
```sql
-- Verificar consistência da view final
SELECT
    'Consistência View Final' as validacao,
    (SELECT COUNT(DISTINCT id_gestacao) FROM `rj-sms-sandbox.sub_pav_us._view`) as gestacoes_view,
    (SELECT COUNT(DISTINCT id_gestacao) FROM `rj-sms-sandbox.sub_pav_us._condicoes`) as gestacoes_base,
    (SELECT COUNT(DISTINCT id_gestacao) FROM `rj-sms-sandbox.sub_pav_us._atendimentos`) as gestacoes_atendimentos;
```

**Critérios de Aprovação:**
- [ ] Gestações na view = Gestações na base (tabela _condicoes)
- [ ] Gestações com atendimentos ≤ Gestações totais
- [ ] Nenhuma perda de dados na consolidação

---

## 📈 Validação de Performance

### **☑️ Métricas de Execução**

#### **Tempo de Processamento**
```sql
-- Análise de performance da execução atual
SELECT
    job_id,
    statement_type,
    DATETIME_DIFF(end_time, start_time, MINUTE) as duracao_minutos,
    total_bytes_processed / 1024 / 1024 / 1024 as gb_processados,
    total_slot_ms / 1000 / 60 as slot_minutos_usados
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE DATE(creation_time) = CURRENT_DATE()
    AND statement_type = 'CALL'
ORDER BY start_time DESC;
```

**Critérios de Aprovação:**
- [ ] Execução completa em < 90 minutos
- [ ] Uso de slots < 120 minutos por procedimento
- [ ] Volume processado coerente com dados históricos
- [ ] Sem falhas de timeout

#### **Crescimento de Dados**
```sql
-- Monitorar crescimento das tabelas
SELECT
    table_name,
    row_count,
    ROUND(size_bytes / 1024 / 1024, 2) as size_mb,
    last_modified_time
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLE_STORAGE`
WHERE table_name IN ('_condicoes', '_atendimentos', '_view')
ORDER BY size_mb DESC;
```

**Critérios de Aprovação:**
- [ ] Crescimento < 20% em relação à execução anterior
- [ ] Tamanho coerente entre as tabelas
- [ ] Última modificação = data de hoje

---

## 🎯 Checklist Final de Aprovação

### **✅ APROVAÇÃO TÉCNICA**
- [ ] Todas as 3 tabelas criadas (_condicoes, _atendimentos, _view)
- [ ] Contagens coerentes entre tabelas
- [ ] Sem jobs com falha no dia
- [ ] Performance dentro do esperado
- [ ] Integridade referencial preservada

### **✅ APROVAÇÃO CLÍNICA**
- [ ] Valores clínicos dentro de faixas aceitáveis
- [ ] Prevalências de condições epidemiologicamente coerentes
- [ ] Distribuição de fases gestacionais adequada
- [ ] Códigos CID apropriados
- [ ] Cobertura assistencial dentro do esperado

### **✅ APROVAÇÃO DE QUALIDADE**
- [ ] < 15% de dados missing em campos críticos
- [ ] < 5% de valores clínicos inválidos
- [ ] Distribuição territorial coerente
- [ ] Relações temporais consistentes
- [ ] Sem duplicatas ou inconsistências

### **✅ APROVAÇÃO FINAL**
- [ ] Todas as validações técnicas aprovadas
- [ ] Todas as validações clínicas aprovadas
- [ ] Todas as validações de qualidade aprovadas
- [ ] Documentação de execução completa
- [ ] Backup realizado

---

## 📋 Relatório de Validação

### **Template de Relatório**
```sql
-- Relatório de validação executiva
WITH
-- Métricas principais
metricas_principais AS (
    SELECT
        COUNT(*) as total_gestacoes,
        COUNT(DISTINCT id_paciente) as pacientes_unicos,
        COUNT(CASE WHEN fase_atual = 'Gestação' THEN 1 END) as gestacoes_ativas
    FROM `rj-sms-sandbox.sub_pav_us._view`
),

-- Qualidade dos dados
qualidade AS (
    SELECT
        COUNT(CASE WHEN cpf IS NULL OR cpf = '' THEN 1 END) as sem_cpf,
        COUNT(CASE WHEN pressao_sistolica < 80 OR pressao_sistolica > 250 THEN 1 END) as pressao_invalida,
        COUNT(*) as total
    FROM `rj-sms-sandbox.sub_pav_us._view`
),

-- Cobertura assistencial
cobertura AS (
    SELECT
        COUNT(DISTINCT CASE WHEN a.tipo_atd = 'atd_prenatal' THEN v.id_gestacao END) as com_prenatal,
        COUNT(DISTINCT v.id_gestacao) as total_gestacoes
    FROM `rj-sms-sandbox.sub_pav_us._view` v
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a ON v.id_gestacao = a.id_gestacao
)

-- Relatório final
SELECT
    'RELATÓRIO DE VALIDAÇÃO MONITOR GESTANTE' as titulo,
    CURRENT_DATETIME() as data_validacao,
    (SELECT total_gestacoes FROM metricas_principais) as total_gestacoes,
    (SELECT gestacoes_ativas FROM metricas_principais) as gestacoes_ativas,
    ROUND((SELECT sem_cpf * 100.0 / total FROM qualidade), 2) as perc_sem_cpf,
    ROUND((SELECT pressao_invalida * 100.0 / total FROM qualidade), 2) as perc_pressao_invalida,
    ROUND((SELECT com_prenatal * 100.0 / total_gestacoes FROM cobertura), 2) as perc_cobertura_prenatal,
    CASE
        WHEN (SELECT sem_cpf * 100.0 / total FROM qualidade) < 15
            AND (SELECT pressao_invalida * 100.0 / total FROM qualidade) < 5
            AND (SELECT com_prenatal * 100.0 / total_gestacoes FROM cobertura) > 70
        THEN '✅ APROVADO'
        ELSE '⚠️ REVISAR'
    END as status_final;
```

---

**Responsável pela Validação**: ________________
**Data**: ________________
**Status Final**: ________________
**Observações**: ________________

---

*Checklist de Validação | Monitor Gestante v2.0 | SMS-RJ*