# Documentação da Lógica: Monitoramento de Sífilis

Este documento detalha a lógica do arquivo `proced_8_sifilis.sql`. É um algoritmo altamente especializado para reconstruir a história do tratamento da sífilis na gestação, avaliando não apenas se o remédio foi dado, mas se o ciclo foi feito corretamente (doses e intervalos).

## Visão Geral do Fluxo

O desafio da sífilis é que o tratamento envolve múltiplas doses com intervalos rígidos, e a paciente pode se reinfectar. Portanto, não basta saber se ela "tomou Benzetacil". Precisamos saber **"quantos ciclos completos ela fez"**.

```text
[ Diagnóstico ] --> [ VDRL Inicial ] --> [ Ciclo de Tratamento (3 doses) ] --> [ VDRL Controle ] --> [ Tratamento Parceiro ]
```

---

## Passo 1: Identificação de Casos (`diagnosticos_raw`)

**Objetivo:** Encontrar gestantes com sífilis. O algoritmo é agressivo na busca, olhando tanto campos estruturados quanto JSONs brutos de atendimento.

**Fontes:**
1.  Tabela `episodio_assistencial`.
2.  Tabela bruta `atendimento` (JSON), procurando dentro de arrays de condições.

**CIDs Alvo:**
*   `A51.*`: Sífilis precoce
*   `A53.*`: Outras formas de sífilis
*   `O98.1`: Sífilis complicando a gravidez

---

## Passo 2: Reconstrução dos Ciclos de Tratamento

**Objetivo:** Transformar registros soltos de dispensação de medicamento em "Ciclos de Tratamento" estruturados.

**O Medicamento:** Benzilpenicilina Benzatina (Benzetacil).

**Problema:**
```text
Dispensações: [01/Jan] ... [08/Jan] ... [15/Jan] ................. [01/Jun] ... [08/Jun]
Significado:  |<- Ciclo 1 (Completo) ->|           (Pausa longa)   |<- Início Ciclo 2 ->|
```

**Lógica do Algoritmo (`dispensacoes_com_ciclo`):**
1.  Ordena todas as dispensações da paciente por data.
2.  Calcula o intervalo (dias) entre a dispensação atual e a anterior.
3.  **Regra de Quebra de Ciclo:** Se o intervalo for **MAIOR que 21 dias** (ou se for a 1ª dose), inicia-se um **NOVO CICLO**.
    *   *Nota: O intervalo ideal é 7 dias. Toleramos até 14 dias clinicamente, mas usamos 21 dias na lógica para garantir que doses atrasadas de um mesmo tratamento não sejam contadas erroneamente como um novo tratamento separado.*
4.  Numera as doses dentro de cada ciclo (Dose 1, Dose 2, Dose 3).

**Resultado:**
Identificamos, por exemplo, que a paciente teve "Ciclo 1 com 3 doses" e depois "Ciclo 2 com 1 dose".

---

## Passo 3: Avaliação de Qualidade do Ciclo (`status_tratamento_dispensado`)

Avalia se o ciclo seguiu o protocolo clínico.

**Regras de Status:**
*   **Completo:** 3 doses registradas.
*   **Em Curso:** 1 ou 2 doses, mas a última foi há menos de 14 dias (ainda está no prazo para tomar a próxima).
*   **Incompleto/Abandonado:** Menos de 3 doses e já se passaram mais de 14 dias da última.

---

## Passo 4: Monitoramento Laboratorial (`vdrl_associado`)

**Objetivo:** Vincular os exames de VDRL (titulação) ao ciclo de tratamento específico.

**Regras de Vínculo:**
1.  **VDRL Diagnóstico:** O exame mais recente realizado *antes ou no dia* da 1ª dose do ciclo. (Serve como "foto" inicial da infecção).
2.  **VDRL Controle de Cura:** O primeiro exame realizado **pelo menos 30 dias após** a última dose do ciclo. (Serve para ver se a titulação caiu).

---

## Passo 5: Avaliação Final do Cuidado (`status_final_gestante`)

Gera um indicador semântico resumindo a situação da paciente.

| Cenário Encontrado | Status Gerado |
| :--- | :--- |
| Tratamento feito, mas sem diagnóstico registrado | **ALERTA: Tratamento sem Diagnóstico** |
| Menos de 3 doses e prazo estourado | **FALHA: Tratamento Incompleto** |
| Intervalo entre doses fora de 7-9 dias | **FALHA: Intervalo incorreto** |
| Tratamento ok, mas sem VDRL pós-tratamento | **PENDÊNCIA: Monitoramento de Cura** |
| Tratamento ok + VDRL ok | **Cuidado Adequado** |

---

## Passo 6: O Parceiro (`dados_parceiro_raw`)

Extrai do prontuário da gestante as informações sobre o parceiro.
*   Tratado? (Sim/Não)
*   Fez teste rápido?
*   Tomou quantas doses?

Isso permite calcular a cobertura de tratamento dos parceiros, crucial para evitar reinfecção.
