# Documentação: `proced_5_encaminhamentos.sql`

Este script é responsável por identificar e consolidar os encaminhamentos para o pré-natal de alto risco, consultando as bases do SISREG (Sistema de Regulação) e do SER (Sistema Estadual de Regulação).

## Objetivo Geral
Criar uma tabela consolidada de encaminhamentos (`_encaminhamentos_V2`), permitindo identificar se uma gestante foi referenciada para o pré-natal de alto risco, qual o sistema de origem, o status da solicitação e o diagnóstico associado.

## Tabelas de Origem
- `rj-sms-sandbox.sub_pav_us._gestacoes`: Tabela de gestações únicas (gerada pelo `proced_1`).
- `rj-sms.saude_historico_clinico.paciente`: Dados cadastrais para obtenção do CNS.
- `rj-sms.brutos_sisreg_api.solicitacoes`: Base bruta de solicitações do SISREG.
- `rj-sms-sandbox.sub_pav_us.BD SER PRÉ NATAL 2024_2025AGO`: Base de dados do SER específica para pré-natal.

## Detalhamento da Lógica (CTEs)

### 1. `gestacoes_definidas`
Seleciona apenas as gestações que estão na `fase_atual = 'Gestação'`.

### 2. `paciente_identificadores`
Cria um mapeamento entre o `id_paciente` e seus diversos identificadores (`cpf` e `cns_paciente`), necessário para a busca nas bases reguladoras.

### 3. Pré-filtragem (`sisreg_pre_filtrado` e `ser_pre_filtrado`)
- **SISREG**: Filtra solicitações pelos códigos de procedimento específicos de pré-natal de alto risco (`0703844`, `0703886`, `0737024`, `0710301`, `0710128`) cruzando por CPF ou CNS.
- **SER**: Filtra a base específica do SER cruzando pelo CNS da paciente.

### 4. Associação à Gestação (`encaminhamento_SISREG` e `encaminhamento_SER`)
Vincula os encaminhamentos filtrados às gestações ativas, garantindo que a data da solicitação esteja dentro do período gestacional.
Utiliza `ROW_NUMBER()` para numerar as solicitações cronologicamente por gestação.

### 5. Seleção Final
Realiza a junção das informações do SISREG e SER:
- **`houve_encaminhamento`**: 'Sim' se houver registro em qualquer um dos sistemas.
- **`origem_encaminhamento`**: Indica se veio do 'SISREG', 'SER' ou de 'Ambos'.
- Consolida os dados da **primeira solicitação** (`rn_solicitacao = 1`) de cada sistema.

## Principais Regras de Negócio
- **Cruzamento Multi-identificador**: Utiliza CPF e CNS para maximizar o encontro de registros no SISREG.
- **Janela Temporal**: O encaminhamento só é considerado válido se solicitado entre o início da gestação e a data atual/fim.
- **Procedimentos Específicos**: Foca nos códigos regulatórios que caracterizam o pré-natal de alto risco.

## Descrição da Saída
A tabela final contém:
- `id_gestacao`, `id_paciente`, `cpf`.
- Indicadores: `houve_encaminhamento`, `origem_encaminhamento`.
- Dados SISREG: Data de solicitação, status, situação, procedimento, CID, unidade e médico solicitante.
- Dados SER: Classificação de risco, recurso solicitado, estado da solicitação, datas de agendamento/execução, CID e unidade executante/origem.
