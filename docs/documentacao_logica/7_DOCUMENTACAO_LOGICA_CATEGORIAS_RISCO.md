# Documentação da Lógica: Categorias de Risco (Normalização)

Este documento detalha a lógica do arquivo `proced_7_categorias_risco.sql`. É um procedimento utilitário projetado para transformar dados complexos de risco em um formato tabular simples, facilitando a criação de filtros em dashboards de Business Intelligence (BI).

## Problema de Negócio

Na tabela principal (`linha_tempo`), os riscos de uma gestante são armazenados em uma única célula de texto ("string"), concatenados.

**Exemplo do Dado Original:**
`"HIPERTENSAO; DIABETES; OBESIDADE"`

Isso dificulta perguntas simples como: *"Quantas gestantes têm Diabetes?"*, pois o termo "Diabetes" está misturado com outros textos.

## Solução Técnica

O procedimento realiza uma operação de "explosão" (unnest) da string, transformando uma lista horizontal em múltiplas linhas verticais.

**Pseudocódigo:**
```text
PARA CADA linha da tabela Linha_Tempo:
    PEGAR a coluna 'categorias_risco'
    QUEBRAR o texto a cada ponto-e-vírgula (';')
    
    PARA CADA pedaço resultante:
        CRIAR uma nova linha na tabela de saída
        LIMPAR espaços em branco extras (TRIM)
```

**Representação Visual:**

**Entrada (1 Gestante, 3 Riscos):**
```text
ID: 100
Riscos: "HAS; DM; Obesidade"
```

**Processamento:**
```text
       /---> [100, "HAS"]
[100] -+---> [100, "DM"]
       \---> [100, "Obesidade"]
```

**Saída (Tabela Normalizada):**
| id_gestacao | categoria_risco |
| :--- | :--- |
| 100 | HAS |
| 100 | DM |
| 100 | Obesidade |

---

## Utilidade Prática

Esta tabela (`_categorias_risco`) é geralmente importada em ferramentas como Power BI ou Looker para servir como **Filtro Lateral**.

Quando o usuário clica no filtro "Diabetes", a ferramenta filtra a tabela `_categorias_risco`, pega os IDs correspondentes e usa esses IDs para filtrar a tabela principal.
