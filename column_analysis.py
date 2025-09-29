#!/usr/bin/env python3
"""
Column Analysis Script: Compare view/1_linha_tempo.sql against 111-column specification
"""

# 111 columns from PLANEJAMENTO_111_COLUNAS.md
expected_111_columns = [
    # GRUPO 1: Dados Básicos do Paciente (1-16)
    "id_paciente", "cpf", "cns_string", "nome", "data_nascimento",
    "idade_gestante", "faixa_etaria", "raca", "numero_gestacao", "id_gestacao",
    "data_inicio", "data_fim", "data_fim_efetiva", "dpp", "fase_atual", "trimestre",

    # GRUPO 2: Idade Gestacional (17-18)
    "IG_atual_semanas", "IG_final_semanas",

    # GRUPO 3: Condições Médicas Básicas (19-26)
    "diabetes_previo", "diabetes_gestacional", "diabetes_nao_especificado", "diabetes_total",
    "hipertensao_previa", "preeclampsia", "hipertensao_nao_especificada", "hipertensao_total",

    # GRUPO 4: Análise de Hipertensão (27-38)
    "qtd_pas_alteradas", "teve_pa_grave", "total_medicoes_pa", "percentual_pa_controlada",
    "data_ultima_pa", "ultima_sistolica", "ultima_diastolica", "ultima_pa_controlada",
    "tem_anti_hipertensivo", "tem_anti_hipertensivo_seguro", "tem_anti_hipertensivo_contraindicado", "anti_hipertensivos_seguros",

    # GRUPO 5: Hipertensão Avançada (39-48)
    "anti_hipertensivos_contraindicados", "provavel_hipertensa_sem_diagnostico", "tem_encaminhamento_has",
    "data_primeiro_encaminhamento_has", "cids_encaminhamento_has", "tem_prescricao_aas",
    "data_primeira_prescricao_aas", "tem_aparelho_pa_dispensado", "data_primeira_dispensacao_pa", "qtd_aparelhos_pa_dispensados",

    # GRUPO 6: Antidiabéticos (49-50)
    "tem_antidiabetico", "antidiabeticos_lista",

    # GRUPO 7: Fatores de Risco (51-58)
    "doenca_renal_cat", "doenca_autoimune_cat", "gravidez_gemelar_cat",
    "hipertensao_cronica_confirmada", "diabetes_previo_confirmado", "total_fatores_risco_pe",
    "tem_indicacao_aas", "adequacao_aas_pe",

    # GRUPO 8: Outras Condições (59-67)
    "hiv", "sifilis", "tuberculose", "categorias_risco", "justificativa_condicao",
    "deve_encaminhar", "cid_alto_risco", "max_pressao_sistolica", "max_pressao_diastolica",

    # GRUPO 9: Pressão Arterial e Consultas (68-76)
    "data_max_pa", "total_consultas_prenatal", "prescricao_acido_folico", "prescricao_carbonato_calcio",
    "dias_desde_ultima_consulta", "mais_de_30_sem_atd", "total_visitas_acs", "data_ultima_visita", "dias_desde_ultima_visita_acs",

    # GRUPO 10: Informações Gerais (77-82)
    "obito_indicador", "obito_data", "area_programatica", "clinica_nome", "equipe_nome", "mudanca_equipe_durante_pn",

    # GRUPO 11: Eventos de Parto (83-87)
    "data_parto", "tipo_parto", "estabelecimento_parto", "motivo_atencimento_parto", "desfecho_atendimento_parto",

    # GRUPO 12: Status de Encaminhamentos (88-89)
    "houve_encaminhamento", "origem_encaminhamento",

    # GRUPO 13: Campos SISREG (90-98)
    "sisreg_primeira_data_solicitacao", "sisreg_primeira_status", "sisreg_primeira_situacao",
    "sisreg_primeira_procedimento_nome", "sisreg_primeira_procedimento_id", "sisreg_primeira_cid",
    "sisreg_primeira_unidade_solicitante", "sisreg_primeira_medico_solicitante", "sisreg_primeira_operador_solicitante",

    # GRUPO 14: Campos SER (99-107)
    "ser_classificacao_risco", "ser_recurso_solicitado", "ser_estado_solicitacao", "ser_data_agendamento",
    "ser_data_execucao", "ser_unidade_executante", "ser_cid", "ser_descricao_cid", "ser_unidade_origem",

    # GRUPO 15: Urgência e Emergência (108-111)
    "Urg_Emrg", "ue_data_consulta", "ue_motivo_atendimento", "ue_nome_estabelecimento"
]

# Extracted columns from view/1_linha_tempo.sql (from final CTE SELECT statement)
implemented_columns = [
    # Basic patient data (1-18)
    "id_paciente", "cpf", "cns_string", "nome", "data_nascimento", "idade_gestante",
    "faixa_etaria", "raca", "numero_gestacao", "id_gestacao", "data_inicio", "data_fim",
    "data_fim_efetiva", "dpp", "fase_atual", "trimestre", "IG_atual_semanas", "IG_final_semanas",

    # Basic medical conditions (19-26)
    "diabetes_previo", "diabetes_gestacional", "diabetes_nao_especificado", "diabetes_total",
    "hipertensao_previa", "preeclampsia", "hipertensao_nao_especificada", "hipertensao_total",

    # Hypertension fields from _condicoes table (27-48)
    "qtd_pas_alteradas", "teve_pa_grave", "total_medicoes_pa", "percentual_pa_controlada",
    "data_ultima_pa", "ultima_sistolica", "ultima_diastolica", "ultima_pa_controlada",
    "tem_anti_hipertensivo", "tem_anti_hipertensivo_seguro", "tem_anti_hipertensivo_contraindicado",
    "anti_hipertensivos_seguros", "anti_hipertensivos_contraindicados", "provavel_hipertensa_sem_diagnostico",
    "tem_encaminhamento_has", "data_primeiro_encaminhamento_has", "cids_encaminhamento_has",
    "tem_prescricao_aas", "data_primeira_prescricao_aas", "tem_aparelho_pa_dispensado",
    "data_primeira_dispensacao_pa", "qtd_aparelhos_pa_dispensados",

    # Antidiabetics (49-50)
    "tem_antidiabetico", "antidiabeticos_lista",

    # Risk factors (51-58)
    "doenca_renal_cat", "doenca_autoimune_cat", "gravidez_gemelar_cat",
    "hipertensao_cronica_confirmada", "diabetes_previo_confirmado", "total_fatores_risco_pe",
    "tem_indicacao_aas", "adequacao_aas_pe",

    # Additional field in implementation
    "tem_obesidade",

    # Encaminhamentos section
    "houve_encaminhamento", "origem_encaminhamento", "encaminhado_sisreg",

    # SISREG fields
    "sisreg_primeira_data_solicitacao", "sisreg_primeira_status", "sisreg_primeira_situacao",
    "sisreg_primeira_procedimento_nome", "sisreg_primeira_procedimento_id", "sisreg_primeira_cid",
    "sisreg_primeira_unidade_solicitante", "sisreg_primeira_medico_solicitante", "sisreg_primeira_operador_solicitante",

    # SER fields
    "ser_classificacao_risco", "ser_recurso_solicitado", "ser_estado_solicitacao", "ser_data_agendamento",
    "ser_data_execucao", "ser_unidade_executante", "ser_cid", "ser_descricao_cid", "ser_unidade_origem",

    # Consolidated encaminhamentos fields (additional in implementation)
    "data_primeiro_encaminhamento", "cids_encaminhamento", "procedimentos_encaminhamento", "status_encaminhamento",

    # Other conditions (59-67 equivalent)
    "hiv", "sifilis", "tuberculose", "categorias_risco", "justificativa_condicao",
    "deve_encaminhar", "cid_alto_risco", "max_pressao_sistolica", "max_pressao_diastolica", "data_max_pa",

    # Consultations and care (68-76 equivalent)
    "total_consultas_prenatal", "prescricao_acido_folico", "prescricao_carbonato_calcio",
    "dias_desde_ultima_consulta", "mais_de_30_sem_atd", "total_visitas_acs",
    "data_ultima_visita", "dias_desde_ultima_visita_acs",

    # General information (77-82 equivalent)
    "obito_indicador", "obito_data", "area_programatica", "clinica_nome",
    "equipe_nome", "mudanca_equipe_durante_pn",

    # Birth events (83-87 equivalent)
    "data_parto", "tipo_parto", "estabelecimento_parto", "motivo_atencimento_parto", "desfecho_atendimento_parto",

    # Emergency/urgency (108-111 equivalent)
    "Urg_Emrg", "ue_data_consulta", "ue_motivo_atendimento", "ue_nome_estabelecimento"
]

def analyze_columns():
    """Compare expected vs implemented columns"""

    expected_set = set(expected_111_columns)
    implemented_set = set(implemented_columns)

    missing = expected_set - implemented_set
    extra = implemented_set - expected_set
    present = expected_set & implemented_set

    print("=== COLUMN ANALYSIS REPORT ===")
    print(f"Expected columns: {len(expected_111_columns)}")
    print(f"Implemented columns: {len(implemented_columns)}")
    print(f"Columns present: {len(present)}")
    print(f"Missing columns: {len(missing)}")
    print(f"Extra columns: {len(extra)}")
    print()

    if missing:
        print("🚨 MISSING COLUMNS:")
        for i, col in enumerate(sorted(missing), 1):
            print(f"  {i:2d}. {col}")
        print()

    if extra:
        print("➕ EXTRA COLUMNS (not in 111-column spec):")
        for i, col in enumerate(sorted(extra), 1):
            print(f"  {i:2d}. {col}")
        print()

    print("✅ COLUMNS CORRECTLY IMPLEMENTED:")
    print(f"   {len(present)}/{len(expected_111_columns)} ({len(present)/len(expected_111_columns)*100:.1f}%)")

    return {
        'expected_count': len(expected_111_columns),
        'implemented_count': len(implemented_columns),
        'present_count': len(present),
        'missing_count': len(missing),
        'extra_count': len(extra),
        'missing_columns': sorted(missing),
        'extra_columns': sorted(extra),
        'present_columns': sorted(present)
    }

if __name__ == "__main__":
    result = analyze_columns()

    print("\n=== SUMMARY ===")
    if result['missing_count'] == 0:
        print("🎉 ALL 111 COLUMNS ARE IMPLEMENTED!")
    else:
        print(f"⚠️  {result['missing_count']} columns are missing")
        print(f"📊 Implementation status: {result['present_count']}/{result['expected_count']} columns")