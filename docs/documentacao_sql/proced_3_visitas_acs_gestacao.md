# Documentação: `proced_3_visitas_acs_gestacao.sql`

Este script é responsável por filtrar e organizar as visitas domiciliares realizadas pelos Agentes Comunitários de Saúde (ACS) durante o período gestacional.

## Objetivo Geral
Criar uma tabela consolidada de visitas de ACS (`_visitas_acs_gestacao`), permitindo o acompanhamento da frequência e do profissional que realizou a visita domiciliar para cada gestação.

## Tabelas de Origem
- `rj-sms-sandbox.sub_pav_us._gestacoes`: Tabela de gestações únicas (gerada pelo `proced_1`).
- `rj-sms.saude_historico_clinico.episodio_assistencial`: Base de registros clínicos e visitas domiciliares.

## Detalhamento da Lógica (CTEs)

### 1. `marcadores_temporais`
Importa os dados básicos da gestação, incluindo nome da unidade (`clinica_nome`) e equipe de saúde (`equipe_nome`) para contexto.

### 2. `visitas_com_join`
Realiza o filtro principal dos episódios assistenciais:
- **Fornecedor**: 'vitacare'.
- **Especialidade do Profissional**: 'Agente comunitário de saúde'.
- **Subtipo do Episódio**: 'Visita Domiciliar'.
- **Período**: A data da visita (`entrada_data`) deve estar entre o início da gestação (`data_inicio`) e o fim real ou estimado (`data_fim_efetiva`).

### 3. Seleção Final
Adiciona uma numeração sequencial (`numero_visita`) por gestação, ordenada pela data da visita de forma crescente.

## Principais Regras de Negócio
- Considera apenas registros do sistema Vitacare.
- Filtra estritamente por visitas realizadas por ACS (exclui outras especialidades que possam fazer visitas domiciliares).
- Vincula a visita à gestação específica da paciente baseada na janela temporal.

## Descrição da Saída
A tabela final contém:
- `id_hci`: Identificador único do episódio.
- `id_gestacao`, `id_paciente`, `cpf`, `nome_gestante`: Identificadores da paciente e da gestação.
- `entrada_data`: Data em que a visita foi realizada.
- `nome_estabelecimento`: Unidade de saúde do ACS.
- `nome_profissional`: Nome do ACS que realizou a visita.
- `numero_visita`: Contador sequencial (1ª visita, 2ª visita, etc.).
- `data_inicio`, `data_fim`, `data_fim_efetiva`: Metadados da gestação para referência.
