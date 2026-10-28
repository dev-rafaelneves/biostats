import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/services/photo_storage_service.dart';
import 'package:biostats/services/security_service.dart';
import 'package:biostats/utils/calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('biostats_f5_test_');
    PhotoStorageService.setOverrideDirectory(tempDir);
    SecurityService.inMemorySecureStore.clear();
  });

  tearDown(() async {
    PhotoStorageService.setOverrideDirectory(null);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Fase 5 — Qualidade de Código e Testes Automatizados', () {
    // 1. Teste de Importação Substituir vs Mesclar
    test('Import Backup JSON — Substituir (merge: false) vs Mesclar (merge: true)', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      final profile = UserProfile(
        id: 'u1',
        nome: 'Rafael Souza',
        dataNascimento: DateTime(1995, 5, 20),
        sexo: Sexo.M,
        alturaCm: 178,
        criadoEm: DateTime(2026, 1, 1),
      );
      await appState.saveUserProfile(profile);

      // Cadastra avaliação original A1
      final av1 = Avaliacao(
        id: 'av_orig_1',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 1, 10),
        pesoKg: 80.0,
        medidas: const MedidasCorporais(cintura: 88.0, pescoco: 38.0),
      );
      final calc1 = BioCalculator.buildCalculosSnapshot(
        profile: profile,
        avaliacao: av1,
      );
      await appState.addAvaliacao(
        avaliacao: av1,
        resultado: Resultados(
          id: 'res_orig_1',
          avaliacaoId: av1.id,
          calculos: calc1.toJson(),
        ),
      );

      expect(appState.avaliacoes.length, 1);
      expect(appState.avaliacoes.first.id, 'av_orig_1');

      // Backup JSON com 2 avaliações: av_orig_1 (atualizada para 79kg) e av_nova_2 (78kg)
      final backupData = {
        'version': 2,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'perfil_pessoal': profile.toJson(),
          'avaliacoes': [
            {
              'id': 'av_orig_1',
              'cliente_id': 'u1',
              'data_avaliacao': DateTime(2026, 1, 10).toIso8601String(),
              'peso_kg': 79.0,
              'medidas': {'cintura': 87.0, 'pescoco': 38.0},
            },
            {
              'id': 'av_nova_2',
              'cliente_id': 'u1',
              'data_avaliacao': DateTime(2026, 2, 10).toIso8601String(),
              'peso_kg': 78.0,
              'medidas': {'cintura': 85.0, 'pescoco': 38.0},
            },
          ],
          'resultados': [],
          'fotos': [],
          'pesagens': [
            {
              'id': 'pes_1',
              'cliente_id': 'u1',
              'data': DateTime(2026, 1, 10).toIso8601String(),
              'peso_kg': 79.0,
            },
          ],
        },
      };

      // Teste A: Mesclar (merge: true) -> deve preservar e atualizar por id
      await appState.importBackupJson(backupData, merge: true);
      expect(appState.avaliacoes.length, 2);
      final updatedOrig = appState.avaliacoes.firstWhere((a) => a.id == 'av_orig_1');
      expect(updatedOrig.pesoKg, 79.0); // atualizou o existente
      expect(appState.avaliacoes.any((a) => a.id == 'av_nova_2'), isTrue); // incluiu novo

      // Teste B: Substituir (merge: false) com dataset novo
      final replaceBackupData = {
        'version': 2,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'perfil_pessoal': profile.toJson(),
          'avaliacoes': [
            {
              'id': 'av_substituta_3',
              'cliente_id': 'u1',
              'data_avaliacao': DateTime(2026, 3, 1).toIso8601String(),
              'peso_kg': 76.5,
              'medidas': {'cintura': 82.0, 'pescoco': 38.0},
            },
          ],
          'resultados': [],
          'fotos': [],
          'pesagens': [],
        },
      };

      await appState.importBackupJson(replaceBackupData, merge: false);
      expect(appState.avaliacoes.length, 1);
      expect(appState.avaliacoes.first.id, 'av_substituta_3');
      expect(appState.avaliacoes.first.pesoKg, 76.5);
    });

    // 2. Teste de fromJson tolerante com formatos legados
    test('Modelos Legados — fromJson tolera formatos antigos v1/v2 sem quebrar', () {
      // Avaliação legada com medidas ausentes
      final rawLegacyAvaliacao = {
        'id': 'legacy_av_01',
        'userId': 'u1',
        'dataAvaliacao': '2025-05-10T10:00:00.000',
        'pesoKg': 82.5,
        'medidas': {'cintura': 90.0, 'pescoco': 38.0},
      };

      final av = Avaliacao.fromJson(rawLegacyAvaliacao);
      expect(av.id, 'legacy_av_01');
      expect(av.pesoKg, 82.5);
      expect(av.medidas.quadril, isNull);
      expect(av.medidas.braco, isNull);

      // Snapshot legado v1 com valores como String ou ausentes
      final rawLegacySnapshot = {
        'imc': '26.04',
        'bfNavy': '20.5',
        'bfRfm': 0.0,
        'tmbKatch': 1750,
      };

      final snapshot = CalculosSnapshot.fromJson(rawLegacySnapshot);
      expect(snapshot.calcVersion, 1); // detecta versão legada v1 (< 2)
      expect(snapshot.imc, closeTo(26.04, 0.01));
      expect(snapshot.bfNavy, closeTo(20.5, 0.01));
      expect(snapshot.lbmFinal, closeTo(0.0, 0.01)); // não quebra com ausência
      expect(snapshot.bfPrincipal, closeTo(20.5, 0.01)); // fallback automático para navy
    });

    // 3. Teste da Migração F2 (Fotos em disco)
    test('Migração F2 — Converte fotos Base64 legadas para arquivos em disco', () async {
      const mockBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      final savedPath = await PhotoStorageService.savePhotoFromBase64('test_photo_1', mockBase64);
      expect(savedPath, isNotNull);
      expect(savedPath!.contains('test_photo_1.jpg'), isTrue);

      // Lê bytes de volta do disco
      final bytes = await PhotoStorageService.readPhotoBytes(savedPath);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));

      // Limpeza de fotos
      await PhotoStorageService.deletePhotoFile(savedPath);
      final bytesAfter = await PhotoStorageService.readPhotoBytes(savedPath);
      expect(bytesAfter, isNull);
    });

    // 4. Teste de Recálculo F3 (Snapshots legados auto-recalculados com fórmulas científicas)
    test('Recálculo F3 — Snapshots legados v0/v1 são recalculados no AppState.init()', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      final profile = UserProfile(
        id: 'u1',
        nome: 'Rafael Teste',
        dataNascimento: DateTime(1990, 6, 15),
        sexo: Sexo.M,
        alturaCm: 178,
        criadoEm: DateTime(2026, 1, 1),
      );
      await appState.saveUserProfile(profile);

      final av = Avaliacao(
        id: 'av_legacy_recalc',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 2, 1),
        pesoKg: 80.0,
        medidas: const MedidasCorporais(cintura: 86.0, pescoco: 38.0),
      );

      // Insere com snapshot legado (calcVersion: 0, lbmFinal: 0.0)
      final legacySnapshot = {
        'imc': 25.2,
        'bfNavy': 18.0,
        'calcVersion': 0,
        'lbmFinal': 0.0,
      };

      await appState.addAvaliacao(
        avaliacao: av,
        resultado: Resultados(
          id: 'res_legacy',
          avaliacaoId: av.id,
          calculos: legacySnapshot,
        ),
      );

      // Antes do init, snapshot tinha calcVersion: 0
      final resBefore = appState.getResultadoForAvaliacao(av.id);
      expect(resBefore?.snapshot.calcVersion, 0);

      // Reinicializa o AppState (simulando reabertura do aplicativo)
      await appState.init();

      // Após o init(), a auto-recalculação da Fase 3 deve ter atualizado calcVersion para 2
      final resAfter = appState.getResultadoForAvaliacao(av.id);
      expect(resAfter?.snapshot.calcVersion, 2);
      expect(resAfter?.snapshot.lbmFinal, greaterThan(60.0));
      expect(resAfter?.snapshot.bfPrincipal, greaterThan(0.0));
      expect(resAfter?.snapshot.metodoPrincipal, 'navy');
      expect(resAfter?.snapshot.macros.grams.protein, greaterThan(80));
    });

    // 5. Teste de Segurança F4 (PIN, Salt, Lockout e Persistência)
    test('Segurança F4 — Hash SHA-256 com salt e bloqueio progressivo', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const pin = '4321';
      final salt = SecurityService.generateSalt();
      final hash = SecurityService.hashPin(pin, salt);

      expect(salt.length, 32); // 16 bytes em hex
      expect(hash.length, 64); // SHA-256 hex string

      // Simula salvamento
      SecurityService.inMemorySecureStore['biostats_pin_salt'] = salt;
      SecurityService.inMemorySecureStore['biostats_pin_sha256'] = hash;

      expect(await SecurityService.verifyPin('4321'), isTrue);
      expect(await SecurityService.verifyPin('0000'), isFalse);

      // Testa contagem de falhas e lockout
      expect(SecurityService.calculateLockoutSeconds(1), 0);
      expect(SecurityService.calculateLockoutSeconds(4), 0);
      expect(SecurityService.calculateLockoutSeconds(5), 30);
      expect(SecurityService.calculateLockoutSeconds(6), 60);
      expect(SecurityService.calculateLockoutSeconds(7), 300);

      // Simula 5 falhas no prefs
      for (int i = 0; i < 5; i++) {
        await SecurityService.recordFailedAttempt(prefs);
      }

      final lockoutUntil = SecurityService.getLockoutUntil(prefs);
      expect(lockoutUntil, isNotNull);
      final remaining = SecurityService.getRemainingLockoutSeconds(lockoutUntil);
      expect(remaining, greaterThanOrEqualTo(25));
      expect(remaining, lessThanOrEqualTo(30));

      // Reset após sucesso
      await SecurityService.resetFailedAttempts(prefs);
      expect(SecurityService.getFailedAttempts(prefs), 0);
      expect(SecurityService.getLockoutUntil(prefs), isNull);
    });

    // 6. Teste de AppState — Listas sempre mantidas ordenadas
    test('AppState — Listas mantidas pré-ordenadas em O(1)', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      final profile = UserProfile(
        id: 'u1',
        nome: 'Ordenado',
        dataNascimento: DateTime(1990, 1, 1),
        sexo: Sexo.M,
        alturaCm: 175,
        criadoEm: DateTime(2026, 1, 1),
      );
      await appState.saveUserProfile(profile);

      // Insere avaliações fora de ordem
      final avJan = Avaliacao(
        id: 'av_jan',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 1, 15),
        pesoKg: 82.0,
        medidas: const MedidasCorporais(),
      );
      final avMar = Avaliacao(
        id: 'av_mar',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 3, 15),
        pesoKg: 78.0,
        medidas: const MedidasCorporais(),
      );
      final avFev = Avaliacao(
        id: 'av_fev',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 2, 15),
        pesoKg: 80.0,
        medidas: const MedidasCorporais(),
      );

      const dummyRes = Resultados(
        id: 'res_dummy',
        avaliacaoId: 'dummy',
        calculos: {},
      );

      await appState.addAvaliacao(avaliacao: avJan, resultado: dummyRes, syncDailyWeight: false);
      await appState.addAvaliacao(avaliacao: avMar, resultado: dummyRes, syncDailyWeight: false);
      await appState.addAvaliacao(avaliacao: avFev, resultado: dummyRes, syncDailyWeight: false);

      // Avaliações devem estar pré-ordenadas da mais recente para a mais antiga (Mar -> Fev -> Jan)
      expect(appState.avaliacoes.length, 3);
      expect(appState.avaliacoes[0].id, 'av_mar');
      expect(appState.avaliacoes[1].id, 'av_fev');
      expect(appState.avaliacoes[2].id, 'av_jan');

      // Pesagens devem estar pré-ordenadas cronologicamente (Jan -> Fev -> Mar)
      await appState.addPesagem(Pesagem(id: 'p3', userId: 'u1', data: DateTime(2026, 3, 1), pesoKg: 78.5));
      await appState.addPesagem(Pesagem(id: 'p1', userId: 'u1', data: DateTime(2026, 1, 1), pesoKg: 82.5));
      await appState.addPesagem(Pesagem(id: 'p2', userId: 'u1', data: DateTime(2026, 2, 1), pesoKg: 80.5));

      expect(appState.pesagens.length, 3);
      expect(appState.pesagens[0].id, 'p1');
      expect(appState.pesagens[1].id, 'p2');
      expect(appState.pesagens[2].id, 'p3');
    });
  });
}
