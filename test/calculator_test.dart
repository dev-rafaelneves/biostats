import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/services/security_service.dart';
import 'package:biostats/utils/calculator.dart';
import 'package:biostats/utils/report_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

    test('Macronutrientes Científicos em g/kg e Pisos Calóricos (F3)', () {
      // Caso 1: Homem, TDEE 2500, Emagrecimento, Peso 80kg, LBM 64kg
      final resM = BioCalculator.calculateMacrosAndGoals(
        2500,
        Objetivo.emagrecimento,
        sexo: Sexo.M,
        pesoKg: 80,
        lbmKg: 64,
      );
      expect(resM.targetCalories, 2000); // 2500 - 500
      expect(resM.grams.protein, 115); // 64kg LBM * 1.8 = 115.2 -> 115g
      expect(resM.grams.fat, 64); // 80kg peso * 0.8 = 64g
      expect(resM.grams.carbs, 241); // (2000 - (115*4) - (64*9)) / 4 = 964 / 4 = 241g
      expect(resM.macros.protein + resM.macros.fat + resM.macros.carbs, 100);

      // Caso 2: Piso Calórico Feminino (1200 kcal)
      final resLowF = BioCalculator.calculateMacrosAndGoals(
        1400,
        Objetivo.emagrecimento,
        sexo: Sexo.F,
        pesoKg: 60,
        lbmKg: 45,
      );
      expect(resLowF.targetCalories, 1200); // 1400 - 500 = 900 -> piso 1200
      expect(resLowF.grams.protein, 81); // 45 * 1.8 = 81g
      expect(resLowF.grams.fat, 48); // 60 * 0.8 = 48g

      // Caso 3: Piso Calórico Masculino (1500 kcal)
      final resLowM = BioCalculator.calculateMacrosAndGoals(
        1700,
        Objetivo.emagrecimento,
        sexo: Sexo.M,
        pesoKg: 75,
        lbmKg: 58,
      );
      expect(resLowM.targetCalories, 1500); // 1700 - 500 = 1200 -> piso 1500

      // Caso 4: Hipertrofia (2.0 g/kg LBM e +300 kcal)
      final resHip = BioCalculator.calculateMacrosAndGoals(
        2200,
        Objetivo.hipertrofia,
        sexo: Sexo.M,
        pesoKg: 70,
        lbmKg: 55,
      );
      expect(resHip.targetCalories, 2500); // 2200 + 300
      expect(resHip.grams.protein, 110); // 55 * 2.0 = 110g
      expect(resHip.grams.fat, 56); // 70 * 0.8 = 56g
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
        calculos: calculos.toJson(),
        calcVersion: 2,
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
          ).toJson(),
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
          ).toJson(),
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
      expect(await appState.unlockSession('0000'), isFalse);
      expect(await appState.unlockSession('1234'), isTrue);
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

      // Avaliação sem pescoço preenchido (bfNavy = 0, bfRfm > 0, bfPrincipal = bfRfm)
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
      // Sem pescoço: bfNavy fica 0.0, bfRfm > 0, bfPrincipal = bfRfm e metodo = 'rfm'
      expect(snap.bfNavy, 0.0);
      expect(snap.bfRfm, greaterThan(0.0));
      expect(snap.bfPrincipal, snap.bfRfm);
      expect(snap.metodoPrincipal, 'rfm');
      expect(snap.metodoPrincipalLabel, 'RFM');
    });

    test('F3 — Idade na data da avaliação', () {
      final profile = UserProfile(
        id: 'user-age',
        nome: 'Teste Idade',
        dataNascimento: DateTime(1990, 6, 15),
        sexo: Sexo.M,
        alturaCm: 175,
        criadoEm: DateTime(2020, 1, 1),
      );

      // Antes do aniversário em 2024
      expect(profile.idadeNaData(DateTime(2024, 6, 14)), 33);
      // No dia do aniversário em 2024
      expect(profile.idadeNaData(DateTime(2024, 6, 15)), 34);
      // Depois do aniversário em 2024
      expect(profile.idadeNaData(DateTime(2024, 6, 16)), 34);
    });

    test('F3 — Massa Magra Real LBM = peso * (1 - BF%) e Katch-McArdle', () {
      final profile = UserProfile(
        id: 'user-lbm',
        nome: 'Teste LBM',
        dataNascimento: DateTime(1995, 1, 1),
        sexo: Sexo.M,
        alturaCm: 180,
        criadoEm: DateTime(2026, 1, 1),
      );
      // Avaliação com medidas completas: peso 80kg, cintura 84cm, pescoço 38cm
      final av = Avaliacao(
        id: 'av-lbm',
        userId: profile.id,
        dataAvaliacao: DateTime(2026, 10, 20),
        pesoKg: 80.0,
        nivelAtividade: 1.55,
        objetivo: Objetivo.manutencao,
        medidas: const MedidasCorporais(cintura: 84, pescoco: 38),
      );
      final snap = BioCalculator.buildCalculosSnapshot(
        profile: profile,
        avaliacao: av,
      );

      expect(snap.bfNavy, greaterThan(0));
      expect(snap.bfPrincipal, snap.bfNavy);
      expect(snap.metodoPrincipal, 'navy');

      // LBM real = 80 * (1 - (bf/100))
      final expectedLbmReal =
          BioCalculator.round2(80.0 * (1.0 - (snap.bfPrincipal / 100.0)));
      expect(snap.lbmFinal, expectedLbmReal);
      // Katch-McArdle usa lbmFinal
      expect(
        snap.bmrKatch,
        BioCalculator.calculateKatchMcArdleBMR(snap.lbmFinal),
      );
    });

    test('F3 — CalculosSnapshot.fromJson tolerante com snapshot legado v1', () {
      final legacyMap = {
        'imc': 24.5,
        'rcq': 0.85,
        'rcEst': 0.48,
        'bfNavy': 16.8,
        'bfRfm': 18.2,
        'bfDeurenberg': 19.5,
        'lbmBoer': 62.0,
        'bmrKatch': 1700.0,
        'tdee': 2400.0,
        'bai': 22.0,
        'bri': 3.1,
        'ci': 1.15,
        // Sem bfPrincipal, sem metodoPrincipal, sem calcVersion
      };

      final snapshot = CalculosSnapshot.fromJson(legacyMap);
      expect(snapshot.imc, 24.5);
      expect(snapshot.bfNavy, 16.8);
      expect(snapshot.bfPrincipal, 16.8);
      expect(snapshot.metodoPrincipal, 'navy');
      expect(snapshot.metodoPrincipalLabel, 'US Navy');
      expect(snapshot.lbmFinal, 62.0); // fallback para lbmBoer
      expect(snapshot.calcVersion, 1);
    });

    test('F3 — Auto-recalculação de snapshots legados no AppState.init()',
        () async {
      final profile = UserProfile(
        id: 'user-migr',
        nome: 'Usuario Legado',
        dataNascimento: DateTime(1990, 5, 10),
        sexo: Sexo.M,
        alturaCm: 178,
        criadoEm: DateTime(2025, 1, 1),
      );

      final av = Avaliacao(
        id: 'av-legada',
        userId: profile.id,
        dataAvaliacao: DateTime(2025, 6, 1),
        pesoKg: 82.0,
        nivelAtividade: 1.55,
        objetivo: Objetivo.emagrecimento,
        medidas: const MedidasCorporais(cintura: 86, pescoco: 38),
      );

      // Insere resultado com calcVersion = 1 e sem bfPrincipal
      final resLegado = Resultados(
        id: 'res-legado',
        avaliacaoId: av.id,
        calculos: {
          'imc': 25.88,
          'bfNavy': 17.0,
          'lbmBoer': 61.5,
          'calcVersion': 1,
        },
        calcVersion: 1,
      );

      SharedPreferences.setMockInitialValues({
        'biostats_user_profile': jsonEncode(profile.toJson()),
        'biostats_avaliacoes': jsonEncode([av.toJson()]),
        'biostats_resultados': jsonEncode([resLegado.toJson()]),
      });

      final appState = AppState();
      await appState.init();

      final reloadedRes = appState.getResultadoForAvaliacao('av-legada');
      expect(reloadedRes, isNotNull);
      // Deve ter sido recalculado para v2 automaticamente
      expect(reloadedRes!.calcVersion, 2);
      expect(reloadedRes.snapshot.bfPrincipal, greaterThan(0));
      expect(reloadedRes.snapshot.lbmFinal, greaterThan(0));
      expect(reloadedRes.snapshot.metodoPrincipal, 'navy');
    });

    test('F4 — Hash SHA-256 com Salt criptográfico para PIN', () {
      final salt1 = SecurityService.generateSalt();
      final salt2 = SecurityService.generateSalt();
      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1, isNot(equals(salt2)));

      final hash1 = SecurityService.hashPin('1234', salt1);
      final hash2 = SecurityService.hashPin('1234', salt2);
      // O mesmo PIN com salts diferentes gera hashes completamente diferentes (anti-rainbow table)
      expect(hash1, isNot(equals(hash2)));

      // O mesmo PIN com o mesmo salt é estritamente determinístico
      expect(SecurityService.hashPin('1234', salt1), equals(hash1));
      expect(SecurityService.hashPin('9999', salt1), isNot(equals(hash1)));
    });

    test('F4 — Lockout progressivo após tentativas incorretas (30s, 60s, 300s)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 1 a 4 tentativas: sem lockout
      for (int i = 1; i <= 4; i++) {
        final lock = await SecurityService.recordFailedAttempt(prefs);
        expect(lock, isNull);
        expect(SecurityService.getFailedAttempts(prefs), i);
        expect(SecurityService.calculateLockoutSeconds(i), 0);
      }

      // 5ª tentativa: bloqueio de 30 segundos
      final lock5 = await SecurityService.recordFailedAttempt(prefs);
      expect(lock5, isNotNull);
      expect(SecurityService.calculateLockoutSeconds(5), 30);
      expect(SecurityService.getRemainingLockoutSeconds(lock5), inInclusiveRange(28, 30));

      // 6ª tentativa: bloqueio de 60 segundos
      final lock6 = await SecurityService.recordFailedAttempt(prefs);
      expect(lock6, isNotNull);
      expect(SecurityService.calculateLockoutSeconds(6), 60);
      expect(SecurityService.getRemainingLockoutSeconds(lock6), inInclusiveRange(58, 60));

      // 7ª tentativa: bloqueio de 300 segundos (5 minutos)
      final lock7 = await SecurityService.recordFailedAttempt(prefs);
      expect(lock7, isNotNull);
      expect(SecurityService.calculateLockoutSeconds(7), 300);
      expect(SecurityService.getRemainingLockoutSeconds(lock7), inInclusiveRange(298, 300));

      // Reset
      await SecurityService.resetFailedAttempts(prefs);
      expect(SecurityService.getFailedAttempts(prefs), 0);
      expect(SecurityService.getLockoutUntil(prefs), isNull);
    });

    test('F4 — Migração de PIN em texto puro para Secure Storage com Hash',
        () async {
      SharedPreferences.setMockInitialValues({
        'biostats_app_pin': '9876',
      });
      final prefs = await SharedPreferences.getInstance();

      // Executa migração
      await SecurityService.migrateLegacyPinIfNecessary(prefs);

      // Texto puro deve ter sido removido
      expect(prefs.containsKey('biostats_app_pin'), isFalse);

      // Validação pelo hash seguro
      expect(await SecurityService.hasSecurePin(), isTrue);
      expect(await SecurityService.verifyPin('9876'), isTrue);
      expect(await SecurityService.verifyPin('0000'), isFalse);
    });

    test('F4 — Lockout integrado no AppState com persistência', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      await appState.setAppPin('5555');
      expect(appState.hasPinLock, isTrue);
      appState.lockSession();
      expect(appState.isLocked, isTrue);

      // 4 tentativas erradas
      for (int i = 0; i < 4; i++) {
        expect(await appState.unlockSession('0000'), isFalse);
        expect(appState.isLockedOut, isFalse);
      }

      // 5ª tentativa errada ativa lockout de 30s
      expect(await appState.unlockSession('0000'), isFalse);
      expect(appState.isLockedOut, isTrue);
      expect(appState.remainingLockoutSeconds, greaterThan(0));

      // Mesmo com o PIN correto, durante o lockout não deve desbloquear
      expect(await appState.unlockSession('5555'), isFalse);
      expect(appState.isLocked, isTrue);
    });
  });
}
