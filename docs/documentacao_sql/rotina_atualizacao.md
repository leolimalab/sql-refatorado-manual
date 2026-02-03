# Documentação: `rotina_atualizacao.sql`

Este script atua como o orquestrador principal de todo o pipeline de dados do Monitor Gestante.

## Objetivo Geral
Garantir a execução sequencial e ordenada de todos os procedimentos armazenados (`procedures`), respeitando as dependências entre eles para que os dados finais da Linha do Tempo estejam corretos e atualizados.

## Fluxo de Execução (Ordem de Dependência)

O script chama as procedures na seguinte ordem:

1.  **`proced_1_gestacoes`**: Identifica as gestações. É a base de tudo.
2.  **`proced_2_atd_prenatal_aps`**: Processa atendimentos na APS. Depende da identificação das gestações.
3.  **`proced_3_visitas_acs_gestacao`**: Processa visitas de ACS. Depende da identificação das gestações.
4.  **`proced_4_consultas_emergenciais`**: Processa atendimentos de emergência. Depende da identificação das gestações.
5.  **`proced_5_encaminhamentos`**: Processa dados de regulação (SISREG/SER). Depende da identificação das gestações.
6.  **`proced_6_linha_tempo`**: Consolida todos os dados anteriores. Depende da conclusão de todos os passos de 1 a 5.
7.  **`proced_7_categorias_risco`**: Desnormaliza categorias de risco para BI. Depende dos dados consolidados no passo 6.

## Considerações Técnicas
- **Encadeamento**: Como as tabelas finais de uma procedure são usadas como entrada para as próximas, a ordem de chamada é crítica.
- **Manutenção**: Qualquer nova procedure que adicione dados à Linha do Tempo deve ser inserida nesta rotina, preferencialmente antes da `proced_6_linha_tempo`.

> [!NOTE]
> A procedure `proced_8_sifilis` não está incluída nesta rotina de atualização no arquivo atual. Caso o monitoramento de sífilis deva fazer parte do fluxo automático, ela deve ser adicionada à lista de chamadas.
