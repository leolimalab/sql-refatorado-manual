# Documentação da Lógica: Visitas Domiciliares (ACS)

Este documento detalha a lógica utilizada no arquivo `proced_3_visitas_acs_gestacao.sql`. O objetivo é mapear a cobertura de visitas domiciliares realizadas pelos Agentes Comunitários de Saúde (ACS) especificamente durante o período da gestação.

## Visão Geral do Fluxo

O processo cruza a base de produção dos ACS (fichas de visita) com a linha do tempo das gestantes.

```text
[ Gestantes Ativas ]      [ Produção ACS (Visitas) ]
        |                          |
        +---------> [ JOIN ] <-----+
                       |
               [ Visitas Validadas ]
```

---

## Passo 1: CTE `marcadores_temporais`

**Objetivo:** Carregar a lista de gestantes e definir a "janela de oportunidade" para a visita.

**Fonte de Dados:** Tabela `_gestacoes` (gerada no procedimento 1).

**Representação Visual:**
```text
Gestante A: [ Início: 01/Jan ] ------------------------ [ Fim: 01/Out ]
Gestante B: [ Início: 15/Mar ] -------- (Em curso) ---> [ Hoje ]
```

---

## Passo 2: CTE `visitas_com_join`

**Objetivo:** Filtrar apenas as visitas domiciliares que ocorreram dentro do período da gestação.

**Filtros de Qualidade:**
1.  **Profissional:** Deve ser "Agente comunitário de saúde".
2.  **Tipo:** Deve ser "Visita Domiciliar".
3.  **Fonte:** Sistema "Vitacare".

**Lógica de Vínculo:**
Uma visita conta para a gestante SE:
*   O ID do Paciente coincide.
*   A Data da Visita é >= Data de Início da Gestação.
*   A Data da Visita é <= Data de Fim da Gestação (ou Hoje).

**Pseudocódigo:**
```text
PARA CADA Registro de Produção do ACS:
    SE (Profissional == 'ACS') E (Atividade == 'Visita'):
        PROCURAR Gestação ativa para este paciente na data da visita.
        
        SE Encontrada:
            CAPTURAR dados da visita (Data, Profissional, Equipe)
            VINCULAR à Gestação
```

**Representação Visual:**
```text
Visitas do ACS João:
1. 10/Dez (Antes da Gravidez) --> IGNORAR
2. 15/Jan (Durante) ----------> CAPTURAR (Visita #1)
3. 20/Fev (Durante) ----------> CAPTURAR (Visita #2)
4. 05/Nov (Pós-Parto) --------> IGNORAR (Neste fluxo)
```

---

## Passo 3: Ordenação e Numeração

**Objetivo:** Organizar a sequência de visitas para facilitar a análise de frequência (ex: "Recebeu visita mensalmente?").

**Lógica:**
Cria um contador sequencial para cada gestação, ordenado pela data da visita.

**Resultado Final:**
| id_gestacao | data_visita | numero_visita | nome_profissional |
| :--- | :--- | :--- | :--- |
| G-100 | 15/01/2024 | 1 | ACS Maria |
| G-100 | 20/02/2024 | 2 | ACS Maria |
| G-100 | 15/03/2024 | 3 | ACS Maria |

---

## Resumo dos Campos Chave Gerados

| Campo | Descrição |
|-------|-----------|
| `total_visitas_acs` | Contagem total de visitas válidas no período |
| `data_ultima_visita` | Data da visita mais recente (para cálculo de recência) |
| `dias_desde_ultima_visita` | Indicador de abandono (Hoje - Última Visita) |
