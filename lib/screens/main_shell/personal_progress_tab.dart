import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/body_recomposition_insight.dart';
import '../../widgets/evaluation_details_widget.dart';
import '../../widgets/evolution_charts.dart';
import '../../widgets/export_data_card.dart';
import '../../widgets/ios_action_sheet.dart';
import '../../widgets/latest_evaluation_card.dart';
import '../../widgets/photo_comparison.dart';
import '../../widgets/weekly_weight_tracker.dart';
import '../evaluation_comparator_screen.dart';
import '../evaluation_form_screen.dart';

enum DashboardSection {
  tudo('Tudo', Icons.dashboard_customize_outlined),
  resumo('Resumo & Peso', Icons.monitor_weight_outlined),
  evolucao('Gráficos & Fotos', Icons.show_chart_rounded),
  ficha('Ficha Detalhada', Icons.assignment_outlined);

  final String label;
  final IconData icon;
  const DashboardSection(this.label, this.icon);
}

class PersonalProgressTab extends StatefulWidget {
  final AppState appState;

  const PersonalProgressTab({super.key, required this.appState});

  @override
  State<PersonalProgressTab> createState() => _PersonalProgressTabState();
}

class _PersonalProgressTabState extends State<PersonalProgressTab> {
  String? _selectedAvaliacaoId;
  DashboardSection _activeSection = DashboardSection.tudo;

  Future<void> _openNewEvaluation(BuildContext context) async {
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => EvaluationFormScreen(appState: widget.appState),
      ),
    );
    if (createdId != null && mounted) {
      setState(() => _selectedAvaliacaoId = createdId);
    }
  }

  void _openComparator(
    BuildContext context, {
    String? baseId,
    String? compareId,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => EvaluationComparatorScreen(
          appState: widget.appState,
          initialBaseId: baseId,
          initialCompareId: compareId,
        ),
      ),
    );
  }

  Future<void> _openEditEvaluation(
    BuildContext context,
    Avaliacao avaliacao,
  ) async {
    final updatedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => EvaluationFormScreen(
          appState: widget.appState,
          initialAvaliacao: avaliacao,
        ),
      ),
    );
    if (updatedId != null && mounted) {
      setState(() => _selectedAvaliacaoId = updatedId);
    }
  }

  void _confirmDeleteEvaluation(BuildContext context, String evalId) {
    IosActionSheet.show(
      context: context,
      title: 'Excluir Avaliação',
      description:
          'Esta ação é irreversível e os dados desta avaliação serão permanentemente apagados.',
      confirmText: 'Excluir Avaliação',
      onConfirm: () async {
        await widget.appState.deleteAvaliacao(evalId);
        if (!mounted) return;
        setState(() {
          if (_selectedAvaliacaoId == evalId) {
            _selectedAvaliacaoId = null;
          }
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avaliação excluída')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.appState.userProfile;
    if (profile == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final evaluations = widget.appState.joinedEvaluations;

    final effectiveSelectedId = (evaluations.isNotEmpty &&
            (_selectedAvaliacaoId == null ||
                !evaluations
                    .any((e) => e.avaliacao.id == _selectedAvaliacaoId)))
        ? evaluations.first.avaliacao.id
        : _selectedAvaliacaoId;

    JoinedEvaluation? selectedJoined;
    int selectedIdx = 0;
    for (int i = 0; i < evaluations.length; i++) {
      if (evaluations[i].avaliacao.id == effectiveSelectedId) {
        selectedJoined = evaluations[i];
        selectedIdx = i;
        break;
      }
    }
    selectedJoined ??= evaluations.isNotEmpty ? evaluations.first : null;
    final Avaliacao? previousAvaliacao =
        (selectedJoined != null && selectedIdx + 1 < evaluations.length)
            ? evaluations[selectedIdx + 1].avaliacao
            : null;

    final showResumo = _activeSection == DashboardSection.tudo ||
        _activeSection == DashboardSection.resumo;
    final showEvolucao = _activeSection == DashboardSection.tudo ||
        _activeSection == DashboardSection.evolucao;
    final showFicha = _activeSection == DashboardSection.tudo ||
        _activeSection == DashboardSection.ficha;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          toolbarHeight: 74,
          backgroundColor: isDark
              ? AppColors.darkBackground.withValues(alpha: 0.92)
              : AppColors.lightBackground.withValues(alpha: 0.92),
          centerTitle: false,
          titleSpacing: 20,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEU PAINEL CORPORAL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Olá, ${profile.primeiroNome} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  '${profile.sexo.shortLabel} • ${profile.idade}a • ${profile.alturaCm.toStringAsFixed(0)}cm',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: evaluations.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.indigoPrimary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                size: 32,
                                color: AppColors.indigoPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'O ponto de partida! 🚀',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Registre sua primeira autoavaliação, ${profile.primeiroNome}, e dê o primeiro passo para acompanhar seus resultados!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.45,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _openNewEvaluation(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indigoPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(200, 48),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 22),
                              label: const Text(
                                'Nova Avaliação',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Visão Geral + Botão Pílula Nova Avaliação
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Visão Geral',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (evaluations.length >= 2)
                                    OutlinedButton.icon(
                                      key: const ValueKey(
                                          'btn_open_comparator_header'),
                                      onPressed: () => _openComparator(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.indigoPrimary,
                                        side: const BorderSide(
                                          color: AppColors.indigoPrimary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.compare_arrows_rounded,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        'Comparar',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ElevatedButton.icon(
                                    onPressed: () => _openNewEvaluation(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.indigoPrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text(
                                      'Nova Avaliação',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Barra de Filtro Rápido por Seção
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: DashboardSection.values.map((section) {
                                final active = _activeSection == section;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    avatar: Icon(
                                      section.icon,
                                      size: 16,
                                      color: active
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : const Color(0xFF475569)),
                                    ),
                                    label: Text(section.label),
                                    selected: active,
                                    showCheckmark: false,
                                    onSelected: (_) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _activeSection = section);
                                    },
                                    selectedColor: AppColors.indigoPrimary,
                                    backgroundColor: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    labelStyle: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : const Color(0xFF475569)),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      side: BorderSide(
                                        color: active
                                            ? Colors.transparent
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (showResumo) ...[
                            // 1. Card Resumo da Última Avaliação + Meta Pessoal
                            LatestEvaluationCard(
                              evaluations: evaluations,
                              profile: profile,
                              onUpdateProfile: (u) =>
                                  widget.appState.saveUserProfile(u),
                            ),
                            const SizedBox(height: 18),

                            // 2. Rastreador de Pesagens Diárias & Média Semanal
                            WeeklyWeightTracker(appState: widget.appState),
                            const SizedBox(height: 18),

                            // 3. Card Inteligente de Recomposição Corporal (quando houver >= 2 avaliações)
                            if (evaluations.length >= 2) ...[
                              BodyRecompositionInsight(
                                evaluations: evaluations,
                                onOpenComparator: () =>
                                    _openComparator(context),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ],

                          if (showEvolucao) ...[
                            // 4. Gráficos de Evolução (Peso/Massa Magra e BF%)
                            EvolutionCharts(evaluations: evaluations),
                            const SizedBox(height: 18),

                            // 5. Comparativo Fotográfico (Antes/Depois com Slider e Zoom)
                            PhotoComparison(
                              appState: widget.appState,
                              selectedAvaliacaoId: effectiveSelectedId,
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (showFicha) ...[
                            // 6. Seletor e Detalhes por Avaliação
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Detalhes por Avaliação',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                if (selectedJoined != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _openEditEvaluation(
                                          context,
                                          selectedJoined!.avaliacao,
                                        ),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: AppColors.indigoPrimary,
                                        ),
                                        label: const Text(
                                          'Editar',
                                          style: TextStyle(
                                            color: AppColors.indigoPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _confirmDeleteEvaluation(
                                          context,
                                          selectedJoined!.avaliacao.id,
                                        ),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text(
                                          'Excluir Atual',
                                          style: TextStyle(
                                            color: AppColors.rose,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Pílulas de Seleção de Avaliação
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  evaluations.length,
                                  (idx) {
                                    final ev = evaluations[idx];
                                    final isSelected =
                                        ev.avaliacao.id == effectiveSelectedId;
                                    final label = idx == 0
                                        ? 'Última (Atual)'
                                        : DateFormat('dd/MM/yyyy')
                                            .format(ev.avaliacao.dataAvaliacao);

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        showCheckmark: false,
                                        onSelected: (_) {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _selectedAvaliacaoId =
                                                ev.avaliacao.id;
                                          });
                                        },
                                        selectedColor: isDark
                                            ? AppColors.indigoPrimary
                                            : const Color(0xFF0F172A),
                                        backgroundColor: isDark
                                            ? AppColors.darkSurface
                                            : Colors.white,
                                        labelStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.darkTextSecondary
                                                  : const Color(0xFF475569)),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.transparent
                                                : (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (selectedJoined != null) ...[
                              EvaluationDetailsWidget(
                                profile: profile,
                                avaliacao: selectedJoined.avaliacao,
                                resultado: selectedJoined.resultado,
                                previousAvaliacao: previousAvaliacao,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 7. Área de Exportação (PDF e CSV)
                            ExportDataCard(
                              profile: profile,
                              evaluations: evaluations,
                              selectedEvaluation: selectedJoined,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
