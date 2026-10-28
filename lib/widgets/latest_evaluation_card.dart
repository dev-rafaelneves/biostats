import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class LatestEvaluationCard extends StatelessWidget {
  final List<JoinedEvaluation> evaluations;
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onUpdateProfile;

  const LatestEvaluationCard({
    super.key,
    required this.evaluations,
    this.profile,
    this.onUpdateProfile,
  });

  double _extractBf(JoinedEvaluation? ev) {
    if (ev == null) return 0.0;
    return ev.resultado?.snapshot.bfPrincipal ?? 0.0;
  }

  String _metodoBf(JoinedEvaluation? ev) {
    if (ev == null) return 'Navy';
    return ev.resultado?.snapshot.metodoPrincipalLabel ?? 'Navy';
  }

  Future<void> _showGoalDialog(BuildContext context, UserProfile user) async {
    final pesoCtrl = TextEditingController(
      text: user.metaPesoKg != null ? user.metaPesoKg!.toStringAsFixed(1) : '',
    );
    final bfCtrl = TextEditingController(
      text: user.metaBfPct != null ? user.metaBfPct!.toStringAsFixed(1) : '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Minhas Metas Pessoais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pesoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Peso Alvo (kg)',
                  hintText: 'Ex: 75.0',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bfCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Gordura Corporal Alvo (%)',
                  hintText: 'Ex: 14.0',
                ),
              ),
            ],
          ),
          actions: [
            if (user.metaPesoKg != null || user.metaBfPct != null)
              TextButton(
                onPressed: () {
                  onUpdateProfile?.call(user.copyWith(clearMetas: true));
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: AppColors.rose),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                double? parsePos(String s) {
                  final v = double.tryParse(s.trim().replaceAll(',', '.'));
                  return (v != null && v > 0) ? v : null;
                }

                final novoPeso = parsePos(pesoCtrl.text);
                final novoBf = parsePos(bfCtrl.text);
                HapticFeedback.lightImpact();
                onUpdateProfile?.call(
                  UserProfile(
                    id: user.id,
                    nome: user.nome,
                    dataNascimento: user.dataNascimento,
                    sexo: user.sexo,
                    alturaCm: user.alturaCm,
                    metaPesoKg: novoPeso,
                    metaBfPct: novoBf,
                    criadoEm: user.criadoEm,
                  ),
                );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Salvar Meta'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (evaluations.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sorted = [...evaluations]..sort(
        (a, b) =>
            b.avaliacao.dataAvaliacao.compareTo(a.avaliacao.dataAvaliacao),
      );

    final current = sorted[0];
    final previous = sorted.length > 1 ? sorted[1] : null;
    final oldest = sorted.last;

    final currentWeight = current.avaliacao.pesoKg;
    final previousWeight = previous?.avaliacao.pesoKg;
    final weightDelta =
        previousWeight != null ? currentWeight - previousWeight : 0.0;

    final currentBF = _extractBf(current);
    final previousBF = _extractBf(previous);
    final bfDelta =
        (previous != null && previousBF > 0 && currentBF > 0)
            ? currentBF - previousBF
            : 0.0;

    final currentLBM = current.resultado?.snapshot.lbmFinal ?? 0.0;
    final previousLBM = previous?.resultado?.snapshot.lbmFinal ?? 0.0;
    final lbmDelta =
        (previous != null && previousLBM > 0) ? currentLBM - previousLBM : 0.0;

    // Semântica de cor do Peso baseada no Objetivo da avaliação atual
    final bool weightInverseColor =
        current.avaliacao.objetivo == Objetivo.emagrecimento;

    final dateStr =
        DateFormat('dd/MM/yyyy').format(current.avaliacao.dataAvaliacao);

    final metaPeso = profile?.metaPesoKg;
    final metaBf = profile?.metaBfPct;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Última Avaliação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Foco: ${current.avaliacao.objetivo.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (profile != null && onUpdateProfile != null)
                TextButton.icon(
                  onPressed: () => _showGoalDialog(context, profile!),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: isDark
                        ? AppColors.indigoLight
                        : AppColors.indigoPrimary,
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: Text(
                    (metaPeso != null || metaBf != null)
                        ? 'Editar Meta'
                        : 'Definir Meta',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  title: 'Peso',
                  value: '${currentWeight.toStringAsFixed(1)} kg',
                  delta: weightDelta,
                  icon: Icons.monitor_weight_outlined,
                  iconColor: AppColors.blue,
                  inverseColor: weightInverseColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricColumn(
                  title: currentBF > 0 ? 'Gordura (${_metodoBf(current)})' : 'Gordura',
                  value: currentBF > 0
                      ? '${currentBF.toStringAsFixed(1)} %'
                      : '--',
                  delta: bfDelta,
                  icon: Icons.water_drop_outlined,
                  iconColor: AppColors.orange,
                  inverseColor: true, // Menos gordura = verde
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricColumn(
                  title: 'Massa Magra',
                  value: '${currentLBM.toStringAsFixed(1)} kg',
                  delta: lbmDelta,
                  icon: Icons.timeline_rounded,
                  iconColor: AppColors.emerald,
                  inverseColor: false, // Mais massa magra = verde
                ),
              ),
            ],
          ),

          // Barra de Progresso de Meta Pessoal (quando configurada)
          if (metaPeso != null || metaBf != null) ...[
            const SizedBox(height: 16),
            _GoalProgressSection(
              currentWeight: currentWeight,
              initialWeight: oldest.avaliacao.pesoKg,
              targetWeight: metaPeso,
              currentBf: currentBF,
              initialBf: _extractBf(oldest),
              targetBf: metaBf,
            ),
          ],

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : const Color(0xFFF8FAFC),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Avaliação realizada em: $dateStr',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressSection extends StatelessWidget {
  final double currentWeight;
  final double initialWeight;
  final double? targetWeight;
  final double currentBf;
  final double initialBf;
  final double? targetBf;

  const _GoalProgressSection({
    required this.currentWeight,
    required this.initialWeight,
    this.targetWeight,
    required this.currentBf,
    required this.initialBf,
    this.targetBf,
  });

  double _computeProgress(double start, double current, double target) {
    final totalSpan = (target - start).abs();
    if (totalSpan < 0.1) {
      return (current - target).abs() <= 0.3 ? 1.0 : 0.5;
    }
    if (target < start) {
      // Meta de redução
      if (current <= target) return 1.0;
      if (current >= start) return 0.08;
      return ((start - current) / totalSpan).clamp(0.08, 1.0);
    } else {
      // Meta de ganho
      if (current >= target) return 1.0;
      if (current <= start) return 0.08;
      return ((current - start) / totalSpan).clamp(0.08, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          if (targetWeight != null) ...[
            Builder(
              builder: (_) {
                final diff = (currentWeight - targetWeight!).abs();
                final reached = diff <= 0.2;
                final progress = _computeProgress(
                  initialWeight,
                  currentWeight,
                  targetWeight!,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Meta de Peso: ${targetWeight!.toStringAsFixed(1)} kg',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        Text(
                          reached
                              ? 'Meta atingida! 🎉'
                              : 'Faltam ${diff.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: reached
                                ? AppColors.emerald
                                : AppColors.indigoPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          reached ? AppColors.emerald : AppColors.indigoPrimary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (targetWeight != null && targetBf != null && currentBf > 0)
            const SizedBox(height: 10),
          if (targetBf != null && currentBf > 0) ...[
            Builder(
              builder: (_) {
                final diff = (currentBf - targetBf!).abs();
                final reached = currentBf <= targetBf! + 0.2;
                final progress = _computeProgress(
                  initialBf > 0 ? initialBf : currentBf + 4,
                  currentBf,
                  targetBf!,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Meta de Gordura: ${targetBf!.toStringAsFixed(1)}%',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        Text(
                          reached
                              ? 'Meta atingida! 🔥'
                              : 'Faltam ${diff.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color:
                                reached ? AppColors.emerald : AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          reached ? AppColors.emerald : AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String title;
  final String value;
  final double delta;
  final IconData icon;
  final Color iconColor;
  final bool inverseColor;

  const _MetricColumn({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.iconColor,
    required this.inverseColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = delta > 0.04;
    final isNegative = delta < -0.04;

    Color textColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8);
    Color bgColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    IconData deltaIcon = Icons.remove_rounded;

    if (isPositive) {
      deltaIcon = Icons.arrow_upward_rounded;
      final isGood = !inverseColor;
      textColor = isGood ? const Color(0xFF059669) : const Color(0xFFE11D48);
      bgColor = isGood
          ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.12)
          : const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.18 : 0.12);
    } else if (isNegative) {
      deltaIcon = Icons.arrow_downward_rounded;
      final isGood = inverseColor;
      textColor = isGood ? const Color(0xFF059669) : const Color(0xFFE11D48);
      bgColor = isGood
          ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.12)
          : const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.18 : 0.12);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(deltaIcon, size: 12, color: textColor),
              const SizedBox(width: 2),
              Text(
                delta.abs().toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
