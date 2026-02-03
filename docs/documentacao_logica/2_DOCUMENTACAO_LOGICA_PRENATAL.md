# Documentação da Lógica: Consultas de Pré-Natal (APS)

Este documento detalha a lógica utilizada no arquivo `proced_2_atd_prenatal_aps.sql`. O objetivo deste procedimento é identificar consultas de pré-natal válidas, calcular indicadores nutricionais (IMC, ganho de peso) e estruturar o histórico de atendimentos da gestante.

## Visão Geral do Fluxo

O script cruza a linha do tempo das gestações com os registros de atendimento da Atenção Primária (SISAB/Vitacare). Ele aplica regras específicas para:
1.  Determinar o peso e altura basais (iniciais) da gestante.
2.  Filtrar apenas consultas qualificadas como pré-natal (profissionais e tipos de atendimento específicos).
3.  Calcular a evolução do peso e IMC ao longo das consultas.

---

## Passo 1: Definição do Peso Basal (Inicial)

**Objetivo:** Encontrar o peso de referência da gestante *antes* de engravidar ou no início da gestação para monitorar o ganho de peso.

**Estratégia de Busca (Priorização):**
O algoritmo tenta encontrar o melhor registro de peso seguindo esta ordem:
1.  **Prioridade 1 (Ideal):** Peso medido até 180 dias **ANTES** da Data da Última Menstruação (DUM). Isso representa o peso pré-gestacional real.
2.  **Prioridade 2 (Fallback):** Se não houver peso anterior, usa o primeiro peso medido **APÓS** a DUM (início da gestação).

**Representação Visual:**
```text
      [-180 dias]               [DUM / Início]               [Gestação em Curso]
          |                           |                             |
Busca:    | <--- Zona Ideal (1) ----> | <--- Zona Fallback (2) ---> |
          | (Pega o mais recente)     | (Pega o mais antigo/próximo)|
```

**Pseudocódigo:**
```text
CTE Peso_Anterior:
    Buscar pesos onde Data < DUM E Data >= DUM - 180 dias
    Ordenar por Data DESC (mais próximo da DUM)
    Pegar o primeiro.

CTE Peso_Posterior:
    Buscar pesos onde Data >= DUM
    Ordenar por Data ASC (mais próximo do início)
    Pegar o primeiro.

CTE Final:
    Se existe Peso_Anterior -> Usar Peso_Anterior
    Senão -> Usar Peso_Posterior
```

---

## Passo 2: Definição da Altura (Lógica da Moda)

**Objetivo:** Determinar a altura correta da paciente. Como a altura de adultos é constante, mas erros de digitação são comuns (ex: 1.65, 165, 1.56), usamos estatística para limpar o dado.

**Lógica:** O algoritmo calcula a **MODA** (valor mais frequente) das alturas registradas para a paciente no último ano.

**Exemplo Prático:**
*   Registros: `165 cm`, `165 cm`, `156 cm` (erro), `1.65 m` (convertido para 165).
*   Valor mais frequente: `165`.
*   Resultado: Altura considerada = 1.65m.

---

## Passo 3: Cálculo do IMC Inicial

Com Peso Basal e Altura definidos, calculamos o estado nutricional inicial.

**Fórmula:** `IMC = Peso / (Altura * Altura)`

**Classificação:**
*   **Baixo Peso:** IMC < 18.5
*   **Eutrófico (Normal):** 18.5 <= IMC < 25
*   **Sobrepeso:** 25 <= IMC < 30
*   **Obesidade:** IMC >= 30

---

## Passo 4: Filtro de Consultas (`atendimentos_filtrados`)

**Objetivo:** Identificar quais atendimentos no prontuário contam como consulta de pré-natal.

**Critérios de Inclusão:**
1.  **Tipo de Atendimento:** Deve ser 'Atendimento SOAP' (Evolução clínica padrão).
2.  **Profissional:** Apenas categorias qualificadas (Médicos de Família, Enfermeiros de Família, Obstetras, etc.).
3.  **Sistema:** Apenas registros do prontuário 'Vitacare'.

**Tratamento de CIDs:**
Como um atendimento pode ter múltiplos diagnósticos, eles são agrupados em uma única string (ex: "Z34.9, O24.4") para facilitar a leitura.

---

## Passo 5: Enriquecimento (`consultas_enriquecidas`)

**Objetivo:** Cruzar as consultas filtradas com a gestação e calcular indicadores dinâmicos.

**Lógica de Cruzamento:**
```text
PARA CADA Consulta Filtrada:
    VERIFICAR se Data_Consulta está dentro do intervalo [Data_Inicio, Data_Fim] da gestação.
    SE SIM:
        Calcular Idade Gestacional (Semanas) na data da consulta.
        Calcular Ganho de Peso = (Peso na Consulta - Peso Basal).
        Calcular IMC Atual.
        Listar Prescrições feitas no dia.
```

---

## Resumo dos Campos Chave Gerados

| Campo | Descrição | Origem |
|-------|-----------|--------|
| `data_consulta` | Data do atendimento | Prontuário |
| `ig_consulta` | Idade Gestacional (semanas) no dia | Calculado |
| `peso_inicio` | Peso Basal de referência | Lógica de Prioridade (-180d) |
| `ganho_peso_acumulado` | Diferença entre peso atual e basal | Calculado |
| `classificacao_imc_inicio` | Estado nutricional inicial | Calculado (OMS) |
| `prescricoes` | Lista de medicamentos receitados | Prontuário |
| `profissional_categoria` | Cargo do profissional (Médico/Enf) | Cadastro Profissional |
