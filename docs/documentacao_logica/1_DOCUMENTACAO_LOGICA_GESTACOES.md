# Documentação da Lógica: Identificação de Gestações

Este documento detalha a lógica utilizada no arquivo `proced_1_gestacoes.sql`. O objetivo deste procedimento é construir uma linha do tempo confiável de gestações, identificando inícios, fins e status atual a partir de diagnósticos (CIDs) registrados no histórico clínico.

## Visão Geral do Fluxo

O algoritmo transforma eventos pontuais (diagnósticos em consultas) em períodos contínuos (gestações). Ele resolve o problema de múltiplas consultas para a mesma gravidez agrupando-as e aplicando regras de negócio para determinar se a gestação ainda está ativa.

```text
Entrada (Eventos Dispersos)      Processamento (Agrupamento)      Saída (Linha do Tempo)
[Z32.1] ...................  =>  [Inicio] ...................  =>  Gestação 1 (Ativa)
........ [Z34.9] ..........  =>  [Acompanhamento] ...........  =>  (Mesma Gestação)
................... [Z35.9]  =>  [Acompanhamento] ...........  =>  (Mesma Gestação)
....................................................................................
(2 anos depois)
[Z32.1] ...................  =>  [Novo Inicio] ..............  =>  Gestação 2 (Nova)
```

---

## Passo 1: CTE `cadastro_paciente`

**Objetivo:** Preparar a base de pessoas, calculando a idade atual para referência futura.

**Pseudocódigo:**
```text
PARA CADA pessoa na tabela de pacientes:
    SELECIONAR ID, Nome
    CALCULAR Idade = (Hoje - Data Nascimento) em anos
```

---

## Passo 2: CTE `eventos_brutos`

**Objetivo:** Filtrar apenas os eventos clínicos que sinalizam gravidez.

**Fonte de Dados:** Tabela `episodio_assistencial` (Histórico Clínico), filtrando por CIDs específicos.

**CIDs Monitorados:**
*   `Z32.1`: Gravidez confirmada
*   `Z34`: Supervisão de gravidez normal (e subcategorias)
*   `Z35`: Supervisão de gravidez de alto risco (e subcategorias)

**Pseudocódigo:**
```text
PARA CADA diagnóstico no histórico:
    SE (CID é Z32.1 OU Começa com Z34 OU Começa com Z35)
    E (Situação é ATIVO ou RESOLVIDO):
        MARCAR como 'gestacao'
        EXTRAIR Data do Evento
```

---

## Passo 3: CTEs de Agrupamento Temporal (`inicios_com_grupo`, `grupos_inicios`)

**Objetivo:** O coração do algoritmo. Determinar se um evento pertence à gestação atual ou inicia uma nova. Usamos uma **janela de 60 dias** de silêncio clínico para separar gestações.

**Lógica da Janela:**
Se uma paciente tem um diagnóstico de gravidez hoje, e o anterior foi há menos de 60 dias, assume-se que é a mesma gravidez. Se foi há mais de 60 dias (ou se é o primeiro registro), marca-se como uma "Nova Ocorrência".

**Pseudocódigo:**
```text
ORDENAR eventos da paciente por data (E1, E2, E3...)

PARA CADA evento (Atual vs Anterior):
    DIFERENCA = Data_Atual - Data_Anterior
    
    SE (Anterior é NULO) OU (DIFERENCA >= 60 dias):
        FLAG_NOVA_GESTACAO = 1
    SENAO:
        FLAG_NOVA_GESTACAO = 0

GRUPO_ID = Soma Acumulada dos Flags
(Isso cria um ID único para cada "bloco" de eventos próximos)
```

**Representação Visual:**
```text
Eventos:    E1 ----(20d)---- E2 ----(15d)---- E3 -----------------(200d)----------------- E4
Flag:       1                 0                0                                           1
Grupo ID:   1                 1                1                                           2
Resultado:  [      Gestação 1 (Grupo 1)        ]                                         [ Gestação 2 ]
```

---

## Passo 4: CTE `inicios_deduplicados`

**Objetivo:** Definir a data de início "oficial" da gestação dentro de cada grupo.
O algoritmo opta pelo evento **mais recente** dentro do grupo de inícios para ancorar a gestação. Isso é uma escolha de design para pegar o dado mais atualizado possível sobre a confirmação.

---

## Passo 5: CTE `gestacoes_unicas`

**Objetivo:** Determinar a data de fim da gestação, se houver.

**Lógica:**
Busca o primeiro evento com situação `RESOLVIDO` que ocorra *após* a data de início da gestação.

**Pseudocódigo:**
```text
PARA CADA Gestação Identificada (Data Inicio):
    PROCURAR na lista de eventos 'RESOLVIDO' da mesma paciente
    ENCONTRAR o primeiro evento onde Data_Resolvido > Data_Inicio
    SE encontrar, Data_Fim = Data_Resolvido
```

---

## Passo 6: CTE `gestacoes_com_status` e `filtrado`

**Objetivo:** Calcular datas estimadas e definir a fase atual da gestante (Gestação, Puerpério, Encerrada).

**Regra dos 299 Dias (Limite Técnico):**
Se a gestação não tem data de fim registrada, o sistema assume que ela dura no máximo 299 dias (42 semanas + 5 dias). Após isso, é considerada encerrada automaticamente.

**Cálculo da DPP (Data Provável do Parto):**
`DPP = Data_Inicio + 40 Semanas` (Estimativa padrão, já que a DUM exata nem sempre está disponível nos CIDs).

**Árvore de Decisão de Fases:**

```text
                 HOJE
                   |
         Tem Data Fim Registrada?
         /                      \
       NÃO                      SIM
        |                        |
  Passou 299 dias           Passou 45 dias
  do Início?                do Fim?
   /      \                  /      \
 SIM      NÃO              SIM      NÃO
  |        |                |        |
ENCERRADA  GESTAÇÃO      ENCERRADA   PUERPÉRIO
```

**Cálculo do Trimestre:**
*   **1º Trimestre:** <= 13 semanas
*   **2º Trimestre:** 14 a 27 semanas
*   **3º Trimestre:** >= 28 semanas

---

## Passo 7: CTE `equipe_durante_gestacao`

**Objetivo:** Identificar qual Equipe de Saúde da Família (ESF) acompanhou a paciente.
Busca a atualização de cadastro mais recente que ocorreu **durante** a gestação.

---

## Resumo dos Campos Chave Gerados

| Campo | Descrição | Origem/Cálculo |
|-------|-----------|----------------|
| `id_gestacao` | ID único (ID_Paciente + Sequencial) | Gerado no agrupamento |
| `data_inicio` | Data do evento de confirmação da gravidez | `inicios_deduplicados` |
| `data_fim_efetiva` | Data de encerramento real ou estimada (299 dias) | Regra de Negócio |
| `fase_atual` | Gestação, Puerpério ou Encerrada | Lógica de Datas |
| `dpp` | Data Provável do Parto (Estimada) | Inicio + 40 semanas |
| `idade_gestante` | Idade da paciente em anos | `cadastro_paciente` |
