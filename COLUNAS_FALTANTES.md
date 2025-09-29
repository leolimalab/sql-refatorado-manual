# 🔍 ANÁLISE DE COLUNAS FALTANTES

## 📊 **Status Atual**
- **Arquivo Atual**: ~92 colunas
- **Arquivo Original**: 111 colunas
- **Faltando**: ~19 colunas

## ❌ **COLUNAS PRINCIPAIS AUSENTES**

### **1. Hipertensão Avançada** (5 campos)
- `anti_hipertensivos_contraindicados` 
- `tem_anti_hipertensivo_contraindicado`
- `provavel_hipertensa_sem_diagnostico`
- `tem_encaminhamento_has` 
- `data_primeiro_encaminhamento_has`
- `cids_encaminhamento_has`

### **2. Dispensação de Aparelho PA** (3 campos) 
- `tem_aparelho_pa_dispensado`
- `data_primeira_dispensacao_pa`
- `qtd_aparelhos_pa_dispensados`

### **3. Antidiabéticos** (2 campos)
- `tem_antidiabetico`
- `antidiabeticos_lista`

### **4. Fatores de Risco** (8 campos)
- `doenca_renal_cat`
- `doenca_autoimune_cat` 
- `gravidez_gemelar_cat`
- `hipertensao_cronica_confirmada`
- `diabetes_previo_confirmado`
- `total_fatores_risco_pe`
- `tem_indicacao_aas`
- `adequacao_aas_pe`

### **5. Mudança de Equipe** (1 campo)
- `mudanca_equipe_durante_pn`

### **6. Eventos de Parto** (5 campos)
- `data_parto`
- `tipo_parto` 
- `estabelecimento_parto`
- `motivo_atencimento_parto`
- `desfecho_atendimento_parto`

---

## 🔧 **CTEs QUE PRECISAM SER IMPLEMENTADAS**

1. ✅ `classificacao_anti_hipertensivos` (expandir)
2. ✅ `dispensacao_aparelho_pa`
3. ✅ `prescricoes_antidiabeticos`
4. ✅ `fatores_risco_categorias`
5. ✅ `fatores_risco_pe_adequacao` 
6. ✅ `unnested_equipes`
7. ✅ `equipe_durante_gestacao`
8. ✅ `equipe_anterior_gestacao`
9. ✅ `mudanca_equipe`
10. ✅ `eventos_parto`
11. ✅ `partos_associados`
12. ✅ `resumo_encaminhamento_has`

---

## ⚠️ **ORDEM DAS COLUNAS**

Algumas colunas podem estar fora de ordem. A ordem correta deve ser:
1-16: Dados básicos
17-18: Idade gestacional  
19-26: Condições básicas
27-49: Hipertensão completa
49-50: Antidiabéticos
51-58: Fatores de risco
59-82: Outras condições
83-87: Eventos parto
88-89: Status encaminhamentos  
90-107: Detalhes encaminhamentos
108-111: Urgência/emergência


