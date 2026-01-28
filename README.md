# 📋 Monitor Gestante - SQL Refatorado Manual

## 🎯 Visão Geral

Este diretório contém a reorganização modular dos códigos SQL do Monitor Gestante, distribuindo as CTEs em uma estrutura organizada por funcionalidade.

## 📁 Estrutura de Pastas

```
sql_refatorado_manual/
├── condicoes/          # Condições médicas e diagnósticos
├── atendimentos/       # Atendimentos, consultas e visitas
├── tarefas/           # Protocolos e tarefas clínicas (futuro)
├── view/              # Views consolidadas e indicadores
└── aux/               # Funções auxiliares e utilitários (futuro)
```

## 🚀 Ordem de Execução

### **FASE 1: Condições Base**
```sql
-- 1. Criar tabela base de condições e gestações
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_gestacoes`();
```

### **FASE 2: Atendimentos**
```sql
-- 2. Criar tabela de atendimentos pré-natal
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_prenatal_aps`();

-- 3. Adicionar visitas ACS
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_visitas_acs`();

-- 4. Adicionar consultas emergenciais
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_consultas_emergenciais`();

-- 5. Adicionar encaminhamentos
CALL `rj-sms-sandbox.sub_pav_us.proced_atd_encaminhamentos`();
```

### **FASE 2.5: Complementar Condições**
```sql
-- 6. Complementar com dados de hipertensão (APÓS atendimentos)
CALL `rj-sms-sandbox.sub_pav_us.proced_cond_hipertensao_gestacional`();
```

### **FASE 3: View Consolidada**
```sql
-- 7. Gerar view final consolidada
CALL `rj-sms-sandbox.sub_pav_us.proced_view_linha_tempo_consolidada`();
```

## 📊 Tabelas Geradas

| Tabela | Descrição | Origem |
|--------|-----------|---------|
| `_condicoes` | Gestações e condições médicas | condicoes/ |
| `_atendimentos` | Todos os tipos de atendimentos | atendimentos/ |
| `_view` | View consolidada final | view/ |

## 🔄 Reutilização de CTEs

Conforme as regras estabelecidas, algumas CTEs são reutilizadas entre arquivos:

- **filtrado**: Base de gestações (de `1_gestacoes.sql`)
- **condicoes_gestantes_raw**: Condições médicas (de `1_gestacoes.sql`)
- **pacientes_info**: Dados de pacientes (de `1_gestacoes.sql`)
- CTEs de hipertensão: Reutilizadas de `2_gest_hipertensao.sql`

## ⚠️ Observações Importantes

1. **Ordem de Execução**: Deve ser respeitada devido às dependências entre tabelas
   - ⚠️ **CRÍTICO**: `2_gest_hipertensao.sql` DEVE ser executado APÓS todos os atendimentos, pois referencia a tabela `_atendimentos`
2. **Compatibilidade**: Mantém a estrutura original para compatibilidade com aplicações existentes
3. **Nenhuma CTE Nova**: Conforme solicitado, nenhuma CTE nova foi criada
4. **Modularidade**: Cada módulo pode ser executado independentemente após as dependências
5. **Dependências de Tabelas**:
   - `_condicoes` ← Base para todas as outras
   - `_atendimentos` ← Necessária para `2_gest_hipertensao.sql`
   - `_view` ← Necessita de ambas as anteriores

## 📝 Arquivos Criados

### Condições
- `condicoes/1_gestacoes.sql` - CTEs básicas de gestação
- `condicoes/2_gest_hipertensao.sql` - Hipertensão na gestação

### Atendimentos  
- `atendimentos/1_atd_prenatal_aps.sql` - Atendimentos pré-natal APS
- `atendimentos/2_visitas_acs_gestacao.sql` - Visitas domiciliares ACS
- `atendimentos/3_consultas_emergenciais.sql` - Consultas emergenciais
- `atendimentos/4_encaminhamentos.sql` - Encaminhamentos SISREG/SER

### Views
- `view/1_linha_tempo.sql` - View consolidada principal

## 🔍 Validação

Para validar a reorganização:

```sql
-- Verificar contagem de registros
SELECT COUNT(*) FROM `rj-sms-sandbox.sub_pav_us._condicoes`;
SELECT COUNT(*) FROM `rj-sms-sandbox.sub_pav_us._atendimentos`;
SELECT COUNT(*) FROM `rj-sms-sandbox.sub_pav_us._view`;

-- Comparar com tabelas originais
-- (ajustar conforme tabelas originais disponíveis)
```

## 📈 Próximos Passos

1. **Implementar arquivos faltantes**:
   - `condicoes/3_gest_diabetes.sql`
   - `condicoes/4_gest_sifilis.sql`
   - Arquivos da pasta `tarefas/`

2. **Testes de Performance**: Comparar performance com versão original

3. **Documentação Detalhada**: Documentar cada CTE e suas dependências

---

**Reorganização realizada conforme especificações do arquivo `CTEs_SQL_Proposta.csv`**


