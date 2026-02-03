# Documentação: `proced_6_linha_tempo.sql`

Este é o script mais complexo e central do projeto, responsável por consolidar todas as informações coletadas nos procedimentos anteriores em uma única "Linha do Tempo" da gestante.

## Objetivo Geral
Gerar a tabela mestre `_linha_tempo`, que serve como fonte de dados para dashboards e relatórios de monitoramento. Ela integra dados clínicos, laboratoriais, medicamentosos, de regulação e desfechos de parto para cada gestante ativa.

## Tabelas de Origem
- `_gestacoes`, `_atendimentos_prenatal_aps`, `_visitas_acs_gestacao`, `_consultas_emergenciais`, `_encaminhamentos_V2`: Tabelas intermediárias geradas pelos procedimentos 1 a 5.
- `rj-sms.saude_historico_clinico.paciente`: Histórico completo do paciente.
- `rj-sms.saude_historico_clinico.episodio_assistencial`: Episódios clínicos gerais.
- `rj-sms.brutos_prontuario_vitacare_historico.cadastro`: Dados de vínculo territorial (unidade de cadastro).
- `rj-sms.saude_estoque.movimento`: Dispensação de materiais (aparelhos de PA).
- `rj-sms-sandbox.sub_pav_us._cids_risco_gestacional_cat_encam`: Tabela auxiliar de CIDs de risco.

## Detalhamento da Lógica (CTEs de Destaque)

### 1. Núcleo Clínico e de Risco
- **`condicoes_flags`**: Centraliza a identificação de doenças preexistentes ou gestacionais (Diabetes, Hipertensão, HIV, Sífilis, etc.) via mapeamento de CIDs.
- **`categorias_risco_gestacional`**: Classifica a gestação em categorias de risco clínico.

### 2. Gestão Territorial e Vínculo
- **`cad_e_atd`**: Lógica robusta para determinar a unidade de saúde principal da gestante, priorizando onde ela tem cadastro ativo e maior volume de atendimentos.
- **`equipe_durante_gestacao` / `equipe_anterior_gestacao`**: Detecta mudanças de equipe de saúde da família durante o pré-natal.

### 3. Análise de Hipertensão (Módulo HAS)
- **`analise_pressao_arterial`**: Avalia cada medição de PA (normal, alterada ou grave).
- **`resumo_controle_pressorico`**: Calcula o percentual de PA controlada e identifica situações de gravidade.
- **`prescricoes_anti_hipertensivos`**: Mapeia o uso de medicamentos, classificando-os em Seguros (ex: Metildopa) ou Contraindicados na gestação (ex: Enalapril).
- **`provavel_hipertensa_sem_diagnostico`**: Lógica de detecção precoce para pacientes com medições alteradas ou medicação prescrita, mas sem o CID correspondente no prontuário.

### 4. Prevenção e Adequação (Módulo AAS e Cálcio)
- **`fatores_risco_pe_adequacao`**: Lógica complexa que avalia 9 fatores de alto risco e 2 moderados. Cruza a idade gestacional com a prescrição de AAS para determinar se a conduta médica está:
    - Adequada (prescrito na janela 12-20s).
    - Necessária (indicado mas não prescrito).
    - Falha de conduta (passou da janela sem prescrição).

### 5. Desfechos e Cruzamento Hospitalar
- **`eventos_parto` / `partos_associados`**: Busca no prontuário hospitalar (Vitai) sinais de parto ou aborto para encerrar a linha do tempo ou identificar o puerpério.
- **`Urgencia_e_emergencia`**: Traz o último evento de urgência para destaque no monitoramento.

## Principais Regras de Negócio
- **Janela de AAS**: Considera o período ideal de início entre 12 e 20 semanas de gestação.
- **Status do Monitoramento**: Filtra apenas gestantes ativas ou no puerpério para o resultado final.
- **Deduplicação e Prioridade**: Sempre busca o registro mais recente ou a informação mais confiável (ex: CPF em vez de CNS quando possível).

## Descrição da Saída
A tabela consolidada possui centenas de colunas, agrupadas em:
- **Identificação**: CPF, CNS, Nome, Idade, Raça, Área Programática (AP).
- **Gestação**: IG atual, trimestre, DPP, fase (Gestação/Puerpério).
- **Marcadores de Risco**: Flags para todas as patologias monitoradas.
- **Dados de HAS/Diabetes**: Detalhamento de PA, medicamentos e controle.
- **Indicadores de Qualidade**: Total de consultas, visitas de ACS, adequação de AAS/Cálcio.
- **Vínculo**: Unidade de cadastro, unidade de atendimento, equipe atual e anterior.
- **Hospitalar**: Dados de urgência e dados do parto (se houver).
