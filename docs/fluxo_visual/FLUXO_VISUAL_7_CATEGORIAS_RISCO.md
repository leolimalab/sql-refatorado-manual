# FLUXO VISUAL - PROCEDIMENTO 7: CATEGORIAS DE RISCO

## Visão Geral do Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PROCEDIMENTO 7 - CATEGORIAS DE RISCO           │
│                     (Normalização de Dados de Risco)                │
└─────────────────────────────────────────────────────────────────────┘

ENTRADA:                          PROCESSAMENTO:                    SAÍDA:
┌──────────────────┐             ┌────────────────┐              ┌─────────────────┐
│ _linha_tempo     │             │ SPLIT & UNNEST │              │_categorias_risco│
│                  │────────────>│                │─────────────>│                 │
│ • id_gestacao    │             │ • Split por ;  │              │ • id_gestacao   │
│ • categorias_    │             │ • UNNEST       │              │ • categoria_    │
│   risco (string) │             │ • TRIM         │              │   risco (único) │
└──────────────────┘             └────────────────┘              └─────────────────┘

PROBLEMA RESOLVIDO:
┌───────────────────────────────────────────────────────────────────┐
│ ❌ ANTES: "HAS; DM; Obesidade" → Difícil filtrar em BI           │
│ ✅ DEPOIS: 3 linhas separadas → Filtro simples no Power BI      │
└───────────────────────────────────────────────────────────────────┘

COMPLEXIDADE: ⭐⭐☆☆☆ (Baixa - Operação de Normalização Simples)
DEPENDÊNCIAS: ✅ Requer _linha_tempo (Procedimento 6) estar completo
TEMPO EXECUÇÃO: ~10-30 segundos (operação rápida de string)
```

---

## Etapa Única: Desnormalização de Categorias de Risco

### Pipeline de Transformação

```
┌──────────────────────────────────────────────────────────────────────┐
│                   TRANSFORMAÇÃO DE NORMALIZAÇÃO                      │
└──────────────────────────────────────────────────────────────────────┘

PASSO 1: LEITURA DA LINHA DO TEMPO
┌─────────────────────────────────────────────────────────┐
│ SELECT id_gestacao, categorias_risco                    │
│ FROM _linha_tempo                                       │
│ WHERE categorias_risco IS NOT NULL                      │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
PASSO 2: QUEBRA DA STRING CONCATENADA
┌─────────────────────────────────────────────────────────┐
│ SPLIT(categorias_risco, ';') → Array de strings        │
│                                                         │
│ Exemplo:                                                │
│ Input:  "HAS; DM; Obesidade"                           │
│ Output: ["HAS", " DM", " Obesidade"]                   │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
PASSO 3: EXPLOSÃO DO ARRAY (UNNEST)
┌─────────────────────────────────────────────────────────┐
│ UNNEST(array_categorias) AS categoria_individual        │
│                                                         │
│ Efeito: 1 linha → N linhas (uma por categoria)        │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
PASSO 4: LIMPEZA DE ESPAÇOS (TRIM)
┌─────────────────────────────────────────────────────────┐
│ TRIM(categoria_individual) → Remove espaços extras      │
│                                                         │
│ Exemplo:                                                │
│ Input:  " DM "                                         │
│ Output: "DM"                                           │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
PASSO 5: INSERÇÃO NA TABELA NORMALIZADA
┌─────────────────────────────────────────────────────────┐
│ INSERT INTO _categorias_risco                           │
│ (id_gestacao, categoria_risco)                          │
│ VALUES (id, categoria_limpa)                            │
└─────────────────────────────────────────────────────────┘
```

---

## Fluxo Lógico Visual

### Transformação de Dados (1:N)

```
ENTRADA (Tabela _linha_tempo):
┌────────────┬─────────────────────────────────────────┐
│id_gestacao │ categorias_risco                        │
├────────────┼─────────────────────────────────────────┤
│ 100        │ "HAS; DM; Obesidade"                    │
│ 101        │ "SIFILIS"                               │
│ 102        │ "PRE_ECLAMPSIA; GEMELARIDADE; HAS"      │
│ 103        │ NULL                                    │
└────────────┴─────────────────────────────────────────┘
                        │
                        ▼
                   PROCESSAMENTO:
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    ▼                   ▼                   ▼
[ID: 100]          [ID: 101]          [ID: 102]
    │                   │                   │
SPLIT(';')         SPLIT(';')         SPLIT(';')
    │                   │                   │
    ├─> "HAS"           └─> "SIFILIS"       ├─> "PRE_ECLAMPSIA"
    ├─> "DM"                                ├─> "GEMELARIDADE"
    └─> "Obesidade"                         └─> "HAS"
        │                   │                   │
        └───────────────────┴───────────────────┘
                        │
                        ▼
                   TRIM APLICADO
                        │
                        ▼
SAÍDA (Tabela _categorias_risco - NORMALIZADA):
┌────────────┬─────────────────┐
│id_gestacao │ categoria_risco │
├────────────┼─────────────────┤
│ 100        │ HAS             │
│ 100        │ DM              │
│ 100        │ Obesidade       │
│ 101        │ SIFILIS         │
│ 102        │ PRE_ECLAMPSIA   │
│ 102        │ GEMELARIDADE    │
│ 102        │ HAS             │
└────────────┴─────────────────┘

OBSERVAÇÃO: ID 103 foi excluído (categorias_risco = NULL)
```

---

## Algoritmo Detalhado em Pseudocódigo

```
PROCEDIMENTO categorias_risco():

    // 1. TRUNCAR TABELA DE SAÍDA (limpar dados antigos)
    TRUNCATE TABLE _categorias_risco;

    // 2. PROCESSAR CADA GESTAÇÃO COM CATEGORIAS DE RISCO
    PARA CADA linha EM _linha_tempo:

        // Validação: apenas processar se há categorias
        SE linha.categorias_risco IS NOT NULL E linha.categorias_risco != '' ENTÃO:

            // 3. QUEBRAR STRING EM ARRAY
            array_categorias = SPLIT(linha.categorias_risco, ';');

            // 4. EXPANDIR ARRAY EM MÚLTIPLAS LINHAS
            PARA CADA categoria EM array_categorias:

                // 5. LIMPAR ESPAÇOS EM BRANCO
                categoria_limpa = TRIM(categoria);

                // 6. INSERIR NOVA LINHA NA TABELA NORMALIZADA
                SE categoria_limpa != '' ENTÃO:
                    INSERT INTO _categorias_risco (
                        id_gestacao,
                        categoria_risco
                    ) VALUES (
                        linha.id_gestacao,
                        categoria_limpa
                    );
                FIM SE;
            FIM PARA;
        FIM SE;
    FIM PARA;

    // 7. RETORNAR ESTATÍSTICAS
    RETORNAR COUNT(*) AS total_linhas_geradas;

FIM PROCEDIMENTO;
```

---

## Lógica de Decisão - Filtro de Validação

```
                    ┌─────────────────────┐
                    │ Linha da Linha_Tempo│
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ categorias_risco    │
                    │   IS NOT NULL?      │
                    └──────────┬──────────┘
                               │
                 ┌─────────────┴─────────────┐
                 │                           │
           ┌─────▼─────┐               ┌────▼─────┐
           │    SIM    │               │   NÃO    │
           │ Processar │               │  Pular   │
           └─────┬─────┘               └──────────┘
                 │
      ┌──────────▼──────────┐
      │ String não vazia?   │
      │   (length > 0)      │
      └──────────┬──────────┘
                 │
   ┌─────────────┴─────────────┐
   │                           │
┌──▼──┐                   ┌────▼─────┐
│ SIM │                   │   NÃO    │
│Split│                   │  Pular   │
└──┬──┘                   └──────────┘
   │
   ▼
┌────────────────────┐
│ UNNEST + TRIM      │
│ → Gerar N linhas   │
└────────────────────┘
```

---

## Exemplo Completo de Transformação

### Cenário: Gestante com Múltiplos Riscos

**ENTRADA** (Tabela _linha_tempo):
```
┌────────────┬──────────────────────────────────────────────────────────┐
│id_gestacao │ categorias_risco                                          │
├────────────┼──────────────────────────────────────────────────────────┤
│ 45678      │ "HAS_CRONICA; DM_GESTACIONAL; OBESIDADE_GRAU_II; SIFILIS"│
└────────────┴──────────────────────────────────────────────────────────┘
```

**PROCESSAMENTO**:
```sql
-- Passo 1: SPLIT por ponto-e-vírgula
SPLIT("HAS_CRONICA; DM_GESTACIONAL; OBESIDADE_GRAU_II; SIFILIS", ';')
→ ["HAS_CRONICA", " DM_GESTACIONAL", " OBESIDADE_GRAU_II", " SIFILIS"]

-- Passo 2: UNNEST (explosão do array)
UNNEST([...]) AS categoria
→ 4 linhas criadas

-- Passo 3: TRIM (remoção de espaços)
TRIM(" DM_GESTACIONAL") → "DM_GESTACIONAL"
TRIM(" OBESIDADE_GRAU_II") → "OBESIDADE_GRAU_II"
TRIM(" SIFILIS") → "SIFILIS"
```

**SAÍDA** (Tabela _categorias_risco):
```
┌────────────┬────────────────────┐
│id_gestacao │ categoria_risco    │
├────────────┼────────────────────┤
│ 45678      │ HAS_CRONICA        │
│ 45678      │ DM_GESTACIONAL     │
│ 45678      │ OBESIDADE_GRAU_II  │
│ 45678      │ SIFILIS            │
└────────────┴────────────────────┘
```

---

## Utilidade para Business Intelligence

### Problema Resolvido

**❌ ANTES (Dados Concatenados):**
```
Pergunta: "Quantas gestantes têm Diabetes?"
Resposta: Impossível filtrar diretamente
Solução: Usar LIKE '%DM%' → pode gerar falsos positivos
```

**✅ DEPOIS (Dados Normalizados):**
```
Pergunta: "Quantas gestantes têm Diabetes?"
Resposta: SELECT COUNT(DISTINCT id_gestacao)
          FROM _categorias_risco
          WHERE categoria_risco = 'DM_GESTACIONAL'
```

### Padrão de Uso em BI

```
┌─────────────────────────────────────────────────────────────────┐
│                    FERRAMENTA DE BI (Power BI)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  FILTRO LATERAL (Categorias de Risco):                         │
│  ☑ HAS_CRONICA          → Seleciona IDs: [100, 102, 45678]    │
│  ☐ DM_GESTACIONAL                                              │
│  ☐ OBESIDADE                                                   │
│  ☑ SIFILIS              → Seleciona IDs: [101, 45678]         │
│                                                                 │
│  ─────────────────────────────────────────────────────────────│
│                                                                 │
│  RESULTADO: Gestantes com HAS_CRONICA OU SIFILIS:             │
│  IDs: [100, 101, 102, 45678] → 4 gestantes                    │
│                                                                 │
│  TABELA PRINCIPAL (_linha_tempo):                              │
│  ┌────────┬──────────────┬────────┬───────────┐               │
│  │ID      │Nome          │Idade   │Fase       │               │
│  ├────────┼──────────────┼────────┼───────────┤               │
│  │100     │Maria Silva   │28      │Gestação   │               │
│  │101     │Ana Costa     │32      │Puerpério  │               │
│  │102     │Joana Lima    │25      │Gestação   │               │
│  │45678   │Clara Santos  │30      │Gestação   │               │
│  └────────┴──────────────┴────────┴───────────┘               │
└─────────────────────────────────────────────────────────────────┘

FLUXO DE FILTRAGEM:
1. Usuário seleciona categorias no painel lateral
2. BI identifica IDs correspondentes em _categorias_risco
3. BI filtra _linha_tempo usando esses IDs
4. Dashboard atualiza com dados filtrados
```

---

## Comparação: Antes vs Depois

### Estrutura dos Dados

```
┌─────────────────────────────────────────────────────────────────┐
│              TABELA DESNORMALIZADA (linha_tempo)                │
├─────────────────────────────────────────────────────────────────┤
│ ✅ VANTAGEM: Compacta, fácil de ler para humanos               │
│ ❌ DESVANTAGEM: Difícil de filtrar/agregar programaticamente   │
└─────────────────────────────────────────────────────────────────┘
      Exemplo: "HAS; DM; Obesidade" (1 célula, 1 linha)


┌─────────────────────────────────────────────────────────────────┐
│            TABELA NORMALIZADA (categorias_risco)                │
├─────────────────────────────────────────────────────────────────┤
│ ✅ VANTAGEM: Ideal para filtros, agregações, SQL JOINs         │
│ ❌ DESVANTAGEM: Mais linhas (redundância de IDs)               │
└─────────────────────────────────────────────────────────────────┘
      Exemplo: "HAS", "DM", "Obesidade" (3 linhas separadas)
```

---

## Métricas e Performance

### Estatísticas Esperadas

```
┌──────────────────────────────────────────────────────────────┐
│                   MÉTRICAS DE EXECUÇÃO                       │
├──────────────────────────────────────────────────────────────┤
│ Tempo de Execução:      ~10-30 segundos                     │
│ Complexidade:            O(n × m)                           │
│   • n = número de gestações                                 │
│   • m = média de categorias por gestação (~2-4)            │
│                                                              │
│ Exemplo de Expansão:                                        │
│   Input:  10.000 gestações                                  │
│   Output: ~25.000 linhas (fator de expansão 2.5x)          │
│                                                              │
│ Tamanho da Tabela:                                          │
│   • Colunas: 2 (id_gestacao, categoria_risco)              │
│   • Índice Recomendado: CREATE INDEX ON categoria_risco    │
│   • Índice Recomendado: CREATE INDEX ON id_gestacao        │
└──────────────────────────────────────────────────────────────┘
```

### Categorias de Risco Comuns

```
┌─────────────────────────┬──────────────┬─────────────────────┐
│ CATEGORIA               │ PREVALÊNCIA  │ ORIGEM NO PIPELINE  │
├─────────────────────────┼──────────────┼─────────────────────┤
│ HAS_CRONICA             │ ~15-20%      │ CID I10-I15         │
│ HAS_GESTACIONAL         │ ~5-8%        │ CID O13             │
│ PRE_ECLAMPSIA           │ ~2-4%        │ CID O14             │
│ DM_GESTACIONAL          │ ~7-10%       │ CID O24.4           │
│ DM_PRE_GESTACIONAL      │ ~3-5%        │ CID E10-E14         │
│ OBESIDADE               │ ~20-25%      │ IMC ≥30             │
│ SIFILIS                 │ ~1-2%        │ CID A51/A53/O981    │
│ GEMELARIDADE            │ ~1-1.5%      │ CID O30             │
│ HIV                     │ <1%          │ CID B20-B24         │
│ TUBERCULOSE             │ <1%          │ CID A15-A19         │
└─────────────────────────┴──────────────┴─────────────────────┘

NOTA: Percentuais aproximados baseados em dados epidemiológicos
```

---

## Consultas SQL Típicas

### Exemplo 1: Contar Gestantes por Categoria de Risco

```sql
SELECT
    categoria_risco,
    COUNT(DISTINCT id_gestacao) AS total_gestantes,
    ROUND(COUNT(DISTINCT id_gestacao) * 100.0 /
          (SELECT COUNT(DISTINCT id_gestacao) FROM _categorias_risco), 2) AS percentual
FROM _categorias_risco
GROUP BY categoria_risco
ORDER BY total_gestantes DESC;
```

**Resultado Esperado:**
```
┌─────────────────────┬─────────────────┬────────────┐
│ categoria_risco     │ total_gestantes │ percentual │
├─────────────────────┼─────────────────┼────────────┤
│ OBESIDADE           │ 2.500           │ 25.00%     │
│ HAS_CRONICA         │ 1.800           │ 18.00%     │
│ DM_GESTACIONAL      │ 950             │ 9.50%      │
│ PRE_ECLAMPSIA       │ 320             │ 3.20%      │
│ SIFILIS             │ 150             │ 1.50%      │
└─────────────────────┴─────────────────┴────────────┘
```

### Exemplo 2: Gestantes com Múltiplos Riscos

```sql
WITH contagem_riscos AS (
    SELECT
        id_gestacao,
        COUNT(*) AS qtd_categorias_risco
    FROM _categorias_risco
    GROUP BY id_gestacao
)
SELECT
    qtd_categorias_risco,
    COUNT(*) AS qtd_gestantes
FROM contagem_riscos
GROUP BY qtd_categorias_risco
ORDER BY qtd_categorias_risco;
```

**Resultado Esperado:**
```
┌──────────────────────┬────────────────┐
│ qtd_categorias_risco │ qtd_gestantes  │
├──────────────────────┼────────────────┤
│ 1                    │ 6.500          │ ← Maioria: 1 risco
│ 2                    │ 2.200          │
│ 3                    │ 950            │
│ 4                    │ 280            │
│ 5+                   │ 70             │ ← Alto risco
└──────────────────────┴────────────────┘
```

### Exemplo 3: Combinação de Riscos Comum

```sql
WITH gestantes_has AS (
    SELECT DISTINCT id_gestacao
    FROM _categorias_risco
    WHERE categoria_risco IN ('HAS_CRONICA', 'HAS_GESTACIONAL')
),
gestantes_dm AS (
    SELECT DISTINCT id_gestacao
    FROM _categorias_risco
    WHERE categoria_risco IN ('DM_GESTACIONAL', 'DM_PRE_GESTACIONAL')
)
SELECT COUNT(*) AS gestantes_has_e_dm
FROM gestantes_has
INNER JOIN gestantes_dm USING (id_gestacao);
```

---

## Dependências e Integrações

### Relação com Outros Procedimentos

```
PROCEDIMENTO 6 (linha_tempo)
         │
         │ Gera coluna:
         │ • categorias_risco (string concatenada)
         │
         ▼
┌─────────────────────┐
│  PROCEDIMENTO 7     │◄─── VOCÊ ESTÁ AQUI
│ (categorias_risco)  │
└─────────────────────┘
         │
         │ Produz:
         │ • _categorias_risco (tabela normalizada)
         │
         ▼
┌─────────────────────┐
│ FERRAMENTAS DE BI   │
│ • Power BI          │
│ • Looker            │
│ • Metabase          │
│ • Tableau           │
└─────────────────────┘
```

### Campos Utilizados da Linha do Tempo

```
┌──────────────────────────────────────────────────────────────┐
│           CAMPOS LIDOS DE _linha_tempo                       │
├──────────────────────────────────────────────────────────────┤
│ ✅ id_gestacao                (Chave primária)               │
│ ✅ categorias_risco           (String concatenada com ';')   │
│ ❌ Nenhum outro campo é necessário                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Qualidade e Validação

### Regras de Qualidade

```
✅ VALIDAÇÕES DE INTEGRIDADE:

1. Sem Duplicatas:
   • Cada (id_gestacao, categoria_risco) aparece UMA vez

2. Sem Valores Nulos:
   • categoria_risco NOT NULL
   • id_gestacao NOT NULL

3. Sem Strings Vazias:
   • TRIM(categoria_risco) != ''

4. Referential Integrity:
   • Todo id_gestacao existe em _linha_tempo
```

### Query de Validação Pós-Execução

```sql
-- Verificar duplicatas (deve retornar 0)
SELECT
    id_gestacao,
    categoria_risco,
    COUNT(*) AS duplicatas
FROM _categorias_risco
GROUP BY id_gestacao, categoria_risco
HAVING COUNT(*) > 1;

-- Verificar valores nulos (deve retornar 0)
SELECT COUNT(*)
FROM _categorias_risco
WHERE id_gestacao IS NULL OR categoria_risco IS NULL;

-- Verificar strings vazias (deve retornar 0)
SELECT COUNT(*)
FROM _categorias_risco
WHERE TRIM(categoria_risco) = '';

-- Verificar integridade referencial
SELECT COUNT(*) AS orfaos
FROM _categorias_risco r
LEFT JOIN _linha_tempo l ON r.id_gestacao = l.id_gestacao
WHERE l.id_gestacao IS NULL;
```

---

## Limitações e Considerações

### Limitações Conhecidas

```
⚠️ LIMITAÇÕES:

1. Formato Fixo:
   • Depende de delimitador ';' fixo
   • Mudanças no formato requerem atualização do código

2. Sem Hierarquia:
   • Não captura relações hierárquicas entre riscos
   • Exemplo: "HAS" é mais genérico que "HAS_CRONICA"

3. Sem Temporal:
   • Não indica quando cada risco foi identificado
   • Para histórico temporal, consultar _linha_tempo

4. Sem Severidade:
   • Não classifica gravidade dos riscos
   • Todos os riscos têm peso igual na tabela
```

### Considerações de Performance

```
📊 PERFORMANCE:

• Operação Leve: String splitting é rápido
• Índices Recomendados:
  - CREATE INDEX idx_cat_risco ON _categorias_risco(categoria_risco)
  - CREATE INDEX idx_id_gestacao ON _categorias_risco(id_gestacao)

• Estratégia de Refresh:
  - TRUNCATE + INSERT é adequado (tabela pequena)
  - Alternativa: DROP + CREATE (mais seguro para schema changes)
```

---

## Símbolos e Convenções

```
┌─────────┬──────────────────────────────────────────────────┐
│ SÍMBOLO │ SIGNIFICADO                                      │
├─────────┼──────────────────────────────────────────────────┤
│ ┌─┐     │ Início/Fim de processo                           │
│ │ │     │ Fluxo de dados (direção)                         │
│ ├─┤     │ Decisão (bifurcação)                             │
│ ●       │ Ponto de validação                               │
│ ▼       │ Continuação do fluxo                             │
│ ✅      │ Validação bem-sucedida / Dado correto            │
│ ❌      │ Validação falhada / Dado incorreto               │
│ ⚠️      │ Atenção / Limitação conhecida                    │
│ 📊      │ Métrica / Estatística                            │
└─────────┴──────────────────────────────────────────────────┘
```

---

## Resumo Executivo

```
╔═══════════════════════════════════════════════════════════════╗
║          PROCEDIMENTO 7 - CATEGORIAS DE RISCO                 ║
║                    (NORMALIZAÇÃO)                             ║
╠═══════════════════════════════════════════════════════════════╣
║ OBJETIVO:                                                     ║
║ Transformar categorias de risco concatenadas em linhas       ║
║ individuais para facilitar filtros em ferramentas de BI      ║
║                                                               ║
║ COMPLEXIDADE: ⭐⭐☆☆☆ (Baixa)                                 ║
║                                                               ║
║ ENTRADA:                                                      ║
║ • Tabela: _linha_tempo                                        ║
║ • Campo: categorias_risco (string: "RISCO1; RISCO2; ...")    ║
║                                                               ║
║ PROCESSAMENTO:                                                ║
║ • SPLIT por ponto-e-vírgula                                  ║
║ • UNNEST do array resultante                                 ║
║ • TRIM de espaços em branco                                  ║
║                                                               ║
║ SAÍDA:                                                        ║
║ • Tabela: _categorias_risco                                   ║
║ • Estrutura: (id_gestacao, categoria_risco)                  ║
║ • Formato: 1 linha por categoria de risco                    ║
║                                                               ║
║ UTILIDADE:                                                    ║
║ • Filtros laterais em dashboards de BI                       ║
║ • Agregações por tipo de risco                               ║
║ • Análises combinatórias de riscos                           ║
║                                                               ║
║ TEMPO DE EXECUÇÃO: ~10-30 segundos                           ║
║ DEPENDÊNCIAS: ✅ Procedimento 6 (linha_tempo)                 ║
╚═══════════════════════════════════════════════════════════════╝
```
