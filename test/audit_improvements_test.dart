import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/screens/main_shell/progress_overview_section.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/services/database_service.dart';
import 'package:biostats/services/photo_storage_service.dart';
import 'package:biostats/theme/app_theme.dart';
import 'package:biostats/utils/calculator.dart';
import 'package:biostats/widgets/evaluation_details_widget.dart';
import 'package:biostats/widgets/evolution_charts.dart';
import 'package:biostats/widgets/photo_comparison.dart';
import 'package:biostats/widgets/weekly_weight_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProfile = UserProfile(
    id: 'u-audit-1',
    nome: 'Rafael Teste',
    dataNascimento: DateTime(2003, 5, 10),
    sexo: Sexo.M,
    alturaCm: 181.0,
    criadoEm: DateTime(2026, 1, 1),
  );

  group('Fase 1 & 2 - Auditoria Antropométrica, Seletor de Método e Design System', () {
    test('Detecta discrepância biométrica quando IMC >= 28 e US Navy < 19%', () {
      final avaliacaoDiscrepante = Avaliacao(
        id: 'av-disc-1',
        userId: testProfile.id,
        dataAvaliacao: DateTime(2026, 10, 29),
        pesoKg: 99.8,
        nivelAtividade: 1.375,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(
          pescoco: 39.0,
          cintura: 87.0,
          quadril: 111.5,
        ),
      );

      final snap = BioCalculator.buildCalculosSnapshot(
        profile: testProfile,
        avaliacao: avaliacaoDiscrepante,
      );

      expect(snap.imc, greaterThanOrEqualTo(30.0));
      expect(snap.bfNavy, lessThan(18.0));
      expect(snap.bfDeurenberg, greaterThan(24.0));
      expect(snap.hasBiometricDiscrepancy, isTrue);
    });

    test('Permite escolher manualmente o método de BF% preferido (Deurenberg / RFM / Navy)', () {
      final avaliacao = Avaliacao(
        id: 'av-pref-1',
        userId: testProfile.id,
        dataAvaliacao: DateTime(2026, 10, 29),
        pesoKg: 99.8,
        nivelAtividade: 1.375,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(
          pescoco: 39.0,
          cintura: 87.0,
          quadril: 111.5,
        ),
      );

      final snapDeurenberg = BioCalculator.buildCalculosSnapshot(
        profile: testProfile,
        avaliacao: avaliacao,
        preferredMethod: 'deurenberg',
      );
      expect(snapDeurenberg.metodoPrincipal, equals('deurenberg'));
      expect(snapDeurenberg.bfPrincipal, equals(snapDeurenberg.bfDeurenberg));

      final snapRfm = BioCalculator.buildCalculosSnapshot(
        profile: testProfile,
        avaliacao: avaliacao,
        preferredMethod: 'rfm',
      );
      expect(snapRfm.metodoPrincipal, equals('rfm'));
      expect(snapRfm.bfPrincipal, equals(snapRfm.bfRfm));
    });

    test('AppState.setPreferredBfMethod recalcula LBM/Macros e limpa cache de IA', () async {
      SharedPreferences.setMockInitialValues({});
      DatabaseService.inMemoryAiInsights.clear();

      final appState = AppState();
      await appState.init();
      await appState.saveUserProfile(testProfile);

      final av = Avaliacao(
        id: 'av-state-1',
        userId: testProfile.id,
        dataAvaliacao: DateTime(2026, 10, 29),
        pesoKg: 99.8,
        nivelAtividade: 1.375,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(
          pescoco: 39.0,
          cintura: 87.0,
          quadril: 111.5,
        ),
      );

      final initialSnap = BioCalculator.buildCalculosSnapshot(
        profile: testProfile,
        avaliacao: av,
      );
      final initialRes = Resultados(
        id: 'res-state-1',
        avaliacaoId: av.id,
        calculos: initialSnap.toJson(),
      );

      await appState.addAvaliacao(
        avaliacao: av,
        resultado: initialRes,
        novasFotos: const [],
      );

      await DatabaseService.saveAiInsight(
        tipo: 'evaluation_summary',
        referenciaId: av.id,
        conteudoMd: 'Parecer antigo',
        modelo: 'gemini-3.8-flash',
      );

      expect(
        await DatabaseService.getAiInsight('evaluation_summary', av.id),
        isNotNull,
      );

      await appState.setPreferredBfMethod(av.id, 'deurenberg');

      final updatedRes = appState.getResultadoForAvaliacao(av.id);
      expect(updatedRes, isNotNull);
      expect(updatedRes!.snapshot.metodoPrincipal, equals('deurenberg'));
      expect(updatedRes.snapshot.bfPrincipal, closeTo(25.6, 0.5));
      expect(updatedRes.snapshot.lbmFinal, closeTo(74.2, 0.8));

      // Cache de IA da avaliação deve ter sido invalidado após mudar o método
      expect(
        await DatabaseService.getAiInsight('evaluation_summary', av.id),
        isNull,
      );
    });

    test('ThemeExtension BioThemeColors está registrada nos temas claro e escuro', () {
      final lightExt = AppTheme.lightTheme.extension<BioThemeColors>();
      final darkExt = AppTheme.darkTheme.extension<BioThemeColors>();

      expect(lightExt, isNotNull);
      expect(darkExt, isNotNull);
      expect(lightExt!.background, equals(AppColors.lightBackground));
      expect(darkExt!.background, equals(AppColors.darkBackground));
      expect(lightExt.successText.value, equals(0xFF047857));
      expect(lightExt.warningText.value, equals(0xFF9A3412));
      expect(lightExt.dangerText.value, equals(0xFFBE123C));
      expect(darkExt.successText.value, equals(0xFF34D399));
      expect(darkExt.warningText.value, equals(0xFFFB923C));
      expect(darkExt.dangerText.value, equals(0xFFFB7185));
    });

    test('ProgressOverviewSection.isWeightDeltaFavorable avalia delta conforme objetivo', () {
      expect(
        ProgressOverviewSection.isWeightDeltaFavorable(
          0.5,
          Objetivo.hipertrofia,
        ),
        isTrue,
      );
      expect(
        ProgressOverviewSection.isWeightDeltaFavorable(
          -0.5,
          Objetivo.hipertrofia,
        ),
        isFalse,
      );
      expect(
        ProgressOverviewSection.isWeightDeltaFavorable(
          -0.5,
          Objetivo.emagrecimento,
        ),
        isTrue,
      );
      expect(
        ProgressOverviewSection.isWeightDeltaFavorable(
          0.5,
          Objetivo.emagrecimento,
        ),
        isFalse,
      );
      expect(
        ProgressOverviewSection.isWeightDeltaFavorable(
          0.5,
          Objetivo.manutencao,
        ),
        isNull,
      );
      expect(
        ProgressOverviewSection.isWeightDeltaFavorable(
          0.0,
          Objetivo.emagrecimento,
        ),
        isNull,
      );
    });

    test('ProgressOverviewSection.buildWeightGoalSublabel diferencia direção e conclusão', () {
      expect(
        ProgressOverviewSection.buildWeightGoalSublabel(78.0, 75.0),
        equals('3.0 kg acima da meta'),
      );
      expect(
        ProgressOverviewSection.buildWeightGoalSublabel(72.5, 75.0),
        equals('Faltam 2.5 kg'),
      );
      expect(
        ProgressOverviewSection.buildWeightGoalSublabel(75.04, 75.0),
        equals('Meta atingida!'),
      );
    });

    testWidgets(
      'ProgressOverviewSection exibe pesagens diárias mesmo sem avaliações completas e omite Meta Calórica',
      (WidgetTester tester) async {
        await initializeDateFormatting('pt_BR');
        SharedPreferences.setMockInitialValues({});
        final appState = AppState();
        await appState.init();

        final profileWithGoal = UserProfile(
          id: 'u-resumo-1',
          nome: 'Rafael Resumo',
          dataNascimento: DateTime(2000, 1, 1),
          sexo: Sexo.M,
          alturaCm: 180.0,
          metaPesoKg: 75.0,
          criadoEm: DateTime(2026, 1, 1),
        );
        await appState.saveUserProfile(profileWithGoal);
        await appState.addPesagem(
          Pesagem(
            id: 'p-1',
            userId: profileWithGoal.id,
            data: DateTime.now(),
            pesoKg: 79.5,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ProgressOverviewSection(
                  appState: appState,
                  profile: profileWithGoal,
                  evaluations: const [],
                  onQuickWeight: () {},
                  onNewEvaluation: () {},
                  onOpenComparator: () {},
                  onNavigateToTab: (_) {},
                  onEditGoal: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('79.5'), findsOneWidget);
        expect(find.text('META DE PESO'), findsOneWidget);
        expect(find.text('4.5 kg acima da meta'), findsOneWidget);
        expect(find.text('Complete sua 1ª avaliação física'), findsOneWidget);
        expect(find.text('META CALÓRICA'), findsNothing);
        expect(find.text('GORDURA (%BF)'), findsNothing);
        expect(
          find.byKey(const ValueKey('btn_open_comparator_header')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'WeeklyWeightTracker exibe gráfico limpo, legenda binária e protege registros de avaliação no histórico',
      (WidgetTester tester) async {
        await initializeDateFormatting('pt_BR');
        SharedPreferences.setMockInitialValues({});
        final appState = AppState();
        await appState.init();

        final profile = UserProfile(
          id: 'u-pesagens-1',
          nome: 'Rafael Pesagens',
          dataNascimento: DateTime(2000, 1, 1),
          sexo: Sexo.M,
          alturaCm: 180.0,
          metaPesoKg: 75.0,
          criadoEm: DateTime(2026, 1, 1),
        );
        await appState.saveUserProfile(profile);

        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        await appState.addPesagem(
          Pesagem(
            id: 'p-manual-1',
            userId: profile.id,
            data: today,
            pesoKg: 79.0,
          ),
        );

        final av = Avaliacao(
          id: 'av-pesagens-1',
          userId: profile.id,
          dataAvaliacao: yesterday,
          pesoKg: 80.0,
          nivelAtividade: 1.375,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(
            pescoco: 38.0,
            cintura: 86.0,
          ),
        );
        final snap = BioCalculator.buildCalculosSnapshot(
          profile: profile,
          avaliacao: av,
        );
        await appState.addAvaliacao(
          avaliacao: av,
          resultado: Resultados(
            id: 'res-pesagens-1',
            avaliacaoId: av.id,
            calculos: snap.toJson(),
          ),
          syncDailyWeight: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: WeeklyWeightTracker(appState: appState),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Evolução e Tendência do Peso'), findsOneWidget);
        expect(find.textContaining('EMA α'), findsNothing);
        expect(find.text('Sem registro'), findsOneWidget);
        expect(find.text('Pesado'), findsOneWidget);
        expect(find.text('Menos'), findsNothing);

        final toggleHistory =
            find.byKey(const ValueKey('btn_toggle_weight_history'));
        await tester.ensureVisible(toggleHistory);
        await tester.tap(toggleHistory);
        await tester.pumpAndSettle();

        // Apenas a pesagem manual exibe "Excluir" e "Toque para editar";
        // o registro vindo de avaliação exibe o selo "Avaliação".
        expect(find.text('Avaliação'), findsOneWidget);
        expect(find.text('Excluir'), findsOneWidget);
        expect(find.text('Toque para editar'), findsOneWidget);
      },
    );

    testWidgets(
      'EvolutionCharts exibe CTA com 1 avaliação, remove EMA e plota método principal sem zeros',
      (WidgetTester tester) async {
        await initializeDateFormatting('pt_BR');
        final av1 = Avaliacao(
          id: 'av-evo-1',
          userId: testProfile.id,
          dataAvaliacao: DateTime(2026, 10, 1),
          pesoKg: 82.0,
          nivelAtividade: 1.375,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(),
        );
        final snap1 = BioCalculator.buildCalculosSnapshot(
          profile: testProfile,
          avaliacao: av1,
          preferredMethod: 'deurenberg',
        );
        final j1 = JoinedEvaluation(
          avaliacao: av1,
          resultado: Resultados(
            id: 'r-evo-1',
            avaliacaoId: av1.id,
            calculos: snap1.toJson(),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EvolutionCharts(
                  evaluations: [j1],
                  onNewEvaluation: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('btn_charts_new_eval')),
          findsOneWidget,
        );

        final av2 = Avaliacao(
          id: 'av-evo-2',
          userId: testProfile.id,
          dataAvaliacao: DateTime(2026, 11, 1),
          pesoKg: 80.0,
          nivelAtividade: 1.375,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(),
        );
        final snap2 = BioCalculator.buildCalculosSnapshot(
          profile: testProfile,
          avaliacao: av2,
          preferredMethod: 'deurenberg',
        );
        final j2 = JoinedEvaluation(
          avaliacao: av2,
          resultado: Resultados(
            id: 'r-evo-2',
            avaliacaoId: av2.id,
            calculos: snap2.toJson(),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EvolutionCharts(
                  evaluations: [j2, j1],
                  pesagens: [
                    Pesagem(
                      id: 'p-evo-1',
                      userId: testProfile.id,
                      data: DateTime(2026, 11, 1),
                      pesoKg: 80.0,
                    ),
                  ],
                  onNewEvaluation: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('EMA:'), findsNothing);
        expect(find.textContaining('Tendência: 80.0 kg'), findsOneWidget);
        expect(find.textContaining('Deurenberg'), findsOneWidget);
      },
    );

    testWidgets(
      'PhotoComparison exibe convite quando sem fotos e badges Antes/Depois com duas fotos',
      (WidgetTester tester) async {
        await initializeDateFormatting('pt_BR');
        final tempDir =
            Directory.systemTemp.createTempSync('biostats_photo_cmp_');
        PhotoStorageService.setOverrideDirectory(tempDir);
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        SharedPreferences.setMockInitialValues({});
        final appState = AppState();
        await appState.init();

        await appState.saveUserProfile(testProfile);

        final avOld = Avaliacao(
          id: 'av-ph-1',
          userId: testProfile.id,
          dataAvaliacao: DateTime(2026, 10, 1),
          pesoKg: 82.0,
          nivelAtividade: 1.375,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(pescoco: 39, cintura: 90),
        );
        final snapOld = BioCalculator.buildCalculosSnapshot(
          profile: testProfile,
          avaliacao: avOld,
        );
        await appState.addAvaliacao(
          avaliacao: avOld,
          resultado: Resultados(
            id: 'r-ph-1',
            avaliacaoId: avOld.id,
            calculos: snapOld.toJson(),
          ),
          syncDailyWeight: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: PhotoComparison(
                  appState: appState,
                  selectedAvaliacaoId: avOld.id,
                  onNewEvaluation: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('btn_photos_empty_add')),
          findsOneWidget,
        );

        const pngBase64 =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

        final avNew = Avaliacao(
          id: 'av-ph-2',
          userId: testProfile.id,
          dataAvaliacao: DateTime(2026, 11, 1),
          pesoKg: 79.0,
          nivelAtividade: 1.375,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(pescoco: 38, cintura: 86),
        );
        final snapNew = BioCalculator.buildCalculosSnapshot(
          profile: testProfile,
          avaliacao: avNew,
        );
        await tester.runAsync(() async {
          await appState.updateAvaliacao(
            avaliacao: avOld,
            resultado: Resultados(
              id: 'r-ph-1',
              avaliacaoId: avOld.id,
              calculos: snapOld.toJson(),
            ),
            fotosDaAvaliacao: [
              FotoAvaliacao(
                id: 'f-old',
                userId: testProfile.id,
                avaliacaoId: 'av-ph-1',
                tipo: FotoTipo.frente,
                fotoBase64: pngBase64,
                criadoEm: DateTime(2026, 10, 1),
              ),
            ],
            syncDailyWeight: false,
          );
          await appState.addAvaliacao(
            avaliacao: avNew,
            resultado: Resultados(
              id: 'r-ph-2',
              avaliacaoId: avNew.id,
              calculos: snapNew.toJson(),
            ),
            novasFotos: [
              FotoAvaliacao(
                id: 'f-new',
                userId: testProfile.id,
                avaliacaoId: 'av-ph-2',
                tipo: FotoTipo.frente,
                fotoBase64: pngBase64,
                criadoEm: DateTime(2026, 11, 1),
              ),
            ],
            syncDailyWeight: false,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: PhotoComparison(
                  appState: appState,
                  selectedAvaliacaoId: avNew.id,
                  onNewEvaluation: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DESLIZE PARA COMPARAR'), findsNothing);
        expect(
          find.text('Arraste a barra na foto para comparar'),
          findsOneWidget,
        );
        expect(find.text('FOTO ANTERIOR (ANTES)'), findsOneWidget);
        expect(find.text('FOTO POSTERIOR (DEPOIS)'), findsOneWidget);
        expect(find.textContaining('Antes •'), findsOneWidget);
        expect(find.textContaining('Depois •'), findsOneWidget);
      },
    );

    testWidgets(
      'EvaluationDetailsWidget usa rótulos claros, colapsa IBW secundário, oculta medidas vazias e adapta discrepância',
      (WidgetTester tester) async {
        await initializeDateFormatting('pt_BR');
        final av = Avaliacao(
          id: 'av-ficha-1',
          userId: testProfile.id,
          dataAvaliacao: DateTime(2026, 11, 10),
          pesoKg: 99.8,
          nivelAtividade: 1.375,
          objetivo: Objetivo.emagrecimento,
          medidas: const MedidasCorporais(
            pescoco: 39.0,
            cintura: 87.0,
            quadril: 111.5,
          ),
        );

        final snapNavy = BioCalculator.buildCalculosSnapshot(
          profile: testProfile,
          avaliacao: av,
          preferredMethod: 'navy',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EvaluationDetailsWidget(
                  profile: testProfile,
                  avaliacao: av,
                  resultado: Resultados(
                    id: 'res-ficha-1',
                    avaliacaoId: av.id,
                    calculos: snapNavy.toJson(),
                  ),
                  onSelectBfMethod: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('indica obesidade'), findsOneWidget);
        expect(find.text('Cintura / Quadril (RCQ)'), findsOneWidget);
        expect(find.text('Cintura / Altura (RCEst)'), findsOneWidget);
        expect(find.text('99.8 kg'), findsOneWidget);
        expect(find.text('-- cm'), findsNothing);
        expect(find.text('Braço'), findsNothing);

        // IBW secundário inicia recolhido
        expect(find.text('Fórmula de Devine'), findsOneWidget);
        expect(find.text('Fórmula de Robinson'), findsNothing);

        final toggleIbw =
            find.byKey(const ValueKey('btn_toggle_ibw_formulas'));
        await tester.ensureVisible(toggleIbw);
        await tester.tap(toggleIbw);
        await tester.pumpAndSettle();
        expect(find.text('Fórmula de Robinson'), findsOneWidget);

        // Quando trocado para Deurenberg, o banner muda para informativo
        final snapDeurenberg = BioCalculator.buildCalculosSnapshot(
          profile: testProfile,
          avaliacao: av,
          preferredMethod: 'deurenberg',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EvaluationDetailsWidget(
                  profile: testProfile,
                  avaliacao: av,
                  resultado: Resultados(
                    id: 'res-ficha-1',
                    avaliacaoId: av.id,
                    calculos: snapDeurenberg.toJson(),
                  ),
                  onSelectBfMethod: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Referência ajustada:'), findsOneWidget);
        expect(find.textContaining('Discrepância detectada:'), findsNothing);
      },
    );
  });
}
