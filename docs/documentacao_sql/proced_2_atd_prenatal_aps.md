# Documentação: `proced_2_atd_prenatal_aps.sql`

Este script é responsável por consolidar todos os atendimentos de pré-natal realizados na Atenção Primária à Saúde (APS) para cada gestação identificada.

## Objetivo Geral
Criar uma visão detalhada dos atendimentos de pré-natal (`_atendimentos_prenatal_aps`), incluindo dados antropométricos (peso, altura, IMC), pressão arterial, diagnósticos (CIDs), prescrições e cálculos de ganho de peso.

## Tabelas de Origem
- `rj-sms-sandbox.sub_pav_us._gestacoes`: Tabela de gestações únicas (gerada pelo `proced_1`).
- `rj-sms.saude_historico_clinico.episodio_assistencial`: Base de registros clínicos, medidas e prescrições.

## Detalhamento da Lógica (CTEs)

### 1. `marcadores_temporais`
Importa os dados básicos de cada gestação da tabela mestre `_gestacoes`.

### 2. Lógica de Peso e Altura Inicial (`peso_anterior_dum`, `peso_posterior_dum`, `peso_proximo_inicio`)
Busca o peso mais próximo ao início da gestação (DUM - Data da Última Menstruação) para servir de base:
- **Prioridade**: Peso registrado até 180 dias **antes** da DUM.
- **Fallback**: Peso registrado **após** a DUM (o primeiro registro disponível).
- O resultado garante um "Peso Inicial" único por gestação.

### 3. Lógica de Altura Moda (`alturas_filtradas`, `altura_preferencial`, `altura_fallback`, `altura_moda_completa`)
Calcula a altura da paciente usando a **moda** (valor mais frequente) dos registros:
- Busca preferencialmente registros entre 1 ano antes do início e o fim da gestação.
- Se não houver, usa qualquer registro de altura disponível no histórico.

### 4. `peso_altura_inicio`
Combina o peso e altura iniciais para calcular o **IMC de Início** e sua classificação (Baixo peso, Eutrófico, Sobrepeso ou Obesidade).

### 5. `atendimentos_filtrados`
Filtra os episódios assistenciais para identificar consultas de pré-natal na APS:
- **Subtipo**: 'Atendimento SOAP'.
- **Fornecedor**: 'vitacare'.
- **Categorias Profissionais**: Filtra por especialidades ESF (Médicos e Enfermeiros de Família), Ginecologistas, Obstetras, etc.
- Agrega CIDs em uma única string (`cid_string`).

### 6. `atendimentos_gestacao`
Associa os atendimentos às gestações com base no `id_paciente` e na data da consulta estar dentro do período da gestação.
Calcula a **IG (Idade Gestacional)** na data da consulta e o trimestre correspondente.

### 7. `prescricoes_aggregadas`
Agrega todas as prescrições médicas realizadas no mesmo atendimento em uma string.

### 8. `consultas_enriquecidas`
Consolida todas as informações:
- Calcula o **ganho de peso acumulado** (Peso da consulta - Peso inicial).
- Calcula o **IMC da consulta**.
- Atribui o número sequencial da consulta (`numero_consulta`) por gestação.

## Principais Regras de Negócio
- **Público Alvo**: Atualmente o resultado final filtra apenas gestações com `fase_atual = 'Gestação'`.
- **Classificação de IMC**: Segue faixas de corte padrão (<18, <25, <30, >=30).
- **IG da Consulta**: Calculada em semanas desde a `data_inicio`.

## Descrição da Saída
A tabela final contém:
- Identificadores: `id_gestacao`, `id_paciente`.
- Dados da Consulta: `data_consulta`, `numero_consulta`, `ig_consulta`, `trimestre_consulta`.
- Linha de Base: `peso_inicio`, `altura_inicio`, `imc_inicio`, `classificacao_imc_inicio`.
- Dados Antropométricos: `peso` (atual), `imc_consulta`, `ganho_peso_acumulado`.
- Sinais Vitais: `pressao_sistolica`, `pressao_diastolica`.
- Clínico: `descricao_s` (subjetivo/motivo), `cid_string`, `desfecho`, `prescricoes`.
- Local e Profissional: `estabelecimento`, `profissional_nome`, `profissional_categoria`.
