import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_lock_gate.dart';
import '../widgets/body_recomposition_insight.dart';
import '../widgets/data_backup_manager.dart';
import '../widgets/evaluation_details_widget.dart';
import '../widgets/evolution_charts.dart';
import '../widgets/export_data_card.dart';
import '../widgets/ios_action_sheet.dart';
import '../widgets/latest_evaluation_card.dart';
import '../widgets/legal_disclaimer_modal.dart';
import '../widgets/photo_comparison.dart';
import '../widgets/quick_weight_dialog.dart';
import '../widgets/weekly_weight_tracker.dart';
import 'evaluation_comparator_screen.dart';
import 'evaluation_form_screen.dart';
import 'onboarding_screen.dart';
import 'profile_setup_screen.dart';

class MainShell extends StatefulWidget {
  final AppState appState;

  const MainShell({
    super.key,
    required this.appState,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDisclaimer();
    });
  }

  void _checkDisclaimer() {
    if (!mounted) return;
    LegalDisclaimerModal.showIfNeeded(
      context,
      alreadyAccepted: widget.appState.disclaimerAccepted,
      onAccept: () => widget.appState.acceptDisclaimer(),
    );
  }

  void _openQuickWeightDialog(BuildContext context) {
    QuickWeightDialog.show(context, appState: widget.appState);
  }

  void _openNewEvaluation(BuildContext context) {
    Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => EvaluationFormScreen(appState: widget.appState),
      ),
    );
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

  void _showQuickActionSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'AÇÕES RÁPIDAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                  ),
                  ListTile(
                    key: const ValueKey('action_quick_weight'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openQuickWeightDialog(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.indigoPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.indigoPrimary,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      '⚡ Registrar Peso de Hoje',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'Salva pesagem matinal em 2 segundos com micro-feedback',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    key: const ValueKey('action_full_evaluation'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openNewEvaluation(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.straighten_rounded,
                        color: AppColors.emerald,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      '📋 Nova Avaliação Completa',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'Medidas com fita métrica, fotos e composição corporal',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ),
                  if (widget.appState.avaliacoes.length >= 2) ...[
                    const Divider(height: 16),
                    ListTile(
                      key: const ValueKey('action_open_comparator'),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openComparator(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: AppColors.orange,
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        '⚖️ Comparar Avaliações',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        'Comparador lado a lado com métricas, fotos e metas',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppLockGate(
      appState: widget.appState,
      child: Scaffold(
        extendBody: true,
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                key: const ValueKey('fab_quick_actions'),
                onPressed: () => _showQuickActionSheet(context),
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Registrar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              )
            : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _PersonalProgressPlaceholder(appState: widget.appState),
            _SettingsTab(appState: widget.appState),
          ],
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 83,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BottomNavItem(
                          icon: Icons.insights_rounded,
                          label: 'Meu Progresso',
                          isSelected: _selectedIndex == 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = 0);
                          },
                        ),
                        _BottomNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings_rounded,
                          label: 'Ajustes',
                          isSelected: _selectedIndex == 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = 1);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? AppColors.indigoLight : AppColors.indigoPrimary)
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              size: 25,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DashboardSection {
  tudo('Tudo', Icons.dashboard_customize_outlined),
  resumo('Resumo & Peso', Icons.monitor_weight_outlined),
  evolucao('Gráficos & Fotos', Icons.show_chart_rounded),
  ficha('Ficha Detalhada', Icons.assignment_outlined);

  final String label;
  final IconData icon;
  const _DashboardSection(this.label, this.icon);
}

class _PersonalProgressPlaceholder extends StatefulWidget {
  final AppState appState;

  const _PersonalProgressPlaceholder({required this.appState});

  @override
  State<_PersonalProgressPlaceholder> createState() =>
      _PersonalProgressPlaceholderState();
}

class _PersonalProgressPlaceholderState
    extends State<_PersonalProgressPlaceholder> {
  String? _selectedAvaliacaoId;
  _DashboardSection _activeSection = _DashboardSection.tudo;

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

    final showResumo = _activeSection == _DashboardSection.tudo ||
        _activeSection == _DashboardSection.resumo;
    final showEvolucao = _activeSection == _DashboardSection.tudo ||
        _activeSection == _DashboardSection.evolucao;
    final showFicha = _activeSection == _DashboardSection.tudo ||
        _activeSection == _DashboardSection.ficha;

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
                              children: _DashboardSection.values.map((section) {
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

class _SettingsTab extends StatelessWidget {
  final AppState appState;

  const _SettingsTab({required this.appState});

  @override
  Widget build(BuildContext context) {
    final profile = appState.userProfile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark
              ? AppColors.darkBackground.withValues(alpha: 0.9)
              : AppColors.lightBackground.withValues(alpha: 0.9),
          centerTitle: false,
          title: Text(
            'Ajustes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.6,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  appState.toggleTheme();
                },
                tooltip: isDark ? 'Ativar Modo Claro' : 'Ativar Modo Escuro',
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                ),
                icon: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Meu Perfil Pessoal
                    if (profile != null)
                      Material(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.indigoLight,
                                          AppColors.indigoPrimary,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      profile.nome[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.nome,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${profile.sexo.label} • ${profile.idade} anos • ${profile.alturaCm.toStringAsFixed(0)} cm',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => ProfileSetupScreen(
                                      initialProfile: profile,
                                      onSave: (updated) {
                                        appState.saveUserProfile(updated);
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Perfil e histórico recalculados com sucesso!',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              leading: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.indigoPrimary,
                                size: 20,
                              ),
                              title: const Text(
                                'Editar Meus Dados Pessoais',
                                style: TextStyle(
                                  color: AppColors.indigoPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => OnboardingScreen(
                                      onFinish: () => Navigator.of(ctx).pop(),
                                    ),
                                  ),
                                );
                              },
                              leading: const Icon(
                                Icons.auto_awesome_outlined,
                                color: AppColors.indigoPrimary,
                                size: 20,
                              ),
                              title: const Text(
                                'Rever Introdução do App',
                                style: TextStyle(
                                  color: AppColors.indigoPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Card de Privacidade e Segurança (Fase 4)
                    Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Privacidade e Segurança',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          ListTile(
                            onTap: () => AppLockGate.showConfigurePinDialog(
                              context,
                              appState,
                            ),
                            leading: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.indigoPrimary,
                              size: 20,
                            ),
                            title: const Text(
                              'Bloqueio por PIN (4 Dígitos)',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              appState.hasPinLock
                                  ? 'Ativado • Protege o app ao abrir e no multitarefas'
                                  : 'Desativado • Toque para configurar uma senha',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const Divider(indent: 16, height: 1),
                          SwitchListTile.adaptive(
                            value: appState.discreetPhotos,
                            onChanged: (_) {
                              HapticFeedback.selectionClick();
                              appState.toggleDiscreetPhotos();
                            },
                            activeTrackColor: AppColors.indigoPrimary,
                            secondary: const Icon(
                              Icons.visibility_off_outlined,
                              color: AppColors.indigoPrimary,
                              size: 20,
                            ),
                            title: const Text(
                              'Modo Discreto nas Fotos',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'Desfoca as fotos de evolução até você tocar para revelar',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gerenciador de Backup de Dados (JSON)
                    DataBackupManager(appState: appState),

                    const SizedBox(height: 20),

                    // Sair da Conta / Resetar Todos os Dados
                    Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gerenciamento da Conta Local',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ao apenas sair, suas avaliações e pesagens permanecem salvas no aparelho. Se desejar zerar o aplicativo por completo, use a opção Apagar Todos os Dados.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              IosActionSheet.show(
                                context: context,
                                title: 'Sair do Aplicativo',
                                description:
                                    'Deseja realmente sair do seu perfil atual? Suas avaliações continuarão salvas.',
                                confirmText: 'Sair do Aplicativo',
                                onConfirm: () => appState.logout(),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                    color: AppColors.rose,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sair do Aplicativo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              IosActionSheet.show(
                                context: context,
                                title: 'Apagar Todos os Dados',
                                description:
                                    'ATENÇÃO: Esta ação apagará permanentemente seu perfil, todas as suas avaliações, fotos e pesagens deste aparelho. Exporte um backup antes se desejar guardá-los.',
                                confirmText: 'Apagar Tudo Permanentemente',
                                onConfirm: () => appState.resetAllData(),
                              );
                            },
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_forever_rounded,
                                    size: 20,
                                    color: AppColors.rose,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Apagar Todos os Dados (Reset)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.rose,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
