import 'package:flutter_test/flutter_test.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/services/database_service.dart';
import 'package:biostats/services/gemini_service.dart';
import 'package:biostats/utils/calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GeminiService.inMemorySecureStore.clear();
    GeminiService.mockResponseText = null;
    DatabaseService.inMemoryAiInsights.clear();
  });

  group('GeminiService - Gerenciamento Seguro da Chave', () {
    test('Salva, recupera e verifica existência da chave', () async {
      expect(await GeminiService.hasApiKey(), isFalse);
      expect(await GeminiService.getApiKey(), isNull);

      await GeminiService.saveApiKey('AIzaSyDummyKeyForTesting1234567890');

      expect(await GeminiService.hasApiKey(), isTrue);
      expect(
        await GeminiService.getApiKey(),
        equals('AIzaSyDummyKeyForTesting1234567890'),
      );
    });

    test('Mascara a chave de forma segura no padrão Apple HIG', () {
      expect(GeminiService.maskApiKey(null), equals('Não configurada'));
      expect(GeminiService.maskApiKey(''), equals('Não configurada'));
      expect(GeminiService.maskApiKey('short'), equals('••••••••••••'));

      final masked =
          GeminiService.maskApiKey('AIzaSyTestingSuperSecretKey9988');
      expect(masked.startsWith('AIzaSy'), isTrue);
      expect(masked.endsWith('9988'), isTrue);
      expect(masked.contains('••••••••••••'), isTrue);
    });

    test('Remove a chave do armazenamento seguro', () async {
      await GeminiService.saveApiKey('AIzaSyTempKey123456');
      expect(await GeminiService.hasApiKey(), isTrue);

      await GeminiService.removeApiKey();
      expect(await GeminiService.hasApiKey(), isFalse);
      expect(await GeminiService.getApiKey(), isNull);
    });

    test('Testa conexão da chave simulada em ambiente de teste', () async {
      final resEmpty = await GeminiService.testConnection('');
      expect(resEmpty.success, isFalse);

      final resInvalid = await GeminiService.testConnection('invalid_key');
      expect(resInvalid.success, isFalse);

      final resValid =
          await GeminiService.testConnection('AIzaSyValidApiKey12345');
      expect(resValid.success, isTrue);
      expect(resValid.message, contains('sucesso'));
    });
  });

  group('DatabaseService - Cache Local de Insights de IA', () {
    test('Salva e recupera insight com cache hit instantâneo', () async {
      expect(
        await DatabaseService.getAiInsight('evaluation_summary', 'eval-1'),
        isNull,
      );

      await DatabaseService.saveAiInsight(
        tipo: 'evaluation_summary',
        referenciaId: 'eval-1',
        conteudoMd: '## Diagnóstico\nComposição excelente!',
        modelo: 'gemini-3.8-flash',
      );

      final cached =
          await DatabaseService.getAiInsight('evaluation_summary', 'eval-1');
      expect(cached, isNotNull);
      expect(cached, contains('Composição excelente!'));
    });

    test('Limpa insight específico do cache', () async {
      await DatabaseService.saveAiInsight(
        tipo: 'comparison',
        referenciaId: 'evalA_evalB',
        conteudoMd: 'Evolução consistente.',
        modelo: 'gemini-3.8-flash',
      );

      await DatabaseService.deleteAiInsight('comparison', 'evalA_evalB');
      expect(
        await DatabaseService.getAiInsight('comparison', 'evalA_evalB'),
        isNull,
      );
    });
  });

  group('GeminiService - Geração com Cache e Mock', () {
    final profile = UserProfile(
      id: 'usr-1',
      nome: 'Rafael',
      dataNascimento: DateTime(1995, 5, 20),
      sexo: Sexo.M,
      alturaCm: 178,
      criadoEm: DateTime(2026, 1, 1),
    );

    final avaliacao = Avaliacao(
      id: 'eval-10',
      userId: 'usr-1',
      dataAvaliacao: DateTime(2026, 10, 1),
      pesoKg: 78.5,
      nivelAtividade: 1.55,
      objetivo: Objetivo.hipertrofia,
      medidas: const MedidasCorporais(
        cintura: 81,
        quadril: 99,
        pescoco: 38,
        braco: 38,
        coxa: 58,
        dobraAbdomen: 14,
        dobraTriceps: 10,
        dobraSuprailiaca: 12,
      ),
    );

    final calculosSnapshot = BioCalculator.buildCalculosSnapshot(
      profile: profile,
      avaliacao: avaliacao,
    );

    final resultado = Resultados(
      id: 'res-10',
      avaliacaoId: 'eval-10',
      calculos: calculosSnapshot.toJson(),
    );

    test('Gera parecer usando mock e persiste automaticamente no cache',
        () async {
      GeminiService.mockResponseText =
          '### Diagnóstico BioStats\nExcelente índice de massa magra de 67.9 kg.';

      final insight = await GeminiService.generateEvaluationInsight(
        profile: profile,
        avaliacao: avaliacao,
        resultado: resultado,
      );

      expect(insight, contains('67.9 kg'));

      // Verifica se gravou no cache
      final cached = await DatabaseService.getAiInsight(
        'evaluation_summary',
        'eval-10',
      );
      expect(cached, equals(insight));

      // Limpa mock para garantir que próxima chamada lê do cache sem erro
      GeminiService.mockResponseText = null;
      final cachedInsight = await GeminiService.generateEvaluationInsight(
        profile: profile,
        avaliacao: avaliacao,
        resultado: resultado,
      );
      expect(cachedInsight, equals(insight));
    });

    test('Lança StateError quando não há chave configurada nem mock', () async {
      await GeminiService.removeApiKey();
      GeminiService.mockResponseText = null;

      expect(
        () => GeminiService.generateEvaluationInsight(
          profile: profile,
          avaliacao: avaliacao,
          resultado: resultado,
        ),
        throwsStateError,
      );
    });
  });
}
