import 'dart:convert';
import 'dart:io';
import 'package:biostats/models/models.dart';
import 'package:biostats/services/app_state.dart';
import 'package:biostats/services/photo_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Fase 2 — Armazenamento Físico de Fotos e Migração', () {
    late Directory tempPhotosDir;

    setUp(() async {
      tempPhotosDir = Directory.systemTemp.createTempSync('biostats_test_photos_');
      PhotoStorageService.setOverrideDirectory(tempPhotosDir);
    });

    tearDown(() async {
      if (tempPhotosDir.existsSync()) {
        tempPhotosDir.deleteSync(recursive: true);
      }
    });

    test('PhotoStorageService salva e lê bytes e Base64 do disco com limpeza', () async {
      const sampleText = 'BioStats Foto Teste 123';
      final sampleBytes = utf8.encode(sampleText);
      final sampleBase64 = base64Encode(sampleBytes);

      final savedPath = await PhotoStorageService.savePhotoFromBase64('test_photo_1', sampleBase64);
      expect(savedPath, isNotNull);
      expect(File(savedPath!).existsSync(), isTrue);

      final readBytes = await PhotoStorageService.readPhotoBytes(savedPath);
      expect(readBytes, isNotNull);
      expect(utf8.decode(readBytes!), sampleText);

      await PhotoStorageService.deletePhotoFile(savedPath);
      expect(File(savedPath).existsSync(), isFalse);
    });

    test('Migração de fotos Base64 legadas para arquivos físicos em disco', () async {
      final fakeBytes = utf8.encode('Fake ImageData 12345');
      final fakeBase64 = 'data:image/jpeg;base64,${base64Encode(fakeBytes)}';

      final mockProfile = UserProfile(
        id: 'mig-user',
        nome: 'Usuario Migracao',
        dataNascimento: DateTime(1990, 6, 20),
        sexo: Sexo.F,
        alturaCm: 165,
        criadoEm: DateTime(2026, 1, 1),
      );

      final mockAvaliacao = Avaliacao(
        id: 'mig-av1',
        userId: 'mig-user',
        dataAvaliacao: DateTime(2026, 5, 10),
        pesoKg: 62.0,
        medidas: const MedidasCorporais(cintura: 70, quadril: 95, pescoco: 33),
      );

      final mockFoto = FotoAvaliacao(
        id: 'mig-foto1',
        avaliacaoId: 'mig-av1',
        userId: 'mig-user',
        tipo: FotoTipo.frente,
        fotoBase64: fakeBase64,
        criadoEm: DateTime(2026, 5, 10),
      );

      final mockPesagem = Pesagem(
        id: 'mig-pes1',
        userId: 'mig-user',
        data: DateTime(2026, 5, 10),
        pesoKg: 62.0,
      );

      SharedPreferences.setMockInitialValues({
        'biostats_user_profile': jsonEncode(mockProfile.toJson()),
        'biostats_avaliacoes': jsonEncode([mockAvaliacao.toJson()]),
        'biostats_resultados': jsonEncode([]),
        'biostats_fotos': jsonEncode([mockFoto.toJson()]),
        'biostats_pesagens': jsonEncode([mockPesagem.toJson()]),
        'biostats-theme': 'dark',
      });

      final appState = AppState();
      await appState.init();

      expect(appState.userProfile?.nome, 'Usuario Migracao');
      expect(appState.avaliacoes.length, 1);
      expect(appState.avaliacoes.first.pesoKg, 62.0);
      expect(appState.pesagens.length, 1);
      expect(appState.fotos.length, 1);

      // Foto convertida para arquivo físico no disco
      final migratedFoto = appState.fotos.first;
      expect(migratedFoto.filePath, isNotNull);
      expect(File(migratedFoto.filePath!).existsSync(), isTrue);

      final decodedBytes = appState.getDecodedPhotoBytes(migratedFoto);
      expect(decodedBytes, isNotNull);
      expect(utf8.decode(decodedBytes!), 'Fake ImageData 12345');

      // Strings gigantes removidas do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('biostats_avaliacoes'), isFalse);
      expect(prefs.containsKey('biostats_fotos'), isFalse);
      expect(prefs.containsKey('biostats_resultados'), isFalse);
      expect(prefs.containsKey('biostats_pesagens'), isFalse);
    });

    test('Exportação de backup lê fotos do disco e mantém JSON com Base64 para compatibilidade', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      await appState.init();

      final profile = UserProfile(
        id: 'exp-user',
        nome: 'Export Teste',
        dataNascimento: DateTime(1992, 8, 12),
        sexo: Sexo.M,
        alturaCm: 180,
        criadoEm: DateTime(2026, 1, 1),
      );
      await appState.saveUserProfile(profile);

      final photoPath = await PhotoStorageService.savePhotoBytes(
        'disk_foto_1',
        utf8.encode('BytesFotoExportacao'),
      );

      final av = Avaliacao(
        id: 'av_exp',
        userId: 'exp-user',
        dataAvaliacao: DateTime(2026, 10, 1),
        pesoKg: 80,
        medidas: const MedidasCorporais(cintura: 82),
      );
      const res = Resultados(id: 'res_exp', avaliacaoId: 'av_exp', calculos: {});
      final foto = FotoAvaliacao(
        id: 'disk_foto_1',
        avaliacaoId: 'av_exp',
        userId: 'exp-user',
        tipo: FotoTipo.frente,
        filePath: photoPath,
        criadoEm: DateTime(2026, 10, 1),
      );

      await appState.addAvaliacao(avaliacao: av, resultado: res, novasFotos: [foto]);

      final jsonBackup = appState.exportBackupJson();
      expect(jsonBackup['version'], 2);

      final data = jsonBackup['data'] as Map<String, dynamic>;
      final exportedFotos = data['fotos'] as List;
      expect(exportedFotos.length, 1);

      final firstFotoMap = exportedFotos.first as Map<String, dynamic>;
      final base64String = firstFotoMap['foto_base64'] as String;
      expect(base64String.startsWith('data:image/jpeg;base64,'), isTrue);

      final clean = base64String.split(',').last;
      expect(utf8.decode(base64Decode(clean)), 'BytesFotoExportacao');
    });
  });
}
