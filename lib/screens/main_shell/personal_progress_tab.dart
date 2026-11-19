import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_insight_card.dart';
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
  final ValueChanged<int>? onSegmentChanged;
  final VoidCallback? onNavigateToSettings;

  const PersonalProgressTab({
    super.key,
    required this.appState,
    this.onSegmentChanged,
    this.onNavigateToSettings,
  });

  @override
  State<PersonalProgressTab> createState() => _PersonalProgressTabState();
}

class _PersonalProgressTabState extends State<PersonalProgressTab> {
  String? _selectedAvaliacaoId;
  int _selectedSegment = 0; // 0: Resumo, 1: Pesagens, 2: Evolução, 3: Ficha

  void _selectSegment(int tabIdx) {
    setState(() => _selectedSegment = tabIdx);
    widget.onSegmentChanged?.call(tabIdx);
  }

  Future<void> _showEditGoalSheet(
    BuildContext context,
    UserProfile profile,
  ) async {
    HapticFeedback.selectionClick();
    final pesoCtrl = TextEditingController(
      text: profile.metaPesoKg != null
          ? profile.metaPesoKg!.toStringAsFixed(1)
          : '',
    );
    final bfCtrl = TextEditingController(
      text: profile.metaBfPct != null
          ? profile.metaBfPct!.toStringAsFixed(1)
          : '',
    );

    double? parseVal(TextEditingController c) {
      final raw = c.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) return null;
      final v = double.tryParse(raw);
      return (v != null && v > 0) ? v : null;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.bioColors;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Definir Metas Corporais',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Opcional: acompanhe quanto falta e a previsão de chegada nos gráficos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pesoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Meta de Peso (kg)',
                      hintText: 'Ex: 78.0',
                      filled: true,
                      fillColor: colors.surfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bfCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Meta de Gordura (%BF)',
                      hintText: 'Ex: 15.0',
                      filled: true,
                      fillColor: colors.surfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final updated = UserProfile(
                          id: profile.id,
                          nome: profile.nome,
                          dataNascimento: profile.dataNascimento,
                          sexo: profile.sexo,
                          alturaCm: profile.alturaCm,
                          metaPesoKg: parseVal(pesoCtrl),
                          metaBfPct: parseVal(bfCtrl),
                          criadoEm: profile.criadoEm,
                        );
                        await widget.appState.saveUserProfile(updated);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Metas atualizadas com sucesso!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigoPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Salvar Metas',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    pesoCtrl.dispose();
    bfCtrl.dispose();
  }

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

    final colors = context.bioColors;
    final now = DateTime.now();
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);

    return CustomScrollView(
      slivers: [
        // App Bar com Large Title estilo iOS HIG (centralizado até 460px no Desktop/Web)
        SliverAppBar(
          pinned: true,
          toolbarHeight: 74,
          backgroundColor: colors.background.withValues(alpha: 0.92),
          centerTitle: false,
          titleSpacing: 16,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Row(
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
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: colors.textMuted,
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
                            color: colors.textPrimary,
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
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '${profile.sexo.shortLabel} • ${profile.idade}a • ${profile.alturaCm.toStringAsFixed(0)}cm',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                          0: _buildSegmentLabel('Resumo', 0, context),
                          1: _buildSegmentLabel('Pesagens', 1, context),
                          2: _buildSegmentLabel('Evolução', 2, context),
                          3: _buildSegmentLabel('Ficha', 3, context),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            _selectSegment(val);
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

  Widget _buildSegmentLabel(String label, int index, BuildContext context) {
    final colors = context.bioColors;
    final isDark = context.isDarkMode;
    final selected = _selectedSegment == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : colors.textSecondary,
          ),
        ),
      ),
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
    final colors = context.bioColors;

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
          onNavigateToTab: _selectSegment,
          onEditGoal: () => _showEditGoalSheet(context, profile),
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    key: const ValueKey('btn_open_comparator_header'),
                    onPressed: () => _openComparator(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.accent,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.compare_arrows_rounded, size: 17),
                    label: const Text(
                      'Comparar Avaliações',
                      style: TextStyle(
                        fontSize: 13.5,
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colors.textMuted,
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
                          foregroundColor: colors.accent,
                          minimumSize: const Size(0, 44),
                        ),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: colors.accent,
                        ),
                        label: Text(
                          'Editar',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 13.5,
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
                          foregroundColor: colors.dangerText,
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(
                          'Excluir',
                          style: TextStyle(
                            color: colors.dangerText,
                            fontSize: 13.5,
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
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedAvaliacaoId = ev.avaliacao.id;
                          });
                        },
                        selectedColor: isDark
                            ? AppColors.indigoPrimary
                            : const Color(0xFF0F172A),
                        backgroundColor: colors.surface,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : colors.border,
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
              if (selectedJoined.resultado != null) ...[
                AiInsightCard.evaluation(
                  key: ValueKey(
                    'ai_eval_${selectedJoined.avaliacao.id}_${selectedJoined.resultado?.snapshot.metodoPrincipal}',
                  ),
                  appState: widget.appState,
                  profile: profile,
                  avaliacao: selectedJoined.avaliacao,
                  resultado: selectedJoined.resultado,
                  onOpenSettings: widget.onNavigateToSettings,
                ),
                const SizedBox(height: 18),
              ],
              EvaluationDetailsWidget(
                profile: profile,
                avaliacao: selectedJoined.avaliacao,
                resultado: selectedJoined.resultado,
                previousAvaliacao: previousAvaliacao,
                onSelectBfMethod: (method) {
                  widget.appState.setPreferredBfMethod(
                    selectedJoined.avaliacao.id,
                    method,
                  );
                },
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
