# Changelog - Melhorias e Correções de Bugs

**Data:** 2026-01-28

## Resumo das Alterações

Este documento descreve as melhorias de legibilidade e correções de bugs realizadas no código SQL do Monitor Gestante.

---

## Bugs Corrigidos

### 1. Cálculo de Faixa Etária Incorreto
**Arquivo:** `1_condicoes/1_gestacoes.sql`

**Problema:** O cálculo original usava uma lógica incorreta:
```sql
-- ANTES (incorreto)
CASE
    WHEN DATE_DIFF(CURRENT_DATE(), gcs.data_inicio, YEAR) - gcs.idade_gestante <= 15 THEN '≤15 anos'
```

**Correção:** Usar diretamente a idade da gestante:
```sql
-- DEPOIS (correto)
CASE
    WHEN gcs.idade_gestante <= 15 THEN '≤15 anos'
```

---

### 2. STRING_AGG de Medicamentos Anti-Hipertensivos
**Arquivo:** `1_condicoes/2_gest_hipertensao.sql`

**Problema:** A lógica com `STRING_AGG` + `CASE` retornava apenas um medicamento por linha.

**Correção:** Usar `CONCAT` com flags para construir a lista corretamente:
```sql
CONCAT(
    CASE WHEN pah.tem_metildopa = 1 THEN 'METILDOPA; ' ELSE '' END,
    CASE WHEN pah.tem_hidralazina = 1 THEN 'HIDRALAZINA; ' ELSE '' END,
    CASE WHEN pah.tem_nifedipina = 1 THEN 'NIFEDIPINA' ELSE '' END
)
```

---

### 3. Filtro Contraditório na View
**Arquivo:** `view/1_linha_tempo.sql`

**Problema:** Dois filtros contraditórios:
- Linha 989: `WHERE f.fase_atual = 'Gestação'`
- Linha 995: `WHERE fase_atual IN ('Gestação', 'Puerpério')`

**Correção:** Unificar o filtro para incluir ambas as fases:
```sql
WHERE f.fase_atual IN ('Gestação', 'Puerpério')
```

---

### 4. Filtro Faltante no altura_fallback
**Arquivo:** `2_atendimentos/1_atd_prenatal_aps.sql`

**Problema:** O `UNION ALL` de `altura_fallback` não filtrava por `rn=1`, podendo retornar múltiplas alturas.

**Correção:**
```sql
SELECT * FROM altura_fallback
WHERE rn = 1  -- ADICIONADO
  AND id_gestacao NOT IN (SELECT id_gestacao FROM altura_preferencial WHERE rn = 1)
```

---

### 5. Inconsistência nos Nomes dos Procedimentos
**Arquivos:** `README.md`, `executar_reorganizacao_completa.sql`

**Problema:** Os nomes dos procedimentos no README e no script de execução não correspondiam aos nomes reais nos arquivos SQL.

**Correção:** Atualizado para usar os nomes corretos:
- `proced_cond_gestacoes` (não `proced_condicoes_gestacoes`)
- `proced_atd_visitas_acs` (não `proced_atd_visitas_acs_gestacao`)
- etc.

---

## Melhorias de Qualidade

### 1. Proteção de CAST com SAFE_CAST
**Arquivo:** `1_condicoes/2_gest_hipertensao.sql`

Adicionado `SAFE_CAST` para evitar erros com valores inválidos de pressão arterial:
```sql
SAFE_CAST(fapn.pressao_sistolica AS INT64) AS pressao_sistolica
```

### 2. Validação de Valores Fisiológicos
Adicionado filtro para valores de PA fisiologicamente válidos:
```sql
AND SAFE_CAST(fapn.pressao_sistolica AS INT64) BETWEEN 60 AND 300
AND SAFE_CAST(fapn.pressao_diastolica AS INT64) BETWEEN 30 AND 200
```

### 3. Documentação Padronizada
Adicionado cabeçalho detalhado em todos os arquivos SQL com:
- Descrição do propósito
- Lista de dependências
- Filtros aplicados
- Formato de saída
- Data de última atualização

### 4. Correção de Indentação
Arquivo `3_consultas_emergenciais.sql` tinha indentação inconsistente (espaços extras no início de várias linhas).

---

## Arquivos Modificados

1. `README.md` - Nomes dos procedimentos corrigidos
2. `executar_reorganizacao_completa.sql` - Nomes corrigidos + timestamp de início
3. `1_condicoes/1_gestacoes.sql` - Bug faixa_etaria + documentação
4. `1_condicoes/2_gest_hipertensao.sql` - Bug STRING_AGG + SAFE_CAST + documentação
5. `2_atendimentos/1_atd_prenatal_aps.sql` - Bug altura_fallback + documentação
6. `2_atendimentos/2_visitas_acs_gestacao.sql` - Documentação
7. `2_atendimentos/3_consultas_emergenciais.sql` - Indentação + documentação
8. `2_atendimentos/4_encaminhamentos.sql` - Documentação
9. `view/1_linha_tempo.sql` - Bug filtro contraditório + documentação

---

## Recomendações Futuras

1. **Adicionar tratamento de erros**: Implementar `BEGIN...EXCEPTION...END` nos procedimentos
2. **Criar testes unitários**: Validar os cálculos de idade gestacional, trimestre, etc.
3. **Implementar CTEs faltantes**: Conforme listado em `COLUNAS_FALTANTES.md`
4. **Otimização de performance**: Analisar os JOINs e considerar índices/particionamento
5. **Reutilização de CTEs**: Considerar criar views materializadas para CTEs compartilhadas

---

*Gerado automaticamente em 2026-01-28*
