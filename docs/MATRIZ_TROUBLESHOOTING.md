# 🔧 Monitor Gestante - Matriz de Troubleshooting

**Guia completo de solução de problemas para o sistema Monitor Gestante**

---

## 🚨 Matriz de Problemas e Soluções

### **CATEGORIA 1: Erros de Execução**

#### **❌ Erro: "Table not found: _condicoes"**
**Sintomas:**
- Procedimentos 2-7 falham com erro de tabela não encontrada
- Mensagem: `Table 'rj-sms-sandbox.sub_pav_us._condicoes' not found`

**Diagnóstico:**
```sql
-- Verificar se tabela base existe
SELECT table_name, creation_time
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLES`
WHERE table_name = '_condicoes';
```

**Solução:**
```sql
-- 1. Executar procedimento base obrigatório
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`();

-- 2. Verificar criação bem-sucedida
SELECT COUNT(*) as total_gestacoes
FROM `rj-sms-sandbox.sub_pav_us._condicoes`;
```

**Prevenção:**
- Sempre executar procedimentos na ordem correta
- Verificar sucesso da Fase 1 antes de prosseguir

---

#### **❌ Erro: "Access Denied" em tabelas rj-sms**
**Sintomas:**
- Falha na execução do primeiro procedimento
- Mensagem: `Access Denied: Table rj-sms.saude_historico_clinico.episodio_assistencial`

**Diagnóstico:**
```bash
# Testar acesso às tabelas base
bq show rj-sms:saude_historico_clinico.episodio_assistencial
bq show rj-sms:saude_historico_clinico.paciente
bq show rj-sms:saude_historico_clinico.condicao_diagnostico
```

**Solução:**
1. **Imediata**: Solicitar permissões ao administrador BigQuery
2. **Verificação**: Confirmar acesso com equipe TI SMS-RJ
3. **Teste**: Re-executar após liberação das permissões

**Prevenção:**
- Verificar permissões antes de iniciar processamento
- Manter contato ativo com equipe de infraestrutura

---

#### **❌ Erro: "Query timeout" ou Execução Muito Lenta**
**Sintomas:**
- Jobs que ficam rodando por mais de 2 horas
- Timeout de execução no BigQuery
- Console mostra "Query is taking longer than expected"

**Diagnóstico:**
```sql
-- Verificar volume de dados sendo processado
SELECT
    table_name,
    row_count,
    size_bytes / 1024 / 1024 / 1024 as size_gb
FROM `rj-sms.saude_historico_clinico.INFORMATION_SCHEMA.TABLE_STORAGE`
WHERE table_name IN ('episodio_assistencial', 'paciente', 'condicao_diagnostico')
ORDER BY size_gb DESC;

-- Verificar jobs lentos recentes
SELECT
    job_id,
    statement_type,
    DATETIME_DIFF(end_time, start_time, MINUTE) as duration_minutes,
    total_bytes_processed / 1024 / 1024 / 1024 as gb_processed
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    AND DATETIME_DIFF(end_time, start_time, MINUTE) > 60
ORDER BY duration_minutes DESC;
```

**Solução:**
```sql
-- 1. Adicionar filtros temporais aos procedimentos base
-- Exemplo: Modificar CTE eventos_brutos
eventos_brutos AS (
    SELECT
        id_hci,
        paciente.id_paciente AS id_paciente,
        -- ... outros campos
    FROM `rj-sms.saude_historico_clinico.episodio_assistencial` episodio
    -- ADICIONAR FILTRO TEMPORAL
    WHERE DATE(episodio.data_inicio) >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
    -- ... resto da query
)

-- 2. Executar por lotes (chunking)
-- Processar dados por período mensal
```

**Prevenção:**
- Implementar filtros temporais padrão
- Monitorar volume de dados regularmente
- Executar em horários de menor carga

---

### **CATEGORIA 2: Problemas de Qualidade de Dados**

#### **⚠️ Problema: Alto Percentual de Dados NULL**
**Sintomas:**
- Muitos campos importantes com valores NULL
- Relatórios com dados incompletos

**Diagnóstico:**
```sql
-- Análise de completude por campo crítico
WITH completude AS (
    SELECT
        COUNT(*) as total,
        COUNT(cpf) as com_cpf,
        COUNT(idade_gestante) as com_idade,
        COUNT(semanas_gestacao) as com_semanas,
        COUNT(pressao_sistolica) as com_pressao,
        COUNT(imc_atual) as com_imc
    FROM `rj-sms-sandbox.sub_pav_us._view`
)

SELECT
    'CPF' as campo,
    ROUND((total - com_cpf) * 100.0 / total, 2) as perc_missing
FROM completude

UNION ALL

SELECT
    'Idade Gestante' as campo,
    ROUND((total - com_idade) * 100.0 / total, 2) as perc_missing
FROM completude

UNION ALL

SELECT
    'Semanas Gestação' as campo,
    ROUND((total - com_semanas) * 100.0 / total, 2) as perc_missing
FROM completude

UNION ALL

SELECT
    'Pressão Sistólica' as campo,
    ROUND((total - com_pressao) * 100.0 / total, 2) as perc_missing
FROM completude

UNION ALL

SELECT
    'IMC' as campo,
    ROUND((total - com_imc) * 100.0 / total, 2) as perc_missing
FROM completude;
```

**Solução:**
```sql
-- 1. Identificar origem dos dados missing
SELECT
    estabelecimento.nome_fantasia,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN cpf IS NULL OR cpf = '' THEN 1 END) as sem_cpf,
    ROUND(COUNT(CASE WHEN cpf IS NULL OR cpf = '' THEN 1 END) * 100.0 / COUNT(*), 2) as perc_sem_cpf
FROM `rj-sms-sandbox.sub_pav_us._view` v
GROUP BY estabelecimento.nome_fantasia
HAVING perc_sem_cpf > 20
ORDER BY perc_sem_cpf DESC;

-- 2. Investigar fonte dos dados no período
SELECT
    DATE(data_inicio) as data,
    COUNT(*) as total,
    COUNT(CASE WHEN cpf IS NULL THEN 1 END) as sem_cpf
FROM `rj-sms-sandbox.sub_pav_us._view`
WHERE DATE(data_inicio) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY DATE(data_inicio)
ORDER BY data DESC;
```

**Prevenção:**
- Implementar validação de qualidade nos sistemas fonte
- Alertas automáticos para queda de qualidade
- Treinamento das unidades de saúde

---

#### **⚠️ Problema: Valores Clínicos Inconsistentes**
**Sintomas:**
- Pressão arterial com valores impossíveis
- IMC fora da faixa normal humana
- Idades gestacionais impossíveis

**Diagnóstico:**
```sql
-- Identificar valores clínicos anômalos
WITH valores_anômalos AS (
    SELECT
        'Pressão Sistólica Inválida' as problema,
        COUNT(*) as casos,
        'Valores < 60 ou > 300 mmHg' as detalhes
    FROM `rj-sms-sandbox.sub_pav_us._view`
    WHERE pressao_sistolica < 60 OR pressao_sistolica > 300

    UNION ALL

    SELECT
        'Pressão Diastólica Inválida' as problema,
        COUNT(*) as casos,
        'Valores < 40 ou > 200 mmHg' as detalhes
    FROM `rj-sms-sandbox.sub_pav_us._view`
    WHERE pressao_diastolica < 40 OR pressao_diastolica > 200

    UNION ALL

    SELECT
        'IMC Impossível' as problema,
        COUNT(*) as casos,
        'Valores < 10 ou > 60' as detalhes
    FROM `rj-sms-sandbox.sub_pav_us._view`
    WHERE imc_atual < 10 OR imc_atual > 60

    UNION ALL

    SELECT
        'Idade Gestante Inválida' as problema,
        COUNT(*) as casos,
        'Idade < 10 ou > 60 anos' as detalhes
    FROM `rj-sms-sandbox.sub_pav_us._view`
    WHERE idade_gestante < 10 OR idade_gestante > 60
)

SELECT * FROM valores_anômalos
WHERE casos > 0;
```

**Solução:**
```sql
-- 1. Implementar validação nos procedimentos
-- Adicionar nas CTEs de cálculo:
CASE
    WHEN CAST(pressao_sistolica AS INT64) BETWEEN 60 AND 300
    THEN CAST(pressao_sistolica AS INT64)
    ELSE NULL
END as pressao_sistolica_validada,

CASE
    WHEN imc_calculado BETWEEN 10 AND 60
    THEN imc_calculado
    ELSE NULL
END as imc_atual

-- 2. Criar view limpa para relatórios
CREATE OR REPLACE VIEW `rj-sms-sandbox.sub_pav_us._view_validada` AS
SELECT
    *,
    CASE
        WHEN pressao_sistolica BETWEEN 60 AND 300 THEN pressao_sistolica
        ELSE NULL
    END as pressao_sistolica_limpa,
    CASE
        WHEN imc_atual BETWEEN 10 AND 60 THEN imc_atual
        ELSE NULL
    END as imc_limpo
FROM `rj-sms-sandbox.sub_pav_us._view`;
```

---

### **CATEGORIA 3: Problemas de Performance**

#### **🐌 Problema: Degradação de Performance ao Longo do Tempo**
**Sintomas:**
- Execução que antes levava 30 min agora leva 2 horas
- Aumento progressivo no tempo de processamento

**Diagnóstico:**
```sql
-- Análise de tendência de performance
WITH performance_historica AS (
    SELECT
        DATE(creation_time) as data_execucao,
        AVG(DATETIME_DIFF(end_time, start_time, MINUTE)) as tempo_medio_minutos,
        AVG(total_bytes_processed / 1024 / 1024 / 1024) as gb_medio_processado,
        COUNT(*) as jobs_executados
    FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
    WHERE statement_type = 'CALL'
        AND DATE(creation_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    GROUP BY DATE(creation_time)
    ORDER BY data_execucao
)

SELECT
    data_execucao,
    tempo_medio_minutos,
    gb_medio_processado,
    LAG(tempo_medio_minutos) OVER (ORDER BY data_execucao) as tempo_anterior,
    ROUND((tempo_medio_minutos - LAG(tempo_medio_minutos) OVER (ORDER BY data_execucao)) * 100.0 / LAG(tempo_medio_minutos) OVER (ORDER BY data_execucao), 2) as variacao_perc
FROM performance_historica;
```

**Solução:**
```sql
-- 1. Analisar crescimento das tabelas fonte
SELECT
    table_name,
    row_count,
    ROUND(size_bytes / 1024 / 1024 / 1024, 2) as size_gb,
    last_modified_time
FROM `rj-sms.saude_historico_clinico.INFORMATION_SCHEMA.TABLES`
WHERE table_name IN ('episodio_assistencial', 'paciente', 'condicao_diagnostico')
ORDER BY size_gb DESC;

-- 2. Implementar particionamento temporal
-- Modificar CTEs base para usar filtros de data mais restritivos
WHERE DATE(data_inicio) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)  -- Em vez de processar tudo

-- 3. Otimizar JOINs críticos
-- Usar clustering nos campos de JOIN mais frequentes
```

---

### **CATEGORIA 4: Problemas de Dependências**

#### **🔗 Problema: Quebra de Sequência de Execução**
**Sintomas:**
- Procedimentos executados fora de ordem
- Dados inconsistentes entre tabelas
- Falhas em procedimentos dependentes

**Diagnóstico:**
```sql
-- Verificar integridade das dependências
WITH integridade_dependencias AS (
    SELECT
        'Gestações órfãs em atendimentos' as problema,
        COUNT(*) as casos
    FROM `rj-sms-sandbox.sub_pav_us._atendimentos` a
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._condicoes` c
        ON a.id_gestacao = c.id_gestacao
    WHERE c.id_gestacao IS NULL

    UNION ALL

    SELECT
        'Gestações sem atendimentos' as problema,
        COUNT(*) as casos
    FROM `rj-sms-sandbox.sub_pav_us._condicoes` c
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
        ON c.id_gestacao = a.id_gestacao
    WHERE a.id_gestacao IS NULL

    UNION ALL

    SELECT
        'View sem base em condições' as problema,
        COUNT(*) as casos
    FROM `rj-sms-sandbox.sub_pav_us._view` v
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._condicoes` c
        ON v.id_gestacao = c.id_gestacao
    WHERE c.id_gestacao IS NULL
)

SELECT * FROM integridade_dependencias
WHERE casos > 0;
```

**Solução:**
```sql
-- 1. Limpeza completa e re-execução ordenada
DROP TABLE IF EXISTS `rj-sms-sandbox.sub_pav_us._view`;
DROP TABLE IF EXISTS `rj-sms-sandbox.sub_pav_us._atendimentos`;
DROP TABLE IF EXISTS `rj-sms-sandbox.sub_pav_us._condicoes`;

-- 2. Re-execução na ordem correta
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`();
-- Aguardar conclusão antes de prosseguir
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_prenatal_aps`();
-- Continuar sequencialmente...

-- 3. Implementar verificações de dependência nos procedimentos
-- Adicionar no início de cada procedimento:
IF NOT EXISTS (SELECT 1 FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLES` WHERE table_name = '_condicoes') THEN
    RAISE USING MESSAGE = 'ERRO: Tabela _condicoes não encontrada. Execute proced_cond_gestacoes primeiro.';
END IF;
```

---

## 🔍 Scripts de Diagnóstico

### **Script 1: Diagnóstico Completo de Sistema**
```sql
-- Diagnóstico geral do sistema Monitor Gestante
WITH
-- Verificar existência das tabelas
tabelas_sistema AS (
    SELECT
        table_name,
        creation_time,
        row_count,
        ROUND(size_bytes / 1024 / 1024, 2) as size_mb
    FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLES`
    WHERE table_name IN ('_condicoes', '_atendimentos', '_view')
),

-- Jobs recentes
jobs_recentes AS (
    SELECT
        job_id,
        job_type,
        statement_type,
        state,
        DATETIME_DIFF(end_time, start_time, MINUTE) as duration_minutes,
        error_result.reason as erro
    FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
    WHERE DATE(creation_time) >= CURRENT_DATE()
        AND statement_type = 'CALL'
    ORDER BY creation_time DESC
    LIMIT 10
),

-- Qualidade dos dados
qualidade_dados AS (
    SELECT
        COUNT(*) as total_gestacoes,
        COUNT(CASE WHEN cpf IS NULL OR cpf = '' THEN 1 END) as sem_cpf,
        COUNT(CASE WHEN idade_gestante IS NULL THEN 1 END) as sem_idade,
        COUNT(CASE WHEN pressao_sistolica < 60 OR pressao_sistolica > 300 THEN 1 END) as pressao_invalida
    FROM `rj-sms-sandbox.sub_pav_us._view`
)

-- Relatório consolidado
SELECT
    'DIAGNÓSTICO SISTEMA MONITOR GESTANTE' as titulo,
    CURRENT_DATETIME() as data_diagnostico,

    -- Status das tabelas
    (SELECT COUNT(*) FROM tabelas_sistema) as tabelas_disponiveis,

    -- Jobs hoje
    (SELECT COUNT(*) FROM jobs_recentes WHERE state = 'DONE') as jobs_concluidos_hoje,
    (SELECT COUNT(*) FROM jobs_recentes WHERE state = 'FAILED') as jobs_falharam_hoje,

    -- Qualidade
    (SELECT total_gestacoes FROM qualidade_dados) as total_gestacoes,
    (SELECT ROUND(sem_cpf * 100.0 / total_gestacoes, 2) FROM qualidade_dados) as perc_sem_cpf,
    (SELECT ROUND(pressao_invalida * 100.0 / total_gestacoes, 2) FROM qualidade_dados) as perc_pressao_invalida,

    -- Status geral
    CASE
        WHEN (SELECT COUNT(*) FROM tabelas_sistema) = 3
            AND (SELECT COUNT(*) FROM jobs_recentes WHERE state = 'FAILED') = 0
            AND (SELECT sem_cpf * 100.0 / total_gestacoes FROM qualidade_dados) < 20
        THEN '✅ SISTEMA SAUDÁVEL'
        ELSE '⚠️ ATENÇÃO NECESSÁRIA'
    END as status_geral;
```

### **Script 2: Recovery Automático**
```sql
-- Script de recovery automático para problemas comuns
DECLARE recovery_status STRING DEFAULT 'INICIANDO';

BEGIN
    -- Verificar se tabelas existem
    IF NOT EXISTS (SELECT 1 FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLES` WHERE table_name = '_condicoes') THEN
        SET recovery_status = 'EXECUTANDO_BASE';
        CALL `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`();
    END IF;

    -- Verificar integridade da base
    IF (SELECT COUNT(*) FROM `rj-sms-sandbox.sub_pav_us._condicoes`) = 0 THEN
        RAISE USING MESSAGE = 'ERRO CRÍTICO: Tabela _condicoes vazia após execução';
    END IF;

    -- Verificar e recriar atendimentos se necessário
    IF NOT EXISTS (SELECT 1 FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLES` WHERE table_name = '_atendimentos') THEN
        SET recovery_status = 'RECRIANDO_ATENDIMENTOS';
        CALL `rj-sms-sandbox.sub_pav_us.proced_atd_prenatal_aps`();
        CALL `rj-sms-sandbox.sub_pav_us.proced_atd_visitas_acs`();
        CALL `rj-sms-sandbox.sub_pav_us.proced_atd_consultas_emergenciais`();
        CALL `rj-sms-sandbox.sub_pav_us.proced_atd_encaminhamentos`();
    END IF;

    -- Finalizar com view consolidada
    SET recovery_status = 'FINALIZANDO';
    CALL `rj-sms-sandbox.sub_pav_us.proced_cond_hipertensao_gestacional`();
    CALL `rj-sms-sandbox.sub_pav_us.proced_view_linha_tempo_consolidada`();

    SET recovery_status = 'CONCLUÍDO';
    SELECT recovery_status as status_recovery, CURRENT_DATETIME() as timestamp_conclusao;

    EXCEPTION WHEN ERROR THEN
        SELECT 'ERRO NO RECOVERY' as status, @@error.message as detalhes_erro;
END;
```

---

## 📞 Escalação de Problemas

### **NÍVEL 1: Problemas Rotineiros** *(Resolver localmente)*
- Execução fora de ordem
- Jobs lentos pontuais
- Validação de dados rotineira

### **NÍVEL 2: Problemas Técnicos** *(Escalar para TI)*
- Problemas de permissão persistentes
- Degradação significativa de performance
- Corrupção de dados

### **NÍVEL 3: Problemas Críticos** *(Escalar para gestão)*
- Sistema completamente indisponível
- Perda de dados
- Problemas de compliance/privacidade

### **Contatos de Escalação:**
- **Suporte Técnico**: Equipe SubPAV-US
- **Infraestrutura**: TI SMS-RJ
- **Gestão**: Coordenação de Saúde da Mulher

---

*Matriz de Troubleshooting | Monitor Gestante v2.0 | SMS-RJ*