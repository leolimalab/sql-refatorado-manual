# Documentação: `proced_4_consultas_emergenciais.sql`

Este script identifica e consolida os atendimentos de emergência realizados por gestantes em unidades hospitalares ou de pronto atendimento (URPA).

## Objetivo Geral
Criar uma tabela consolidada de consultas emergenciais (`_consultas_emergenciais`), integrando dados do sistema hospitalar (Vitai) com o monitoramento de gestação para alertar sobre intercorrências.

## Tabelas de Origem
- `rj-sms-sandbox.sub_pav_us._gestacoes`: Tabela de gestações únicas (gerada pelo `proced_1`).
- `rj-sms.saude_historico_clinico.episodio_assistencial`: Base de registros clínicos hospitalares e emergenciais.

## Detalhamento da Lógica (CTEs)

### 1. `marcadores_temporais`
Importa os metadados da gestação (`id_gestacao`, `data_inicio`, `fase_atual`, etc.) e a vinculação com a APS.

### 2. `cids_agrupados`
Reúne todos os diagnósticos (CIDs) associados a um mesmo atendimento de emergência em strings concatenadas (`cids_emergencia` e `descricoes_cids_emergencia`).
- **Filtro**: `fornecedor = 'vitai'` e `subtipo = 'Emergência'`.

### 3. `atendimentos_ue_com_join` (Nota: CTE definida mas não utilizada diretamente no SELECT final)
Realiza a junção entre os episódios de emergência e as gestações, filtrando pela janela temporal da gravidez.

### 4. Seleção Final
Realiza o JOIN principal entre `episodio_assistencial` e `marcadores_temporais`:
- **Condições**: O atendimento deve ser do tipo 'Emergência' via sistema 'vitai' e ocorrer dentro do período gestacional.
- **Cálculos**: Determina a `idade_gestacional_consulta` (em semanas) e o `numero_consulta` (ordem sequencial de emergências para aquela gestação).

## Principais Regras de Negócio
- Considera apenas registros do sistema **Vitai** (foco em redes de emergência integrada).
- Vincula o atendimento à gestação caso a data de entrada ocorra entre a DUM e o fim da gestação (efetivo ou estimado).
- Agrega múltiplos CIDs para dar uma visão completa da possível intercorrência.

## Descrição da Saída
A tabela final contém:
- Identificação: `id_gestacao`, `id_paciente`, `cpf`, `nome_gestante`, `idade_gestante`.
- Contexto Gestacional: `data_inicio`, `fase_atual`, `idade_gestacional_consulta`, `unidade_APS_PN`, `equipe_PN_APS`.
- Dados do Atendimento: `id_hci`, `data_consulta`, `numero_consulta`, `motivo_atendimento`, `desfecho_atendimento`.
- Diagnóstico: `cids_emergencia`, `descricoes_cids_emergencia`.
- Local e Profissional: `nome_profissional`, `especialidade_profissional`, `nome_estabelecimento`.
