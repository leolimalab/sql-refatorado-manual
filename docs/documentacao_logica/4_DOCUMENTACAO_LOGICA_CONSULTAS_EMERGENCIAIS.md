# Documentação da Lógica: Consultas de Emergência (Gestantes)

Este documento detalha a lógica utilizada no arquivo `proced_4_consultas_emergenciais.sql`. O objetivo deste procedimento é identificar todos os atendimentos de emergência realizados por gestantes durante o período de suas gestações ativas.

## Visão Geral do Fluxo

O processo funciona como um "funil" que cruza duas informações principais:
1. A linha do tempo da gestação (Quando começou? Quando terminou?).
2. Os registros de atendimento de emergência do sistema Vitai.

Se um atendimento de emergência acontece **dentro** da janela de tempo da gestação de uma paciente, ele é capturado.

---

## Passo 1: CTE `marcadores_temporais`

**Objetivo:** Preparar a lista de gestações com suas datas de início e fim. Esta tabela define a "janela de oportunidade" para buscar os atendimentos.

**Fonte de Dados:** Tabela `_gestacoes` (gerada no procedimento 1).

**Pseudocódigo:**
```text
PARA CADA gestação identificada anteriormente:
    SELECIONAR:
        - Quem é a gestante (ID, CPF, Nome)
        - Qual é a gestação (ID_Gestacao, Numero)
        - Quando começou (DUM - Data da Última Menstruação)
        - Quando terminou (Data Fim Efetiva ou Data Prevista)
```

**Representação Visual (Janela Temporal):**
```text
          Início da Gestação (DUM)           Fim (Parto/Interrupção)
                   |                                   |
Linha do Tempo:    [===================================]
                   ^
            Apenas atendimentos ocorridos
            neste intervalo serão considerados
```

---

## Passo 2: CTE `cids_agrupados`

**Objetivo:** Um atendimento de emergência pode ter vários diagnósticos (CIDs) registrados. Este passo agrupa todos os CIDs de um único atendimento em uma lista legível (ex: "O20.0, R10.4").

**Fonte de Dados:** `episodio_assistencial` (Histórico Clínico), explodindo o campo `condicoes`.

**Lógica de Filtro:**
1. Fonte deve ser 'vitai'.
2. Subtipo deve ser 'Emergência'.

**Pseudocódigo:**
```text
PARA CADA episódio de emergência do Vitai:
    ENCONTRAR todas as condições (diagnósticos) associadas
    AGRUPAR os códigos (CIDs) em uma lista separada por vírgula
    AGRUPAR as descrições em uma lista separada por vírgula
    RETORNAR uma linha por episódio com suas listas de CIDs
```

**Representação Visual (Agrupamento):**
```text
Episódio #12345
    |
    |---> Diagnóstico 1: O20.0 (Hemorragia)
    |---> Diagnóstico 2: R10.4 (Dor Abdominal)
    |
    V
Saída: ID #12345 | CIDs: "O20.0, R10.4"
```

---

## Passo 3: Consulta Final (O Cruzamento)

**Objetivo:** Cruzar os episódios de emergência com as gestações, calcular a idade gestacional na data da consulta e trazer os CIDs agrupados.

**Lógica Principal:**
1. Buscar atendimentos na tabela `episodio_assistencial` (`ea`).
2. Juntar com `marcadores_temporais` (`mt`) SE:
   - A paciente é a mesma.
   - A data do atendimento é MAIOR/IGUAL ao início da gestação E MENOR/IGUAL ao fim da gestação.
3. Juntar com `cids_agrupados` para trazer os diagnósticos.

**Cálculos Extras:**
- **Idade Gestacional na Consulta:** Diferença em semanas entre a `Data do Atendimento` e a `Data de Início da Gestação`.
- **Número da Consulta:** Ordena as consultas cronologicamente para cada gestação (1ª, 2ª, 3ª emergência...).

**Pseudocódigo:**
```text
PARA CADA atendimento de emergência ('vitai'):
    VERIFICAR se existe uma gestação para esta paciente (Tabela marcadores_temporais)
    
    SE (Data do Atendimento >= Data Inicio Gestação) E (Data do Atendimento <= Data Fim Gestação):
        
        CALCULAR Idade Gestacional = (Data Atendimento - Data Inicio) em semanas
        
        NUMERAR a consulta (Ex: é a 1ª visita desta gravidez? a 2ª?)
        
        BUSCAR os CIDs agrupados (da CTE cids_agrupados)
        
        RETORNAR:
            - Dados da Gestante
            - Data da Emergência
            - Motivo e Desfecho
            - Profissional e Local
            - CIDs
```

**Representação Visual (Cruzamento Final):**

```text
PACIENTE: Maria
GESTACAO: 01/01/2024 a 01/10/2024

Atendimentos encontrados no sistema:
1. 15/12/2023 (Gripe)      -> REJEITADO (Antes da gestação)
2. 15/02/2024 (Dor Baixo Ventre) -> ACEITO (Idade Gestacional: 6 semanas) -> Consulta #1
3. 20/05/2024 (Sangramento)      -> ACEITO (Idade Gestacional: 20 semanas) -> Consulta #2
4. 15/11/2024 (Fratura)    -> REJEITADO (Após o fim da gestação)
```

## Resumo dos Campos Chave Gerados

| Campo | Descrição | Origem |
|-------|-----------|--------|
| `id_gestacao` | Identificador único da gestação | `marcadores_temporais` |
| `data_consulta` | Data que a gestante foi à emergência | `episodio_assistencial` |
| `idade_gestacional_consulta` | Quantas semanas de gravidez ela tinha no dia | Calculado (Diferença de datas) |
| `numero_consulta` | Ordem cronológica da visita na gestação | Calculado (ROW_NUMBER) |
| `cids_emergencia` | Lista de diagnósticos do atendimento | `cids_agrupados` |
