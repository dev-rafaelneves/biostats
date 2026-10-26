import 'package:flutter/material.dart';
import '../models/models.dart';

class BodyRecompositionInsight extends StatelessWidget {
  final List<JoinedEvaluation> evaluations;

  const BodyRecompositionInsight({
    super.key,
    required this.evaluations,
  });

  @override
  Widget build(BuildContext context) {
    if (evaluations.length < 2) return const SizedBox.shrink();

    // evaluations are sorted descending (latest first)
    final newest = evaluations.first;
    final oldest = evaluations.last;

    final initialWeight = oldest.avaliacao.pesoKg;
    final currentWeight = newest.avaliacao.pesoKg;
    final weightDiff = currentWeight - initialWeight;

    double extractBf(JoinedEvaluation ev) {
      final navy = (ev.resultado?.calculos['bfNavy'] as num?)?.toDouble() ?? 0.0;
      if (navy > 0) return navy;
      return (ev.resultado?.calculos['bfRfm'] as num?)?.toDouble() ?? 0.0;
    }

    final initialBf = extractBf(oldest);
    final currentBf = extractBf(newest);

    if (initialBf <= 0 || currentBf <= 0) return const SizedBox.shrink();

    final initialFatMass = initialWeight * (initialBf / 100.0);
    final currentFatMass = currentWeight * (currentBf / 100.0);
    final fatDiff = currentFatMass - initialFatMass;

    final initialLeanMass = initialWeight - initialFatMass;
    final currentLeanMass = currentWeight - currentFatMass;
    final leanDiff = currentLeanMass - initialLeanMass;

    final isGainingMuscle = leanDiff > 0;
    final isLosingFat = fatDiff < 0;
    final isWeightUp = weightDiff > 0;

    String messageTitle;
    String messageBody;
    Color badgeBg;
    Color badgeFg;
    String badgeText;

    if (isGainingMuscle && isLosingFat && isWeightUp) {
      messageTitle = 'A balança está mentindo para você!';
      final wSign = weightDiff > 0 ? '+' : '';
      messageBody =
          'Você está mais pesado(a) ($wSign${weightDiff.toStringAsFixed(1)}kg), mas não se assuste: você perdeu gordura e ganhou massa muscular. O músculo é mais denso que a gordura, por isso o peso subiu, mas suas medidas e saúde estão melhores.';
      badgeBg = const Color(0xFFD1FAE5);
      badgeFg = const Color(0xFF047857);
      badgeText = 'Recomposição Corporal Perfeita';
    } else if (isGainingMuscle && isLosingFat && !isWeightUp) {
      messageTitle = 'Evolução Dupla!';
      messageBody =
          'Incrível! Você perdeu peso na balança (${weightDiff.toStringAsFixed(1)}kg), derreteu gordura e ainda conseguiu ganhar massa muscular ao mesmo tempo. O cenário dos sonhos.';
      badgeBg = const Color(0xFFD1FAE5);
      badgeFg = const Color(0xFF047857);
      badgeText = 'Queima & Hipertrofia';
    } else if (!isGainingMuscle && isLosingFat) {
      messageTitle = 'Secando com sucesso';
      messageBody =
          'Você eliminou ${fatDiff.abs().toStringAsFixed(1)}kg de gordura pura. Houve uma leve perda de massa magra, o que é normal em dietas de déficit calórico. Mantenha as proteínas altas e os treinos intensos!';
      badgeBg = const Color(0xFFE0E7FF);
      badgeFg = const Color(0xFF4338CA);
      badgeText = 'Fase de Emagrecimento';
    } else if (isGainingMuscle && !isLosingFat) {
      messageTitle = 'Construção Muscular';
      final fSign = fatDiff > 0 ? '+' : '';
      messageBody =
          'Você adicionou ${leanDiff.toStringAsFixed(1)}kg de massa magra! Como o ganho de peso veio com um pouco de gordura ($fSign${fatDiff.toStringAsFixed(1)}kg), você provavelmente está em Superávit Calórico (Bulking).';
      badgeBg = const Color(0xFFDBEAFE);
      badgeFg = const Color(0xFF1D4ED8);
      badgeText = 'Fase de Hipertrofia';
    } else {
      messageTitle = 'Alerta de Estagnação';
      messageBody =
          'Parece que você perdeu massa muscular e ganhou gordura em relação à sua primeira avaliação. Considere revisar o volume dos seus treinos na esteira/musculação e a ingestão de proteínas diárias.';
      badgeBg = const Color(0xFFFFEDD5);
      badgeFg = const Color(0xFFC2410C);
      badgeText = 'Atenção aos Treinos';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // slate-900
            Color(0xFF1E293B), // slate-800
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Watermark Dumbbell Icon
          const Positioned(
            right: -18,
            top: -18,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.fitness_center_rounded,
                size: 130,
                color: Colors.white,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badgeText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: badgeFg,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  messageTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  messageBody,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: Color(0xFFCBD5E1), // slate-300
                  ),
                ),
                const SizedBox(height: 20),

                // Grid Massa Gorda vs Massa Magra
                Row(
                  children: [
                    Expanded(
                      child: _RecompMetricTile(
                        title: 'MASSA GORDA',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFB923C),
                        diff: fatDiff,
                        isGoodWhenNegative: true,
                        positiveStatusLabel: 'Aumentou',
                        negativeStatusLabel: 'Reduziu',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RecompMetricTile(
                        title: 'MASSA MAGRA',
                        icon: Icons.fitness_center_rounded,
                        iconColor: const Color(0xFF818CF8),
                        diff: leanDiff,
                        isGoodWhenNegative: false,
                        positiveStatusLabel: 'Aumentou',
                        negativeStatusLabel: 'Perdeu',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecompMetricTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double diff;
  final bool isGoodWhenNegative;
  final String positiveStatusLabel;
  final String negativeStatusLabel;

  const _RecompMetricTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.diff,
    required this.isGoodWhenNegative,
    required this.positiveStatusLabel,
    required this.negativeStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sign = diff > 0 ? '+' : '';
    final isNegative = diff < 0;
    final isGood = isGoodWhenNegative ? isNegative : !isNegative;

    final statusColor = isGood
        ? const Color(0xFF34D399) // emerald-400
        : (isGoodWhenNegative
            ? const Color(0xFFF87171) // red-400
            : const Color(0xFFFB923C)); // orange-400

    final statusIcon =
        isNegative ? Icons.trending_down_rounded : Icons.trending_up_rounded;
    final statusText = isNegative ? negativeStatusLabel : positiveStatusLabel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$sign${diff.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kg',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
