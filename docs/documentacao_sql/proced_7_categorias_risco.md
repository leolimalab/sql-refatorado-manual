# Documentação: `proced_7_categorias_risco.sql`

Este script é uma ferramenta de suporte para explodir e desnormalizar as categorias de risco gestacional que foram concatenadas no procedimento principal.

## Objetivo Geral
Criar uma tabela auxiliar (`_categorias_risco`) onde cada linha representa um único risco associado a uma gestação. Isso facilita a criação de filtros e gráficos em ferramentas de BI que não lidam bem com valores separados por delimitadores (strings concatenadas).

## Tabelas de Origem
- `rj-sms-sandbox.sub_pav_us._linha_tempo`: Tabela mestre gerada pelo `proced_6`.

## Detalhamento da Lógica (CTEs)

### 1. `riscos_separados`
Utiliza a função `SPLIT` para quebrar a string `categorias_risco` (originalmente separada por `;`) em um array.
Em seguida, utiliza o `UNNEST` para transformar cada elemento desse array em uma nova linha.
Aplica um `TRIM` para remover espaços em branco e um filtro para ignorar campos vazios.

### 2. Seleção Final
Seleciona o `id_gestacao` e a `categoria_risco` individual, garantindo que não existam valores nulos.

## Principais Regras de Negócio
- **Desnormalização**: Transforma o formato "1 linha : N riscos" em "N linhas : 1 risco cada".
- **Limpeza de Dados**: Remove excesso de espaços e entradas vazias que podem surgir da separação por delimitador.

## Descrição da Saída
A tabela final contém:
- `id_gestacao`: Identificador da gestação.
- `categoria_risco`: Uma única categoria de risco (ex: "Hipertensão", "Diabetes", "Gemelaridade").
