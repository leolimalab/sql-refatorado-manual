# 📊 Guia do Usuário - Dashboard Monitor da Gestante Carioca

## 📋 Sumário Executivo

O **Dashboard Monitor da Gestante Carioca** é uma plataforma digital desenvolvida pela Secretaria Municipal de Saúde do Rio de Janeiro para monitoramento em tempo real de **26.964 gestações ativas** no município. Este sistema integra dados de múltiplas fontes para oferecer uma visão 360° da saúde materno-infantil no Rio de Janeiro.

### 🎯 Objetivos do Sistema
- **Monitoramento em Tempo Real**: Acompanhamento contínuo de gestantes ativas
- **Gestão Baseada em Evidências**: Decisões fundamentadas em dados precisos
- **Identificação de Grupos de Risco**: Foco especial em gestantes adolescentes
- **Otimização de Recursos**: Distribuição eficiente de equipes e atendimentos
- **Prevenção de Complicações**: Monitoramento de condições críticas

---

## 🌐 Acesso ao Sistema

### 📍 URL de Acesso
- **Desenvolvimento**: `http://localhost:3002`
- **Produção**: [A ser definido pela SMS-Rio]

### 🔐 Requisitos de Acesso
- **Navegador**: Chrome, Firefox, Safari ou Edge (versões atuais)
- **Conexão**: Internet estável para acesso aos dados do BigQuery
- **Resolução**: Mínima 1024x768 (responsivo para mobile)
- **Permissões**: Credenciais da SMS-Rio conforme hierarquia

---

## 📊 Visão Geral do Dashboard

### 🏗️ Arquitetura da Informação

O dashboard está organizado em **6 seções principais**:

1. **📈 Header Principal** - Total de gestações em acompanhamento
2. **⚠️ Grupos de Risco** - Adolescentes vs Mulheres Adultas
3. **💊 Métricas Essenciais** - Prescrições, trimestres e faixas etárias
4. **🏥 Condições Médicas** - Diabetes, hipertensão, HIV, sífilis
5. **📋 Dados de Atendimento** - Consultas, visitas, emergências
6. **🔧 Status do Sistema** - Conectividade e última atualização

### 🎨 Sistema Visual
- **Cores Primárias**: Azul institucional (`#3b82f6`) para saúde pública
- **Códigos de Risco**:
  - 🟢 Verde: Indicadores normais
  - 🟡 Amarelo: Grupos de atenção
  - 🔴 Vermelho: Situações críticas
- **Responsividade**: Adaptação automática para desktop, tablet e mobile

---

## 📋 Seções Detalhadas

### 1. 📈 Header Principal

```
🤰 Monitor da Gestante Carioca
26.964 Gestações em Acompanhamento
```

**Interpretação**:
- Número total de gestantes com acompanhamento ativo
- Inclui apenas gestações na fase "Gestação" (exclui puerpério e encerradas)
- Atualização em tempo real via BigQuery

**Indicadores de Alerta**:
- Mudanças superiores a 5% indicam necessidade de investigação
- Queda abrupta pode sinalizar problemas no sistema

### 2. ⚠️ Grupos de Risco

```
👥 Grupos de Risco Principal
├── 🔴 Gestantes Adolescentes: 4.252 (15,8%)
└── 🟢 Mulheres Adultas: 22.712 (84,2%)
```

**Definições**:
- **Adolescentes**: ≤ 20 anos (alto risco obstétrico)
- **Mulheres Adultas**: > 20 anos (risco padrão)

**Parâmetros de Referência**:
- **Meta SMS-Rio**: < 12% de gestantes adolescentes
- **Indicador Nacional**: ~15% (Brasil, 2023)
- **Alerta Crítico**: > 20% requer intervenção imediata

**Ações Recomendadas**:
- **15,8%**: Percentual próximo à média nacional, manter monitoramento
- **Acima de 18%**: Intensificar programas de educação sexual
- **Acima de 22%**: Ações emergenciais em territórios específicos

### 3. 💊 Métricas Essenciais

#### 3.1 Prescrições Obrigatórias

```
💊 Prescrições Essenciais
├── 🟢 Ácido Fólico: 94,4% ✅
├── 🟢 Carbonato de Cálcio: 90,9% ✅
└── 🔴 AAS (Aspirina): 11,9% ⚠️
```

**Protocolos SMS-Rio**:
- **Ácido Fólico**: Meta 95% (prevenção defeitos tubo neural)
- **Carbonato de Cálcio**: Meta 90% (prevenção pré-eclâmpsia)
- **AAS (Aspirina)**: Meta 80% para alto risco (prevenção pré-eclâmpsia)

**Interpretação do AAS**:
- **11,9%** indica subprescrição significativa
- Possível causa: Critérios restritivos ou falta de identificação de alto risco
- **Ação**: Revisar protocolos e capacitar equipes

#### 3.2 Distribuição por Trimestres

```
📅 Períodos Gestacionais
├── 1º Trimestre: 22,3% (6.012 gestantes)
├── 2º Trimestre: 42,0% (11.325 gestantes)
└── 3º Trimestre: 35,7% (9.627 gestantes)
```

**Distribuição Esperada**:
- **1º Trimestre**: 20-25% (captação precoce)
- **2º Trimestre**: 35-45% (período estável)
- **3º Trimestre**: 30-40% (preparação para parto)

**Análise Atual**:
- ✅ **22,3%** no 1º trimestre indica boa captação precoce
- ✅ **42,0%** no 2º trimestre dentro do esperado
- ✅ **35,7%** no 3º trimestre equilibrado

#### 3.3 Distribuição por Faixas Etárias

```
👥 Faixas Etárias Detalhadas
├── ≤15 anos: 312 (1,2%) 🔴
├── 16-20 anos: 3.940 (14,6%) 🟡
├── 21-30 anos: 14.853 (55,1%) 🟢
├── 31-40 anos: 7.138 (26,5%) 🟢
└── >40 anos: 721 (2,7%) 🟡
```

**Grupos de Atenção Especial**:
- **≤15 anos (1,2%)**: Gravidez na adolescência precoce - protocolo especial
- **>40 anos (2,7%)**: Gestação tardia - monitoramento intensivo

### 4. 🏥 Condições Médicas

#### 4.1 Condições Críticas

```
🏥 Condições Médicas Prioritárias
├── 🔴 Hipertensão: 923 casos (3,4%)
├── 🟡 Diabetes: 145 casos (0,5%)
├── 🔴 HIV: 26 casos (0,1%)
└── 🟢 Sífilis: 0 casos (0,0%)
```

**Benchmarks Nacionais**:
- **Hipertensão**: 2-8% (SMS-Rio: 3,4% ✅)
- **Diabetes Gestacional**: 3-25% (SMS-Rio: 0,5% - investigar subnotificação)
- **HIV**: 0,1-0,5% (SMS-Rio: 0,1% ✅)
- **Sífilis Congênita**: Meta eliminação (SMS-Rio: 0,0% ✅)

#### 4.2 Controle de Pressão Arterial

```
🩺 Monitoramento de Hipertensão
├── PA Alterada (≥2 medições): 137 casos
├── PA Grave (≥160/110): 228 casos
├── Com Anti-hipertensivo: 260 casos
└── Provável Hipertensa: 216 casos
```

**Indicadores de Qualidade**:
- **137 com PA alterada**: Necessita monitoramento intensivo
- **228 com PA grave**: Risco iminente, protocolo emergencial
- **260 medicadas**: Taxa de tratamento de 28% (923 hipertensas)
- **216 prováveis**: Aguardando confirmação diagnóstica

#### 4.3 Fatores de Risco Associados

```
⚠️ Fatores de Risco Adicionais
├── 🔴 Obesidade: 994 casos (3,7%)
├── 🟡 Doença Renal: 7 casos (0,03%)
└── 🟡 Gestação Gemelar: 11 casos (0,04%)
```

### 5. 📋 Dados de Atendimento

#### 5.1 Volume de Atendimentos

```
📊 Atendimentos por Modalidade
├── 🏥 Consultas Pré-natal APS: 203.794
├── 🏠 Visitas ACS: 156.514
├── 🚨 Consultas Emergenciais: 19.659
└── 📋 Encaminhamentos: 27.431
```

**Médias por Gestante**:
- **Pré-natal APS**: 7,6 consultas/gestante (Meta MS: 7 consultas)
- **Visitas ACS**: 5,8 visitas/gestante (Protocolo: 1/mês)
- **Emergências**: 0,7 consultas/gestante (aceitável < 1,0)
- **Encaminhamentos**: 1,0/gestante (dentro do esperado)

#### 5.2 Sistemas de Encaminhamento

```
📋 Encaminhamentos por Sistema
├── 🔵 SISREG: 6.270 (22,9%)
├── 🟡 SER: 0 (0,0%) - Sistema indisponível
├── 🔄 Ambos: 0 (0,0%)
└── 🔴 Por Hipertensão: 0 (Específicos)
```

**Status dos Sistemas**:
- **SISREG**: Funcionando normalmente (22,9% dos encaminhamentos)
- **SER**: Sistema temporariamente indisponível
- **Híbrido**: Nenhum caso usando ambos os sistemas
- **Hipertensão**: Sistema específico em implementação

### 6. 🔧 Status do Sistema

#### 6.1 Conectividade

```
🌐 Status de Conectividade
├── 🟢 BigQuery: Conectado
├── 🟢 Cache: Ativo (5 min)
├── 🟢 API: Operacional
└── 🟢 Dashboard: Online
```

**Indicadores de Sistema**:
- **Verde**: Sistema operacional normal
- **Amarelo**: Degradação de performance
- **Vermelho**: Sistema indisponível (fallback para dados mock)

#### 6.2 Última Atualização

```
📅 Última Reorganização
├── Data: 25/09/2025
├── Hora: 19:40
└── Fonte: BigQuery (Tempo Real)
```

---

## 🔍 Interpretação e Análise

### 📈 Indicadores Principais

#### Gestão de Risco
1. **15,8% de gestantes adolescentes** - Próximo à média nacional
2. **3,4% com hipertensão** - Dentro dos parâmetros esperados
3. **0,5% com diabetes** - Possível subnotificação a investigar
4. **94,4% com ácido fólico** - Excelente adesão ao protocolo

#### Qualidade do Atendimento
1. **7,6 consultas/gestante** - Acima da meta MS (7 consultas)
2. **5,8 visitas ACS/gestante** - Cobertura adequada
3. **0,7 emergências/gestante** - Baixo índice de complications
4. **11,9% com AAS** - Subprescrição significativa a corrigir

### 🚨 Alertas e Ações Prioritárias

#### Crítico (Ação Imediata)
- **AAS 11,9%**: Implementar protocolo de prescrição para alto risco
- **228 gestantes com PA grave**: Monitoramento intensivo urgente
- **Sistema SER indisponível**: Reativar para encaminhamentos completos

#### Importante (Ação em 30 dias)
- **Diabetes 0,5%**: Investigar possível subnotificação
- **312 gestantes ≤15 anos**: Protocolo específico para adolescentes
- **Cache 5 minutos**: Considerar reduzir para 2-3 minutos em produção

#### Monitoramento (Acompanhar)
- **Adolescentes 15,8%**: Manter programas de prevenção
- **Hipertensão 3,4%**: Monitorar tendência mensal
- **Emergências 0,7/gestante**: Manter índice baixo

---

## 👥 Casos de Uso por Perfil

### 🎯 Secretário Municipal de Saúde

**Reunião Executiva Mensal**:
```
📊 KPIs Principais para Apresentação
├── Total: 26.964 gestações (+2,3% vs mês anterior)
├── Risco: 15,8% adolescentes (meta <12%)
├── Qualidade: 94,4% ácido fólico (meta 95%)
└── Alerta: 11,9% AAS (meta 80% alto risco)
```

**Decisões Baseadas em Dados**:
- **Alocação de Recursos**: Focar regiões com >20% adolescentes
- **Capacitação**: Treinamento em prescrição de AAS
- **Parcerias**: Integração com educação para prevenção

### 👩‍⚕️ Coordenador de Atenção Primária

**Planejamento Semanal**:
```
📋 Áreas de Foco Semanal
├── 🔴 228 gestantes PA grave → protocolo urgente
├── 🟡 216 prováveis hipertensas → confirmação diagnóstica
├── 🟢 7,6 consultas/gestante → manter qualidade
└── 📊 Atualizar protocolos AAS
```

**Indicadores de Performance**:
- **Consultas APS**: 7,6/gestante (✅ acima da meta)
- **Visitas ACS**: 5,8/gestante (✅ cobertura adequada)
- **Emergências**: 0,7/gestante (✅ baixo índice)

### 👨‍⚕️ Médico da Atenção Primária

**Consulta Diária**:
- **Prescrições Obrigatórias**:
  - Ácido Fólico: Sempre (94,4% atual)
  - Cálcio: Protocolo padrão (90,9% atual)
  - AAS: Avaliar fatores de risco (apenas 11,9% atual)

**Fatores de Risco AAS**:
- Hipertensão prévia ou atual
- Diabetes gestacional
- Gestação anterior com pré-eclâmpsia
- Idade ≥40 anos ou ≤20 anos

### 👩‍💼 Analista de Dados

**Monitoramento Técnico**:
```
🔧 Checklist Sistema
├── ✅ BigQuery conectado
├── ✅ Cache funcionando (5min)
├── ⚠️ SER indisponível
└── 📊 26.964 registros processados
```

**Validação de Dados**:
- **Consistência**: Total trimestres = Total gestações
- **Qualidade**: Prescrições < 100% (válido)
- **Atualização**: Última reorganização recente

---

## 🛠️ Troubleshooting

### 🔴 Problemas Críticos

#### Dashboard Não Carrega
**Sintomas**: Tela branca ou erro de conexão
**Causas Possíveis**:
- Falha na conexão BigQuery
- Credenciais expiradas
- Problema de rede

**Soluções**:
1. Verificar conexão de internet
2. Aguardar 2-3 minutos (cache pode resolver)
3. Atualizar página (Ctrl+F5)
4. Contatar suporte técnico se persistir

#### Dados Desatualizados
**Sintomas**: Status mostra data/hora antiga
**Diagnóstico**: Verificar "Última Reorganização"
**Ação**:
- Se >6 horas: Possível problema no ETL
- Se >24 horas: Acionar equipe de dados urgente

#### Números Inconsistentes
**Sintomas**: Somas não batem, percentuais estranhos
**Verificação**:
- Total trimestres = Total gestações?
- Percentuais adolescentes + adultas = 100%?
- Prescrições ≤ 100%?

### 🟡 Problemas Moderados

#### Performance Lenta
**Sintomas**: Carregamento >10 segundos
**Otimizações**:
- Cache ativo reduz para 2-3 segundos
- Conexão BigQuery direta: 5-8 segundos
- Fallback dados mock: instantâneo

#### Interface Visual
**Problemas Comuns**:
- **Mobile**: Scroll horizontal aparece → Design responsivo corrige automaticamente
- **Cores**: Dificuldade leitura → Usar modo alto contraste do navegador
- **Tamanho fonte**: Muito pequena → Zoom navegador (Ctrl + +)

### 🟢 Problemas Menores

#### Navegação
- **Bookmark**: Salvar `http://localhost:3002` nos favoritos
- **Múltiplas abas**: Sistema suporta uso em várias abas simultaneamente
- **Atualização**: Sistema atualiza automaticamente a cada 5 minutos

#### Exportação (Futura)
- **Screenshots**: Use ferramenta de captura do sistema
- **Dados**: Funcionalidade de export em desenvolvimento
- **Relatórios**: Integração com BI em planejamento

---

## 📞 Suporte e Contatos

### 🆘 Níveis de Suporte

#### Nível 1 - Suporte Técnico
- **Horário**: 8h-18h, Segunda a Sexta
- **Responsabilidade**: Problemas de acesso, navegação, performance
- **Canal**: [Email/Telefone SMS-Rio]
- **SLA**: 4 horas úteis

#### Nível 2 - Equipe de Dados
- **Horário**: 8h-17h, Segunda a Sexta
- **Responsabilidade**: Inconsistências de dados, validação, ETL
- **Canal**: [Email equipe BigQuery]
- **SLA**: 8 horas úteis

#### Nível 3 - Desenvolvimento
- **Horário**: Sob demanda
- **Responsabilidade**: Bugs sistema, novas funcionalidades
- **Canal**: [Canal desenvolvimento]
- **SLA**: 24-48 horas

### 📋 Informações para Suporte

**Sempre forneça**:
- URL acessada
- Horário do problema
- Navegador e versão
- Mensagem de erro (screenshot)
- Dados esperados vs obtidos

**Template de Chamado**:
```
🆘 Chamado Dashboard Gestante
├── 📅 Data/Hora: [timestamp]
├── 👤 Usuário: [nome e perfil]
├── 🌐 URL: [url específica]
├── 🔍 Problema: [descrição detalhada]
├── 📱 Ambiente: [navegador/SO]
└── 📎 Evidências: [screenshots/logs]
```

---

## 📚 Glossário Técnico

### 🏥 Termos Médicos

**AAS (Ácido Acetilsalicílico)**: Aspirina em baixa dose para prevenção de pré-eclâmpsia em gestantes de alto risco

**ACS (Agente Comunitário de Saúde)**: Profissional que realiza visitas domiciliares para acompanhamento da gestante

**APS (Atenção Primária à Saúde)**: Primeiro nível de atenção do SUS, porta de entrada do sistema

**Pré-eclâmpsia**: Complicação caracterizada por hipertensão e proteinúria após 20 semanas de gestação

**Puerpério**: Período pós-parto (até 42 dias) quando ainda há acompanhamento específico

### 💻 Termos Técnicos

**BigQuery**: Sistema de banco de dados do Google Cloud usado para armazenar dados da SMS-Rio

**Cache**: Armazenamento temporário de dados para melhorar performance (5 minutos no sistema)

**Dashboard**: Painel visual para apresentação de dados e métricas em tempo real

**ETL**: Extract, Transform, Load - processo de atualização dos dados no sistema

**SER**: Sistema Eletrônico de Regulação da SMS-Rio

**SISREG**: Sistema Nacional de Regulação do Ministério da Saúde

### 📊 Indicadores de Saúde

**Captação Precoce**: Início do pré-natal antes de 12 semanas de gestação

**Cobertura ACS**: Percentual de gestantes com pelo menos uma visita domiciliar mensal

**Mortalidade Materna**: Óbitos de mulheres durante gestação ou até 42 dias após o parto

**Taxa de Cesariana**: Percentual de partos cesáreos (meta OMS: <15%)

---

## 📖 Referências Normativas

### 📋 Protocolos SMS-Rio
- Manual de Pré-natal de Baixo Risco (SMS-Rio, 2024)
- Protocolo de Hipertensão na Gestação (SMS-Rio, 2024)
- Diretrizes de Prescrição na Gestação (SMS-Rio, 2024)

### 🇧🇷 Regulamentações Nacionais
- Cadernos de Atenção Básica nº 32 - Atenção ao Pré-natal de Baixo Risco (MS, 2023)
- Diretrizes de Atenção à Gestante: Manual Técnico (MS, 2024)
- Política Nacional de Atenção Integral à Saúde da Mulher (MS, 2024)

### 🌍 Referências Internacionais
- Guidelines for Antenatal Care (WHO, 2024)
- Hypertensive Disorders in Pregnancy (ACOG, 2024)
- Prevention of Pre-eclampsia (FIGO, 2024)

---

## 🔄 Histórico de Versões

| Versão | Data | Principais Alterações |
|--------|------|----------------------|
| 1.0 | 25/09/2025 | Versão inicial do dashboard |
| 1.1 | [Futura] | Integração Sistema SER |
| 1.2 | [Futura] | Exportação de relatórios |
| 2.0 | [Futura] | Dashboard administrativo |

---

**Dashboard Monitor da Gestante Carioca**
© 2025 Secretaria Municipal de Saúde do Rio de Janeiro
**Versão**: 1.0 | **Última Atualização**: 27/09/2025