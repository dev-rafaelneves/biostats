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

  group('GeminiService - Configuração de Tokens e Parser de Resposta', () {
    test('Configura thinkingLevel low e 4096 tokens para família Gemini 3', () {
      final config = GeminiService.buildGenerationConfigForModel(
        'gemini-3.8-flash',
      );

      expect(config['maxOutputTokens'], equals(4096));
      expect(config['temperature'], equals(0.4));
      final thinking = config['thinkingConfig'] as Map<String, dynamic>?;
      expect(thinking, isNotNull);
      expect(thinking!['thinkingLevel'], equals('low'));
      expect(thinking.containsKey('thinkingBudget'), isFalse);
    });

    test('Configura thinkingBudget 512 e 4096 tokens para família Gemini 2.5', () {
      for (final model in ['gemini-2.5-flash', 'gemini-2.5-pro']) {
        final config = GeminiService.buildGenerationConfigForModel(model);
        expect(config['maxOutputTokens'], equals(4096));
        expect(config['temperature'], equals(0.4));
        final thinking = config['thinkingConfig'] as Map<String, dynamic>?;
        expect(thinking, isNotNull);
        expect(thinking!['thinkingBudget'], equals(512));
        expect(thinking.containsKey('thinkingLevel'), isFalse);
      }
    });

    test('Configura testConnection com 128 tokens e budget mínimo seguro por modelo', () {
      final cfg3 = GeminiService.buildGenerationConfigForModel(
        'gemini-3.8-flash',
        isConnectionTest: true,
      );
      expect(cfg3['maxOutputTokens'], equals(128));
      expect(cfg3['temperature'], equals(0.0));
      expect(
        (cfg3['thinkingConfig'] as Map<String, dynamic>)['thinkingLevel'],
        equals('low'),
      );

      final cfg25Flash = GeminiService.buildGenerationConfigForModel(
        'gemini-2.5-flash',
        isConnectionTest: true,
      );
      expect(cfg25Flash['maxOutputTokens'], equals(128));
      expect(
        (cfg25Flash['thinkingConfig'] as Map<String, dynamic>)['thinkingBudget'],
        equals(0),
      );

      final cfg25Pro = GeminiService.buildGenerationConfigForModel(
        'gemini-2.5-pro',
        isConnectionTest: true,
      );
      expect(cfg25Pro['maxOutputTokens'], equals(128));
      expect(
        (cfg25Pro['thinkingConfig'] as Map<String, dynamic>)['thinkingBudget'],
        equals(128),
      );
    });

    test('Concatena múltiplas parts, ignora partes de thought e detecta MAX_TOKENS', () {
      final complete = GeminiService.parseGenerateContentResponse({
        'candidates': [
          {
            'finishReason': 'STOP',
            'content': {
              'parts': [
                {'thought': true, 'text': 'Raciocínio interno oculto'},
                {'text': 'Olá, Rafael! '},
                {'text': 'Parecer completo.'},
              ],
            },
          },
        ],
      });

      expect(complete.text, equals('Olá, Rafael! Parecer completo.'));
      expect(complete.isTruncated, isFalse);

      final truncated = GeminiService.parseGenerateContentResponse({
        'candidates': [
          {
            'finishReason': 'MAX_TOKENS',
            'content': {
              'parts': [
                {'text': 'Olá, Rafael! Parecer'},
              ],
            },
          },
        ],
      });

      expect(truncated.text, equals('Olá, Rafael! Parecer'));
      expect(truncated.isTruncated, isTrue);
    });

    test('Lança StateError para candidates vazios, parts vazias ou bloqueio SAFETY', () {
      expect(
        () => GeminiService.parseGenerateContentResponse({'candidates': []}),
        throwsStateError,
      );
      expect(
        () => GeminiService.parseGenerateContentResponse({
          'candidates': [
            {
              'finishReason': 'STOP',
              'content': {'parts': []},
            },
          ],
        }),
        throwsStateError,
      );
      expect(
        () => GeminiService.parseGenerateContentResponse({
          'candidates': [
            {
              'finishReason': 'SAFETY',
              'content': {
                'parts': [
                  {'text': 'Texto bloqueado'},
                ],
              },
            },
          ],
        }),
        throwsStateError,
      );
    });
  });
}
