import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/screens/main_shell/progress_overview_section.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/services/database_service.dart';
import 'package:biostats/theme/app_theme.dart';
import 'package:biostats/utils/calculator.dart';

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
      expect(lightExt.warningText.value, equals(0xFFC2410C));
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
  });
}
