# Documentação da Lógica: Encaminhamentos (Alto Risco)

Este documento detalha a lógica utilizada no arquivo `proced_5_encaminhamentos.sql`. O objetivo é rastrear solicitações de encaminhamento para pré-natal de alto risco em dois sistemas de regulação diferentes: **SISREG** (Municipal) e **SER** (Estadual/Outro).

## Visão Geral do Fluxo

O processo foca na eficiência: em vez de buscar em todo o banco de dados de regulação (que é enorme), primeiro identificamos quem são nossas gestantes ativas e buscamos *apenas* as solicitações delas.

```text
[ Gestantes Ativas ] -> [ Extrair CPFs/CNS ] -> [ Buscar no SISREG/SER ] -> [ Vincular à Gestação ]
```

---

## Passo 1: Definição do Público Alvo (`gestacoes_definidas`)

**Objetivo:** Selecionar apenas as gestações que estão em curso ('Gestação'). Não analisamos gestações encerradas neste fluxo para otimizar a performance.

---

## Passo 2: Recuperação de Identificadores (`paciente_identificadores`)

**Objetivo:** Criar uma lista de chaves de busca para cada gestante.
Uma paciente pode ter múltiplos documentos. Aqui recuperamos o **CPF** e todas as variações do cartão **CNS** (Cartão Nacional de Saúde).

**Pseudocódigo:**
```text
PARA CADA gestante:
    PEGAR CPF
    PEGAR Lista de CNSs (desaninhando o array de CNS)
    CRIAR tabela de busca: [ID_Paciente, CPF, CNS]
```

---

## Passo 3: Busca nos Sistemas de Regulação (`sisreg_pre_filtrado`, `ser_pre_filtrado`)

**Objetivo:** Encontrar solicitações de procedimentos específicos de pré-natal de alto risco para essas mulheres.

**Sistema 1: SISREG (Municipal)**
*   **Chaves de Busca:** CPF ou CNS.
*   **Filtro de Procedimentos:** Códigos SIGTAP específicos (ex: `0703844` - Consulta em Obstetrícia Alto Risco).

**Sistema 2: SER (Estadual)**
*   **Chaves de Busca:** CNS.
*   **Fonte:** Tabela específica de importação do SER (`BD SER PRÉ NATAL`).

**Representação Visual:**
```text
Gestante (CPF 123)  ---->  [ Tabela SISREG ]
                           |-- Solicitação A (Ortopedia) -> IGNORAR
                           |-- Solicitação B (Pré-Natal Alto Risco) -> CAPTURAR
```

---

## Passo 4: Vínculo Temporal (`encaminhamento_SISREG`, `encaminhamento_SER`)

**Objetivo:** Garantir que a solicitação encontrada pertence à gestação atual (e não a uma gravidez de 2 anos atrás).

**Lógica:**
A data da solicitação deve estar compreendida entre a Data de Início e a Data de Fim (ou Hoje) da gestação.

**Regra de Deduplicação:**
Se houver múltiplas solicitações válidas para a mesma gestação, selecionamos a **primeira** (mais antiga) para marcar o momento em que o risco foi identificado e a ação foi tomada.

**Pseudocódigo:**
```text
PARA CADA Solicitação de Alto Risco encontrada:
    SE Data_Solicitacao >= Data_Inicio_Gestacao 
    E Data_Solicitacao <= Data_Fim_Gestacao:
        VINCULAR à gestação
    
    AGRUPAR por Gestação
    ORDENAR por Data_Solicitacao ASC
    MANTER apenas a 1ª
```

---

## Passo 5: Consolidação Final

**Objetivo:** Unificar as respostas dos dois sistemas em indicadores claros.

**Lógica de Prioridade:**
*   Se tem no SISREG e no SER -> Origem: 'Ambos'
*   Se tem só no SISREG -> Origem: 'SISREG'
*   Se tem só no SER -> Origem: 'SER'

**Campos Gerados:**
*   `houve_encaminhamento`: Sim/Não.
*   `origem_encaminhamento`: Onde foi achado.
*   `sisreg_primeira_status`: Pendente, Agendado, Executado, etc.
*   `sisreg_primeira_unidade_solicitante`: Quem pediu.
*   `ser_classificacao_risco`: Classificação no sistema SER.

---

## Resumo dos Campos Chave Gerados

| Campo | Descrição | Sistema |
|-------|-----------|---------|
| `houve_encaminhamento` | Flag binária (Sim/Não) se achou solicitação | Ambos |
| `sisreg_primeira_data_solicitacao` | Data do pedido | SISREG |
| `sisreg_primeira_status` | Situação atual do pedido | SISREG |
| `ser_data_agendamento` | Data agendada (se houver) | SER |
| `ser_unidade_executante` | Local para onde foi encaminhada | SER |
