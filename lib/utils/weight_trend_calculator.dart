import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'calculator.dart';

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

  /// Resolve o estado unificado do peso consolidando pesagens diárias e avaliações.
  static WeightContext resolveWeightContext({
    required List<Pesagem> pesagens,
    required List<Avaliacao> avaliacoes,
    DateTime? now,
    double alpha = 0.1,
  }) {
    if (pesagens.isEmpty && avaliacoes.isEmpty) {
      return WeightContext.empty;
    }

    final currentNow = now ?? DateTime.now();
    final today = DateTime(currentNow.year, currentNow.month, currentNow.day);

    // Linha do tempo unificada (uma entrada por dia: 'YYYY-MM-DD')
    final Map<String, ({DateTime date, double weight, bool isAvaliacao})> timeline = {};

    // 1. Registra avaliações completas
    for (final av in avaliacoes) {
      final d = DateTime(av.dataAvaliacao.year, av.dataAvaliacao.month, av.dataAvaliacao.day);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      timeline[key] = (date: d, weight: av.pesoKg, isAvaliacao: true);
    }

    // 2. Registra pesagens diárias (se no mesmo dia e peso for idêntico, preserva isAvaliacao; se for nova pesagem do dia, sobrepõe)
    for (final p in pesagens) {
      final d = DateTime(p.data.year, p.data.month, p.data.day);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final existing = timeline[key];
      final isAvaliacao = existing != null && existing.isAvaliacao && existing.weight == p.pesoKg;
      timeline[key] = (date: d, weight: p.pesoKg, isAvaliacao: isAvaliacao);
    }

    final sortedEntries = timeline.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedEntries.isEmpty) {
      return WeightContext.empty;
    }

    final latestEntry = sortedEntries.last;
    final currentWeight = latestEntry.weight;
    final currentDate = latestEntry.date;
    final source = latestEntry.isAvaliacao
        ? WeightSource.avaliacaoCompleta
        : WeightSource.pesagemDiaria;

    // Delta em relação à entrada imediatamente anterior
    double? deltaFromPrevious;
    if (sortedEntries.length >= 2) {
      deltaFromPrevious = currentWeight - sortedEntries[sortedEntries.length - 2].weight;
    }

    // Série cronológica unificada para cálculo de EMA
    final unifiedPesagens = sortedEntries
        .map((e) => Pesagem(
              id: 'unified_${e.date.millisecondsSinceEpoch}',
              userId: 'unified',
              data: e.date,
              pesoKg: e.weight,
            ))
        .toList();

    final emaPoints = computeEma(unifiedPesagens, alpha: alpha);
    final emaWeight = emaPoints.isNotEmpty ? emaPoints.last.emaWeight : currentWeight;

    // Médias Semanais (janela dos últimos 7 dias e 7 dias anteriores)
    final cutoffCurrentWeek = today.subtract(const Duration(days: 7));
    final cutoffPrevWeek = today.subtract(const Duration(days: 14));

    final currentWeekWeights = sortedEntries
        .where((e) => !e.date.isBefore(cutoffCurrentWeek) && !e.date.isAfter(today.add(const Duration(days: 1))))
        .map((e) => e.weight)
        .toList();

    final prevWeekWeights = sortedEntries
        .where((e) => !e.date.isBefore(cutoffPrevWeek) && e.date.isBefore(cutoffCurrentWeek))
        .map((e) => e.weight)
        .toList();

    double? weeklyAverage;
    if (currentWeekWeights.isNotEmpty) {
      weeklyAverage = currentWeekWeights.reduce((a, b) => a + b) / currentWeekWeights.length;
    }

    double? previousWeeklyAverage;
    if (prevWeekWeights.isNotEmpty) {
      previousWeeklyAverage = prevWeekWeights.reduce((a, b) => a + b) / prevWeekWeights.length;
    }

    double? weeklyDelta;
    if (weeklyAverage != null && previousWeeklyAverage != null) {
      weeklyDelta = weeklyAverage - previousWeeklyAverage;
    }

    // Rótulo amigável da origem
    final entryDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final diffDays = today.difference(entryDay).inDays;
    final String sourceLabel;
    if (diffDays == 0) {
      sourceLabel = source == WeightSource.pesagemDiaria ? 'Pesado hoje' : 'Avaliado hoje';
    } else if (diffDays == 1) {
      sourceLabel = source == WeightSource.pesagemDiaria ? 'Pesado ontem' : 'Avaliado ontem';
    } else if (diffDays > 1 && diffDays < 7) {
      sourceLabel = source == WeightSource.pesagemDiaria ? 'Pesado há $diffDays dias' : 'Avaliado há $diffDays dias';
    } else {
      final dateFmt = DateFormat('dd/MM');
      sourceLabel = source == WeightSource.pesagemDiaria
          ? 'Pesagem em ${dateFmt.format(currentDate)}'
          : 'Avaliação em ${dateFmt.format(currentDate)}';
    }

    return WeightContext(
      currentWeight: currentWeight,
      currentDate: currentDate,
      source: source,
      emaWeight: emaWeight,
      deltaFromPrevious: deltaFromPrevious,
      weeklyAverage: weeklyAverage,
      previousWeeklyAverage: previousWeeklyAverage,
      weeklyDelta: weeklyDelta,
      sourceLabel: sourceLabel,
      hasData: true,
    );
  }

  /// Calcula o metabolismo dinâmico em tempo real ancorando a composição da última avaliação ao peso atual.
  static LiveMetabolism? computeLiveMetabolism({
    required UserProfile profile,
    required WeightContext weightContext,
    JoinedEvaluation? latestEvaluation,
  }) {
    if (!weightContext.hasData || weightContext.currentWeight <= 0) {
      return null;
    }

    final weight = weightContext.currentWeight;
    final emaWeight = weightContext.emaWeight;

    // Obtém o %BF da avaliação física como âncora
    double bfPct = 0.0;
    String bfMethod = 'none';
    final snap = latestEvaluation?.resultado?.snapshot;
    if (snap != null && snap.bfPrincipal > 0) {
      bfPct = snap.bfPrincipal;
      bfMethod = snap.metodoPrincipal;
    } else {
      final idade = profile.idade;
      bfPct = BioCalculator.calculateDeurenbergBF(profile.sexo, weight, profile.alturaCm, idade);
      bfMethod = 'deurenberg';
    }

    if (bfPct < 3.0) bfPct = 3.0;
    if (bfPct > 65.0) bfPct = 65.0;

    final fatKg = BioCalculator.round2(weight * (bfPct / 100.0));
    final lbmKg = BioCalculator.round2(weight - fatKg);

    final bmr = BioCalculator.calculateKatchMcArdleBMR(lbmKg);
    final nivelAtividade = latestEvaluation?.avaliacao.nivelAtividade ?? 1.375;
    final tdee = BioCalculator.calculateTDEE(bmr, nivelAtividade);

    final objetivo = latestEvaluation?.avaliacao.objetivo ?? Objetivo.manutencao;

    final macros = BioCalculator.calculateMacrosAndGoals(
      tdee,
      objetivo,
      sexo: profile.sexo,
      pesoKg: weight,
      lbmKg: lbmKg,
    );

    return LiveMetabolism(
      weightUsed: weight,
      emaWeightUsed: emaWeight,
      bfPctUsed: bfPct,
      bfMethod: bfMethod,
      lbmKg: lbmKg,
      fatKg: fatKg,
      bmr: bmr,
      tdee: tdee,
      targetCalories: macros.targetCalories,
      macros: macros,
      objetivo: objetivo,
    );
  }
}

enum WeightSource {
  pesagemDiaria,
  avaliacaoCompleta,
  nenhum;

  String get label {
    switch (this) {
      case WeightSource.pesagemDiaria:
        return 'Pesagem diária';
      case WeightSource.avaliacaoCompleta:
        return 'Avaliação física';
      case WeightSource.nenhum:
        return 'Sem registros';
    }
  }
}

class WeightContext {
  final double currentWeight;
  final DateTime? currentDate;
  final WeightSource source;
  final double? emaWeight;
  final double? deltaFromPrevious;
  final double? weeklyAverage;
  final double? previousWeeklyAverage;
  final double? weeklyDelta;
  final String sourceLabel;
  final bool hasData;

  const WeightContext({
    required this.currentWeight,
    this.currentDate,
    required this.source,
    this.emaWeight,
    this.deltaFromPrevious,
    this.weeklyAverage,
    this.previousWeeklyAverage,
    this.weeklyDelta,
    required this.sourceLabel,
    required this.hasData,
  });

  static const empty = WeightContext(
    currentWeight: 0.0,
    source: WeightSource.nenhum,
    sourceLabel: 'Sem registros',
    hasData: false,
  );
}

class LiveMetabolism {
  final double weightUsed;
  final double? emaWeightUsed;
  final double bfPctUsed;
  final String bfMethod;
  final double lbmKg;
  final double fatKg;
  final double bmr;
  final double tdee;
  final double targetCalories;
  final MacrosAndGoalsResult macros;
  final Objetivo objetivo;

  const LiveMetabolism({
    required this.weightUsed,
    this.emaWeightUsed,
    required this.bfPctUsed,
    required this.bfMethod,
    required this.lbmKg,
    required this.fatKg,
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.macros,
    required this.objetivo,
  });
}
