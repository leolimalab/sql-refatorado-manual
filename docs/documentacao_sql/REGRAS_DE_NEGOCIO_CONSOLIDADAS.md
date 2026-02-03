# Consolidação de Regras de Negócio - Monitor Gestante

Este documento reúne todas as regras de negócio, critérios clínicos e lógicas de monitoramento implementadas nos scripts SQL do projeto.

---

## 1. Gestão do Ciclo Gravídico (`proced_1`)

- **Identificação de Nova Gestação**: Um intervalo de **60 dias** ou mais sem registros de CIDs ativos (`Z32.1`, `Z34.x`, `Z35.x`) define o início de uma nova gestação para a mesma paciente.
- **Data de Fim Estimada**: Caso não haja registro de encerramento (`RESOLVIDO`), a gestação é considerada encerrada **299 dias** (42 semanas e 5 dias) após a data de início (DUM).
- **Período de Puerpério**: Definido como o intervalo de **45 dias** imediatamente após a data de fim (real ou estimada).
- **Classificação de Trimestres**:
    - **1º Trimestre**: Até 13 semanas e 6 dias.
    - **2º Trimestre**: De 14 a 27 semanas e 6 dias.
    - **3º Trimestre**: 28 semanas ou mais.

---

## 2. Linha de Base Antropométrica (`proced_2`)

- **Peso Inicial**: Prioriza registros de peso realizados até **180 dias antes da DUM**. Caso não exista, utiliza o primeiro peso registrado após o início da gestação.
- **Altura Moda**: Utiliza o valor de altura mais frequente (moda) no histórico da paciente, priorizando registros entre 1 ano antes do início e o fim da gestação.
- **Classificação de IMC (Início)**:
    - **Baixo peso**: < 18.5
    - **Eutrófico**: 18.5 a 24.9
    - **Sobrepeso**: 25.0 a 29.9
    - **Obesidade**: >= 30.0

---

## 3. Monitoramento de Hipertensão e Risco Cardiovascular (`proced_6`)

### Regras de Identificação (CIDs)
- **Hipertensão Prévia (Crônica)**: Identificada pelos CIDs `I10` a `I15` ou `O10`. Considera diagnósticos registrados **antes** do fim da gestação.
- **Hipertensão Gestacional / Pré-eclâmpsia**: Identificada pelos CIDs `O11` (PE superposta), `O13` (Gestacional), `O14` (Pré-eclâmpsia), `O15` (Eclâmpsia) ou `O16` (Não especificada). Considera diagnósticos **durante** a gestação.

### Critérios Clínicos e de Alerta
- **Pressão Arterial Alterada**: Medições de PA **>= 140/90 mmHg**.
- **Crise Hipertensiva/Gravidade**: Medições de PA **> 160/110 mmHg**.
- **Provável Hipertensa Sem Diagnóstico**: Paciente sem CID de hipertensão, mas que apresenta pelo menos **2 medições alteradas**, ou teva uma **PA grave**, ou possui **dispensação de aparelho de PA**, ou **prescrição de anti-hipertensivo**.

### Adequação Medicamentosa
- **Seguros**: Metildopa, Hidralazina, Nifedipina.
- **Contraindicados/Cautela**: Enalapril, Captopril, Losartana, Atenolol, Propranolol, Hidroclorotiazida, Furosemida.

---

## 4. Diabetes: Classificação e Identificação (`proced_6`)

- **Diabetes Prévio**: Identificado pelos CIDs `E10` a `E14` ou `O24.0` a `O24.3`. São diagnósticos registrados **antes** do fim da gestação.
- **Diabetes Gestacional**: Identificado pelo CID `O24.4`, registrado **durante** a gestação.
- **Diabetes Não Especificado**: Identificado pelo CID `O24.9`.
- **Deteção Complementar**: Uso de antidiabéticos (Metformina, Insulina, Glibenclamida, Gliclazida) também é usado para confirmar a condição.

---

## 5. Protocolo de Sífilis (`proced_8`)

- **Diagnóstico**: Identificado pelos CIDs `A51`, `A53` ou `O98.1` (Sífilis complicando a gravidez). Considera registros desde **30 dias antes** do início da gestação.
- **Ciclo de Tratamento**: Intervalo maior que **21 dias** entre as doses define um novo ciclo.
- **Intervalo Clínico Ideal**: Entre **7 a 9 dias** entre as doses.
- **Falha de Tratamento**: Intervalo entre doses **> 14 dias** ou menos de 3 doses (se indicado o esquema completo).
- **Monitoramento de Cura**: Necessidade de VDRL pelo menos **30 dias após a última dose** do esquema.

---

## 6. Categorias de Alto Risco e Encaminhamento (`proced_6`)

- **Identificação de Risco**: O sistema cruza os diagnósticos da paciente com uma tabela de mapeamento (`_cids_risco_gestacional_cat_encam`).
- **Principais Categorias**:
    - **Nefropatias**: Doenças renais.
    - **Colagenoses**: Doenças autoimunes (ex: Lupus, SAF).
    - **Gemelaridade**: Gestação múltipla.
    - **Cardiopatias** e outras patologias crônicas graves.
- **Regra de Encaminhamento**: O campo `deve_encaminhar` é ativado quando o CID associado à paciente consta na lista de patologias que exigem acompanhamento em pré-natal de alto risco, conforme pactuação técnica.

---

## 7. Prevenção de Pré-eclâmpsia (AAS e Cálcio) (`proced_6`)

- **Janela de Oportunidade (AAS)**: O período ideal para início da prescrição de AAS é entre a **12ª e 20ª semana** de gestação.
- **Indicação de AAS**:
    - **Alto Risco**: Pelo menos 1 fator (ex: Histórico de PE, Gestação Múltipla, Obesidade, Diabetes, Hipertensão Crônica, Doença Renal/Autoimune).
    - **Risco Moderado**: Pelo menos 2 fatores (ex: Nuliparidade, Idade >= 35 anos).
- **Critérios de Adequação**:
    - **Adequado**: Prescrito dentro da janela (12-20s).
    - **Não Prescrito**: Indicado, mas sem registro de prescrição na janela.
    - **Falha de Conduta**: Paciente passou da 20ª semana sem prescrição, apesar da indicação.

---

## 8. Orquestração e Vínculos (`proced_5`, `proced_6`, `rotina_atualizacao`)

- **Vínculo Territorial**: A unidade de saúde principal é definida priorizando o cadastro ativo e, em caso de múltiplos, a unidade com maior volume de atendimentos de pré-natal.
- **Mudança de Equipe**: Identificada comparando a última equipe ativa na gestação com a equipe registrada antes do início da gravidez.
- **Validade de Encaminhamento**: Somente encaminhamentos (SISREG/SER) solicitados/agendados **durante** o intervalo da gestação são vinculados à linha do tempo atual.
- **Sequência de Dados**: A ordem de processamento deve seguir estritamente: Identificação -> Atendimentos/Vistorias/Regulação -> Consolidação -> Desnormalização.
