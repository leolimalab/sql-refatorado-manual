# Documentação: `proced_8_sifilis.sql`

Este script é especializado no monitoramento do tratamento de sífilis em gestantes, integrando dados de diagnósticos, exames laboratoriais (VDRL), dispensação de medicação e tratamento do parceiro.

## Objetivo Geral
Criar uma tabela detalhada (`_sifilis_gestantes`) para o acompanhamento clínico rigoroso da sífilis, permitindo identificar falhas no tratamento, intervalos incorretos entre doses e a situação do parceiro, com foco na prevenção da sífilis congênita.

## Tabelas de Origem
- `rj-sms.projeto_gestacoes.gestacoes`: Base de gestações ativas.
- `rj-sms.saude_historico_clinico.episodio_assistencial`: Diagnósticos estruturados.
- `rj-sms.brutos_prontuario_vitacare.atendimento`: Diagnósticos em formato JSON.
- `rj-sms.brutos_prontuario_vitacare_historico.pre_natal` / `acto`: Dados históricos de exames e tratamento do parceiro.
- `rj-sms.projeto_estoque.estoque_movimento`: Registros de dispensação de Benzilpenicilina Benzatina.

## Detalhamento da Lógica (CTEs)

### 1. `diagnosticos_raw`
Consolida diagnósticos de sífilis (CIDs A51, A53, O98.1) de duas fontes: a tabela estruturada de episódios e o JSON bruto de atendimentos Vitacare.

### 2. `vdrl_raw`
Extrai resultados e titulações de VDRL do histórico de pré-natal.

### 3. `dados_parceiro_raw`
Recupera a informação mais recente sobre o status de tratamento e exames do parceiro da gestante.

### 4. Ciclos de Tratamento (`dispensacoes_com_lag`, `dispensacoes_com_flag`, `dispensacoes_com_ciclo`, `ciclos_de_tratamento`)
Lógica avançada para agrupar dispensações de penicilina:
- Um novo ciclo é identificado se houver um intervalo maior que **21 dias** entre as doses.
- Agrupa as doses em Dose 1, 2 e 3 para cada ciclo.

### 5. `vdrl_associado`
Vincula o VDRL de diagnóstico (antes da Dose 1) e o VDRL de acompanhamento/cura (pelo menos 30 dias após a última dose do ciclo).

## Principais Regras de Negócio e KPIs
- **Status do Tratamento**:
    - **Completo**: 3 ou mais doses.
    - **Em curso**: Doses 1 ou 2 realizadas há menos de 14 dias (janela para a próxima dose).
    - **Incompleto**: Intervalo maior que 14 dias sem a dose subsequente.
- **Alertas de Falha**:
    - Tratamento sem diagnóstico registrado.
    - Intervalo entre doses incorreto (idealmente entre 7 e 9 dias).
    - Ausência de exames de monitoramento de cura (VDRL pós-tratamento).
- **Tratamento do Parceiro**: Monitora se o parceiro foi tratado simultaneamente.

## Descrição da Saída
A tabela final contém:
- Identificação: `id_gestacao`, `id_paciente`, `id_episodio_sifilis`.
- Tratamento: Datas das doses 1, 2 e 3, número total de doses dispensadas.
- Laboratorial: Data, resultado e titulação do VDRL (diagnóstico e acompanhamento).
- Parceiro: Status de tratamento, doses e resultados de exames do parceiro.
- Status Clínicos: `status_tratamento_dispensado`, `status_final_gestante`, `status_parceiro`.
