import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/models.dart';

enum TrendDirection {
  losing,
  gaining,
  stable,
  diverging,
  insufficientData,
}

class WeightPoint {
  final DateTime date;
  final double rawWeight;
  final double emaWeight;

  const WeightPoint({
    required this.date,
    required this.rawWeight,
    required this.emaWeight,
  });
}

class WeightProjectionResult {
  final double? currentWeight;
  final double? currentEma;
  final double? slopePerDay; // kg por dia
  final double? ratePerWeek; // kg por semana (slope * 7)
  final double? metaPesoKg;
  final DateTime? projectedDate;
  final int? daysRemaining;
  final TrendDirection direction;
  final String message;
  final String detailMessage;

  const WeightProjectionResult({
    this.currentWeight,
    this.currentEma,
    this.slopePerDay,
    this.ratePerWeek,
    this.metaPesoKg,
    this.projectedDate,
    this.daysRemaining,
    required this.direction,
    required this.message,
    required this.detailMessage,
  });
}

class WeightTrendCalculator {
  /// Calcula os pontos com Exponential Moving Average (EMA) com alpha padrão = 0.1
  static List<WeightPoint> computeEma(
    List<Pesagem> pesagens, {
    double alpha = 0.1,
  }) {
    if (pesagens.isEmpty) return const [];

    // Garante ordenação cronológica crescente (antiga -> recente)
    final sorted = [...pesagens]..sort((a, b) => a.data.compareTo(b.data));

    final List<WeightPoint> points = [];
    double ema = sorted.first.pesoKg;

    for (int i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      if (i == 0) {
        ema = p.pesoKg;
      } else {
        ema = (alpha * p.pesoKg) + ((1.0 - alpha) * ema);
      }
      points.add(WeightPoint(
        date: p.data,
        rawWeight: p.pesoKg,
        emaWeight: ema,
      ));
    }

    return points;
  }

  /// Calcula a regressão linear das últimas 4 semanas (28 dias) e projeta a meta
  static WeightProjectionResult computeProjection({
    required List<Pesagem> pesagens,
    required double? metaPesoKg,
    DateTime? referenceDate,
    double alpha = 0.1,
    int daysWindow = 28,
  }) {
    if (pesagens.isEmpty) {
      return const WeightProjectionResult(
        direction: TrendDirection.insufficientData,
        message: 'Sem pesagens registradas',
        detailMessage: 'Adicione pesagens diárias para projetar a tendência.',
      );
    }

    final points = computeEma(pesagens, alpha: alpha);
    final ref = referenceDate ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final cutoff = today.subtract(Duration(days: daysWindow));

    // Filtrar pontos dentro da janela dos últimos 28 dias
    final windowPoints = points.where((pt) {
      final d = DateTime(pt.date.year, pt.date.month, pt.date.day);
      return !d.isBefore(cutoff) && !d.isAfter(today.add(const Duration(days: 1)));
    }).toList();

    // Se houver menos de 2 pesagens na janela, tenta usar os últimos pontos se houver >= 2
    final ptsForRegression = windowPoints.length >= 2
        ? windowPoints
        : (points.length >= 2 ? points.sublist(math.max(0, points.length - 10)) : <WeightPoint>[]);

    if (ptsForRegression.length < 2) {
      final latest = points.last;
      return WeightProjectionResult(
        currentWeight: latest.rawWeight,
        currentEma: latest.emaWeight,
        metaPesoKg: metaPesoKg,
        direction: TrendDirection.insufficientData,
        message: 'Dados insuficientes para projeção',
        detailMessage: 'Registre pesagens com frequência para projetar seu ritmo.',
      );
    }

    // Regressão Linear por mínimos quadrados
    // x = dias a partir da primeira pesagem da janela
    final baseDate = ptsForRegression.first.date;
    final int n = ptsForRegression.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (final pt in ptsForRegression) {
      final x = pt.date.difference(baseDate).inHours / 24.0;
      final y = pt.emaWeight; // usamos EMA para absorver flutuações diárias de líquidos
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator.abs() < 1e-6) {
      final latest = points.last;
      return WeightProjectionResult(
        currentWeight: latest.rawWeight,
        currentEma: latest.emaWeight,
        metaPesoKg: metaPesoKg,
        direction: TrendDirection.stable,
        message: 'Peso estável',
        detailMessage: 'Variação mínima registrada no período.',
      );
    }

    final slopePerDay = ((n * sumXY) - (sumX * sumY)) / denominator; // kg por dia
    final ratePerWeek = slopePerDay * 7.0; // kg por semana

    final currentWeight = points.last.rawWeight;
    final currentEma = points.last.emaWeight;

    // Se o usuário não tem meta definida:
    if (metaPesoKg == null || metaPesoKg <= 0) {
      final rateFmt = ratePerWeek.abs().toStringAsFixed(2);
      final dir = ratePerWeek > 0.05
          ? TrendDirection.gaining
          : (ratePerWeek < -0.05 ? TrendDirection.losing : TrendDirection.stable);
      final rateStr = ratePerWeek > 0.05
          ? '+$rateFmt kg/sem'
          : (ratePerWeek < -0.05 ? '-$rateFmt kg/sem' : '±0.0 kg/sem');

      return WeightProjectionResult(
        currentWeight: currentWeight,
        currentEma: currentEma,
        slopePerDay: slopePerDay,
        ratePerWeek: ratePerWeek,
        direction: dir,
        message: 'Ritmo: $rateStr nas últimas 4 semanas',
        detailMessage: 'Defina uma meta de peso em Ajustes para ver a data prevista.',
      );
    }

    final delta = metaPesoKg - currentEma;

    // Se já atingiu a meta (margem de 200g)
    if (delta.abs() <= 0.2) {
      return WeightProjectionResult(
        currentWeight: currentWeight,
        currentEma: currentEma,
        slopePerDay: slopePerDay,
        ratePerWeek: ratePerWeek,
        metaPesoKg: metaPesoKg,
        direction: TrendDirection.stable,
        message: 'Meta de ${metaPesoKg.toStringAsFixed(1)} kg atingida!',
        detailMessage: 'Parabéns! Mantenha a consistência na sua rotina.',
      );
    }

    final dateFmt = DateFormat('dd/MM');
    final rateFmt = ratePerWeek.abs().toStringAsFixed(2);

    if (delta < 0) {
      // Objetivo: Emagrecimento (perder peso)
      if (slopePerDay < -0.01) {
        // Está perdendo peso de acordo com a meta
        final days = (delta / slopePerDay).round();
        final projected = today.add(Duration(days: days));
        return WeightProjectionResult(
          currentWeight: currentWeight,
          currentEma: currentEma,
          slopePerDay: slopePerDay,
          ratePerWeek: ratePerWeek,
          metaPesoKg: metaPesoKg,
          projectedDate: projected,
          daysRemaining: days,
          direction: TrendDirection.losing,
          message: 'Meta de ${metaPesoKg.toStringAsFixed(1)} kg prevista para ~${dateFmt.format(projected)}',
          detailMessage: 'Ritmo atual: -$rateFmt kg/semana (~$days dias restantes)',
        );
      } else if (slopePerDay > 0.02) {
        return WeightProjectionResult(
          currentWeight: currentWeight,
          currentEma: currentEma,
          slopePerDay: slopePerDay,
          ratePerWeek: ratePerWeek,
          metaPesoKg: metaPesoKg,
          direction: TrendDirection.diverging,
          message: 'Tendência em alta (+$rateFmt kg/sem)',
          detailMessage: 'Divergindo da meta de perda (${metaPesoKg.toStringAsFixed(1)} kg). Ajuste seu plano calórico.',
        );
      } else {
        return WeightProjectionResult(
          currentWeight: currentWeight,
          currentEma: currentEma,
          slopePerDay: slopePerDay,
          ratePerWeek: ratePerWeek,
          metaPesoKg: metaPesoKg,
          direction: TrendDirection.stable,
          message: 'Tendência estável nas últimas 4 semanas',
          detailMessage: 'Meta: ${metaPesoKg.toStringAsFixed(1)} kg (falta ${delta.abs().toStringAsFixed(1)} kg). Aumente o déficit para retomar a perda.',
        );
      }
    } else {
      // Objetivo: Ganho de Peso / Hipertrofia
      if (slopePerDay > 0.01) {
        // Está ganhando peso de acordo com a meta
        final days = (delta / slopePerDay).round();
        final projected = today.add(Duration(days: days));
        return WeightProjectionResult(
          currentWeight: currentWeight,
          currentEma: currentEma,
          slopePerDay: slopePerDay,
          ratePerWeek: ratePerWeek,
          metaPesoKg: metaPesoKg,
          projectedDate: projected,
          daysRemaining: days,
          direction: TrendDirection.gaining,
          message: 'Meta de ${metaPesoKg.toStringAsFixed(1)} kg prevista para ~${dateFmt.format(projected)}',
          detailMessage: 'Ritmo atual: +$rateFmt kg/semana (~$days dias restantes)',
        );
      } else if (slopePerDay < -0.02) {
        return WeightProjectionResult(
          currentWeight: currentWeight,
          currentEma: currentEma,
          slopePerDay: slopePerDay,
          ratePerWeek: ratePerWeek,
          metaPesoKg: metaPesoKg,
          direction: TrendDirection.diverging,
          message: 'Tendência em queda (-$rateFmt kg/sem)',
          detailMessage: 'Divergindo da meta de ganho (${metaPesoKg.toStringAsFixed(1)} kg). Aumente a ingestão de calorias/proteínas.',
        );
      } else {
        return WeightProjectionResult(
          currentWeight: currentWeight,
          currentEma: currentEma,
          slopePerDay: slopePerDay,
          ratePerWeek: ratePerWeek,
          metaPesoKg: metaPesoKg,
          direction: TrendDirection.stable,
          message: 'Tendência estável nas últimas 4 semanas',
          detailMessage: 'Meta: ${metaPesoKg.toStringAsFixed(1)} kg (falta ${delta.toStringAsFixed(1)} kg). Aumente o superávit para retomar o ganho.',
        );
      }
    }
  }
}
