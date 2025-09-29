# 🔧 Matriz de Troubleshooting - Dashboard Monitor da Gestante Carioca

## 🎯 Guia de Diagnóstico Estruturado

### 📊 **Problemas de Dados**

#### 🔴 **Crítico: Dashboard Zerado**
```
💀 SINTOMAS
├── Total gestações = 0
├── Todas métricas zeradas
├── Interface carrega normalmente
└── Status mostra "erro BigQuery"

🔍 DIAGNÓSTICO
├── ✅ Interface funciona → Problema backend
├── ✅ Status visível → Dashboard OK
├── ❌ Dados zerados → Falha ETL ou query
└── ⚠️ BigQuery indisponível

🚨 AÇÃO IMEDIATA (0-15 min)
├── 1. Verificar status BigQuery (console.cloud.google.com)
├── 2. Testar query manual no BigQuery
├── 3. Verificar tabela _linha_tempo
├── 4. Acionar equipe dados SMS-Rio
└── 5. Ativar fallback dados mock

📞 CONTATOS EMERGÊNCIA
├── Suporte TI: [Telefone emergência]
├── Equipe BigQuery: [Email urgente]
└── Coordenação SMS: [WhatsApp plantão]
```

#### 🟡 **Importante: Números Inconsistentes**
```
⚠️ SINTOMAS
├── Trimestres não somam 100%
├── Adolescentes + Adultas ≠ Total
├── Prescrições > 100%
└── Atendimentos negativos

🔍 CHECKLIST VALIDAÇÃO
├── [ ] Soma trimestres = 26.964?
├── [ ] 4.252 + 22.712 = 26.964?
├── [ ] Prescrições ≤ 100%?
├── [ ] Todos números ≥ 0?

🛠️ AÇÃO CORRETIVA (15-60 min)
├── 1. Screenshot das inconsistências
├── 2. Anotar horário/navegador
├── 3. Testar em navegador diferente
├── 4. Aguardar próxima atualização (5 min)
├── 5. Se persistir → acionar dados
└── 6. Usar dados mock temporário

📧 TEMPLATE CHAMADO
Assunto: Dashboard - Inconsistência Numérica
Dados: [Screenshot]
Hora: [Timestamp]
Navegador: [Versão]
Problema: Trimestres somam X, deveria ser 26.964
```

#### 🟢 **Rotina: Dados Desatualizados**
```
📅 SINTOMAS
├── "Última reorganização" > 6h
├── Números não mudaram em 24h
├── Status mostra data antiga
└── Métricas estagnadas

🕐 CRONOGRAMA NORMAL
├── Tempo Real: 2-5 segundos
├── Cache: 5 minutos
├── ETL: 6 horas (04h, 10h, 16h, 22h)
└── Reorganização: Diário 19:40

⏱️ TEMPOS CRÍTICOS
├── >1h sem mudança → Verificar
├── >6h sem ETL → Investigar
├── >24h estagnado → Acionar
└── >48h parado → Emergência

🔄 AÇÃO PADRÃO
├── 1. Verificar "Status Sistema"
├── 2. Conferir hora última reorganização
├── 3. Aguardar próximo ETL
├── 4. Se crítico → acionar suporte
└── 5. Documentar para padrão
```

---

### 💻 **Problemas Técnicos**

#### 🔴 **Crítico: Dashboard Não Carrega**
```
💀 SINTOMAS
├── Tela branca/erro conexão
├── Timeout de carregamento
├── Erro "502 Bad Gateway"
└── "Cannot connect to server"

🔍 DIAGNÓSTICO STEP-BY-STEP
├── 1. Teste outros sites → Internet OK?
├── 2. Teste localhost:3002 → Servidor OK?
├── 3. Console browser (F12) → Erros JS?
├── 4. Rede corporativa → Proxy/Firewall?
└── 5. BigQuery API → Credenciais OK?

🚨 SOLUÇÃO HIERÁRQUICA
├── NÍVEL 1: Aguardar 2-3 minutos (cache)
├── NÍVEL 2: Ctrl+F5 (força refresh)
├── NÍVEL 3: Limpar cache navegador
├── NÍVEL 4: Testar navegador diferente
├── NÍVEL 5: Verificar rede/proxy
├── NÍVEL 6: Restart serviço dashboard
└── NÍVEL 7: Acionar TI SMS-Rio

📊 SLA RESOLUÇÃO
├── Usuário: 5 min (cache/refresh)
├── TI Local: 30 min (rede/navegador)
├── Suporte: 2h (servidor/configuração)
└── Desenvolvimento: 24h (código/BigQuery)
```

#### 🟡 **Importante: Performance Lenta**
```
🐌 SINTOMAS
├── Carregamento >10 segundos
├── Interface "congelada"
├── Timeout consultas
└── Cache não acelera

🔍 DIAGNÓSTICO PERFORMANCE
├── Cache ativo: 2-3s ✅
├── BigQuery direto: 5-8s ✅
├── Primeiro acesso: 8-12s ✅
├── >15s = Problema ❌

⚡ OTIMIZAÇÕES IMMEDIATE
├── 1. Verificar cache ativo (status)
├── 2. Testar horário baixa demanda
├── 3. Verificar conexão internet
├── 4. Limitar abas abertas
├── 5. Fechar aplicações pesadas
└── 6. Usar navegador otimizado

📈 MONITORAMENTO
├── Tempo normal: <5s
├── Alerta: 5-10s
├── Crítico: >10s
└── Emergency: >30s

🔧 FERRAMENTAS DIAGNÓSTICO
├── F12 → Network → Timing
├── Speedtest.net → Velocidade
├── Chrome Task Manager → Memória
└── BigQuery Console → Query time
```

#### 🟢 **Rotina: Interface Visual**
```
🎨 SINTOMAS
├── Layout "quebrado"
├── Cores estranhas
├── Fonte muito pequena/grande
└── Mobile mal formatado

🖥️ SOLUÇÕES POR DEVICE
├── Desktop: Zoom 100% (Ctrl+0)
├── Laptop: Zoom 90-110%
├── Tablet: Rotação portrait/landscape
└── Mobile: Zoom out, scroll vertical

🌐 SOLUÇÕES POR NAVEGADOR
├── Chrome: Limpar cache (Ctrl+Shift+Del)
├── Firefox: Modo privado (Ctrl+Shift+P)
├── Safari: Permitir JavaScript
├── Edge: Modo compatibilidade off
└── Internet Explorer: ❌ Não suportado

🎯 CONFIGURAÇÕES IDEAIS
├── Resolução: ≥1024x768
├── Zoom: 90-110%
├── JavaScript: Habilitado
├── Cookies: Habilitados
└── Ad-blocker: Desabilitado para site
```

---

### 🔐 **Problemas de Acesso**

#### 🔴 **Crítico: Acesso Negado**
```
🚫 SINTOMAS
├── "403 Forbidden"
├── "Unauthorized access"
├── "Invalid credentials"
└── "Permission denied"

🔑 VERIFICAÇÃO CREDENCIAIS
├── 1. Verificar VPN SMS-Rio ativa
├── 2. Confirmar usuário/senha válidos
├── 3. Testar em rede corporativa
├── 4. Verificar IP whitelist
└── 5. Confirmar perfil autorizado

🛡️ PERMISSÕES POR PERFIL
├── Secretário: Acesso total ✅
├── Coordenador: Acesso total ✅
├── Médico/Enfermeiro: Consulta ✅
├── ACS: Em desenvolvimento ⏳
└── Externo: Caso específico ⚠️

📞 AÇÃO ACESSO
├── 1. Confirmar perfil com gestor
├── 2. Solicitar liberação TI
├── 3. Validar necessidade acesso
├── 4. Aguardar aprovação (24-48h)
└── 5. Teste acesso liberado
```

#### 🟡 **Importante: Conectividade Intermitente**
```
📡 SINTOMAS
├── "Conexão perdida" esporádico
├── Dados carregam parcialmente
├── Status "BigQuery desconectado"
└── Fallback para mock ativo

🌐 DIAGNÓSTICO REDE
├── 1. Ping BigQuery: ping googleapis.com
├── 2. Teste velocidade: >10 Mbps
├── 3. Verificar proxy corporativo
├── 4. Confirmar DNS: 8.8.8.8
└── 5. Testar hotspot mobile

🔄 SOLUÇÕES REDE
├── WiFi instável → Cabo ethernet
├── VPN lenta → Desconectar/reconectar
├── Proxy → Configurar exceção
├── Firewall → Liberar googleapis.com
└── DNS → Usar 8.8.8.8/8.8.4.4

📊 QUALIDADE CONEXÃO
├── Excelente: >50 Mbps
├── Boa: 10-50 Mbps ✅
├── Adequada: 5-10 Mbps ⚠️
└── Insuficiente: <5 Mbps ❌
```

---

### 📱 **Problemas por Device**

#### 📱 **Mobile/Tablet**
```
📱 PROBLEMAS COMUNS
├── Layout quebrado → Rotacionar device
├── Zoom inadequado → Pinch to zoom
├── Scroll horizontal → Zoom out
├── Botões pequenos → Acessibilidade
└── Texto ilegível → Aumentar fonte

⚙️ CONFIGURAÇÕES MOBILE
├── Orientação: Portrait preferível
├── Zoom: 80-120%
├── Fonte: Grande/Extra-grande
├── Contraste: Alto se necessário
└── JavaScript: Obrigatório ativo

🎯 TELAS TESTADAS
├── iPhone: ≥5.5" ✅
├── Android: ≥5.0" ✅
├── iPad: Todas ✅
├── Tablet Android: ≥7" ✅
└── Tablet Windows: ≥8" ✅
```

#### 🖥️ **Desktop**
```
💻 CONFIGURAÇÕES IDEAIS
├── Resolução: 1920x1080+ (recomendado)
├── Mínima: 1024x768 ✅
├── Zoom: 100% (padrão)
├── Multi-monitor: Suportado
└── 4K/UHD: Escala 150%

🎨 LAYOUT RESPONSIVO
├── <768px: 1 coluna (mobile)
├── 768-1024px: 2 colunas (tablet)
├── 1024-1280px: 3 colunas (desktop)
├── 1280px+: 4 colunas (widescreen)
└── Ultra-wide: Centralizado

⚙️ OTIMIZAÇÕES DESKTOP
├── RAM: ≥4GB (recomendado 8GB)
├── CPU: Dual-core 2GHz+
├── Browser: Chrome/Firefox atuais
├── Adblocker: Desabilitado para site
└── Popup blocker: Configurado
```

---

### 🚨 **Protocolos de Escalação**

#### ⏱️ **Matriz de Tempo vs Criticidade**

| Problema | Severidade | Tempo Resolução | Escalação |
|----------|------------|-----------------|-----------|
| Dashboard zerado | 🔴 Crítica | 0-30 min | Imediata |
| PA grave não aparece | 🔴 Crítica | 0-15 min | Imediata |
| Dados >24h desatualizados | 🔴 Crítica | 0-60 min | 2h |
| Performance >30s | 🟡 Alta | 2-4h | 4h |
| Interface quebrada | 🟡 Alta | 4-24h | 24h |
| Números inconsistentes | 🟡 Média | 2-8h | 8h |
| Cache não funciona | 🟢 Baixa | 24-48h | 48h |
| Sugestão melhoria | 🟢 Baixa | 1-4 semanas | N/A |

#### 📞 **Níveis de Suporte**

```
🏁 NÍVEL 0: USUÁRIO (0-5 min)
├── F5 (refresh)
├── Ctrl+F5 (força refresh)
├── Aguardar cache (2-3 min)
├── Testar outro navegador
└── Verificar internet

📞 NÍVEL 1: SUPORTE LOCAL (5-30 min)
├── Limpar cache navegador
├── Verificar configurações proxy
├── Testar rede corporativa
├── Restart navegador/computador
└── Configurar exceções firewall

📧 NÍVEL 2: TI SMS-RIO (30 min - 4h)
├── Verificar servidor dashboard
├── Testar conectividade BigQuery
├── Analisar logs sistema
├── Verificar configurações DNS
└── Escalar para desenvolvimento

🔧 NÍVEL 3: DESENVOLVIMENTO (4h - 48h)
├── Debug código dashboard
├── Análise queries BigQuery
├── Correção bugs sistema
├── Deploy correções
└── Teste pós-correção

☁️ NÍVEL 4: GOOGLE CLOUD (48h+)
├── Suporte BigQuery especializado
├── Análise performance infraestrutura
├── Otimização queries complexas
├── Configuração avançada
└── Consultoria arquitetural
```

#### 📋 **Template de Chamado**

```
🎫 TEMPLATE SUPORTE - Dashboard Gestante
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 DATA/HORA: [DD/MM/AAAA HH:MM]
👤 USUÁRIO: [Nome] - [Perfil] - [Unidade]
🌐 URL: [URL específica ou localhost:3002]
💻 AMBIENTE: [Browser] [Versão] / [SO] [Versão]

🚨 PROBLEMA
Categoria: [ ] Dados [ ] Performance [ ] Interface [ ] Acesso
Severidade: [ ] Crítica [ ] Alta [ ] Média [ ] Baixa
Descrição: [Descrever sintomas específicos]

📊 DADOS ESPERADOS vs OBTIDOS
Esperado: [Ex: Total gestações ~27.000]
Obtido: [Ex: Total gestações = 0]
Screenshot: [Anexar se possível]

🔍 TENTATIVAS DE SOLUÇÃO
[ ] Refresh página (F5)
[ ] Limpar cache (Ctrl+F5)
[ ] Outro navegador
[ ] Aguardou 5+ minutos
[ ] Verificou internet

🕐 HISTÓRICO
Última vez funcionou: [Data/hora]
Mudanças recentes: [Sistema/rede/etc]
Frequência: [Primeira vez / Recorrente]

📞 CONTATO
Telefone: [WhatsApp preferencial]
Email: [institucional]
Urgência: [Justificar se crítica]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🎯 **Checklist Preventivo**

### 📋 **Diário (Gestores)**
- [ ] Verificar total gestações (variação <5%)
- [ ] Conferir data última reorganização
- [ ] Validar números críticos (PA grave, adolescentes)
- [ ] Testar performance (<10s carregamento)

### 📋 **Semanal (TI)**
- [ ] Backup configurações sistema
- [ ] Teste conectividade BigQuery
- [ ] Verificar logs erro
- [ ] Atualizar documentação problemas

### 📋 **Mensal (Coordenação)**
- [ ] Review chamados suporte
- [ ] Análise tendências problemas
- [ ] Atualização procedimentos
- [ ] Treinamento usuários novos

---

**🔧 Matriz Troubleshooting Dashboard Gestante Carioca**
*Versão: 1.0 | Atualização: 27/09/2025*