import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/models.dart';

class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService instance = HealthConnectService._();

  final Health _health = Health();
  bool _isConfigured = false;

  /// Retorna true se estiver rodando em ambiente de testes automatizados
  static bool get isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureConfigured() async {
    if (isTestEnvironment) return;
    if (!_isConfigured) {
      await _health.configure();
      _isConfigured = true;
    }
  }

  /// Verifica se Health Connect / Apple Health está disponível na plataforma atual
  Future<bool> isAvailable() async {
    if (kIsWeb || isTestEnvironment) return false;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return false;
      await _ensureConfigured();
      if (Platform.isAndroid) {
        return await _health.isHealthConnectAvailable();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Solicita permissão para leitura de peso corporal
  Future<bool> requestWeightPermission() async {
    if (isTestEnvironment) return false;
    try {
      await _ensureConfigured();
      final types = [HealthDataType.WEIGHT];
      final permissions = [HealthDataAccess.READ];
      final authorized =
          await _health.requestAuthorization(types, permissions: permissions);
      return authorized;
    } catch (e) {
      debugPrint('Erro ao solicitar permissão de peso: $e');
      return false;
    }
  }

  /// Busca registros de peso recentes dos últimos [days] dias de balanças inteligentes
  Future<List<Pesagem>> fetchRecentWeights({
    required String userId,
    int days = 30,
  }) async {
    if (isTestEnvironment) return [];
    try {
      await _ensureConfigured();
      final types = [HealthDataType.WEIGHT];
      final permissions = [HealthDataAccess.READ];
      final hasPerm =
          await _health.hasPermissions(types, permissions: permissions) ?? false;
      if (!hasPerm) {
        final authorized = await requestWeightPermission();
        if (!authorized) return [];
      }

      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: days));
      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );

      final result = <Pesagem>[];
      for (final point in healthData) {
        final val = point.value;
        double? weight;
        if (val is NumericHealthValue) {
          weight = val.numericValue.toDouble();
        }
        if (weight != null && weight > 20 && weight < 400) {
          result.add(
            Pesagem(
              id: 'hc_${point.dateFrom.millisecondsSinceEpoch}',
              userId: userId,
              data: point.dateFrom,
              pesoKg: double.parse(weight.toStringAsFixed(1)),
            ),
          );
        }
      }
      return result;
    } catch (e) {
      debugPrint('Erro ao sincronizar dados do Health Connect: $e');
      return [];
    }
  }
}
