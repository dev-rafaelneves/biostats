import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'security_service.dart';

/// Resultado de teste de conectividade com a API Gemini
class GeminiTestResult {
  final bool success;
  final String message;

  const GeminiTestResult({required this.success, required this.message});
}

/// Serviço de integração com a inteligência artificial do Google Gemini.
/// A chave da API é armazenada estritamente no hardware do dispositivo
/// (FlutterSecureStorage / Android Keystore) e nenhuma informação passa
/// por servidores intermediários.
class GeminiService {
  static const String _keyGeminiApiKey = 'biostats_gemini_api_key';
  static const String _defaultModel = 'gemini-3.8-flash';
  static String _activeModel = _defaultModel;
  static const List<String> candidateModels = [
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];
  static const String _apiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static String get activeModel => _activeModel;

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Mock para testes automatizados
  @visibleForTesting
  static final Map<String, String> inMemorySecureStore = {};

  /// Mock de resposta de texto para testes de geração
  @visibleForTesting
  static String? mockResponseText;

  /// Salva a chave da API do Gemini de forma segura e local
  static Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (SecurityService.isTestEnvironment) {
      inMemorySecureStore[_keyGeminiApiKey] = trimmed;
      return;
    }
    try {
      await _secureStorage.write(key: _keyGeminiApiKey, value: trimmed);
    } catch (e) {
      inMemorySecureStore[_keyGeminiApiKey] = trimmed;
    }
  }

  /// Recupera a chave da API do Gemini salva localmente
  static Future<String?> getApiKey() async {
    if (SecurityService.isTestEnvironment) {
      return inMemorySecureStore[_keyGeminiApiKey];
    }
    try {
      final key = await _secureStorage.read(key: _keyGeminiApiKey);
      return key ?? inMemorySecureStore[_keyGeminiApiKey];
    } catch (e) {
      return inMemorySecureStore[_keyGeminiApiKey];
    }
  }

  /// Verifica se há uma chave da API configurada
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  /// Remove a chave da API do armazenamento seguro
  static Future<void> removeApiKey() async {
    if (SecurityService.isTestEnvironment) {
      inMemorySecureStore.remove(_keyGeminiApiKey);
      return;
    }
    try {
      await _secureStorage.delete(key: _keyGeminiApiKey);
      inMemorySecureStore.remove(_keyGeminiApiKey);
    } catch (e) {
      inMemorySecureStore.remove(_keyGeminiApiKey);
    }
  }

  /// Formata a chave para exibição segura mascarada (ex: AIzaSy...9aBc)
  static String maskApiKey(String? key) {
    if (key == null || key.trim().isEmpty) return 'Não configurada';
    final trimmed = key.trim();
    if (trimmed.length <= 10) return '••••••••••••';
    return '${trimmed.substring(0, 6)}••••••••••••${trimmed.substring(trimmed.length - 4)}';
  }

  /// Valida e testa a conectividade da chave diretamente com a API do Gemini
  static Future<GeminiTestResult> testConnection([String? specificKey]) async {
    final keyToTest = specificKey?.trim() ?? await getApiKey();
    if (keyToTest == null || keyToTest.isEmpty) {
      return const GeminiTestResult(
        success: false,
        message: 'Nenhuma chave informada para teste.',
      );
    }

    if (SecurityService.isTestEnvironment) {
      if (keyToTest.contains('invalid') || keyToTest.length < 5) {
        return const GeminiTestResult(
          success: false,
          message: 'Chave de API inválida ou não autorizada.',
        );
      }
      return const GeminiTestResult(
        success: true,
        message: 'Conexão com Gemini estabelecida com sucesso!',
      );
    }

    final modelsToTry = [
      _activeModel,
      ...candidateModels.where((m) => m != _activeModel),
    ];

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': 'Responda apenas com a palavra: OK'},
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': 5,
        'temperature': 0.0,
      },
    };

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      String lastError = '';

      for (final model in modelsToTry) {
        final endpoint = Uri.parse(
          '$_apiBaseUrl/$model:generateContent?key=$keyToTest',
        );

        final request = await client.postUrl(endpoint);
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.write(jsonEncode(payload));

        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          _activeModel = model;
          return GeminiTestResult(
            success: true,
            message: 'Conexão com Gemini validada com sucesso ($model)!',
          );
        }

        String errorMsg = 'Código ${response.statusCode}';
        try {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final errorObj = decoded['error'] as Map<String, dynamic>?;
          if (errorObj != null && errorObj['message'] != null) {
            errorMsg = errorObj['message'].toString();
          }
        } catch (_) {}
        lastError = errorMsg;

        if (response.statusCode != 404) {
          break;
        }
      }

      return GeminiTestResult(
        success: false,
        message: 'Erro na API do Gemini: $lastError',
      );
    } on SocketException catch (e) {
      final detail = e.osError?.message ?? e.message;
      return GeminiTestResult(
        success: false,
        message:
            'Falha de rede ($detail). Verifique sua conexão e tente novamente.',
      );
    } catch (e) {
      return GeminiTestResult(
        success: false,
        message: 'Falha ao testar conexão: $e',
      );
    } finally {
      client?.close();
    }
  }

  /// Gera ou recupera do cache local o parecer clínico da avaliação
  static Future<String> generateEvaluationInsight({
    required UserProfile profile,
    required Avaliacao avaliacao,
    required Resultados resultado,
    bool forceRefresh = false,
  }) async {
    const tipo = 'evaluation_summary';
    final refId = avaliacao.id;

    // 1. Tentar ler do cache local
    if (!forceRefresh) {
      final cached = await DatabaseService.getAiInsight(tipo, refId);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    if (SecurityService.isTestEnvironment && mockResponseText != null) {
      await DatabaseService.saveAiInsight(
        tipo: tipo,
        referenciaId: refId,
        conteudoMd: mockResponseText!,
        modelo: _defaultModel,
      );
      return mockResponseText!;
    }

    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError(
        'Chave da API do Gemini não configurada. Acesse Ajustes para cadastrar.',
      );
    }

    final calc = resultado.snapshot;
    final medidas = avaliacao.medidas;
    final idade = profile.idadeNaData(avaliacao.dataAvaliacao);
    final massaGordaKg =
        (avaliacao.pesoKg - calc.lbmFinal).clamp(0.0, double.infinity);
    final rcqStr = (medidas.cintura != null &&
            medidas.quadril != null &&
            medidas.quadril! > 0)
        ? (medidas.cintura! / medidas.quadril!).toStringAsFixed(2)
        : 'N/D';
    final hasDobras = medidas.dobraAbdomen != null ||
        medidas.dobraTriceps != null ||
        medidas.dobraSuprailiaca != null;
    final dobrasStr = hasDobras
        ? '- Dobras principais: Abdômen: ${medidas.dobraAbdomen?.toStringAsFixed(0) ?? '0'}mm, Tríceps: ${medidas.dobraTriceps?.toStringAsFixed(0) ?? '0'}mm, Suprailíaca: ${medidas.dobraSuprailiaca?.toStringAsFixed(0) ?? '0'}mm'
        : '';

    final prompt = '''
Você é o Bio-Coach, especialista clínico e esportivo em composição corporal do aplicativo BioStats.
Analise os dados biométricos reais abaixo e forneça um parecer motivador, técnico, humanizado e direto.

DADOS DO USUÁRIO:
- Nome: ${profile.nome}
- Sexo: ${profile.sexo.label}
- Idade: $idade anos
- Altura: ${profile.alturaCm.toStringAsFixed(0)} cm
- Peso na Avaliação: ${avaliacao.pesoKg.toStringAsFixed(1)} kg
- Nível de Atividade: ${avaliacao.nivelAtividade}
- Objetivo Declarado: ${avaliacao.objetivo.label}

RESULTADOS CIENTÍFICOS:
- % Gordura: ${calc.bfPrincipal.toStringAsFixed(1)}% (Método: ${calc.metodoPrincipalLabel})
- Massa Magra (LBM): ${calc.lbmFinal.toStringAsFixed(1)} kg
- Massa Gorda: ${massaGordaKg.toStringAsFixed(1)} kg
- Taxa Metabólica Basal (BMR): ${calc.bmrKatch.toStringAsFixed(0)} kcal
- Gasto Energético Total (TDEE): ${calc.tdee.toStringAsFixed(0)} kcal
- Meta Calórica Sugerida: ${calc.macros.targetCalories.toStringAsFixed(0)} kcal
- Proteína Recomendada: ${calc.macros.grams.protein}g (${calc.lbmFinal > 0 ? (calc.macros.grams.protein / calc.lbmFinal).toStringAsFixed(1) : '2.0'}g/kg LBM)

MEDIDAS & CIRCUNFERÊNCIAS:
- Cintura: ${medidas.cintura?.toStringAsFixed(1) ?? 'N/D'} cm
- Quadril: ${medidas.quadril?.toStringAsFixed(1) ?? 'N/D'} cm
- Relação Cintura-Quadril: $rcqStr
- Braço: ${medidas.braco?.toStringAsFixed(1) ?? 'N/D'} cm
- Coxa: ${medidas.coxa?.toStringAsFixed(1) ?? 'N/D'} cm
$dobrasStr

DIRETRIZES DA RESPOSTA:
1. Comece com um **Diagnóstico de Composição Corporal**: interpretação do % de gordura em relação ao sexo e idade e proporção de massa magra.
2. Analise a **Distribuição Corporal e Adiposidade**: relação cintura/quadril, medidas chave e o que indicam sobre simetria e saúde metabólica.
3. Dê **Diretrizes Práticas de Foco**: estratégia nutricional (relação com a meta calórica e proteínas) e foco de treino para o objetivo dele.
4. Mantenha o texto em Markdown elegante, com tópicos claros, emojis discretos e no máximo 300 a 400 palavras.
5. Conclua com um breve aviso ético lembrando que esta análise complementa, mas não substitui, o acompanhamento de um nutricionista ou profissional de saúde.
''';

    final text = await _callGeminiApi(key: key, prompt: prompt);

    // Salvar no cache local SQLite
    await DatabaseService.saveAiInsight(
      tipo: tipo,
      referenciaId: refId,
      conteudoMd: text,
      modelo: _defaultModel,
    );

    return text;
  }

  /// Gera ou recupera do cache a análise comparativa de evolução entre duas avaliações
  static Future<String> generateComparisonInsight({
    required UserProfile profile,
    required Avaliacao anterior,
    required Resultados resultadoAnt,
    required Avaliacao atual,
    required Resultados resultadoAtual,
    bool forceRefresh = false,
  }) async {
    const tipo = 'comparison';
    final refId = '${anterior.id}_${atual.id}';

    if (!forceRefresh) {
      final cached = await DatabaseService.getAiInsight(tipo, refId);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    if (SecurityService.isTestEnvironment && mockResponseText != null) {
      await DatabaseService.saveAiInsight(
        tipo: tipo,
        referenciaId: refId,
        conteudoMd: mockResponseText!,
        modelo: _defaultModel,
      );
      return mockResponseText!;
    }

    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError(
        'Chave da API do Gemini não configurada. Acesse Ajustes para cadastrar.',
      );
    }

    final calcAnt = resultadoAnt.snapshot;
    final calcAtual = resultadoAtual.snapshot;

    final bfAnt = calcAnt.bfPrincipal;
    final bfAtual = calcAtual.bfPrincipal;
    final lbmAnt = calcAnt.lbmFinal;
    final lbmAtual = calcAtual.lbmFinal;
    final gorduraAnt =
        (anterior.pesoKg - lbmAnt).clamp(0.0, double.infinity);
    final gorduraAtual =
        (atual.pesoKg - lbmAtual).clamp(0.0, double.infinity);

    final deltaPeso = atual.pesoKg - anterior.pesoKg;
    final deltaBf = bfAtual - bfAnt;
    final deltaLbm = lbmAtual - lbmAnt;
    final deltaGordura = gorduraAtual - gorduraAnt;
    final dias = atual.dataAvaliacao.difference(anterior.dataAvaliacao).inDays;

    final cinturaAnt = anterior.medidas.cintura;
    final cinturaAtual = atual.medidas.cintura;
    final deltaCinturaStr = (cinturaAnt != null && cinturaAtual != null)
        ? '${(cinturaAtual - cinturaAnt) >= 0 ? "+" : ""}${(cinturaAtual - cinturaAnt).toStringAsFixed(1)} cm'
        : 'N/D';

    final prompt = '''
Você é o Bio-Coach do aplicativo BioStats. Analise a evolução física entre as duas avaliações abaixo:

USUÁRIO: ${profile.nome} (${profile.sexo.label}, ${profile.alturaCm.toStringAsFixed(0)} cm)
PERÍODO: $dias dias decorridos

AVALIAÇÃO ANTERIOR:
- Data: ${anterior.dataAvaliacao.day}/${anterior.dataAvaliacao.month}/${anterior.dataAvaliacao.year}
- Peso: ${anterior.pesoKg.toStringAsFixed(1)} kg | %BF: ${bfAnt.toStringAsFixed(1)}%
- Massa Magra: ${lbmAnt.toStringAsFixed(1)} kg | Gordura: ${gorduraAnt.toStringAsFixed(1)} kg
- Cintura: ${anterior.medidas.cintura?.toStringAsFixed(1) ?? 'N/D'} cm | Quadril: ${anterior.medidas.quadril?.toStringAsFixed(1) ?? 'N/D'} cm

AVALIAÇÃO ATUAL:
- Data: ${atual.dataAvaliacao.day}/${atual.dataAvaliacao.month}/${atual.dataAvaliacao.year}
- Peso: ${atual.pesoKg.toStringAsFixed(1)} kg | %BF: ${bfAtual.toStringAsFixed(1)}%
- Massa Magra: ${lbmAtual.toStringAsFixed(1)} kg | Gordura: ${gorduraAtual.toStringAsFixed(1)} kg
- Cintura: ${atual.medidas.cintura?.toStringAsFixed(1) ?? 'N/D'} cm | Quadril: ${atual.medidas.quadril?.toStringAsFixed(1) ?? 'N/D'} cm

VARIAÇÕES MATEMÁTICAS:
- Delta de Peso: ${deltaPeso >= 0 ? '+' : ''}${deltaPeso.toStringAsFixed(1)} kg
- Delta de %BF: ${deltaBf >= 0 ? '+' : ''}${deltaBf.toStringAsFixed(1)}%
- Delta de Massa Magra: ${deltaLbm >= 0 ? '+' : ''}${deltaLbm.toStringAsFixed(1)} kg
- Delta de Massa Gorda: ${deltaGordura >= 0 ? '+' : ''}${deltaGordura.toStringAsFixed(1)} kg
- Delta de Cintura: $deltaCinturaStr

DIRETRIZES DA ANÁLISE COMPARATIVA:
1. Avalie a **Qualidade da Mudança Corporal**: destaque se a alteração foi recomposição corporal, perda predominante de gordura preservando músculo, ou se houve perda indesejada de massa magra.
2. Destaque as **Conquistas em Medidas**: compare a cintura e circunferências.
3. Forneça uma **Recomendação Estratégica**: pequenos ajustes nutricionais ou de estímulo de treino para manter o ritmo para o próximo período.
4. Mantenha tom encorajador, científico e conciso (máximo 300 palavras), formatado em Markdown com seções claras.
''';

    final text = await _callGeminiApi(key: key, prompt: prompt);

    await DatabaseService.saveAiInsight(
      tipo: tipo,
      referenciaId: refId,
      conteudoMd: text,
      modelo: _defaultModel,
    );

    return text;
  }

  /// Executa chamada HTTP direta para o endpoint de geração do Gemini
  static Future<String> _callGeminiApi({
    required String key,
    required String prompt,
  }) async {
    final modelsToTry = [
      _activeModel,
      ...candidateModels.where((m) => m != _activeModel),
    ];

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': 800,
        'temperature': 0.4,
      },
    };

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      String lastError = '';

      for (final model in modelsToTry) {
        final endpoint = Uri.parse(
          '$_apiBaseUrl/$model:generateContent?key=$key',
        );

        final request = await client.postUrl(endpoint);
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.write(jsonEncode(payload));

        final response = await request.close().timeout(
          const Duration(seconds: 25),
        );
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          _activeModel = model;
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            throw StateError('O modelo não gerou resposta para a solicitação.');
          }

          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) {
            throw StateError('Conteúdo de resposta vazio do Gemini.');
          }

          final text = parts.first['text'] as String?;
          return text?.trim() ?? 'Sem resposta.';
        }

        String msg = 'Código ${response.statusCode}';
        try {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final errorObj = decoded['error'] as Map<String, dynamic>?;
          if (errorObj != null && errorObj['message'] != null) {
            msg = errorObj['message'].toString();
          }
        } catch (_) {}
        lastError = msg;

        if (response.statusCode != 404) {
          break;
        }
      }

      throw StateError('Erro retornado pela API do Gemini: $lastError');
    } on SocketException catch (e) {
      final detail = e.osError?.message ?? e.message;
      throw StateError(
        'Falha de rede ($detail). Verifique sua conexão e tente novamente.',
      );
    } finally {
      client?.close();
    }
  }
}
