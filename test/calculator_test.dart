import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/utils/calculator.dart';
import 'package:biostats/utils/report_pdf_generator.dart';

void main() {
  group('BioCalculator - Motor Matemático Científico', () {
    test('US Navy Body Fat Formula (Homem, Mulher e bordas)', () {
      expect(
        BioCalculator.calculateUSNavyBF(Sexo.M, 178, 38, 86),
        closeTo(17.2, 0.1),
      );
      expect(
        BioCalculator.calculateUSNavyBF(Sexo.F, 165, 34, 70, 95),
        closeTo(23.82, 0.1),
      );
      expect(BioCalculator.calculateUSNavyBF(Sexo.M, 0, 38, 86), 0);
      expect(BioCalculator.calculateUSNavyBF(Sexo.M, -10, 38, 86), 0);
      expect(BioCalculator.calculateUSNavyBF(Sexo.F, 165, 34, 70, 0), 0);
      expect(BioCalculator.calculateUSNavyBF(Sexo.M, 178, 90, 80), 0);
    });

    test('Relative Fat Mass (RFM)', () {
      expect(BioCalculator.calculateRFM(Sexo.M, 178, 86), 22.6);
      expect(BioCalculator.calculateRFM(Sexo.F, 165, 70), 28.86);
      expect(BioCalculator.calculateRFM(Sexo.M, 178, 0), 0);
      expect(BioCalculator.calculateRFM(Sexo.F, 178, -5), 0);
    });

    test('Boer Lean Body Mass (LBM)', () {
      expect(BioCalculator.calculateBoerLBM(Sexo.M, 80, 180), 61.42);
      expect(BioCalculator.calculateBoerLBM(Sexo.F, 65, 165), 46.13);
    });

    test('Katch-McArdle BMR & TDEE', () {
      expect(BioCalculator.calculateKatchMcArdleBMR(60), 1666);
      expect(BioCalculator.calculateKatchMcArdleBMR(0), 0);
      expect(BioCalculator.calculateTDEE(1666, 1.55), 2582.3);
      expect(BioCalculator.calculateTDEE(0, 1.2), 0);
    });

    test('Fórmula Deurenberg (Baseada no IMC)', () {
      expect(
        BioCalculator.calculateDeurenbergBF(Sexo.M, 80, 178, 30),
        closeTo(21.0, 0.1),
      );
      expect(
        BioCalculator.calculateDeurenbergBF(Sexo.F, 65, 165, 28),
        closeTo(29.68, 0.1),
      );
      expect(BioCalculator.calculateDeurenbergBF(Sexo.M, 0, 178, 30), 0);
    });

    test('Índices Básicos (IMC, RCQ, RCEst)', () {
      expect(BioCalculator.calculateIMC(80, 178), 25.25);
      expect(BioCalculator.calculateIMC(80, 0), 0);
      expect(BioCalculator.calculateRCQ(80, 100), 0.8);
      expect(BioCalculator.calculateRCQ(80, 0), 0);
      expect(BioCalculator.calculateRCEst(80, 160), 0.5);
      expect(BioCalculator.calculateRCEst(80, 0), 0);
    });

    test('Peso Ideal (IBW - Devine, Robinson, Miller, Hamwi)', () {
      final resM = BioCalculator.calculateIBW(Sexo.M, 180);
      expect(resM.devine, closeTo(74.99, 0.1));
      expect(resM.robinson, closeTo(72.65, 0.1));
      expect(resM.hamwi, closeTo(78.36, 0.1));

      final resF = BioCalculator.calculateIBW(Sexo.F, 165);
      expect(resF.devine, closeTo(56.91, 0.1));

      expect(BioCalculator.calculateIBW(Sexo.M, 0).devine, 0);
    });

    test('Macronutrientes e Metas (Emagrecimento, Piso 1200 kcal)', () {
      final res =
          BioCalculator.calculateMacrosAndGoals(2500, Objetivo.emagrecimento);
      expect(res.targetCalories, 2000);
      expect(res.grams.protein, 200);
      expect(res.grams.carbs, 150);
      expect(res.grams.fat, 67);

      final resLow =
          BioCalculator.calculateMacrosAndGoals(1500, Objetivo.emagrecimento);
      expect(resLow.targetCalories, 1200);
    });

    test('Índices Avançados de Risco (BAI, BRI, CI)', () {
      expect(BioCalculator.calculateBAI(100, 170), closeTo(27.1, 0.1));
      expect(BioCalculator.calculateBAI(0, 170), 0);

      expect(BioCalculator.calculateBRI(80, 170), closeTo(2.83, 0.1));
      expect(BioCalculator.calculateBRI(0, 170), 0);

      expect(BioCalculator.calculateCI(80, 70, 170), closeTo(1.14, 0.1));
      expect(BioCalculator.calculateCI(80, 0, 170), 0);
    });

    test('Geração de PDF A4 e Backup/Restore JSON (Parte 6)', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      final profile = UserProfile(
        id: 'user-1',
        nome: 'Rafael Souza',
        dataNascimento: DateTime(1995, 5, 10),
        sexo: Sexo.M,
        alturaCm: 178,
        criadoEm: DateTime(2026, 10, 1),
      );
      await appState.saveUserProfile(profile);

      final avaliacao = Avaliacao(
        id: 'av-1',
        userId: profile.id,
        dataAvaliacao: DateTime(2026, 10, 26),
        pesoKg: 78.5,
        nivelAtividade: 1.55,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(cintura: 84, pescoco: 38, quadril: 98),
      );
      final calculos = BioCalculator.buildCalculosSnapshot(
        profile: profile,
        avaliacao: avaliacao,
      );
      final resultado = Resultados(
        id: 'res-1',
        avaliacaoId: avaliacao.id,
        calculos: calculos,
      );
      await appState.addAvaliacao(avaliacao: avaliacao, resultado: resultado);

      // Valida geração do PDF
      final pdfBytes = await ReportPdfGenerator.generatePdfBytes(
        profile: profile,
        avaliacao: avaliacao,
        resultado: resultado,
      );
      expect(pdfBytes.length, greaterThan(1000));

      // Valida Exportação e Restauração de Backup JSON
      final exported = appState.exportBackupJson();
      expect(exported['version'], 2);

      final newState = AppState();
      await newState.init();
      final preview = newState.inspectBackupJson(exported);
      expect(preview.profileName, 'Rafael Souza');
      expect(preview.avaliacoesCount, 1);

      await newState.importBackupJson(exported);
      expect(newState.userProfile?.nome, 'Rafael Souza');
      expect(newState.avaliacoes.length, 1);
      expect(newState.avaliacoes.first.pesoKg, 78.5);
      // Verifica sincronização automática do peso da avaliação com as pesagens diárias
      expect(newState.pesagens.length, 1);
      expect(newState.pesagens.first.pesoKg, 78.5);
    });

    test(
        'Evolução v2.0: Edição de Avaliação, Recálculo Histórico, Deduplicação de Pesagem, Merge de Backup e PIN Lock',
        () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      final profile = UserProfile(
        id: 'user-1',
        nome: 'Rafael Souza',
        dataNascimento: DateTime(1995, 5, 10),
        sexo: Sexo.M,
        alturaCm: 175,
        criadoEm: DateTime(2026, 10, 1),
      );
      await appState.saveUserProfile(profile);

      final av1 = Avaliacao(
        id: 'av-1',
        userId: profile.id,
        dataAvaliacao: DateTime(2026, 10, 20),
        pesoKg: 80.0,
        nivelAtividade: 1.55,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(cintura: 86, pescoco: 38),
      );
      await appState.addAvaliacao(
        avaliacao: av1,
        resultado: Resultados(
          id: 'res-1',
          avaliacaoId: av1.id,
          calculos: BioCalculator.buildCalculosSnapshot(
            profile: profile,
            avaliacao: av1,
          ),
        ),
      );

      final imcOriginal =
          appState.getResultadoForAvaliacao('av-1')?.calculos['imc'];
      expect(imcOriginal, BioCalculator.calculateIMC(80.0, 175));

      // 1. Atualiza altura no perfil (175 -> 180) e verifica recálculo automático do histórico
      await appState.saveUserProfile(profile.copyWith(alturaCm: 180));
      final imcRecalculado =
          appState.getResultadoForAvaliacao('av-1')?.calculos['imc'];
      expect(imcRecalculado, BioCalculator.calculateIMC(80.0, 180));

      // 2. Edita avaliação existente (80kg -> 77kg) e verifica atualização
      final av1Edited = Avaliacao(
        id: 'av-1',
        userId: profile.id,
        dataAvaliacao: DateTime(2026, 10, 20),
        pesoKg: 77.0,
        nivelAtividade: 1.55,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(cintura: 83, pescoco: 38),
      );
      await appState.updateAvaliacao(
        avaliacao: av1Edited,
        resultado: Resultados(
          id: 'res-1',
          avaliacaoId: 'av-1',
          calculos: BioCalculator.buildCalculosSnapshot(
            profile: appState.userProfile!,
            avaliacao: av1Edited,
          ),
        ),
        fotosDaAvaliacao: const [],
      );
      expect(appState.avaliacoes.first.pesoKg, 77.0);
      // Pesagem do dia 20/10 deve ter sido atualizada para 77.0 sem duplicar
      expect(appState.pesagens.length, 1);
      expect(appState.pesagens.first.pesoKg, 77.0);

      // 3. Testa PIN Lock e Factory Reset
      await appState.setAppPin('1234');
      expect(appState.hasPinLock, isTrue);
      appState.lockSession();
      expect(appState.isLocked, isTrue);
      expect(appState.unlockSession('0000'), isFalse);
      expect(appState.unlockSession('1234'), isTrue);
      expect(appState.isLocked, isFalse);

      await appState.resetAllData();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.avaliacoes, isEmpty);
      expect(appState.pesagens, isEmpty);
      expect(appState.hasPinLock, isFalse);
    });

    test(
        'Refinamento v3.0: Metas Pessoais (metaPesoKg/metaBfPct) e Fallback RFM sem Pescoço',
        () async {
      final profile = UserProfile(
        id: 'user-v3',
        nome: 'Rafael Souza',
        dataNascimento: DateTime(1995, 5, 10),
        sexo: Sexo.M,
        alturaCm: 178,
        criadoEm: DateTime(2026, 10, 1),
        metaPesoKg: 74.0,
        metaBfPct: 13.5,
      );

      final json = profile.toJson();
      expect(json['meta_peso_kg'], 74.0);
      expect(json['meta_bf_pct'], 13.5);

      final restored = UserProfile.fromJson(json);
      expect(restored.metaPesoKg, 74.0);
      expect(restored.metaBfPct, 13.5);

      final cleared = restored.copyWith(clearMetas: true);
      expect(cleared.metaPesoKg, isNull);
      expect(cleared.metaBfPct, isNull);

      // Avaliação sem pescoço preenchido (bf_navy = 0, bf_rfm > 0)
      final avNoNeck = Avaliacao(
        id: 'av-noneck',
        userId: profile.id,
        dataAvaliacao: DateTime(2026, 10, 26),
        pesoKg: 78.0,
        nivelAtividade: 1.55,
        objetivo: Objetivo.hipertrofia,
        medidas: const MedidasCorporais(cintura: 84),
      );
      final snap = BioCalculator.buildCalculosSnapshot(
        profile: profile,
        avaliacao: avNoNeck,
      );
      // Sem pescoço, o snapshot usa RFM como fallback para bfNavy
      expect((snap['bfRfm'] as num).toDouble(), greaterThan(0.0));
      expect(snap['bfNavy'], snap['bfRfm']);
    });
  });
}
