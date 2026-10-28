import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_lock_gate.dart';
import '../widgets/legal_disclaimer_modal.dart';
import '../widgets/quick_weight_dialog.dart';
import 'evaluation_comparator_screen.dart';
import 'evaluation_form_screen.dart';
import 'main_shell/bottom_nav_item.dart';
import 'main_shell/personal_progress_tab.dart';
import 'main_shell/settings_tab.dart';

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
            PersonalProgressTab(appState: widget.appState),
            SettingsTab(appState: widget.appState),
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
                        BottomNavItem(
                          icon: Icons.insights_rounded,
                          label: 'Meu Progresso',
                          isSelected: _selectedIndex == 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = 0);
                          },
                        ),
                        BottomNavItem(
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



