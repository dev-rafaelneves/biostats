import 'package:biostats/models/models.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/services/notification_service.dart';
import 'package:biostats/utils/weight_trend_calculator.dart';
import 'package:biostats/widgets/consistency_heatmap.dart';
import 'package:biostats/widgets/measurement_guide_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('Fase 6 — Funcionalidades Rápidas', () {
    // -------------------------------------------------------------------------
    // 1. Tendência do Peso (EMA α=0.1)
    // -------------------------------------------------------------------------
    test('EMA (α=0.1) — Cálculo matemático exato da média móvel exponencial', () {
      final pesagens = [
        Pesagem(
          id: 'p1',
          userId: 'u1',
          data: DateTime(2026, 10, 1),
          pesoKg: 80.0,
        ),
        Pesagem(
          id: 'p2',
          userId: 'u1',
          data: DateTime(2026, 10, 2),
          pesoKg: 81.0,
        ),
        Pesagem(
          id: 'p3',
          userId: 'u1',
          data: DateTime(2026, 10, 3),
          pesoKg: 79.0,
        ),
      ];

      final points = WeightTrendCalculator.computeEma(pesagens, alpha: 0.1);
      expect(points.length, 3);

      // P0: EMA = 80.0
      expect(points[0].rawWeight, 80.0);
      expect(points[0].emaWeight, 80.0);

      // P1: EMA = 0.1 * 81.0 + 0.9 * 80.0 = 8.1 + 72.0 = 80.1
      expect(points[1].rawWeight, 81.0);
      expect(points[1].emaWeight, closeTo(80.1, 0.001));

      // P2: EMA = 0.1 * 79.0 + 0.9 * 80.1 = 7.9 + 72.09 = 79.99
      expect(points[2].rawWeight, 79.0);
      expect(points[2].emaWeight, closeTo(79.99, 0.001));
    });

    // -------------------------------------------------------------------------
    // 2. Projeção de Meta por Regressão Linear (Últimas 4 Semanas)
    // -------------------------------------------------------------------------
    test('Projeção de Meta — Emagrecimento previsto com data estimada', () {
      // 28 dias perdendo 0.1 kg/dia (~0.7 kg/semana)
      final refDate = DateTime(2026, 10, 28);
      final pesagens = <Pesagem>[];

      for (int i = 27; i >= 0; i--) {
        final d = refDate.subtract(Duration(days: i));
        // peso começando em 82.7 kg até 80.0 kg
        final peso = 80.0 + (i * 0.1);
        pesagens.add(Pesagem(
          id: 'p_$i',
          userId: 'u1',
          data: d,
          pesoKg: peso,
        ));
      }

      final proj = WeightTrendCalculator.computeProjection(
        pesagens: pesagens,
        metaPesoKg: 78.0,
        referenceDate: refDate,
      );

      expect(proj.direction, TrendDirection.losing);
      expect(proj.projectedDate, isNotNull);
      expect(proj.daysRemaining, isNotNull);
      expect(proj.daysRemaining! > 0, isTrue);
      expect(proj.message.contains('Meta de 78.0 kg prevista'), isTrue);
      expect(proj.detailMessage.contains('kg/semana'), isTrue);
    });

    test('Projeção de Meta — Alerta de divergência quando peso sobe em meta de emagrecimento', () {
      final refDate = DateTime(2026, 10, 28);
      final pesagens = <Pesagem>[];

      for (int i = 27; i >= 0; i--) {
        final d = refDate.subtract(Duration(days: i));
        // peso subindo de 78.0 para 80.0 kg
        final peso = 80.0 - (i * 0.08);
        pesagens.add(Pesagem(
          id: 'p_$i',
          userId: 'u1',
          data: d,
          pesoKg: peso,
        ));
      }

      final proj = WeightTrendCalculator.computeProjection(
        pesagens: pesagens,
        metaPesoKg: 75.0, // meta de perda, mas peso está subindo
        referenceDate: refDate,
      );

      expect(proj.direction, TrendDirection.diverging);
      expect(proj.message.contains('Tendência em alta'), isTrue);
      expect(proj.detailMessage.contains('Divergindo da meta de perda'), isTrue);
    });

    // -------------------------------------------------------------------------
    // 3. Heatmap de Consistência e Sequência (Streak)
    // -------------------------------------------------------------------------
    testWidgets('Heatmap — Sequência diária ativa e renderização das 12 semanas', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Simula 5 dias consecutivos de pesagem até hoje
      final pesagens = List.generate(5, (idx) {
        return Pesagem(
          id: 'streak_$idx',
          userId: 'u1',
          data: today.subtract(Duration(days: idx)),
          pesoKg: 75.0 + (idx * 0.1),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConsistencyHeatmap(pesagens: pesagens),
            ),
          ),
        ),
      );

      expect(find.text('Consistência (12 Semanas)'), findsOneWidget);
      expect(find.text('🔥 5 dias'), findsOneWidget);
      expect(find.textContaining('5 de'), findsOneWidget);
      expect(find.textContaining('registrados'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 4. Guia Anatômico de Medição com Silhueta Vetorial (CustomPaint)
    // -------------------------------------------------------------------------
    test('Guia Anatômico — Metadados e passos completos para todos os pontos anatômicos', () {
      for (final type in MeasurementGuideType.values) {
        final info = MeasurementGuideInfo.get(type);
        expect(info.title.isNotEmpty, isTrue);
        expect(info.targetFormula.isNotEmpty, isTrue);
        expect(info.explanation.isNotEmpty, isTrue);
        expect(info.steps.length >= 3, isTrue);
        expect(info.highlightY >= 0.0 && info.highlightY <= 1.0, isTrue);
      }
    });

    testWidgets('Guia Anatômico Modal — Exibição e fechamento suave', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MeasurementGuideModal.show(
                  ctx,
                  MeasurementGuideType.pescoco,
                ),
                child: const Text('Abrir Guia'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guia'));
      await tester.pumpAndSettle();

      expect(find.text('Circunferência do Pescoço'), findsOneWidget);
      expect(find.textContaining('US Navy'), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Entendi, continuar'), findsOneWidget);

      await tester.tap(find.text('Entendi, continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Circunferência do Pescoço'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 5. Lembretes e Notificações (NotificationService + AppState)
    // -------------------------------------------------------------------------
    test('Lembretes — Atualização de configurações no AppState', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      expect(appState.dailyWeightReminderEnabled, isFalse);
      expect(appState.weeklyEvalReminderEnabled, isFalse);

      // Ativa pesagem matinal às 06:45
      await appState.updateDailyWeightReminder(
        enabled: true,
        hour: 6,
        minute: 45,
      );

      expect(appState.dailyWeightReminderEnabled, isTrue);
      expect(appState.dailyWeightReminderHour, 6);
      expect(appState.dailyWeightReminderMinute, 45);

      // Ativa avaliação semanal no Domingo (7) às 08:30
      await appState.updateWeeklyEvalReminder(
        enabled: true,
        weekday: 7,
        hour: 8,
        minute: 30,
      );

      expect(appState.weeklyEvalReminderEnabled, isTrue);
      expect(appState.weeklyEvalReminderWeekday, 7);
      expect(appState.weeklyEvalReminderHour, 8);
      expect(appState.weeklyEvalReminderMinute, 30);

      // Desativa
      await appState.updateDailyWeightReminder(enabled: false);
      expect(appState.dailyWeightReminderEnabled, isFalse);
    });

    test('NotificationService — Execução em ambiente de testes não quebra nem trava', () async {
      expect(NotificationService.isTestEnvironment, isTrue);
      await NotificationService.instance.init();
      final granted = await NotificationService.instance.requestPermissions();
      expect(granted, isTrue);

      await NotificationService.instance.scheduleDailyWeightReminder(
        enabled: true,
        hour: 7,
        minute: 0,
      );

      await NotificationService.instance.scheduleWeeklyEvaluationReminder(
        enabled: true,
        weekday: 7,
        hour: 9,
        minute: 0,
      );
    });
  });
}
