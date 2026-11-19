import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/weight_trend_calculator.dart';

enum _ChartRange { last10, sixMonths, all }

class EvolutionCharts extends StatefulWidget {
  final List<JoinedEvaluation> evaluations;
  final List<Pesagem> pesagens;
  final VoidCallback? onNewEvaluation;

  const EvolutionCharts({
    super.key,
    required this.evaluations,
    this.pesagens = const [],
    this.onNewEvaluation,
  });

  @override
  State<EvolutionCharts> createState() => _EvolutionChartsState();
}

class _EvolutionChartsState extends State<EvolutionCharts> {
  _ChartRange _range = _ChartRange.last10;

  List<JoinedEvaluation> _chronologicalEvaluations() {
    if (widget.evaluations.isEmpty) return [];
    return [...widget.evaluations]..sort(
        (a, b) =>
            a.avaliacao.dataAvaliacao.compareTo(b.avaliacao.dataAvaliacao),
      );
  }

  List<JoinedEvaluation> _filterEvaluations(
    List<JoinedEvaluation> sorted,
    int sixMonthsCount,
  ) {
    if (sorted.isEmpty) return [];

    switch (_range) {
      case _ChartRange.last10:
        if (sorted.length <= 10) return sorted;
        return sorted.sublist(sorted.length - 10);
      case _ChartRange.sixMonths:
        if (sixMonthsCount < 2) return sorted;
        final cutoff = DateTime.now().subtract(const Duration(days: 180));
        return sorted
            .where((e) => !e.avaliacao.dataAvaliacao.isBefore(cutoff))
            .toList();
      case _ChartRange.all:
        return sorted;
    }
  }

  List<_ChartPoint> _buildChartData(List<JoinedEvaluation> sorted) {
    if (sorted.isEmpty) return [];

    final n = sorted.length;
    double sumX = 0, sumYPeso = 0, sumXYPeso = 0, sumXX = 0;

    // Regressão linear do %BF somente sobre os pontos com %BF válido (> 0)
    int bfCount = 0;
    double bfSumX = 0, bfSumY = 0, bfSumXY = 0, bfSumXX = 0;

    for (int i = 0; i < n; i++) {
      final ev = sorted[i];
      final peso = ev.avaliacao.pesoKg;
      final snap = ev.resultado?.snapshot;
      final bf = snap?.bfPrincipal ?? 0.0;
      sumX += i;
      sumYPeso += peso;
      sumXYPeso += i * peso;
      sumXX += i * i;

      if (bf > 0) {
        bfCount++;
        bfSumX += i;
        bfSumY += bf;
        bfSumXY += i * bf;
        bfSumXX += i * i;
      }
    }

    final rawDenom = (n * sumXX) - (sumX * sumX);
    final denominator = rawDenom == 0 ? 1.0 : rawDenom;
    final slopePeso = ((n * sumXYPeso) - (sumX * sumYPeso)) / denominator;
    final interceptPeso = (sumYPeso - (slopePeso * sumX)) / n;

    final rawBfDenom = (bfCount * bfSumXX) - (bfSumX * bfSumX);
    final bfDenominator = rawBfDenom == 0 ? 1.0 : rawBfDenom;
    final slopeBf =
        bfCount >= 2 ? ((bfCount * bfSumXY) - (bfSumX * bfSumY)) / bfDenominator : 0.0;
    final interceptBf =
        bfCount > 0 ? (bfSumY - (slopeBf * bfSumX)) / bfCount : 0.0;

    final fmt = DateFormat('dd MMM', 'pt_BR');

    return List.generate(n, (index) {
      final ev = sorted[index];
      final prev = index > 0 ? sorted[index - 1] : null;

      final peso = ev.avaliacao.pesoKg;
      final snap = ev.resultado?.snapshot;
      final prevSnap = prev?.resultado?.snapshot;

      double? validPos(double? val) => (val != null && val > 0) ? val : null;

      final bfPrincipal = validPos(snap?.bfPrincipal);
      final prevBfPrincipal = validPos(prevSnap?.bfPrincipal);
      final bfNavy = validPos(snap?.bfNavy);
      final prevBfNavy = validPos(prevSnap?.bfNavy);
      final bfRfm = validPos(snap?.bfRfm);
      final prevBfRfm = validPos(prevSnap?.bfRfm);
      final lbm = validPos(snap?.lbmFinal);
      final prevLbm = validPos(prevSnap?.lbmFinal);

      return _ChartPoint(
        index: index,
        dateFormatted: fmt.format(ev.avaliacao.dataAvaliacao),
        peso: peso,
        deltaPeso: prev != null ? peso - prev.avaliacao.pesoKg : 0.0,
        pesoTrend: (slopePeso * index) + interceptPeso,
        lbm: lbm,
        deltaLbm:
            (lbm != null && prevLbm != null) ? lbm - prevLbm : 0.0,
        bfPrincipal: bfPrincipal,
        deltaBfPrincipal: (bfPrincipal != null && prevBfPrincipal != null)
            ? bfPrincipal - prevBfPrincipal
            : 0.0,
        bfTrend: bfCount >= 2 ? (slopeBf * index) + interceptBf : null,
        bfNavy: bfNavy,
        deltaBfNavy:
            (bfNavy != null && prevBfNavy != null) ? bfNavy - prevBfNavy : 0.0,
        bfRfm: bfRfm,
        deltaBfRfm:
            (bfRfm != null && prevBfRfm != null) ? bfRfm - prevBfRfm : 0.0,
      );
    });
  }

  Widget _buildRangePill(
    String label,
    _ChartRange value,
    BioThemeColors colors, {
    bool enabled = true,
  }) {
    final active = enabled && _range == value;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: active,
      label: enabled
          ? 'Período do gráfico: $label'
          : '$label indisponível: menos de 2 avaliações nos últimos 6 meses',
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() => _range = value);
                }
              : () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Registre ao menos 2 avaliações nos últimos 6 meses para usar este filtro.',
                      ),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(100),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.indigoPrimary : colors.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: active ? Colors.transparent : colors.border,
                ),
              ),
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;
    final isDark = context.isDarkMode;
    final chronological = _chronologicalEvaluations();
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final sixMonthsCount = chronological
        .where((e) => !e.avaliacao.dataAvaliacao.isBefore(cutoff))
        .length;
    final effectiveSorted = _filterEvaluations(chronological, sixMonthsCount);
    final chartData = _buildChartData(effectiveSorted);

    if (chartData.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 32,
              color: colors.accent,
            ),
            const SizedBox(height: 10),
            Text(
              'Faça mais uma avaliação para desbloquear as curvas de evolução.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            if (widget.onNewEvaluation != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const ValueKey('btn_charts_new_eval'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onNewEvaluation!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigoPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(190, 48),
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
          ],
        ),
      );
    }

    final sortedPesagens = [...widget.pesagens]
      ..sort((a, b) => a.data.compareTo(b.data));
    final latestPesagem =
        sortedPesagens.isNotEmpty ? sortedPesagens.last : null;
    final emaSeries = WeightTrendCalculator.computeEma(sortedPesagens);
    final latestEma = emaSeries.isNotEmpty ? emaSeries.last.emaWeight : null;
    final weightSubtitle = latestPesagem != null
        ? 'Última pesagem: ${latestPesagem.pesoKg.toStringAsFixed(1)} kg${latestEma != null ? ' • Tendência: ${latestEma.toStringAsFixed(1)} kg' : ''}'
        : null;

    // Determina série principal de %BF segundo o método mais recente da avaliação
    final latestSnap = effectiveSorted.last.resultado?.snapshot;
    final primaryMethodKey = latestSnap?.metodoPrincipal ?? 'none';
    final primaryMethodLabel =
        (latestSnap != null && primaryMethodKey != 'none')
            ? latestSnap.metodoPrincipalLabel
            : 'Gordura Principal';

    final hasBfPrincipal = chartData.any((p) => p.bfPrincipal != null);
    final hasBfNavy = chartData.any((p) => p.bfNavy != null);
    final hasBfRfm = chartData.any((p) => p.bfRfm != null);

    final bfSeries = <_LineSeriesConfig>[
      _LineSeriesConfig(
        name: 'Tendência',
        color: colors.textMuted,
        lineColor: colors.textMuted.withValues(alpha: 0.75),
        unit: '%',
        isTrend: true,
        valueSelector: (p) => p.bfTrend,
        deltaSelector: (_) => 0,
      ),
      if (hasBfPrincipal)
        _LineSeriesConfig(
          name: primaryMethodLabel,
          color: AppColors.orange,
          unit: '%',
          valueSelector: (p) => p.bfPrincipal,
          deltaSelector: (p) => p.deltaBfPrincipal,
          isPositiveGood: false,
        ),
      if (primaryMethodKey != 'rfm' && hasBfRfm)
        _LineSeriesConfig(
          name: 'RFM',
          color: const Color(0xFF8B5CF6),
          unit: '%',
          valueSelector: (p) => p.bfRfm,
          deltaSelector: (p) => p.deltaBfRfm,
          isPositiveGood: false,
        )
      else if (primaryMethodKey != 'navy' && hasBfNavy)
        _LineSeriesConfig(
          name: 'US Navy',
          color: colors.accent,
          unit: '%',
          valueSelector: (p) => p.bfNavy,
          deltaSelector: (p) => p.deltaBfNavy,
          isPositiveGood: false,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.evaluations.length > 2) ...[
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'PERÍODO DOS GRÁFICOS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: colors.textMuted,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildRangePill('Últimas 10', _ChartRange.last10, colors),
                    _buildRangePill(
                      '6 Meses',
                      _ChartRange.sixMonths,
                      colors,
                      enabled: sixMonthsCount >= 2,
                    ),
                    _buildRangePill('Tudo', _ChartRange.all, colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Gráfico 1: Evolução de Peso e Massa Magra (kg)
        _ChartCard(
          title: 'Evolução de Peso e Massa Magra (kg)',
          subtitle: weightSubtitle,
          points: chartData,
          colors: colors,
          isDark: isDark,
          series: [
            _LineSeriesConfig(
              name: 'Tendência de Peso',
              color: colors.textMuted,
              lineColor: colors.textMuted.withValues(alpha: 0.75),
              unit: 'kg',
              isTrend: true,
              valueSelector: (p) => p.pesoTrend,
              deltaSelector: (_) => 0,
            ),
            _LineSeriesConfig(
              name: 'Peso Total',
              color: AppColors.blue,
              unit: 'kg',
              valueSelector: (p) => p.peso,
              deltaSelector: (p) => p.deltaPeso,
              isPositiveGood: false,
            ),
            _LineSeriesConfig(
              name: 'Massa Magra',
              color: AppColors.emerald,
              unit: 'kg',
              valueSelector: (p) => p.lbm,
              deltaSelector: (p) => p.deltaLbm,
              isPositiveGood: true,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Gráfico 2: Percentual de Gordura (%)
        if (hasBfPrincipal || hasBfNavy || hasBfRfm)
          _ChartCard(
            title: 'Percentual de Gordura (%)',
            points: chartData,
            colors: colors,
            isDark: isDark,
            series: bfSeries,
          ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<_ChartPoint> points;
  final List<_LineSeriesConfig> series;
  final BioThemeColors colors;
  final bool isDark;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.points,
    required this.series,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final p in points) {
      for (final s in series) {
        final v = s.valueSelector(p);
        if (v != null && v > 0) {
          if (v < minY) minY = v;
          if (v > maxY) maxY = v;
        }
      }
    }

    if (!minY.isFinite) minY = 0;
    if (!maxY.isFinite) maxY = 100;
    final yMin = math.max(0.0, (minY - 2).floorToDouble());
    final yMax = (maxY + 2).ceilToDouble();
    final double xInterval =
        math.max(1, (points.length / 4).ceil()).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label:
                'Gráfico: $title com ${points.length} avaliações registradas',
            excludeSemantics: true,
            child: SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (points.length - 1).toDouble(),
                    minY: yMin,
                    maxY: yMax <= yMin ? yMin + 4 : yMax,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: colors.border.withValues(alpha: 0.7),
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (val, meta) {
                            return Text(
                              val.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: xInterval,
                          reservedSize: 28,
                          getTitlesWidget: (val, meta) {
                            final idx = val.round();
                            if (idx < 0 ||
                                idx >= points.length ||
                                (val - idx).abs() > 0.01) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                points[idx].dateFormatted,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white.withValues(alpha: 0.96),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final cfg = series[spot.barIndex];
                            if (cfg.isTrend) return null;
                            final pt = points[spot.x.round()];
                            final delta = cfg.deltaSelector(pt);
                            String deltaStr = '';
                            if (delta.abs() > 0.04) {
                              final arrow = delta > 0 ? '↑' : '↓';
                              deltaStr =
                                  ' ($arrow${delta.abs().toStringAsFixed(1)} ${cfg.unit})';
                            }
                            return LineTooltipItem(
                              '${cfg.name}: ${spot.y.toStringAsFixed(1)} ${cfg.unit}$deltaStr',
                              TextStyle(
                                color: cfg.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: series.map((cfg) {
                      final spots = <FlSpot>[];
                      for (final p in points) {
                        final v = cfg.valueSelector(p);
                        if (v != null && v > 0) {
                          spots.add(FlSpot(p.index.toDouble(), v));
                        }
                      }
                      return LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: cfg.lineColor ?? cfg.color,
                        barWidth: cfg.isTrend ? 2 : 3,
                        dashArray: cfg.isTrend ? [4, 4] : null,
                        dotData: FlDotData(
                          show: !cfg.isTrend,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: cfg.color,
                            strokeWidth: 2,
                            strokeColor: colors.surface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legenda
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: series.map((cfg) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cfg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cfg.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final int index;
  final String dateFormatted;
  final double peso;
  final double deltaPeso;
  final double pesoTrend;
  final double? lbm;
  final double deltaLbm;
  final double? bfPrincipal;
  final double deltaBfPrincipal;
  final double? bfTrend;
  final double? bfNavy;
  final double deltaBfNavy;
  final double? bfRfm;
  final double deltaBfRfm;

  const _ChartPoint({
    required this.index,
    required this.dateFormatted,
    required this.peso,
    required this.deltaPeso,
    required this.pesoTrend,
    required this.lbm,
    required this.deltaLbm,
    required this.bfPrincipal,
    required this.deltaBfPrincipal,
    required this.bfTrend,
    required this.bfNavy,
    required this.deltaBfNavy,
    required this.bfRfm,
    required this.deltaBfRfm,
  });
}

class _LineSeriesConfig {
  final String name;
  final Color color;
  final Color? lineColor;
  final String unit;
  final bool isTrend;
  final bool isPositiveGood;
  final double? Function(_ChartPoint) valueSelector;
  final double Function(_ChartPoint) deltaSelector;

  const _LineSeriesConfig({
    required this.name,
    required this.color,
    this.lineColor,
    required this.unit,
    this.isTrend = false,
    this.isPositiveGood = true,
    required this.valueSelector,
    required this.deltaSelector,
  });
}
