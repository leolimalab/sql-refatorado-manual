# ⚡ Guia Rápido - Dashboard Monitor da Gestante Carioca

## 📊 Visão Executiva (30 segundos)

```
🎯 DADOS ATUAIS
├── 26.964 gestações ativas
├── 15,8% adolescentes (4.252)
├── 7,6 consultas pré-natal/gestante
└── 94,4% com ácido fólico

🚨 ALERTAS CRÍTICOS
├── AAS: 11,9% (Meta: 80% alto risco)
├── PA Grave: 228 casos
├── Sistema SER: Indisponível
└── Diabetes: 0,5% (possível subnotificação)
```

## 🎯 Métricas-Chave por Perfil

### 👑 Secretário Municipal
| Indicador | Atual | Meta | Status |
|-----------|-------|------|---------|
| Total Gestações | 26.964 | - | 📊 |
| Adolescentes | 15,8% | <12% | 🟡 |
| Ácido Fólico | 94,4% | 95% | 🟢 |
| AAS Alto Risco | 11,9% | 80% | 🔴 |

### 👩‍⚕️ Coordenador APS
| Métrica | Volume | Qualidade |
|---------|--------|-----------|
| Consultas Pré-natal | 203.794 | 7,6/gestante ✅ |
| Visitas ACS | 156.514 | 5,8/gestante ✅ |
| Emergências | 19.659 | 0,7/gestante ✅ |
| PA Grave | 228 | Protocolo urgente 🔴 |

### 👨‍⚕️ Médico APS
| Prescrição | Taxa | Ação |
|------------|------|------|
| Ácido Fólico | 94,4% | Manter ✅ |
| Cálcio | 90,9% | Manter ✅ |
| AAS | 11,9% | **Revisar protocolo** 🔴 |

## 🚨 Protocolo de Ação Rápida

### Crítico (0-24h)
```bash
# PA Grave (228 casos)
1. Monitoramento intensivo
2. Consulta cardiológica
3. Medicação anti-hipertensiva
4. Avaliação hospitalização

# AAS Subprescrição (11,9%)
1. Revisar critérios alto risco
2. Capacitar equipes
3. Atualizar protocolos
4. Monitorar mensalmente
```

### Importante (1-7 dias)
```bash
# Diabetes Subnotificação (0,5%)
1. Verificar teste TOTG
2. Validar registros
3. Capacitar diagnóstico
4. Revisar fluxo

# Sistema SER Indisponível
1. Verificar conectividade
2. Contatar fornecedor
3. Usar SISREG temporário
4. Monitorar encaminhamentos
```

## 📱 Acesso Rápido

### URLs
- **Produção**: [A definir SMS-Rio]
- **Desenvolvimento**: `localhost:3002`
- **Fallback**: Dados mock automático

### Navegação Rápida
```
F5          → Atualizar dados
Ctrl + +    → Aumentar fonte
Ctrl + F    → Buscar na página
Tab         → Navegação teclado
```

## 🔍 Diagnóstico Express

### Sistema OK ✅
```
🟢 BigQuery: Conectado
🟢 Cache: Ativo (5min)
🟢 Dados: Atualizados
🟢 Performance: <5s
```

### Sistema Problema ❌
```
🔴 Erro conexão → Aguardar 3min
🟡 Cache expirado → F5
🔴 Dados antigos → Verificar ETL
🟡 Lento >10s → Verificar rede
```

## 📊 Interpretação Rápida

### Grupos Risco
- **<12%** adolescentes = 🟢 Excelente
- **12-18%** adolescentes = 🟡 Atenção
- **>18%** adolescentes = 🔴 Crítico

### Prescrições
- **>90%** ácido fólico = 🟢 Adequado
- **>80%** cálcio = 🟢 Adequado
- **>80%** AAS alto risco = 🟢 Adequado

### Atendimentos
- **≥7** consultas/gestante = 🟢 Meta MS
- **≥1** visita ACS/mês = 🟢 Cobertura
- **<1** emergência/gestante = 🟢 Qualidade

## 📞 Contatos Emergência

| Problema | Contato | SLA |
|----------|---------|-----|
| Dashboard não carrega | Suporte TI | 2h |
| Dados inconsistentes | Equipe Dados | 4h |
| PA Grave não aparece | Suporte + Médico | 30min |
| Sistema SER indisponível | Fornecedor | 2h |

## 🎯 Checklist Diário

### 📋 Gestor (5 min)
- [ ] Verificar total gestações (mudança >5%?)
- [ ] Conferir % adolescentes (>18%?)
- [ ] Validar prescrições críticas (AAS <20%?)
- [ ] Checar PA grave (>200 casos?)

### 📋 Coordenador (3 min)
- [ ] Revisar volume atendimentos
- [ ] Conferir casos PA grave
- [ ] Validar sistema conectividade
- [ ] Verificar encaminhamentos

### 📋 Médico (2 min)
- [ ] Protocolo AAS atualizado?
- [ ] Prescrições obrigatórias OK?
- [ ] Fatores risco identificados?
- [ ] Casos críticos priorizados?

## 🔧 Troubleshooting Express

| Sintoma | Solução Rápida |
|---------|----------------|
| Tela branca | Ctrl+F5, aguardar 2min |
| Números zerados | Cache expirado, aguardar |
| Data antiga | Problema ETL, acionar dados |
| Performance lenta | Verificar internet/cache |
| Mobile quebrado | Rotacionar device, zoom out |

---

**⚡ Guia Rápido Dashboard Gestante Carioca**
*Para informações detalhadas, consulte GUIA_DO_USUARIO.md*