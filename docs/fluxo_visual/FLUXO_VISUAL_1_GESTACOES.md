# Fluxo Visual: Procedimento 1 - Identificação de Gestações

## Visão Geral do Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PROCED_1_GESTACOES - PIPELINE COMPLETO                   │
│                                                                             │
│  Transforma eventos clínicos dispersos em linha do tempo de gestações      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Fluxo Detalhado das CTEs

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 1: cadastro_paciente                                               ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Fonte: saude_dados_mestres.paciente                                      ┃
┃ Objetivo: Preparar base de pacientes com idade calculada                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  SELECT id_paciente, nome, cpf, cns, data_nascimento
         │  CALCULAR idade = DATE_DIFF(HOJE, data_nascimento, YEAR)
         │
         ▼
    ┌─────────────────────────────────┐
    │  Paciente ID  │  Nome  │  Idade │
    ├───────────────┼────────┼────────┤
    │  P001         │  Maria │   28   │
    │  P002         │  Ana   │   32   │
    │  P003         │  Julia │   25   │
    └─────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 2: eventos_brutos                                                  ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Fonte: saude_historico_clinico.episodio_assistencial                     ┃
┃ Filtro: CIDs de gestação (Z321, Z34%, Z35%)                             ┃
┃ Objetivo: Extrair apenas eventos que sinalizam gravidez                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  FILTRAR condicoes WHERE:
         │    - c.id = 'Z321' (Gravidez confirmada) OU
         │    - c.id LIKE 'Z34%' (Supervisão normal) OU
         │    - c.id LIKE 'Z35%' (Alto risco)
         │  E c.situacao IN ('ATIVO', 'RESOLVIDO')
         │
         ▼
    ┌───────────────────────────────────────────────────────┐
    │ id_paciente │ data_evento │ CID    │ situacao         │
    ├─────────────┼─────────────┼────────┼──────────────────┤
    │ P001        │ 2024-01-15  │ Z321   │ ATIVO            │
    │ P001        │ 2024-02-10  │ Z349   │ ATIVO            │
    │ P001        │ 2024-03-05  │ Z349   │ ATIVO            │
    │ P001        │ 2024-07-20  │ Z349   │ RESOLVIDO        │
    │ P001        │ 2025-11-01  │ Z321   │ ATIVO  ← NOVO!   │
    └───────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 3a: inicios_com_grupo                                             ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Regra: Gap de 60+ dias = Nova Gestação                                  ┃
┃ Objetivo: Detectar quando eventos pertencem à mesma gestação            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  CALCULAR dias_desde_anterior = data_atual - LAG(data_anterior)
         │
         │  IF dias_desde_anterior IS NULL OR >= 60:
         │      nova_gestacao_flag = 1
         │  ELSE:
         │      nova_gestacao_flag = 0
         │
         ▼
    ┌──────────────────────────────────────────────────────────────┐
    │ data_evento │ dias_gap │ nova_gestacao_flag │ Interpretação │
    ├─────────────┼──────────┼────────────────────┼───────────────┤
    │ 2024-01-15  │   NULL   │         1          │ 1ª Gestação   │
    │ 2024-02-10  │    26    │         0          │ Mesma         │
    │ 2024-03-05  │    23    │         0          │ Mesma         │
    │ 2024-07-20  │   137    │         1          │ (Fim? Próx.)  │
    │ 2025-11-01  │   469    │         1          │ 2ª Gestação   │
    └──────────────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 3b: grupos_inicios                                                ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Técnica: Soma acumulada dos flags                                       ┃
┃ Objetivo: Criar ID único para cada bloco de gestação                    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  grupo_numero = SUM(nova_gestacao_flag) OVER (
         │      PARTITION BY id_paciente
         │      ORDER BY data_evento
         │  )
         │
         ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │ data_evento │ flag │ grupo_numero │ Significado                  │
    ├─────────────┼──────┼──────────────┼──────────────────────────────┤
    │ 2024-01-15  │  1   │      1       │ ┐                            │
    │ 2024-02-10  │  0   │      1       │ ├─ Gestação 1 (Grupo 1)     │
    │ 2024-03-05  │  0   │      1       │ ┘                            │
    │ 2024-07-20  │  1   │      2       │ (Transição/Ambíguo)          │
    │ 2025-11-01  │  1   │      3       │ ── Gestação 2 (Grupo 3)     │
    └─────────────────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 4: inicios_deduplicados                                           ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Estratégia: Pegar evento MAIS RECENTE de cada grupo                     ┃
┃ Objetivo: Definir data oficial de início da gestação                    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  PARA CADA grupo:
         │      data_inicio = MAX(data_evento) WHERE grupo = X
         │
         ▼
    ┌────────────────────────────────────────────────────┐
    │ id_paciente │ grupo │ data_inicio │ id_gestacao   │
    ├─────────────┼───────┼─────────────┼───────────────┤
    │ P001        │   1   │ 2024-03-05  │ P001_1        │
    │ P001        │   3   │ 2025-11-01  │ P001_3        │
    └────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 5: gestacoes_unicas                                               ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Fonte: Eventos com situacao = 'RESOLVIDO'                               ┃
┃ Objetivo: Encontrar data de fim real da gestação                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  PARA CADA gestacao:
         │      data_fim = MIN(data_evento)
         │          WHERE situacao = 'RESOLVIDO'
         │          AND data_evento > data_inicio
         │
         ▼
    ┌──────────────────────────────────────────────────────┐
    │ id_gestacao │ data_inicio │ data_fim    │ Status   │
    ├─────────────┼─────────────┼─────────────┼──────────┤
    │ P001_1      │ 2024-03-05  │ 2024-07-20  │ Fechada  │
    │ P001_3      │ 2025-11-01  │ NULL        │ Aberta   │
    └──────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 6a: gestacoes_com_status                                          ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Regra: Gestações sem fim são encerradas após 299 dias (42s + 5d)       ┃
┃ Objetivo: Calcular data_fim_efetiva e status atual                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  data_fim_estimada = data_inicio + 299 dias
         │  data_fim_efetiva = COALESCE(data_fim_real, data_fim_estimada)
         │  dpp = data_inicio + 280 dias (40 semanas)
         │
         │  CALCULAR:
         │    - semanas_gestacao
         │    - trimestre_atual
         │    - idade_gestacional_fim
         │
         ▼
    ┌────────────────────────────────────────────────────────────────┐
    │ id_gestacao │ data_inicio │ data_fim_efetiva │ dpp        │ IG │
    ├─────────────┼─────────────┼──────────────────┼────────────┼────┤
    │ P001_1      │ 2024-03-05  │ 2024-07-20       │ 2024-12-10 │ 20s│
    │ P001_3      │ 2025-11-01  │ 2026-08-27*      │ 2026-08-08 │ 6s │
    └────────────────────────────────────────────────────────────────┘
                                  * estimada
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 6b: filtrado - Classificação de Fase                              ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Árvore de Decisão: Gestação / Puerpério / Encerrada                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │                    HOJE está...
         │                        │
         │          ┌─────────────┴──────────────┐
         │          │                            │
         │    Antes da data_fim?           Depois da data_fim?
         │          │                            │
         │     "GESTAÇÃO"               Há menos de 45 dias?
         │                                      │
         │                          ┌───────────┴────────────┐
         │                          │                        │
         │                         SIM                      NÃO
         │                          │                        │
         │                    "PUERPÉRIO"              "ENCERRADA"
         │
         ▼
    ┌───────────────────────────────────────────────────────────────┐
    │ id_gestacao │ fase_atual  │ Dias desde fim │ Lógica         │
    ├─────────────┼─────────────┼────────────────┼────────────────┤
    │ P001_1      │ Encerrada   │      177       │ > 45 dias      │
    │ P001_3      │ Gestação    │      -287      │ Ainda gestando │
    └───────────────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ PASSO 7: equipe_durante_gestacao                                        ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Fonte: brutos_prontuario_vitacare_historico.cadastro                    ┃
┃ Objetivo: Identificar equipe ESF que acompanhou a gestação              ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │  BUSCAR cadastro mais recente onde:
         │      data_atualizacao BETWEEN data_inicio AND data_fim_efetiva
         │
         ▼
    ┌──────────────────────────────────────────────────────────┐
    │ id_gestacao │ equipe_familia    │ ine      │ area       │
    ├─────────────┼───────────────────┼──────────┼────────────┤
    │ P001_1      │ ESF Vila Nova     │ INE12345 │ Área 02    │
    │ P001_3      │ ESF Centro        │ INE67890 │ Área 01    │
    └──────────────────────────────────────────────────────────┘
                    │
                    ▼

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ SAÍDA FINAL: Tabela _gestacoes                                          ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_us._gestacoes`         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    ┌──────────────────────────────────────────────────────────────────┐
    │                     CAMPOS PRINCIPAIS                            │
    ├──────────────────┬───────────────────────────────────────────────┤
    │ id_gestacao      │ Chave primária (id_paciente + seq)           │
    │ id_paciente      │ FK para paciente                              │
    │ data_inicio      │ Data confirmação da gravidez                  │
    │ data_fim_efetiva │ Data fim real ou estimada (299 dias)          │
    │ fase_atual       │ Gestação | Puerpério | Encerrada             │
    │ dpp              │ Data Provável do Parto (inicio + 40 semanas)  │
    │ semanas_gestacao │ Idade gestacional em semanas                  │
    │ trimestre_atual  │ 1º | 2º | 3º Trimestre                        │
    │ idade_gestante   │ Idade da paciente em anos                     │
    │ equipe_familia   │ ESF que acompanhou                            │
    │ ine              │ Identificador Nacional de Equipe              │
    └──────────────────┴───────────────────────────────────────────────┘
```

## Resumo Visual do Algoritmo

```
╔══════════════════════════════════════════════════════════════════════════╗
║                     REGRA DOS 60 DIAS - EXEMPLO                          ║
╚══════════════════════════════════════════════════════════════════════════╝

Timeline de Eventos:
═══════════════════════════════════════════════════════════════════════════

2024-01-15        2024-02-10        2024-03-05              2025-11-01
    │                 │                 │                         │
   Z321              Z349              Z349                     Z321
    │                 │                 │                         │
    └────── 26d ──────┴────── 23d ──────┘                         │
            ▼                 ▼                                    │
        (< 60 dias)      (< 60 dias)                              │
            │                 │                                    │
    ┌───────┴─────────────────┴───────┐                           │
    │      GESTAÇÃO 1 (Grupo 1)       │                           │
    │     Início: 2024-03-05          │                           │
    └─────────────────────────────────┘                           │
                                                                   │
                                            469 dias (> 60)        │
                                                   ▼               │
                                           ┌───────────────────────┘
                                           │  GESTAÇÃO 2 (Grupo 3)
                                           │  Início: 2025-11-01
                                           └───────────────────────
```

## Métricas de Processamento

```
┌────────────────────────────────────────────────────────────────┐
│ ESTATÍSTICAS TÍPICAS DO PIPELINE                              │
├────────────────────────────────────────────────────────────────┤
│ • Eventos CID brutos processados:        ~500.000             │
│ • Gestações únicas identificadas:        ~150.000             │
│ • Taxa de deduplicação:                  ~70%                 │
│ • Gestações com data_fim real:           ~60%                 │
│ • Gestações com data_fim estimada:       ~40%                 │
│ • Tempo médio de execução:               30-60 segundos       │
└────────────────────────────────────────────────────────────────┘
```

## Legenda de Símbolos

```
│  ─  Fluxo sequencial de dados
▼     Saída de uma etapa
┌─┐   Tabela ou dataset
┏━┓   CTE (Common Table Expression)
═══   Timeline temporal
```
