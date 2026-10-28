import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculator.dart';

class LivePreviewCard extends StatelessWidget {
  final CalculosSnapshot calculos;
  final Sexo sexo;
  final bool hasPescoco;
  final bool hasQuadril;

  const LivePreviewCard({
    super.key,
    required this.calculos,
    required this.sexo,
    required this.hasPescoco,
    required this.hasQuadril,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imc = calculos.imc;
    final bfNavy = calculos.bfNavy;
    final bfRfm = calculos.bfRfm;
    final bfPrinc = calculos.bfPrincipal;
    final metodoLabel = calculos.metodoPrincipalLabel;
    final lbm = calculos.lbmFinal;
    final metaKcal = calculos.macros.targetCalories;

    final missingNavyField = !hasPescoco || (sexo == Sexo.F && !hasQuadril);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indigoPrimary.withValues(alpha: isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.indigoPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 16,
                color: AppColors.indigoPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'PRÉVIA EM TEMPO REAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark
                      ? AppColors.indigoLight
                      : AppColors.indigoPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _PreviewMetric(
                label: 'IMC',
                value: imc > 0 ? imc.toStringAsFixed(1) : '--',
              ),
              _PreviewMetric(
                label: 'BF% ($metodoLabel)',
                value: bfPrinc > 0 ? '${bfPrinc.toStringAsFixed(1)}%' : '--',
              ),
              if (bfNavy > 0 && metodoLabel != 'US Navy')
                _PreviewMetric(
                  label: 'BF% (Navy)',
                  value: '${bfNavy.toStringAsFixed(1)}%',
                ),
              if (bfRfm > 0 && metodoLabel != 'RFM')
                _PreviewMetric(
                  label: 'BF% (RFM)',
                  value: '${bfRfm.toStringAsFixed(1)}%',
                ),
              _PreviewMetric(
                label: 'Massa Magra',
                value: lbm > 0 ? '${lbm.toStringAsFixed(1)}kg' : '--',
              ),
              _PreviewMetric(
                label: 'Meta',
                value: metaKcal > 0 ? '${metaKcal.toStringAsFixed(0)}kcal' : '--',
              ),
            ],
          ),
          if (missingNavyField) ...[
            const SizedBox(height: 8),
            Text(
              sexo == Sexo.F
                  ? '💡 Dica: Preencha Pescoço e Quadril para calcular também o % de Gordura US Navy.'
                  : '💡 Dica: Preencha o Pescoço para calcular também o % de Gordura US Navy.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.darkTextPrimary
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
