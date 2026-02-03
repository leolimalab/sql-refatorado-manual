# Documentação da Lógica de Dados - Monitor Gestante

Este diretório contém a documentação detalhada da lógica de transformação de dados (ELT) utilizada no projeto Monitor Gestante.
A documentação está dividida por procedimento (etapa do pipeline), explicando o pseudocódigo e as regras de negócio aplicadas.

## Índice de Procedimentos

| Ordem | Arquivo SQL | Documentação | Descrição Resumida |
| :--- | :--- | :--- | :--- |
| **01** | `proced_1_gestacoes.sql` | [Lógica de Identificação de Gestações](./1_DOCUMENTACAO_LOGICA_GESTACOES.md) | Transforma diagnósticos brutos em uma linha do tempo de gestações (Início, Fim, Idade Gestacional). |
| **02** | `proced_2_atd_prenatal_aps.sql` | [Lógica de Pré-Natal APS](./2_DOCUMENTACAO_LOGICA_PRENATAL.md) | Identifica consultas de pré-natal, calcula IMC inicial e ganho de peso. |
| **03** | `proced_3_visitas_acs_gestacao.sql` | [Lógica de Visitas ACS](./3_DOCUMENTACAO_LOGICA_VISITAS_ACS.md) | Mapeia visitas domiciliares de Agentes Comunitários durante a gestação. |
| **04** | `proced_4_consultas_emergenciais.sql` | [Lógica de Emergências](./4_DOCUMENTACAO_LOGICA_CONSULTAS_EMERGENCIAIS.md) | Identifica atendimentos de emergência e seus desfechos. |
| **05** | `proced_5_encaminhamentos.sql` | [Lógica de Encaminhamentos](./5_DOCUMENTACAO_LOGICA_ENCAMINHAMENTOS.md) | Rastreia solicitações de Alto Risco no SISREG e SER. |
| **06** | `proced_6_linha_tempo.sql` | [Linha do Tempo Completa](./6_DOCUMENTACAO_LOGICA_LINHA_TEMPO.md) | **Tabela Principal.** Consolida todos os dados anteriores, calcula riscos de hipertensão/pré-eclâmpsia e adequação de AAS. |
| **07** | `proced_7_categorias_risco.sql` | [Normalização de Riscos](./7_DOCUMENTACAO_LOGICA_CATEGORIAS_RISCO.md) | Utilitário para explodir a lista de riscos em linhas individuais. |
| **08** | `proced_8_sifilis.sql` | [Monitoramento de Sífilis](./8_DOCUMENTACAO_LOGICA_SIFILIS.md) | Algoritmo especializado para rastrear ciclos de tratamento (Benzetacil), exames VDRL e tratamento do parceiro. |

---

## Como usar esta documentação
Cada arquivo de documentação contém:
1.  **Objetivo:** O que o script faz.
2.  **Pseudocódigo/Lógica:** Explicação simplificada do algoritmo ("se isso, então aquilo").
3.  **Regras de Negócio:** Critérios clínicos ou administrativos utilizados (ex: janelas de tempo, CIDs específicos).

Utilize estas referências para validar regras com a área técnica ou para entender como os indicadores são calculados.
