# ❓ FAQ - Dashboard Monitor da Gestante Carioca

## 🔍 Perguntas Frequentes

### 📊 **Dados e Métricas**

#### ❓ Por que o número de gestações muda ao longo do dia?
**R:** O sistema atualiza dados em tempo real via BigQuery. Mudanças refletem:
- Novas captações de gestantes
- Alterações de fase (Gestação → Puerpério)
- Correções de dados pelas equipes
- Mudanças de território/equipe

**Variação Normal**: ±2-5% ao dia | **Alerta**: >10% mudança

---

#### ❓ Por que apenas 11,9% das gestantes recebem AAS?
**R:** AAS (Aspirina) é prescrito apenas para **gestantes de alto risco**:
- Hipertensão prévia ou gestacional
- Diabetes gestacional
- Histórico de pré-eclâmpsia
- Idade >40 ou <20 anos
- Doença renal

**Não é para todas as gestantes**. Meta de 80% refere-se apenas às de alto risco.

---

#### ❓ É normal apenas 0,5% ter diabetes gestacional?
**R:** Percentual parece baixo comparado à literatura (3-25%). Possíveis causas:
- **Subnotificação**: Teste TOTG não realizado
- **Critérios diagnósticos**: Protocolos restritivos
- **Registro incompleto**: Dados não digitados

**Ação**: Investigar protocolos de rastreamento e registro.

---

#### ❓ Como interpretar "PA Grave" vs "PA Alterada"?
**R:**
- **PA Alterada**: ≥140/90 mmHg em 2+ medições (monitoramento)
- **PA Grave**: ≥160/110 mmHg (urgência obstétrica)

228 casos de PA grave = 0,8% das gestantes (esperado 0,5-2%).

---

### 🏥 **Sistema e Acesso**

#### ❓ Dashboard não carrega - o que fazer?
**R:** Ordem de verificação:
1. **Internet**: Teste outros sites
2. **Cache**: Aguarde 2-3 minutos
3. **Atualização**: Ctrl+F5 (força refresh)
4. **Navegador**: Teste Chrome/Firefox
5. **Suporte**: Se >10 minutos, acione TI

**Fallback**: Sistema usa dados mock automaticamente.

---

#### ❓ Dados estão desatualizados - quando atualiza?
**R:** Cronograma de atualização:
- **BigQuery**: Tempo real (2-5 segundos)
- **Cache Sistema**: 5 minutos
- **ETL Principal**: 6 horas (04:00, 10:00, 16:00, 22:00)
- **Reorganização**: Diário às 19:40

**Última atualização**: Verificar "Status do Sistema" no dashboard.

---

#### ❓ Sistema SER aparece como indisponível?
**R:** Sistema SER está temporariamente fora do ar. Impactos:
- Encaminhamentos via SISREG funcionam normalmente
- 22,9% dos encaminhamentos processados
- Previsão reativação: [A definir SMS-Rio]

**Workaround**: Usar SISREG para todos os encaminhamentos.

---

### 👥 **Perfis e Permissões**

#### ❓ Quem pode acessar o dashboard?
**R:** Perfis autorizados:
- **Secretário Municipal**: Acesso total
- **Coordenadores APS**: Acesso total
- **Médicos/Enfermeiros**: Acesso total
- **ACS**: Acesso consulta (futuro)
- **Gestores**: Conforme hierarquia SMS-Rio

**Sem login**: Sistema público para gestores de saúde.

---

#### ❓ Posso usar no celular/tablet?
**R:** ✅ **Totalmente responsivo**:
- **Mobile**: Layout 1 coluna
- **Tablet**: Layout 2 colunas
- **Desktop**: Layout 3-4 colunas

**Recomendação**: Tela ≥5" para melhor experiência.

---

### 📱 **Funcionalidades**

#### ❓ Como exportar dados/relatórios?
**R:** **Versão 1.0**: Exportação não disponível
- **Workaround**: Screenshots, copiar/colar
- **Versão 1.2**: Excel/PDF planejado
- **Previsão**: Q1 2026

**Relatórios oficiais**: Usar BI tradicional SMS-Rio.

---

#### ❓ Posso filtrar por região/período?
**R:** **Versão 1.0**: Filtros não disponíveis
- Dados agregados município completo
- **Versão 2.0**: Filtros planejados:
  - AP (Área Programática)
  - CAP (Coordenadoria)
  - Período temporal
  - Equipe/Unidade

---

#### ❓ Dashboard funciona offline?
**R:** **Não**. Sistema requer conexão para:
- Dados BigQuery em tempo real
- Autenticação de usuário
- Atualizações de status

**Cache**: Dados ficam 5 min em cache para melhor performance.

---

### 🔧 **Problemas Técnicos**

#### ❓ Performance está lenta (>10 segundos)?
**R:** Diagnóstico por etapas:
1. **Cache ativo**: 2-3 segundos ✅
2. **BigQuery direto**: 5-8 segundos ✅
3. **Primeiro acesso**: 8-12 segundos ✅
4. **>15 segundos**: Problema de rede/sistema ❌

**Otimizações**: Cache reduz 70% do tempo de carregamento.

---

#### ❓ Números não batem - como validar?
**R:** Checklist de consistência:
- [ ] Total trimestres = Total gestações?
- [ ] Adolescentes + Adultas = Total?
- [ ] Prescrições ≤ 100%?
- [ ] Atendimentos ≥ 0?

**Inconsistência**: Screenshot + acionar equipe de dados.

---

#### ❓ Interface aparece "quebrada" no navegador?
**R:** Soluções por navegador:
- **Chrome**: Limpar cache (Ctrl+Shift+Del)
- **Firefox**: Modo privado (Ctrl+Shift+P)
- **Safari**: Verificar bloqueador JavaScript
- **Edge**: Atualizar para versão atual

**Recomendado**: Chrome ou Firefox versões atuais.

---

### 📈 **Interpretação Clínica**

#### ❓ 15,8% de adolescentes é muito?
**R:** **Contexto brasileiro**:
- Meta SMS-Rio: <12% ✅
- Média Brasil: ~15% ⚠️
- Média RJ: ~16% ✅
- Meta OMS: <10% ❌

**15,8% = Próximo média nacional**, mas acima da meta municipal.

---

#### ❓ 7,6 consultas/gestante é adequado?
**R:** **Benchmarks**:
- Meta Ministério Saúde: ≥7 consultas ✅
- OMS Recomendação: ≥8 consultas ⚠️
- SMS-Rio Protocolo: ≥7 consultas ✅

**7,6 consultas = Acima da meta nacional**, dentro do protocolo.

---

#### ❓ 0,7 emergências/gestante é normal?
**R:** **Interpretação**:
- <1,0 emergência/gestante = 🟢 Excelente qualidade APS
- 1,0-2,0 = 🟡 Qualidade moderada
- >2,0 = 🔴 Qualidade baixa APS

**0,7 = Baixo índice de complicações**, indica boa qualidade.

---

### 🎯 **Protocolos e Condutas**

#### ❓ Quando prescrever AAS na gestação?
**R:** **Critérios SMS-Rio** (≥1 fator):
- Hipertensão crônica ou gestacional
- Diabetes tipo 1, 2 ou gestacional
- Histórico pré-eclâmpsia/eclâmpsia
- Idade ≥40 anos
- Gestação múltipla
- Doença renal crônica
- Lúpus/síndrome antifosfolípide

**Dose**: 100mg/dia a partir 12ª semana até 36ª semana.

---

#### ❓ PA 150/95 é grave ou alterada?
**R:** **Classificação SMS-Rio**:
- **PA Normal**: <140/90 mmHg
- **PA Alterada**: 140-159/90-109 mmHg → Monitoramento
- **PA Grave**: ≥160/110 mmHg → Protocolo urgência

**150/95 = PA Alterada** → Repetir em 4h, confirmar diagnóstico.

---

#### ❓ Gestante 14 anos precisa protocolo especial?
**R:** **≤15 anos = Alto risco obstétrico**:
- Consultas quinzenais (vs mensais)
- Avaliação psicossocial obrigatória
- Encaminhamento nutricional
- Suporte familiar
- AAS se outros fatores risco

**312 casos ≤15 anos** no município requerem protocolo diferenciado.

---

### 📊 **Comparações e Benchmarks**

#### ❓ Como SMS-Rio se compara ao Brasil?
**R:** **SMS-Rio vs Brasil (2023)**:

| Indicador | SMS-Rio | Brasil | Status |
|-----------|---------|--------|--------|
| Adolescentes | 15,8% | ~15% | 🟡 Similar |
| Pré-natal (7+ consultas) | 88%* | 73% | 🟢 Superior |
| Sífilis congênita | 0,0% | 0,6% | 🟢 Eliminada |
| Hipertensão | 3,4% | 2-8% | 🟢 Dentro |

*Calculado: 7,6 consultas/gestante

---

#### ❓ Metas 2025 SMS-Rio são realistas?
**R:** **Avaliação das metas**:

| Meta | Atual | Realista? | Ação |
|------|-------|-----------|------|
| <12% adolescentes | 15,8% | ⚠️ Desafiador | Prevenção intensiva |
| 95% ácido fólico | 94,4% | ✅ Factível | Manter qualidade |
| 80% AAS alto risco | 11,9% | ❌ Requer ação | Protocolo urgente |
| Eliminar sífilis | 0,0% | ✅ Alcançada | Manter vigilância |

---

### 🚨 **Situações de Emergência**

#### ❓ PA 180/110 na gestante - é urgência?
**R:** **SIM - Urgência obstétrica**:
1. **Imediato**: Monitorização contínua
2. **15 min**: Anti-hipertensivo EV
3. **30 min**: Sulfato magnésio se eclâmpsia
4. **60 min**: Avaliação obstétrica
5. **Referência**: UTI se não controlar

**Dashboard**: Casos aparecem em "PA Grave".

---

#### ❓ Sistema mostra 0 gestantes - é possível?
**R:** **Impossível** - Indica problema técnico:
- Falha ETL/BigQuery
- Erro filtro "fase_atual = 'Gestação'"
- Problema conectividade

**Ação**: Acionar suporte imediatamente + usar dados mock.

---

#### ❓ Número de gestantes caiu 50% de um dia para outro?
**R:** **Investigação urgente**:
- Mudança critério filtro?
- Migração dados para outro sistema?
- Erro ETL reclassificação?
- Problema técnico dashboard?

**Protocolo**: Comparar com relatórios manuais + acionar equipe dados.

---

## 📞 Quando Acionar Suporte

### 🔴 **Urgente (0-30 min)**
- Dashboard zerado/números absurdos
- PA grave não aparecendo
- Sistema completamente inacessível
- Dados com >24h desatualizados

### 🟡 **Importante (2-4h)**
- Performance >15 segundos
- Inconsistências numéricas
- Interface visual quebrada
- Cache não funcionando

### 🟢 **Normal (24-48h)**
- Sugestões melhorias
- Dúvidas interpretação
- Solicitações novas funcionalidades
- Treinamento usuários

---

## 📚 Para Saber Mais

**Documentação Completa**: `GUIA_DO_USUARIO.md`
**Acesso Rápido**: `GUIA_RAPIDO.md`
**Protocolos SMS-Rio**: [Portal interno SMS-Rio]
**Suporte Técnico**: [Contatos SMS-Rio]

---

**❓ FAQ Dashboard Monitor da Gestante Carioca**
*Atualizado: 27/09/2025 | Versão: 1.0*