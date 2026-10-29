import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/evaluation_details_widget.dart';
import '../../widgets/evolution_charts.dart';
import '../../widgets/export_data_card.dart';
import '../../widgets/ios_action_sheet.dart';
import '../../widgets/photo_comparison.dart';
import '../../widgets/quick_weight_dialog.dart';
import '../../widgets/weekly_weight_tracker.dart';
import '../evaluation_comparator_screen.dart';
import '../evaluation_form_screen.dart';
import 'progress_overview_section.dart';

class PersonalProgressTab extends StatefulWidget {
  final AppState appState;

  const PersonalProgressTab({super.key, required this.appState});

  @override
  State<PersonalProgressTab> createState() => _PersonalProgressTabState();
}

class _PersonalProgressTabState extends State<PersonalProgressTab> {
  String? _selectedAvaliacaoId;
  int _selectedSegment = 0; // 0: Resumo, 1: Pesagens, 2: Evolução, 3: Ficha

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

    final now = DateTime.now();
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);

    return CustomScrollView(
      slivers: [
        // App Bar com Large Title estilo iOS HIG
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
                      dateStr.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Meu Progresso',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Controle Deslizante Segmentado Nativo iOS
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<int>(
                        groupValue: _selectedSegment,
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        thumbColor: isDark
                            ? AppColors.indigoPrimary
                            : Colors.white,
                        padding: const EdgeInsets.all(4),
                        children: {
                          0: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            child: Text(
                              'Resumo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedSegment == 0
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          1: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            child: Text(
                              'Pesagens',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedSegment == 1
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          2: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            child: Text(
                              'Evolução',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedSegment == 2
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          3: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            child: Text(
                              'Ficha',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedSegment == 3
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSegment = val);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Conteúdo Dinâmico por Segmento
                    _buildActiveTabContent(
                      context,
                      isDark: isDark,
                      profile: profile,
                      evaluations: evaluations,
                      effectiveSelectedId: effectiveSelectedId,
                      selectedJoined: selectedJoined,
                      previousAvaliacao: previousAvaliacao,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context, {
    required bool isDark,
    required UserProfile profile,
    required List<JoinedEvaluation> evaluations,
    required String? effectiveSelectedId,
    required JoinedEvaluation? selectedJoined,
    required Avaliacao? previousAvaliacao,
  }) {
    switch (_selectedSegment) {
      case 0:
        // 1. Aba Resumo (Destaques Apple Health style)
        if (evaluations.isEmpty) {
          return _buildEmptyState(context, isDark, profile);
        }
        return ProgressOverviewSection(
          appState: widget.appState,
          profile: profile,
          evaluations: evaluations,
          onQuickWeight: () => QuickWeightDialog.show(
            context,
            appState: widget.appState,
          ),
          onNewEvaluation: () => _openNewEvaluation(context),
          onOpenComparator: () => _openComparator(context),
          onNavigateToTab: (tabIdx) =>
              setState(() => _selectedSegment = tabIdx),
        );

      case 1:
        // 2. Aba Pesagens & Hábito Diário
        return WeeklyWeightTracker(appState: widget.appState);

      case 2:
        // 3. Aba Evolução (Gráficos Longitudinais & Fotos)
        if (evaluations.isEmpty) {
          return _buildEmptyState(context, isDark, profile);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (evaluations.length >= 2) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'CURVAS HISTÓRICAS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    key: const ValueKey('btn_open_comparator_header'),
                    onPressed: () => _openComparator(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.indigoPrimary,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.compare_arrows_rounded, size: 17),
                    label: const Text(
                      'Comparar 2 Marcos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            EvolutionCharts(
              evaluations: evaluations,
              pesagens: widget.appState.pesagens,
            ),
            const SizedBox(height: 20),
            PhotoComparison(
              appState: widget.appState,
              selectedAvaliacaoId: effectiveSelectedId,
            ),
          ],
        );

      case 3:
      default:
        // 4. Aba Ficha Completa de Medidas & Nutrição
        if (evaluations.isEmpty) {
          return _buildEmptyState(context, isDark, profile);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'DATA DA AVALIAÇÃO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (selectedJoined != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openEditEvaluation(
                          context,
                          selectedJoined.avaliacao,
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: AppColors.indigoPrimary,
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(
                            color: AppColors.indigoPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _confirmDeleteEvaluation(
                          context,
                          selectedJoined.avaliacao.id,
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Excluir',
                          style: TextStyle(
                            color: AppColors.rose,
                            fontSize: 13,
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
                    final isSelected = ev.avaliacao.id == effectiveSelectedId;
                    final label = idx == 0
                        ? 'Mais Recente'
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
                            _selectedAvaliacaoId = ev.avaliacao.id;
                          });
                        },
                        selectedColor: isDark
                            ? AppColors.indigoPrimary
                            : const Color(0xFF0F172A),
                        backgroundColor:
                            isDark ? AppColors.darkSurface : Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF475569)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
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
              const SizedBox(height: 20),
            ],

            ExportDataCard(
              profile: profile,
              evaluations: evaluations,
              selectedEvaluation: selectedJoined,
            ),
          ],
        );
    }
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    UserProfile profile,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.indigoPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.straighten_rounded,
              size: 28,
              color: AppColors.indigoPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Comece seu acompanhamento!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Registre sua primeira avaliação física para visualizar sua composição corporal, gráficos e fotos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _openNewEvaluation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigoPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(190, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Nova Avaliação',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
