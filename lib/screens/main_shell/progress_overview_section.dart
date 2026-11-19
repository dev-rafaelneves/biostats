import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculator.dart';

class ProgressOverviewSection extends StatelessWidget {
  final AppState appState;
  final UserProfile profile;
  final List<JoinedEvaluation> evaluations;
  final VoidCallback onQuickWeight;
  final VoidCallback onNewEvaluation;
  final VoidCallback onOpenComparator;
  final void Function(int tabIndex) onNavigateToTab;
  final VoidCallback? onEditGoal;

  const ProgressOverviewSection({
    super.key,
    required this.appState,
    required this.profile,
    required this.evaluations,
    required this.onQuickWeight,
    required this.onNewEvaluation,
    required this.onOpenComparator,
    required this.onNavigateToTab,
    this.onEditGoal,
  });

  /// Indica se a variação de peso é favorável segundo o objetivo declarado.
  /// Retorna `null` para variação nula, manutenção ou objetivo ausente.
  @visibleForTesting
  static bool? isWeightDeltaFavorable(double delta, Objetivo? objetivo) {
    if (delta == 0 || objetivo == null || objetivo == Objetivo.manutencao) {
      return null;
    }
    return objetivo == Objetivo.hipertrofia ? delta > 0 : delta < 0;
  }

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
    final isDark = context.isDarkMode;
    final colors = context.bioColors;
    final latest = evaluations.firstOrNull;
    final previous = evaluations.length >= 2 ? evaluations[1] : null;

    final snapshot = latest?.resultado?.snapshot;
    final weightContext = appState.currentWeightContext;
    final liveMeta = appState.liveMetabolism;

    final currentWeight = weightContext.hasData
        ? weightContext.currentWeight
        : (latest?.avaliacao.pesoKg ?? 0.0);
    final currentBf = liveMeta?.bfPctUsed ?? (snapshot?.bfPrincipal ?? 0.0);
    final currentLbm = liveMeta?.lbmKg ?? (snapshot?.lbmFinal ?? 0.0);
    final currentFatKg = liveMeta?.fatKg ??
        (currentWeight > 0 && currentBf > 0
            ? BioCalculator.round2(currentWeight * (currentBf / 100.0))
            : 0.0);
    final targetKcal = liveMeta?.targetCalories ??
        (snapshot?.macros.targetCalories ?? 0.0);
    final macros = liveMeta?.macros ?? snapshot?.macros;

    // Streak & Pesagens
    final pesagens = appState.pesagens;
    final streak = _computeStreak(pesagens);

    // Variação unificada do peso
    final deltaPeso = weightContext.deltaFromPrevious ??
        (previous != null && latest != null
            ? currentWeight - previous.avaliacao.pesoKg
            : null);

    final deltaFavorable = deltaPeso != null
        ? isWeightDeltaFavorable(deltaPeso, latest?.avaliacao.objetivo)
        : null;
    final deltaPesoColor = deltaFavorable == null
        ? colors.textSecondary
        : (deltaFavorable ? colors.successText : colors.dangerText);
    final deltaPesoBg = deltaFavorable == null
        ? colors.surfaceSubtle
        : (deltaFavorable
            ? AppColors.emerald.withValues(alpha: 0.14)
            : AppColors.rose.withValues(alpha: 0.14));

    double? deltaBf;
    double? deltaLbm;
    double? deltaFat;

    if (previous != null) {
      final prevSnap = previous.resultado?.snapshot;
      final prevWeight = previous.avaliacao.pesoKg;
      final prevBf = prevSnap?.bfPrincipal ?? 0.0;
      final prevLbm = prevSnap?.lbmFinal ?? 0.0;
      final prevFatKg = prevWeight * (prevBf / 100.0);

      if (currentBf > 0 && prevBf > 0) {
        deltaBf = currentBf - prevBf;
        deltaFat = currentFatKg - prevFatKg;
      }
      if (currentLbm > 0 && prevLbm > 0) {
        deltaLbm = currentLbm - prevLbm;
      }
    }

    final bfMethodLabel = (snapshot != null && snapshot.metodoPrincipal != 'none')
        ? snapshot.metodoPrincipalLabel
        : (liveMeta != null && liveMeta.bfMethod != 'none'
            ? liveMeta.bfMethod.toUpperCase()
            : null);

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
          const SizedBox(height: 4),
        ],

        // 1. Hero Metric Card (Apple Health style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.border,
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
              // Top row responsiva: Origem + Tendência/Método + Streak Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            weightContext.hasData
                                ? weightContext.sourceLabel
                                : (latest != null
                                    ? DateFormat('dd MMM yyyy', 'pt_BR')
                                        .format(latest.avaliacao.dataAvaliacao)
                                    : 'Sem avaliações'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                        ),
                        if (weightContext.emaWeight != null &&
                            (currentWeight - weightContext.emaWeight!).abs() >=
                                0.1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tendência: ${weightContext.emaWeight!.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          )
                        else if (snapshot != null &&
                            snapshot.metodoPrincipal != 'none')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              snapshot.metodoPrincipalLabel,
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
                  const SizedBox(width: 8),
                  Semantics(
                    label: streak > 0
                        ? 'Sequência atual de $streak dias com pesagem'
                        : 'Sem sequência ativa de pesagens',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        streak > 0
                            ? '🔥 $streak dia${streak > 1 ? 's' : ''}'
                            : '0 dias',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.warningText,
                        ),
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
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (deltaPeso != null)
                    Semantics(
                      label:
                          'Variação de peso: ${deltaPeso > 0 ? '+' : ''}${deltaPeso.toStringAsFixed(1)} quilos',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: deltaPesoBg,
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
                              color: deltaPesoColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${deltaPeso.abs().toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: deltaPesoColor,
                              ),
                            ),
                          ],
                        ),
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
                      sublabel:
                          bfMethodLabel != null ? 'Método: $bfMethodLabel' : null,
                      delta: deltaBf != null
                          ? '${deltaBf >= 0 ? '+' : ''}${deltaBf.toStringAsFixed(1)}%'
                          : null,
                      deltaColor: deltaBf != null
                          ? (deltaBf <= 0
                              ? colors.successText
                              : colors.dangerText)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'MASSA MAGRA',
                      value: currentLbm > 0
                          ? '${currentLbm.toStringAsFixed(1)} kg'
                          : '--',
                      sublabel: currentFatKg > 0
                          ? 'Gordura: ${currentFatKg.toStringAsFixed(1)} kg'
                          : null,
                      delta: deltaLbm != null
                          ? '${deltaLbm >= 0 ? '+' : ''}${deltaLbm.toStringAsFixed(1)} kg'
                          : null,
                      deltaColor: deltaLbm != null
                          ? (deltaLbm >= 0
                              ? colors.successText
                              : colors.dangerText)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      key: const ValueKey('tile_meta_peso'),
                      label: 'META DE PESO',
                      value: profile.metaPesoKg != null
                          ? '${profile.metaPesoKg!.toStringAsFixed(1)} kg'
                          : 'Definir meta',
                      sublabel: profile.metaPesoKg != null && currentWeight > 0
                          ? '${(currentWeight - profile.metaPesoKg!).abs().toStringAsFixed(1)} kg restante'
                          : (onEditGoal != null ? 'Toque para configurar' : null),
                      onTap: onEditGoal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'META CALÓRICA',
                      value: targetKcal > 0
                          ? '${targetKcal.toStringAsFixed(0)} kcal'
                          : '--',
                      sublabel: macros?.grams != null
                          ? 'Prot ${macros!.grams.protein}g • Carb ${macros.grams.carbs}g • Gord ${macros.grams.fat}g'
                          : null,
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
                  foregroundColor: colors.accent,
                  side: BorderSide(
                    color: colors.accent,
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
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (deltaFat < 0 && deltaLbm > 0)
                        ? AppColors.emerald.withValues(alpha: 0.14)
                        : colors.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (deltaFat < 0 && deltaLbm > 0)
                        ? Icons.auto_awesome_rounded
                        : Icons.insights_rounded,
                    color: (deltaFat < 0 && deltaLbm > 0)
                        ? colors.successText
                        : colors.accent,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gordura: ${deltaFat >= 0 ? "+" : ""}${deltaFat.toStringAsFixed(1)}kg  •  Músculo: ${deltaLbm >= 0 ? "+" : ""}${deltaLbm.toStringAsFixed(1)}kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Atalho de Destaque para o Bio-Coach Inteligente (Gemini)
        if (latest != null && latest.resultado != null) ...[
          Semantics(
            button: true,
            label:
                'Bio-Coach Inteligente Gemini. Toque para ver o parecer clínico da sua avaliação.',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('btn_biocoach_overview_shortcut'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onNavigateToTab(3);
                },
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF312E81).withValues(alpha: 0.55),
                              const Color(0xFF4C1D95).withValues(alpha: 0.45),
                            ]
                          : [
                              const Color(0xFFEEF2FF),
                              const Color(0xFFF5F3FF),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Bio-Coach Inteligente',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    appState.hasGeminiApiKey
                                        ? 'IA Ativa'
                                        : 'Gemini',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toque para gerar ou ler o diagnóstico clínico da sua avaliação',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: colors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
  final VoidCallback? onTap;

  const _MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.sublabel,
    this.delta,
    this.deltaColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;

    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: onTap != null
            ? Border.all(color: colors.accent.withValues(alpha: 0.28))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colors.textMuted,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: colors.accent,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: onTap != null && value == 'Definir meta'
                      ? colors.accent
                      : colors.textPrimary,
                ),
              ),
              if (delta != null)
                Text(
                  delta!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: deltaColor ?? colors.successText,
                  ),
                ),
            ],
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 3),
            Text(
              sublabel!,
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: '$label: $value${sublabel != null ? ', $sublabel' : ''}',
        child: container,
      );
    }

    return Semantics(
      button: true,
      label: '$label: $value. Toque para configurar ou editar sua meta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          borderRadius: BorderRadius.circular(12),
          child: container,
        ),
      ),
    );
  }
}
