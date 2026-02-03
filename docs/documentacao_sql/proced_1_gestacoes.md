# Documentação: `proced_1_gestacoes.sql`

Este script é responsável por identificar e consolidar as gestações únicas de cada paciente, definindo seu início, fim (real ou estimado), fase atual (Gestação, Puerpério ou Encerrada) e a equipe de saúde responsável.

## Objetivo Geral
Criar uma tabela mestre de gestações (`_gestacoes`) que serve como base para o monitoramento de gestantes, permitindo rastrear o histórico de cada gestação por paciente.

## Tabelas de Origem
- `rj-sms.saude_historico_clinico.paciente`: Dados cadastrais da paciente e histórico de equipe de saúde.
- `rj-sms.saude_historico_clinico.episodio_assistencial`: Eventos clínicos e diagnósticos (CIDs).

## Detalhamento da Lógica (CTEs)

### 1. `cadastro_paciente`
Extrai o `id_paciente`, `nome` e calcula a `idade_gestante` atual a partir da `data_nascimento`.

### 2. `eventos_brutos`
Filtra os episódios assistenciais em busca de CIDs relacionados à gestação:
- **Z32.1**: Gravidez confirmada.
- **Z34.x**: Supervisão de gravidez normal.
- **Z35.x**: Supervisão de gravidez de alto risco.
Considera apenas diagnósticos com situação 'ATIVO' ou 'RESOLVIDO'.

### 3. `inicios_brutos` e `finais`
Separa os eventos de gestação com base na situação:
- **`inicios_brutos`**: CID em situação 'ATIVO'.
- **`finais`**: CID em situação 'RESOLVIDO'.

### 4. `inicios_com_grupo` e `grupos_inicios`
Lógica para agrupar múltiplos registros de início que pertencem à mesma gestação.
- Um novo grupo (gestação) é identificado se o intervalo entre eventos for maior ou igual a **60 dias**.

### 5. `inicios_deduplicados`
Consolida cada grupo de início em um único registro, pegando o evento mais recente dentro do grupo.

### 6. `gestacoes_unicas`
Une as datas de início com a primeira data de fim (`RESOLVIDO`) encontrada após o início.
Gera o `id_gestacao` (formato: `{id_paciente}-{numero_gestacao}`).

### 7. `gestacoes_com_status`
Define a `data_fim_efetiva`:
- Se não houver data de fim registrada, estima o fim após **299 dias** (42 semanas + 5 dias) do início, se essa data já tiver passado.
- Calcula a **DPP** (Data Provável do Parto) como 40 semanas após o início.

### 8. `filtrado`
Define a `fase_atual`:
- **Gestação**: Em curso e dentro dos 299 dias.
- **Puerpério**: Até 45 dias após a data de fim.
- **Encerrada**: Fora dos períodos acima.
Calcula também o `trimestre_atual_gestacao` (1º, 2º ou 3º).

### 9. `unnested_equipes`, `equipe_durante_gestacao` e `equipe_durante_final`
Recupera a última equipe de saúde associada à paciente que estava ativa durante o período da gestação.

## Principais Regras de Negócio
- **Janela de Nova Gestação**: 60 dias sem novos registros 'ATIVOS' para considerar uma nova gestação.
- **Fim Estimado**: 299 dias após o início caso não haja registro de encerramento ('RESOLVIDO').
- **Puerpério**: Definido como os 45 dias subsequentes ao fim da gestação.
- **Trimestres**:
    - 1º: até 13 semanas.
    - 2º: 14 a 27 semanas.
    - 3º: 28 semanas ou mais.

## Descrição da Saída
A tabela final contém:
- `id_hci`, `id_gestacao`, `id_paciente`, `cpf`, `nome`
- `idade_gestante`
- `numero_gestacao` (ordem cronológica para o paciente)
- `data_inicio`, `data_fim`, `data_fim_efetiva`, `dpp`
- `fase_atual`, `trimestre_atual_gestacao`
- `equipe_nome`, `clinica_nome`
