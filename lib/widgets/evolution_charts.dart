import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

enum _ChartRange { last10, sixMonths, all }

class EvolutionCharts extends StatefulWidget {
  final List<JoinedEvaluation> evaluations;

  const EvolutionCharts({
    super.key,
    required this.evaluations,
  });

  @override
  State<EvolutionCharts> createState() => _EvolutionChartsState();
}

class _EvolutionChartsState extends State<EvolutionCharts> {
  _ChartRange _range = _ChartRange.last10;

  List<JoinedEvaluation> _filterEvaluations() {
    if (widget.evaluations.isEmpty) return [];

    // Ordem cronológica crescente (mais antiga para mais recente)
    final sorted = [...widget.evaluations]..sort(
        (a, b) =>
            a.avaliacao.dataAvaliacao.compareTo(b.avaliacao.dataAvaliacao),
      );

    switch (_range) {
      case _ChartRange.last10:
        if (sorted.length <= 10) return sorted;
        return sorted.sublist(sorted.length - 10);
      case _ChartRange.sixMonths:
        final cutoff = DateTime.now().subtract(const Duration(days: 180));
        final filtered = sorted
            .where((e) => !e.avaliacao.dataAvaliacao.isBefore(cutoff))
            .toList();
        return filtered.length >= 2 ? filtered : sorted;
      case _ChartRange.all:
        return sorted;
    }
  }

  List<_ChartPoint> _buildChartData() {
    final sorted = _filterEvaluations();
    if (sorted.isEmpty) return [];

    final n = sorted.length;
    double sumX = 0, sumYPeso = 0, sumXYPeso = 0, sumXX = 0;
    double sumYBf = 0, sumXYBf = 0;

    for (int i = 0; i < n; i++) {
      final ev = sorted[i];
      final peso = ev.avaliacao.pesoKg;
      final snap = ev.resultado?.snapshot;
      final bf = snap?.bfPrincipal ?? 0.0;
      sumX += i;
      sumYPeso += peso;
      sumXYPeso += i * peso;
      sumXX += i * i;
      sumYBf += bf;
      sumXYBf += i * bf;
    }

    final rawDenom = (n * sumXX) - (sumX * sumX);
    final denominator = rawDenom == 0 ? 1.0 : rawDenom;

    final slopePeso = ((n * sumXYPeso) - (sumX * sumYPeso)) / denominator;
    final interceptPeso = (sumYPeso - (slopePeso * sumX)) / n;

    final slopeBf = ((n * sumXYBf) - (sumX * sumYBf)) / denominator;
    final interceptBf = (sumYBf - (slopeBf * sumX)) / n;

    final fmt = DateFormat('dd MMM', 'pt_BR');

    return List.generate(n, (index) {
      final ev = sorted[index];
      final prev = index > 0 ? sorted[index - 1] : null;

      final peso = ev.avaliacao.pesoKg;
      final snap = ev.resultado?.snapshot;
      final prevSnap = prev?.resultado?.snapshot;

      final bfNavy = snap?.bfNavy ?? 0.0;
      final bfRfm = snap?.bfRfm ?? 0.0;
      final lbm = snap?.lbmFinal ?? 0.0;

      final prevBfNavy = prevSnap?.bfNavy ?? 0.0;
      final prevBfRfm = prevSnap?.bfRfm ?? 0.0;
      final prevLbm = prevSnap?.lbmFinal ?? 0.0;

      return _ChartPoint(
        index: index,
        dateFormatted: fmt.format(ev.avaliacao.dataAvaliacao),
        peso: peso,
        deltaPeso: prev != null ? peso - prev.avaliacao.pesoKg : 0.0,
        pesoTrend: (slopePeso * index) + interceptPeso,
        lbm: lbm,
        deltaLbm: prev != null ? lbm - prevLbm : 0.0,
        bfNavy: bfNavy,
        deltaBfNavy: prev != null ? bfNavy - prevBfNavy : 0.0,
        bfTrend: (slopeBf * index) + interceptBf,
        bfRfm: bfRfm,
        deltaBfRfm: prev != null ? bfRfm - prevBfRfm : 0.0,
      );
    });
  }

  Widget _buildRangePill(String label, _ChartRange value, bool isDark) {
    final active = _range == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _range = value);
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? AppColors.indigoPrimary
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartData = _buildChartData();

    if (chartData.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          ),
        ),
        child: Text(
          'Faça pelo menos mais uma avaliação para visualizar os gráficos de evolução temporal.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF64748B),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.evaluations.length > 2) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'PERÍODO DOS GRÁFICOS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRangePill('Últimas 10', _ChartRange.last10, isDark),
                  _buildRangePill('6 Meses', _ChartRange.sixMonths, isDark),
                  _buildRangePill('Tudo', _ChartRange.all, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Gráfico 1: Evolução de Peso e Massa Magra (kg)
        _ChartCard(
          title: 'Evolução de Peso e Massa Magra (kg)',
          points: chartData,
          series: [
            _LineSeriesConfig(
              name: 'Tendência de Peso',
              color: const Color(0xFFCBD5E1),
              isTrend: true,
              valueSelector: (p) => p.pesoTrend,
              deltaSelector: (_) => 0,
            ),
            _LineSeriesConfig(
              name: 'Peso Total',
              color: AppColors.blue,
              valueSelector: (p) => p.peso,
              deltaSelector: (p) => p.deltaPeso,
              isPositiveGood: false,
            ),
            _LineSeriesConfig(
              name: 'Massa Magra',
              color: AppColors.emerald,
              valueSelector: (p) => p.lbm,
              deltaSelector: (p) => p.deltaLbm,
              isPositiveGood: true,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Gráfico 2: Percentual de Gordura (%)
        _ChartCard(
          title: 'Percentual de Gordura (%)',
          points: chartData,
          series: [
            _LineSeriesConfig(
              name: 'Tendência de BF',
              color: const Color(0xFFCBD5E1),
              isTrend: true,
              valueSelector: (p) => p.bfTrend,
              deltaSelector: (_) => 0,
            ),
            _LineSeriesConfig(
              name: 'US Navy',
              color: AppColors.orange,
              valueSelector: (p) => p.bfNavy,
              deltaSelector: (p) => p.deltaBfNavy,
              isPositiveGood: false,
            ),
            _LineSeriesConfig(
              name: 'RFM',
              color: const Color(0xFF8B5CF6), // violet-500
              valueSelector: (p) => p.bfRfm,
              deltaSelector: (p) => p.deltaBfRfm,
              isPositiveGood: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<_ChartPoint> points;
  final List<_LineSeriesConfig> series;

  const _ChartCard({
    required this.title,
    required this.points,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final p in points) {
      for (final s in series) {
        final v = s.valueSelector(p);
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
    }

    if (!minY.isFinite) minY = 0;
    if (!maxY.isFinite) maxY = 100;
    final yMin = math.max(0.0, (minY - 2).floorToDouble());
    final yMax = (maxY + 2).ceilToDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
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
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFF1F5F9),
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
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
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
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF64748B),
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
                            deltaStr = ' ($arrow${delta.abs().toStringAsFixed(1)})';
                          }
                          return LineTooltipItem(
                            '${cfg.name}: ${spot.y.toStringAsFixed(1)}$deltaStr',
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
                    return LineChartBarData(
                      spots: points
                          .map(
                            (p) => FlSpot(
                              p.index.toDouble(),
                              cfg.valueSelector(p),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: cfg.color,
                      barWidth: cfg.isTrend ? 2 : 3,
                      dashArray: cfg.isTrend ? [4, 4] : null,
                      dotData: FlDotData(
                        show: !cfg.isTrend,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: cfg.color,
                          strokeWidth: 2,
                          strokeColor:
                              isDark ? AppColors.darkSurface : Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
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
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF64748B),
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
  final double lbm;
  final double deltaLbm;
  final double bfNavy;
  final double deltaBfNavy;
  final double bfTrend;
  final double bfRfm;
  final double deltaBfRfm;

  const _ChartPoint({
    required this.index,
    required this.dateFormatted,
    required this.peso,
    required this.deltaPeso,
    required this.pesoTrend,
    required this.lbm,
    required this.deltaLbm,
    required this.bfNavy,
    required this.deltaBfNavy,
    required this.bfTrend,
    required this.bfRfm,
    required this.deltaBfRfm,
  });
}

class _LineSeriesConfig {
  final String name;
  final Color color;
  final bool isTrend;
  final bool isPositiveGood;
  final double Function(_ChartPoint) valueSelector;
  final double Function(_ChartPoint) deltaSelector;

  const _LineSeriesConfig({
    required this.name,
    required this.color,
    this.isTrend = false,
    this.isPositiveGood = true,
    required this.valueSelector,
    required this.deltaSelector,
  });
}
