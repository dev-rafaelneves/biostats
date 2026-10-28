import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class ProgressOverviewSection extends StatelessWidget {
  final AppState appState;
  final UserProfile profile;
  final List<JoinedEvaluation> evaluations;
  final VoidCallback onQuickWeight;
  final VoidCallback onNewEvaluation;
  final VoidCallback onOpenComparator;
  final void Function(int tabIndex) onNavigateToTab;

  const ProgressOverviewSection({
    super.key,
    required this.appState,
    required this.profile,
    required this.evaluations,
    required this.onQuickWeight,
    required this.onNewEvaluation,
    required this.onOpenComparator,
    required this.onNavigateToTab,
  });

  int _computeStreak(List<Pesagem> pesagens) {
    if (pesagens.isEmpty) return 0;
    final dates = pesagens
        .map((p) => DateTime(p.data.year, p.data.month, p.data.day))
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor = dates.contains(today)
        ? today
        : (dates.contains(yesterday) ? yesterday : today);

    if (!dates.contains(cursor)) return 0;

    int streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latest = evaluations.firstOrNull;
    final previous = evaluations.length >= 2 ? evaluations[1] : null;

    final snapshot = latest?.resultado?.snapshot;
    final currentWeight = latest?.avaliacao.pesoKg ?? 0.0;
    final currentBf = snapshot?.bfPrincipal ?? 0.0;
    final currentLbm = snapshot?.lbmFinal ?? 0.0;
    final targetKcal = snapshot?.macros.targetCalories ?? 0.0;

    // Streak & Pesagens
    final pesagens = appState.pesagens;
    final streak = _computeStreak(pesagens);

    // Variação em relação à avaliação anterior
    double? deltaPeso;
    double? deltaBf;
    double? deltaLbm;
    double? deltaFat;

    if (previous != null && latest != null) {
      final prevSnap = previous.resultado?.snapshot;
      final prevWeight = previous.avaliacao.pesoKg;
      final prevBf = prevSnap?.bfPrincipal ?? 0.0;
      final prevLbm = prevSnap?.lbmFinal ?? 0.0;

      deltaPeso = currentWeight - prevWeight;
      if (currentBf > 0 && prevBf > 0) {
        deltaBf = currentBf - prevBf;
        final currentFatKg = currentWeight * (currentBf / 100.0);
        final prevFatKg = prevWeight * (prevBf / 100.0);
        deltaFat = currentFatKg - prevFatKg;
      }
      if (currentLbm > 0 && prevLbm > 0) {
        deltaLbm = currentLbm - prevLbm;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (evaluations.length >= 2) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                key: const ValueKey('btn_open_comparator_header'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onOpenComparator();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.indigoPrimary,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
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
          const SizedBox(height: 4),
        ],

        // 1. Hero Metric Card (Apple Health style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Label + Data da avaliação + Streak Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigoPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latest != null
                              ? DateFormat('dd MMM yyyy', 'pt_BR')
                                  .format(latest.avaliacao.dataAvaliacao)
                              : 'Sem avaliações',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigoPrimary,
                          ),
                        ),
                      ),
                      if (snapshot != null && snapshot.metodoPrincipal != 'none') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            snapshot.metodoPrincipalLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      streak > 0 ? '🔥 $streak dia${streak > 1 ? 's' : ''}' : '0 dias',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Peso grande em destaque
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currentWeight > 0 ? currentWeight.toStringAsFixed(1) : '--',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  if (deltaPeso != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (deltaPeso == 0)
                            ? Colors.grey.withValues(alpha: 0.12)
                            : (deltaPeso < 0
                                ? AppColors.emerald.withValues(alpha: 0.12)
                                : AppColors.rose.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            deltaPeso < 0
                                ? Icons.arrow_downward_rounded
                                : (deltaPeso > 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.remove_rounded),
                            size: 13,
                            color: deltaPeso < 0
                                ? AppColors.emerald
                                : (deltaPeso > 0
                                    ? AppColors.rose
                                    : Colors.grey),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${deltaPeso.abs().toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: deltaPeso < 0
                                  ? AppColors.emerald
                                  : (deltaPeso > 0
                                      ? AppColors.rose
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Grade 2x2 Clean: Gordura, Massa Magra, Meta e Calorias
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'GORDURA (%BF)',
                      value: currentBf > 0
                          ? '${currentBf.toStringAsFixed(1)}%'
                          : '--',
                      delta: deltaBf != null
                          ? '${deltaBf >= 0 ? '+' : ''}${deltaBf.toStringAsFixed(1)}%'
                          : null,
                      deltaColor: deltaBf != null
                          ? (deltaBf <= 0 ? AppColors.emerald : AppColors.rose)
                          : null,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'MASSA MAGRA',
                      value: currentLbm > 0
                          ? '${currentLbm.toStringAsFixed(1)} kg'
                          : '--',
                      delta: deltaLbm != null
                          ? '${deltaLbm >= 0 ? '+' : ''}${deltaLbm.toStringAsFixed(1)} kg'
                          : null,
                      deltaColor: deltaLbm != null
                          ? (deltaLbm >= 0 ? AppColors.emerald : AppColors.rose)
                          : null,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'META DE PESO',
                      value: profile.metaPesoKg != null
                          ? '${profile.metaPesoKg!.toStringAsFixed(1)} kg'
                          : 'Sem meta',
                      sublabel: profile.metaPesoKg != null && currentWeight > 0
                          ? '${(currentWeight - profile.metaPesoKg!).abs().toStringAsFixed(1)} kg restante'
                          : null,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'META CALÓRICA',
                      value: targetKcal > 0
                          ? '${targetKcal.toStringAsFixed(0)} kcal'
                          : '--',
                      sublabel: snapshot?.macros.macros != null
                          ? 'P:${snapshot!.macros.grams.protein}g C:${snapshot.macros.grams.carbs}g G:${snapshot.macros.grams.fat}g'
                          : null,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Dupla de Ações Rápidas (Pílulas iOS)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const ValueKey('btn_quick_weight_home'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onQuickWeight();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigoPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 20),
                label: const Text(
                  'Pesar Hoje',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('btn_new_eval_home'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onNewEvaluation();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.indigoPrimary,
                  side: const BorderSide(
                    color: AppColors.indigoPrimary,
                    width: 1.4,
                  ),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
            ),
          ],
        ),

        // 3. Card Inteligente de Recomposição Corporal (quando houver >= 2 avaliações)
        if (deltaFat != null && deltaLbm != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (deltaFat < 0 && deltaLbm > 0)
                        ? AppColors.emerald.withValues(alpha: 0.12)
                        : AppColors.indigoPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (deltaFat < 0 && deltaLbm > 0)
                        ? Icons.auto_awesome_rounded
                        : Icons.insights_rounded,
                    color: (deltaFat < 0 && deltaLbm > 0)
                        ? AppColors.emerald
                        : AppColors.indigoPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (deltaFat < 0 && deltaLbm > 0)
                            ? 'Recomposição Corporal Perfeita!'
                            : 'Evolução da Composição',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gordura: ${deltaFat >= 0 ? "+" : ""}${deltaFat.toStringAsFixed(1)}kg  •  Músculo: ${deltaLbm >= 0 ? "+" : ""}${deltaLbm.toStringAsFixed(1)}kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // 4. Lista Agrupada iOS (Inset Grouped Style) para Navegação
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'SEÇÕES DO SEU PROGRESSO',
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

        Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _NavListTile(
                icon: Icons.monitor_weight_outlined,
                iconColor: AppColors.indigoPrimary,
                title: 'Pesagens Diárias & Tendência',
                subtitle: 'Gráfico suavizado EMA, meta e heatmap',
                onTap: () => onNavigateToTab(1),
                isDark: isDark,
              ),
              const Divider(indent: 56, height: 1),
              _NavListTile(
                icon: Icons.show_chart_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Gráficos & Fotos Lado a Lado',
                subtitle: 'Evolução longitudinal e slider antes/depois',
                onTap: () => onNavigateToTab(2),
                isDark: isDark,
              ),
              const Divider(indent: 56, height: 1),
              _NavListTile(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.emerald,
                title: 'Ficha Completa de Medidas',
                subtitle: 'Circunferências, dobras cutâneas e macros',
                onTap: () => onNavigateToTab(3),
                isDark: isDark,
              ),
              if (evaluations.length >= 2) ...[
                const Divider(indent: 56, height: 1),
                _NavListTile(
                  icon: Icons.compare_arrows_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Comparador de Avaliações',
                  subtitle: 'Compare quaisquer 2 marcos lado a lado',
                  onTap: onOpenComparator,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final String? delta;
  final Color? deltaColor;
  final bool isDark;

  const _MetricTile({
    required this.label,
    required this.value,
    this.sublabel,
    this.delta,
    this.deltaColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 6),
                Text(
                  delta!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: deltaColor ?? AppColors.emerald,
                  ),
                ),
              ],
            ],
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel!,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _NavListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
