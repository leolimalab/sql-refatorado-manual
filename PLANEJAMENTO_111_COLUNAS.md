# 📋 PLANEJAMENTO COMPLETO - 111 Colunas do Arquivo Original

## 🎯 **Objetivo**
Garantir que o script `1_linha_tempo.sql` tenha **TODAS as 111 colunas** do arquivo original `6_linha_tempo.sql` na **MESMA ORDEM**.

## 📊 **Análise das 111 Colunas do Arquivo Original**

### **GRUPO 1: Dados Básicos do Paciente (1-16)**
1. `id_paciente`
2. `cpf` 
3. `cns_string`
4. `nome`
5. `data_nascimento`
6. `idade_gestante`
7. `faixa_etaria`
8. `raca`
9. `numero_gestacao`
10. `id_gestacao`
11. `data_inicio`
12. `data_fim`
13. `data_fim_efetiva`
14. `dpp`
15. `fase_atual`
16. `trimestre`

### **GRUPO 2: Idade Gestacional (17-18)**
17. `IG_atual_semanas`
18. `IG_final_semanas`

### **GRUPO 3: Condições Médicas Básicas (19-26)**
19. `diabetes_previo`
20. `diabetes_gestacional`
21. `diabetes_nao_especificado`
22. `diabetes_total`
23. `hipertensao_previa`
24. `preeclampsia`
25. `hipertensao_nao_especificada`
26. `hipertensao_total`

### **GRUPO 4: Análise de Hipertensão (27-38)**
27. `qtd_pas_alteradas`
28. `teve_pa_grave`
29. `total_medicoes_pa`
30. `percentual_pa_controlada`
31. `data_ultima_pa`
32. `ultima_sistolica`
33. `ultima_diastolica`
34. `ultima_pa_controlada`
35. `tem_anti_hipertensivo`
36. `tem_anti_hipertensivo_seguro`
37. `tem_anti_hipertensivo_contraindicado`
38. `anti_hipertensivos_seguros`

### **GRUPO 5: Hipertensão Avançada (39-49)**
39. `anti_hipertensivos_contraindicados`
40. `provavel_hipertensa_sem_diagnostico`
41. `tem_encaminhamento_has`
42. `data_primeiro_encaminhamento_has`
43. `cids_encaminhamento_has`
44. `tem_prescricao_aas`
45. `data_primeira_prescricao_aas`
46. `tem_aparelho_pa_dispensado`
47. `data_primeira_dispensacao_pa`
48. `qtd_aparelhos_pa_dispensados`

### **GRUPO 6: Antidiabéticos (49-50)**
49. `tem_antidiabetico`
50. `antidiabeticos_lista`

### **GRUPO 7: Fatores de Risco (51-58)**
51. `doenca_renal_cat`
52. `doenca_autoimune_cat`
53. `gravidez_gemelar_cat`
54. `hipertensao_cronica_confirmada`
55. `diabetes_previo_confirmado`
56. `total_fatores_risco_pe`
57. `tem_indicacao_aas`
58. `adequacao_aas_pe`

### **GRUPO 8: Outras Condições (59-67)**
59. `hiv`
60. `sifilis`
61. `tuberculose`
62. `categorias_risco`
63. `justificativa_condicao`
64. `deve_encaminhar`
65. `cid_alto_risco`
66. `max_pressao_sistolica`
67. `max_pressao_diastolica`

### **GRUPO 9: Pressão Arterial e Consultas (68-76)**
68. `data_max_pa`
69. `total_consultas_prenatal`
70. `prescricao_acido_folico`
71. `prescricao_carbonato_calcio`
72. `dias_desde_ultima_consulta`
73. `mais_de_30_sem_atd`
74. `total_visitas_acs`
75. `data_ultima_visita`
76. `dias_desde_ultima_visita_acs`

### **GRUPO 10: Informações Gerais (77-83)**
77. `obito_indicador`
78. `obito_data`
79. `area_programatica`
80. `clinica_nome`
81. `equipe_nome`
82. `mudanca_equipe_durante_pn`

### **GRUPO 11: Eventos de Parto (83-87)**
83. `data_parto`
84. `tipo_parto`
85. `estabelecimento_parto`
86. `motivo_atencimento_parto`
87. `desfecho_atendimento_parto`

### **GRUPO 12: Status de Encaminhamentos (88-90)**
88. `houve_encaminhamento`
89. `origem_encaminhamento`

### **GRUPO 13: Campos SISREG (90-98)**
90. `sisreg_primeira_data_solicitacao`
91. `sisreg_primeira_status`
92. `sisreg_primeira_situacao`
93. `sisreg_primeira_procedimento_nome`
94. `sisreg_primeira_procedimento_id`
95. `sisreg_primeira_cid`
96. `sisreg_primeira_unidade_solicitante`
97. `sisreg_primeira_medico_solicitante`
98. `sisreg_primeira_operador_solicitante`

### **GRUPO 14: Campos SER (99-107)**
99. `ser_classificacao_risco`
100. `ser_recurso_solicitado`
101. `ser_estado_solicitacao`
102. `ser_data_agendamento`
103. `ser_data_execucao`
104. `ser_unidade_executante`
105. `ser_cid`
106. `ser_descricao_cid`
107. `ser_unidade_origem`

### **GRUPO 15: Urgência e Emergência (108-111)**
108. `Urg_Emrg`
109. `ue_data_consulta`
110. `ue_motivo_atendimento`
111. `ue_nome_estabelecimento`

---

## 🔧 **Plano de Implementação**

### **FASE 1: CTEs Ausentes** ⚠️
Implementar CTEs que não existem ainda:

#### **1.1 CTEs de Hipertensão Avançada**
- `provavel_hipertensa_sem_diagnostico` 
- `tem_encaminhamento_has` 
- `dispensacao_aparelho_pa`
- `fatores_risco_categorias` 
- `fatores_risco_pe_adequacao`

#### **1.2 CTEs de Eventos de Parto**
- `eventos_parto`
- `partos_associados`

#### **1.3 CTEs de Equipe**
- `unnested_equipes`
- `equipe_durante_gestacao`
- `equipe_anterior_gestacao`
- `mudanca_equipe`

### **FASE 2: Campos Calculados** ⚠️
Implementar campos calculados ausentes:
- `diabetes_nao_especificado`
- `hipertensao_nao_especificada`
- Campos de adequação AAS

### **FASE 3: Reutilização de Dados Existentes** ✅
Usar dados já calculados nos scripts da pasta `sql_refatorado_manual/`:

#### **3.1 Da Tabela `_condicoes`**
```sql
-- Campos de hipertensão básica já populados por 2_gest_hipertensao.sql
f.qtd_pas_alteradas,
f.teve_pa_grave,
f.total_medicoes_pa,
-- ... outros 11 campos
```

#### **3.2 Da Tabela `_atendimentos`** 
```sql
-- Encaminhamentos já populados por 4_encaminhamentos.sql
-- Consultas pré-natal por 1_atd_prenatal_aps.sql
-- Visitas ACS por 2_visitas_acs_gestacao.sql
-- Consultas emergenciais por 3_consultas_emergenciais.sql
```

### **FASE 4: Ajuste da Ordem das Colunas** ⚠️
Reorganizar o SELECT final para seguir **EXATAMENTE** a ordem do arquivo original.

---

## 📋 **CTEs Necessárias por Fonte**

### **✅ JÁ EXISTEM (Reutilizar)**
- `filtrado` → `_condicoes`
- `pacientes_info` → CTE existente
- `pacientes_todos_cns` → CTE existente
- `condicoes_flags` → CTE existente
- `consultas_prenatal` → Agregação de `_atendimentos`
- `status_prescricoes` → CTE existente
- `encaminhamentos_*` → CTEs existentes

### **⚠️ FALTAM (Implementar)**
1. `unnested_equipes` 
2. `equipe_durante_gestacao`
3. `equipe_anterior_gestacao` 
4. `mudanca_equipe`
5. `eventos_parto`
6. `partos_associados`
7. `fatores_risco_categorias`
8. `fatores_risco_pe_adequacao`
9. `dispensacao_aparelho_pa`
10. `resumo_encaminhamento_has`
11. `prescricoes_antidiabeticos`
12. `prenatal_risco_marcadores`

---

## 🚀 **Próximos Passos**

1. **Identificar campos ausentes** comparando com arquivo atual
2. **Implementar CTEs faltantes** uma por vez
3. **Ajustar SELECT final** para ordem correta das 111 colunas
4. **Testar execução** para garantir compatibilidade
5. **Validar saída** com arquivo original

---

## 📊 **Status Atual vs Meta**

| Aspecto | Atual | Meta | Status |
|---------|--------|------|--------|
| Total de Colunas | ~65 | 111 | ⚠️ 46 faltando |
| Dados Básicos | ✅ | ✅ | Completo |
| Hipertensão Básica | ✅ | ✅ | Completo |
| Hipertensão Avançada | ⚠️ | ✅ | Parcial |
| Encaminhamentos | ✅ | ✅ | Completo |  
| Fatores de Risco | ❌ | ✅ | Ausente |
| Eventos de Parto | ❌ | ✅ | Ausente |
| Mudança de Equipe | ❌ | ✅ | Ausente |

---

**Meta:** 🎯 **111 colunas na ordem exata do arquivo original**


