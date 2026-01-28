#!/usr/bin/env python3
"""
Analise de colunas: compara a especificacao de 111 colunas com a
implementacao do SELECT final em view/1_linha_tempo.sql.
"""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence

EXPECTED_COLUMNS_COUNT = 111
MAX_MISMATCHES_TO_SHOW = 10

# 111 columns from PLANEJAMENTO_111_COLUNAS.md
EXPECTED_111_COLUMNS = [
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
IMPLEMENTED_COLUMNS = [
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

# Aliases for backwards compatibility
expected_111_columns = EXPECTED_111_COLUMNS
implemented_columns = IMPLEMENTED_COLUMNS


@dataclass(frozen=True)
class OrderMismatch:
    position: int
    expected: str
    found: str


@dataclass(frozen=True)
class ColumnReport:
    expected: Sequence[str]
    implemented: Sequence[str]
    missing: List[str]
    extra: List[str]
    duplicates_expected: Dict[str, int]
    duplicates_implemented: Dict[str, int]
    order_mismatches: List[OrderMismatch]
    expected_positions: Dict[str, List[int]]
    implemented_positions: Dict[str, List[int]]

    @property
    def expected_count(self) -> int:
        return len(self.expected)

    @property
    def implemented_count(self) -> int:
        return len(self.implemented)

    @property
    def expected_unique_count(self) -> int:
        return len(set(self.expected))

    @property
    def implemented_unique_count(self) -> int:
        return len(set(self.implemented))

    @property
    def present_count(self) -> int:
        return len(set(self.expected) & set(self.implemented))

    @property
    def missing_count(self) -> int:
        return len(self.missing)

    @property
    def extra_count(self) -> int:
        return len(self.extra)

    @property
    def order_matches(self) -> bool:
        return len(self.order_mismatches) == 0


def index_positions(columns: Sequence[str]) -> Dict[str, List[int]]:
    positions: Dict[str, List[int]] = {}
    for idx, col in enumerate(columns, start=1):
        positions.setdefault(col, []).append(idx)
    return positions


def find_duplicates(columns: Sequence[str]) -> Dict[str, int]:
    counts = Counter(columns)
    return {col: count for col, count in counts.items() if count > 1}


def compare_order(expected: Sequence[str], implemented: Sequence[str]) -> List[OrderMismatch]:
    expected_set = set(expected)
    implemented_filtered = [col for col in implemented if col in expected_set]
    mismatches: List[OrderMismatch] = []
    for idx, (exp, got) in enumerate(zip(expected, implemented_filtered), start=1):
        if exp != got:
            mismatches.append(OrderMismatch(position=idx, expected=exp, found=got))
    return mismatches


def analyze_columns(expected: Sequence[str], implemented: Sequence[str]) -> ColumnReport:
    expected_set = set(expected)
    implemented_set = set(implemented)

    missing = sorted(expected_set - implemented_set)
    extra = sorted(implemented_set - expected_set)

    return ColumnReport(
        expected=expected,
        implemented=implemented,
        missing=missing,
        extra=extra,
        duplicates_expected=find_duplicates(expected),
        duplicates_implemented=find_duplicates(implemented),
        order_mismatches=compare_order(expected, implemented),
        expected_positions=index_positions(expected),
        implemented_positions=index_positions(implemented),
    )


def format_positions(positions: Iterable[int]) -> str:
    return ", ".join(str(pos) for pos in positions)


def print_list(
    title: str, items: Sequence[str], positions: Optional[Dict[str, List[int]]] = None
) -> None:
    print(title)
    if not items:
        print("  - nenhuma")
        print()
        return
    for i, col in enumerate(items, 1):
        suffix = ""
        if positions is not None and col in positions:
            suffix = f" (posicoes: {format_positions(positions[col])})"
        print(f"  {i:2d}. {col}{suffix}")
    print()


def print_duplicates(title: str, duplicates: Dict[str, int]) -> None:
    print(title)
    if not duplicates:
        print("  - nenhuma")
        print()
        return
    for i, (col, count) in enumerate(sorted(duplicates.items()), 1):
        print(f"  {i:2d}. {col} (x{count})")
    print()


def print_order_mismatches(mismatches: Sequence[OrderMismatch]) -> None:
    if not mismatches:
        print("ORDEM:")
        print("  - OK (ordem das colunas esperadas esta correta)")
        print()
        return

    print("ORDEM:")
    print("  - divergencias encontradas (mostrando as primeiras)")
    for mismatch in mismatches[:MAX_MISMATCHES_TO_SHOW]:
        print(
            f"  {mismatch.position:2d}. esperado={mismatch.expected} | "
            f"encontrado={mismatch.found}"
        )
    if len(mismatches) > MAX_MISMATCHES_TO_SHOW:
        print("  ...")
    print()


def print_summary(report: ColumnReport) -> None:
    print("=== RELATORIO DE ANALISE DE COLUNAS ===")
    print(f"Esperadas: {report.expected_count} (unicas: {report.expected_unique_count})")
    print(
        f"Implementadas: {report.implemented_count} (unicas: {report.implemented_unique_count})"
    )
    print(f"Presentes: {report.present_count}")
    print(f"Faltando: {report.missing_count}")
    print(f"Extras: {report.extra_count}")
    print(
        f"Percentual: {report.present_count}/{report.expected_count} "
        f"({report.present_count / report.expected_count * 100:.1f}%)"
    )
    if report.expected_count != EXPECTED_COLUMNS_COUNT:
        print(
            f"AVISO: esperadas {EXPECTED_COLUMNS_COUNT} colunas, "
            f"mas a lista tem {report.expected_count}."
        )
    print()


def main() -> None:
    report = analyze_columns(EXPECTED_111_COLUMNS, IMPLEMENTED_COLUMNS)

    print_summary(report)
    print_list("COLUNAS FALTANTES:", report.missing, report.expected_positions)
    print_list("COLUNAS EXTRAS:", report.extra, report.implemented_positions)
    print_duplicates("DUPLICADAS NA ESPECIFICACAO:", report.duplicates_expected)
    print_duplicates("DUPLICADAS NA IMPLEMENTACAO:", report.duplicates_implemented)
    print_order_mismatches(report.order_mismatches)

    if report.missing_count == 0 and report.extra_count == 0 and report.order_matches:
        print("STATUS FINAL: OK")
    else:
        print("STATUS FINAL: ATENCAO")


if __name__ == "__main__":
    main()