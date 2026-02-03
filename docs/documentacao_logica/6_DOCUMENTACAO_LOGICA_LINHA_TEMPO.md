# Documentação da Lógica: Linha do Tempo (Tabela Fato)

Este documento detalha a lógica do arquivo `proced_6_linha_tempo.sql`. Este é o **procedimento mestre** do projeto. Ele não apenas junta os dados processados nas etapas anteriores, mas aplica as regras de negócio clínicas mais complexas para avaliar a qualidade do cuidado (Risco Cardiovascular, Adequação de AAS, Controle de Pressão).

## Visão Geral

Esta tabela consolida a visão "360 graus" de cada gestação ativa. Cada linha representa uma gravidez e contém centenas de atributos derivados de múltiplas fontes (Vitacare, SISREG, Farmácia, Exames).

```text
Fontes:
[Gestações] --+
[Pré-Natal] --|
[Exames] -----+--> [ PROCESSAMENTO CENTRAL ] --> [ Tabela Linha do Tempo ]
[Farmácia] ---|
[Regulação] --+
```

---

## 1. Definição da Unidade de Saúde (`cad_e_atd`)

**Problema:** Gestantes frequentemente têm cadastro em uma unidade (ex: perto de casa) mas se consultam em outra (ex: perto do trabalho ou porque mudaram).
**Solução:** Um algoritmo de "Unidade Prioritária" para definir a responsabilidade técnica.

**Lógica de Decisão:**
1.  **Unidade de Atendimento (Frequência):** Onde ela teve mais consultas de pré-natal?
2.  **Unidade de Atendimento (Recência):** Onde foi a última consulta?
3.  **Unidade de Cadastro:** Onde está o cadastro definitivo no Vitacare?

**Pseudocódigo Simplificado:**
```text
SE (Tem consultas registradas):
    Unidade = Unidade com maior nº de consultas
SENAO:
    Unidade = Unidade do cadastro ativo
```

---

## 2. Rastreamento de Comorbidades (`condicoes_flags`)

**Objetivo:** Varrer todo o histórico clínico da paciente (mesmo antes da gravidez) para marcar condições crônicas.

**Janelas de Diagnóstico:**
*   **Hipertensão/Diabetes Prévio:** Diagnóstico com data *anterior* ao início da gestação ou CIDs específicos de doença crônica.
*   **Gestacional:** Diagnóstico com data *dentro* da gestação e CIDs específicos (ex: O24.4, O14).

**Lista de Condições Monitoradas:**
*   Hipertensão (Crônica, Gestacional, Pré-eclâmpsia)
*   Diabetes (Tipo 1, Tipo 2, Gestacional)
*   Sífilis, HIV, Tuberculose
*   Doenças Autoimunes (Lúpus, SAF)

---

## 3. Análise de Hipertensão (`analise_pressao_arterial`)

**Objetivo:** Avaliar o controle da pressão arterial (PA) consulta a consulta.

**Critérios Clínicos:**
*   **PA Controlada:** < 140/90 mmHg
*   **PA Alterada:** >= 140/90 mmHg
*   **PA Grave:** > 160/110 mmHg

**Algoritmo "Provável Hipertensa" (Sem Diagnóstico):**
Identifica gestantes que o sistema *não* marcou como hipertensas (sem CID), mas que apresentam sinais clínicos claros.

**Regra:**
```text
SE (Sem CID de Hipertensão)
E (
    Teve 2+ medições de PA Alterada
    OU
    Teve 1 medição de PA Grave
    OU
    Está usando medicação anti-hipertensiva
)
ENTÃO: Marcar como 'Provável Hipertensa Sem Diagnóstico' (ALERTA)
```

---

## 4. Adequação de Prescrição de AAS (`fatores_risco_pe_adequacao`)

**Objetivo:** Verificar se a gestante com risco de pré-eclâmpsia recebeu a profilaxia com Ácido Acetilsalicílico (AAS) no momento certo. Este é um dos algoritmos mais complexos.

### A. Cálculo do Risco
Soma fatores de risco para decidir se há **Indicação Clínica**.

*   **Alto Risco (Basta 1):** Histórico de pré-eclâmpsia, gestação gemelar, hipertensão crônica, diabetes, doença renal, doença autoimune.
*   **Risco Moderado (Precisa de 2):** Primeira gravidez (nuliparidade), obesidade (IMC > 30), idade >= 35 anos, intervalo interpartal longo (> 10 anos).

### B. Janela de Oportunidade
O AAS é eficaz se iniciado entre **12 e 20 semanas**.

### C. Matriz de Adequação

| Indicação Clínica? | Janela Atual (IG) | Prescrição de AAS? | Status Final |
| :--- | :--- | :--- | :--- |
| **Sim** | < 12 sem | Não | Aguardar janela |
| **Sim** | **12-20 sem** | **Sim** | **ADEQUADO** |
| **Sim** | **12-20 sem** | **Não** | **FALHA (Deve Iniciar)** |
| **Sim** | > 20 sem | Não | Falha (Perdeu Janela) |
| Não | > 20 sem | Sim | Erro (Suspender - Sem indicação) |

---

## 5. Medicamentos Seguros vs Contraindicados

**Objetivo:** Verificar a segurança farmacológica no tratamento da hipertensão.

*   **Seguros na Gestação:** Metildopa, Hidralazina, Nifedipina.
*   **Contraindicados/Cautela:** Enalapril, Captopril, Losartana, Atenolol, Hidroclorotiazida (IECA/BRA/Diuréticos).

O sistema cria flags (`tem_anti_hipertensivo_contraindicado`) se detectar o uso dessas substâncias durante a gravidez.

---

## Resumo dos Campos Chave Gerados

| Campo | Descrição |
|-------|-----------|
| `provavel_hipertensa_sem_diagnostico` | Alerta de qualidade do registro clínico |
| `adequacao_aas_pe` | Status da profilaxia de pré-eclâmpsia (Adequado/Falha) |
| `percentual_pa_controlada` | % de consultas com PA < 140/90 |
| `tem_anti_hipertensivo_seguro` | Uso de Metildopa/Nifedipina/Hidralazina |
| `deve_encaminhar` | Se possui critérios para Alto Risco |
