import 'package:flutter_test/flutter_test.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/utils/calculator.dart';
import 'package:biostats/utils/weight_trend_calculator.dart';

void main() {
  group('Unificação de Pesos e Métricas (Fase 8)', () {
    final now = DateTime(2026, 10, 29, 8, 0);

    final mockProfile = UserProfile(
      id: 'user_test',
      nome: 'Rafael',
      dataNascimento: DateTime(1994, 5, 20),
      sexo: Sexo.M,
      alturaCm: 178,
      metaPesoKg: 75.0,
      metaBfPct: 12.0,
      criadoEm: DateTime(2026, 1, 1),
    );

    test('Lista vazia retorna WeightContext.empty', () {
      final ctx = WeightTrendCalculator.resolveWeightContext(
        pesagens: [],
        avaliacoes: [],
        now: now,
      );

      expect(ctx.hasData, isFalse);
      expect(ctx.currentWeight, 0.0);
      expect(ctx.source, WeightSource.nenhum);
      expect(ctx.sourceLabel, 'Sem registros');
    });

    test('Consolida quando existem apenas pesagens diárias', () {
      final pesagens = [
        Pesagem(
          id: 'p1',
          userId: 'user_test',
          data: DateTime(2026, 10, 27),
          pesoKg: 80.0,
        ),
        Pesagem(
          id: 'p2',
          userId: 'user_test',
          data: DateTime(2026, 10, 28),
          pesoKg: 79.4,
        ),
        Pesagem(
          id: 'p3',
          userId: 'user_test',
          data: DateTime(2026, 10, 29),
          pesoKg: 79.0,
        ),
      ];

      final ctx = WeightTrendCalculator.resolveWeightContext(
        pesagens: pesagens,
        avaliacoes: [],
        now: now,
      );

      expect(ctx.hasData, isTrue);
      expect(ctx.currentWeight, 79.0);
      expect(ctx.source, WeightSource.pesagemDiaria);
      expect(ctx.sourceLabel, 'Pesado hoje');
      expect(ctx.deltaFromPrevious, closeTo(-0.4, 0.001));
      expect(ctx.emaWeight, isNotNull);
      expect(ctx.emaWeight!, lessThan(80.0));
    });

    test('Consolida quando avaliação é mais recente que pesagens antigas', () {
      final pesagens = [
        Pesagem(
          id: 'p1',
          userId: 'user_test',
          data: DateTime(2026, 10, 20),
          pesoKg: 82.0,
        ),
      ];

      final avaliacoes = [
        Avaliacao(
          id: 'av1',
          userId: 'user_test',
          dataAvaliacao: DateTime(2026, 10, 28),
          pesoKg: 80.5,
          nivelAtividade: 1.55,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(cintura: 86, pescoco: 38),
        ),
      ];

      final ctx = WeightTrendCalculator.resolveWeightContext(
        pesagens: pesagens,
        avaliacoes: avaliacoes,
        now: now,
      );

      expect(ctx.hasData, isTrue);
      expect(ctx.currentWeight, 80.5);
      expect(ctx.source, WeightSource.avaliacaoCompleta);
      expect(ctx.sourceLabel, 'Avaliado ontem');
      expect(ctx.deltaFromPrevious, closeTo(-1.5, 0.001));
    });

    test('Pesagem diária de hoje prevalece sobre avaliação de semanas atrás', () {
      final avaliacoes = [
        Avaliacao(
          id: 'av1',
          userId: 'user_test',
          dataAvaliacao: DateTime(2026, 10, 15),
          pesoKg: 81.0,
          nivelAtividade: 1.55,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(cintura: 88, pescoco: 38),
        ),
      ];

      final pesagens = [
        Pesagem(
          id: 'p1',
          userId: 'user_test',
          data: DateTime(2026, 10, 29),
          pesoKg: 78.5,
        ),
      ];

      final ctx = WeightTrendCalculator.resolveWeightContext(
        pesagens: pesagens,
        avaliacoes: avaliacoes,
        now: now,
      );

      expect(ctx.hasData, isTrue);
      expect(ctx.currentWeight, 78.5);
      expect(ctx.source, WeightSource.pesagemDiaria);
      expect(ctx.sourceLabel, 'Pesado hoje');
      expect(ctx.deltaFromPrevious, closeTo(-2.5, 0.001));
    });

    test('Cálculo de LiveMetabolism com âncora de %BF da última avaliação', () {
      final avaliacao = Avaliacao(
        id: 'av1',
        userId: 'user_test',
        dataAvaliacao: DateTime(2026, 10, 15),
        pesoKg: 80.0,
        nivelAtividade: 1.55,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(cintura: 86, pescoco: 38),
      );

      final snap = BioCalculator.buildCalculosSnapshot(
        profile: mockProfile,
        avaliacao: avaliacao,
      );

      final joined = JoinedEvaluation(
        avaliacao: avaliacao,
        resultado: Resultados(
          id: 'res1',
          avaliacaoId: 'av1',
          calculos: snap.toJson(),
        ),
      );

      // Usuário agora pesa 76.0 kg na pesagem de hoje (perdeu 4kg)
      const weightCtx = WeightContext(
        currentWeight: 76.0,
        source: WeightSource.pesagemDiaria,
        sourceLabel: 'Pesado hoje',
        hasData: true,
        emaWeight: 76.5,
      );

      final live = WeightTrendCalculator.computeLiveMetabolism(
        profile: mockProfile,
        weightContext: weightCtx,
        latestEvaluation: joined,
      );

      expect(live, isNotNull);
      expect(live!.weightUsed, 76.0);
      expect(live.bfPctUsed, closeTo(snap.bfPrincipal, 0.01));
      expect(live.lbmKg, closeTo(76.0 * (1.0 - snap.bfPrincipal / 100.0), 0.1));
      expect(live.fatKg, closeTo(76.0 * (snap.bfPrincipal / 100.0), 0.1));
      expect(live.bmr, closeTo(370 + 21.6 * live.lbmKg, 0.1));
      expect(live.tdee, closeTo(live.bmr * 1.55, 0.1));
      expect(live.targetCalories, closeTo(live.tdee - 500, 0.1)); // Déficit de 500 kcal
      expect(live.macros.targetCalories, live.targetCalories);
    });

    test('LiveMetabolism fallback com fórmula de Deurenberg quando sem avaliações', () {
      const weightCtx = WeightContext(
        currentWeight: 80.0,
        source: WeightSource.pesagemDiaria,
        sourceLabel: 'Pesado hoje',
        hasData: true,
      );

      final live = WeightTrendCalculator.computeLiveMetabolism(
        profile: mockProfile,
        weightContext: weightCtx,
        latestEvaluation: null, // Sem avaliações
      );

      expect(live, isNotNull);
      expect(live!.weightUsed, 80.0);
      expect(live.bfMethod, 'deurenberg');
      expect(live.bfPctUsed, greaterThan(10.0));
      expect(live.lbmKg, greaterThan(50.0));
      expect(live.targetCalories, greaterThan(1500.0));
    });
  });
}
