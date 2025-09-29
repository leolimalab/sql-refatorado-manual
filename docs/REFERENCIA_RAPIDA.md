# 🚀 Monitor Gestante - Referência Rápida

**Guia de comandos essenciais para uso diário**

---

## ⚡ Execução Rápida

### **Execução Completa (Automatizada)**
```bash
# Execução completa em um comando
bash executar_reorganizacao_completa.sh
```

### **Execução Manual (Passo a Passo)**
```sql
-- FASE 1: Base (OBRIGATÓRIO PRIMEIRO)
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`();

-- FASE 2: Atendimentos (SEQUENCIAL)
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_prenatal_aps`();
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_visitas_acs`();
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_consultas_emergenciais`();
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_encaminhamentos`();

-- FASE 2.5: Complemento (APÓS ATENDIMENTOS)
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_hipertensao_gestacional`();

-- FASE 3: Consolidação Final
CALL `rj-sms-sandbox.sub_pav_us.proced_view_linha_tempo_consolidada`();
```

---

## 🔍 Validação Rápida

### **Verificação de Status**
```sql
-- Contagem geral das tabelas
SELECT
    'CONDICOES' as tabela,
    COUNT(*) as registros,
    COUNT(DISTINCT id_gestacao) as gestacoes
FROM `rj-sms-sandbox.sub_pav_us._condicoes`

UNION ALL

SELECT
    'ATENDIMENTOS' as tabela,
    COUNT(*) as registros,
    COUNT(DISTINCT id_gestacao) as gestacoes
FROM `rj-sms-sandbox.sub_pav_us._atendimentos`

UNION ALL

SELECT
    'VIEW_FINAL' as tabela,
    COUNT(*) as registros,
    COUNT(DISTINCT id_gestacao) as gestacoes
FROM `rj-sms-sandbox.sub_pav_us._view`;
```

### **Status por Fase Gestacional**
```sql
SELECT
    fase_atual,
    COUNT(*) as total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentual
FROM `rj-sms-sandbox.sub_pav_us._view`
GROUP BY fase_atual
ORDER BY total DESC;
```

### **Tipos de Atendimento**
```sql
SELECT
    tipo_atd,
    COUNT(*) as total,
    COUNT(DISTINCT id_gestacao) as gestacoes_distintas
FROM `rj-sms-sandbox.sub_pav_us._atendimentos`
GROUP BY tipo_atd
ORDER BY total DESC;
```

---

## 📊 Consultas Essenciais

### **Gestantes de Alto Risco (Top 20)**
```sql
SELECT
    nome_paciente,
    idade_gestante,
    semanas_gestacao,
    pressao_sistolica,
    pressao_diastolica,
    imc_atual,
    fase_atual
FROM `rj-sms-sandbox.sub_pav_us._view`
WHERE (pressao_sistolica >= 140 OR pressao_diastolica >= 90)
    OR imc_atual >= 30
    OR idade_gestante >= 35
    OR idade_gestante <= 18
ORDER BY
    CASE WHEN pressao_sistolica >= 140 OR pressao_diastolica >= 90 THEN 1 ELSE 2 END,
    pressao_sistolica DESC,
    idade_gestante DESC
LIMIT 20;
```

### **Cobertura Pré-Natal por Distrito**
```sql
WITH prenatal_coverage AS (
    SELECT
        v.distrito_sanitario,
        v.id_gestacao,
        COUNT(CASE WHEN a.tipo_atd = 'atd_prenatal' THEN 1 END) as consultas_prenatal
    FROM `rj-sms-sandbox.sub_pav_us._view` v
    LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
        ON v.id_gestacao = a.id_gestacao
    WHERE v.fase_atual IN ('Gestação', 'Puerpério')
    GROUP BY v.distrito_sanitario, v.id_gestacao
)

SELECT
    distrito_sanitario,
    COUNT(*) as total_gestacoes,
    COUNT(CASE WHEN consultas_prenatal >= 6 THEN 1 END) as prenatal_adequado,
    ROUND(COUNT(CASE WHEN consultas_prenatal >= 6 THEN 1 END) * 100.0 / COUNT(*), 2) as perc_adequado
FROM prenatal_coverage
GROUP BY distrito_sanitario
ORDER BY perc_adequado DESC;
```

### **Emergências Obstétricas (Últimos 30 dias)**
```sql
SELECT
    v.nome_paciente,
    v.idade_gestante,
    v.semanas_gestacao,
    COUNT(*) as total_emergencias,
    MAX(a.data_atd) as ultima_emergencia,
    STRING_AGG(DISTINCT a.cid_principal) as cids
FROM `rj-sms-sandbox.sub_pav_us._view` v
INNER JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
    ON v.id_gestacao = a.id_gestacao
WHERE a.tipo_atd = 'consulta_emergencial'
    AND a.data_atd >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY v.nome_paciente, v.idade_gestante, v.semanas_gestacao
ORDER BY total_emergencias DESC, ultima_emergencia DESC
LIMIT 20;
```

---

## 🔧 Comandos de Manutenção

### **Monitoramento de Jobs**
```bash
# Jobs ativos agora
bq ls -j --status=RUNNING --max_results=10

# Jobs das últimas 24h
bq ls -j --max_results=20 | head -20

# Detalhes de job específico
bq show -j [JOB_ID]
```

### **Backup Rápido**
```sql
-- Backup da view principal
CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_us._view_backup_hoje` AS
SELECT * FROM `rj-sms-sandbox.sub_pav_us._view`;

-- Verificar backup criado
SELECT
    table_name,
    row_count,
    creation_time
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE '%backup%'
ORDER BY creation_time DESC;
```

### **Limpeza de Tabelas (Recovery)**
```sql
-- ⚠️ CUIDADO: Remove todas as tabelas geradas
DROP TABLE IF EXISTS `rj-sms-sandbox.sub_pav_us._view`;
DROP TABLE IF EXISTS `rj-sms-sandbox.sub_pav_us._atendimentos`;
DROP TABLE IF EXISTS `rj-sms-sandbox.sub_pav_us._condicoes`;
```

---

## 🚨 Troubleshooting Express

### **Problema: "Table not found: _condicoes"**
```sql
-- Solução: Executar procedimento base primeiro
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`();
```

### **Problema: "Access Denied" em tabelas rj-sms**
```bash
# Verificar acesso
bq show rj-sms:saude_historico_clinico.episodio_assistencial
# Se falhar, solicitar permissões ao administrador
```

### **Problema: Jobs muito lentos**
```sql
-- Verificar volume de dados processados hoje
SELECT
    SUM(total_bytes_processed) / 1024 / 1024 / 1024 as gb_processados_hoje,
    COUNT(*) as jobs_hoje
FROM `rj-sms-sandbox.sub_pav_us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE DATE(creation_time) = CURRENT_DATE();
```

### **Problema: Dados inconsistentes**
```sql
-- Verificação rápida de integridade
SELECT
    'Gestações sem atendimentos' as problema,
    COUNT(*) as casos
FROM `rj-sms-sandbox.sub_pav_us._view` v
LEFT JOIN `rj-sms-sandbox.sub_pav_us._atendimentos` a
    ON v.id_gestacao = a.id_gestacao
WHERE a.id_gestacao IS NULL

UNION ALL

SELECT
    'Atendimentos sem gestação' as problema,
    COUNT(*) as casos
FROM `rj-sms-sandbox.sub_pav_us._atendimentos` a
LEFT JOIN `rj-sms-sandbox.sub_pav_us._view` v
    ON a.id_gestacao = v.id_gestacao
WHERE v.id_gestacao IS NULL;
```

---

## 📋 Checklist Diário

### **✅ Antes da Execução**
- [ ] Verificar acesso às tabelas base (rj-sms)
- [ ] Confirmar espaço disponível no projeto
- [ ] Backup das tabelas atuais (se existirem)

### **✅ Durante a Execução**
- [ ] Monitorar jobs ativos
- [ ] Verificar mensagens de erro
- [ ] Acompanhar tempo de execução

### **✅ Após a Execução**
- [ ] Validar contagem de registros
- [ ] Executar queries de integridade
- [ ] Verificar distribuição por fases
- [ ] Confirmar dados de qualidade médica

---

## 🔢 Valores de Referência

### **Limites Clínicos**
| Parâmetro | Normal | Alto Risco |
|-----------|--------|------------|
| Pressão Sistólica | < 140 mmHg | ≥ 140 mmHg |
| Pressão Diastólica | < 90 mmHg | ≥ 90 mmHg |
| IMC | 18.5-29.9 | ≥ 30 |
| Idade | 20-34 anos | < 18 ou ≥ 35 |

### **Códigos CID Principais**
| CID | Descrição |
|-----|-----------|
| Z32.1 | Gestação confirmada |
| Z34.* | Supervisão gravidez normal |
| Z35.* | Supervisão alto risco |
| O10-O16 | Hipertensão gestacional |
| O24.* | Diabetes gestacional |

### **Tipos de Atendimento**
| Código | Descrição |
|--------|-----------|
| atd_prenatal | Consulta pré-natal APS |
| visita_acs | Visita domiciliar ACS |
| consulta_emergencial | Atendimento UPA/Hospital |
| encaminhamento | Encaminhamento SISREG/SER |

---

## 📞 Contatos Rápidos

**🚨 Problemas Críticos**: Equipe TI SMS-RJ
**🩺 Validação Clínica**: Coordenação Saúde da Mulher
**💻 Suporte Técnico**: Equipe SubPAV-US

---

*Referência rápida | Monitor Gestante v2.0 | SMS-RJ*