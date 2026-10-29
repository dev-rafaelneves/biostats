import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _keySecurePinHash = 'biostats_pin_sha256';
  static const String _keySecurePinSalt = 'biostats_pin_salt';
  static const String _keyFailedAttempts = 'biostats_failed_pin_attempts';
  static const String _keyLockoutUntil = 'biostats_lockout_until_iso';
  static const String _keyBiometricsEnabled = 'biostats_biometrics_enabled';
  static const String _keyBlockScreenshots = 'biostats_block_screenshots';

  static const MethodChannel _securityChannel =
      MethodChannel('com.rafaelneves.biostats/security');

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Fallback em memória para testes unitários ou ambientes sem keystore nativo
  @visibleForTesting
  static final Map<String, String> inMemorySecureStore = {};

  /// Indica se está rodando em ambiente de testes automatizados do Flutter
  static bool get isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Gera um salt criptograficamente seguro em formato hexadecimal
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Calcula o hash SHA-256 do PIN concatenado ao Salt
  static String hashPin(String pin, String salt) {
    final input = '$salt:$pin';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Salva o PIN de forma segura como SHA-256(salt + PIN)
  static Future<void> saveSecurePin(String pin) async {
    final salt = generateSalt();
    final hashed = hashPin(pin, salt);

    inMemorySecureStore[_keySecurePinSalt] = salt;
    inMemorySecureStore[_keySecurePinHash] = hashed;

    if (isTestEnvironment) return;

    try {
      await _secureStorage
          .write(key: _keySecurePinSalt, value: salt)
          .timeout(const Duration(milliseconds: 500));
      await _secureStorage
          .write(key: _keySecurePinHash, value: hashed)
          .timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Aviso ao salvar no FlutterSecureStorage: $e');
    }
  }

  /// Remove o PIN seguro configurado
  static Future<void> removeSecurePin() async {
    inMemorySecureStore.remove(_keySecurePinSalt);
    inMemorySecureStore.remove(_keySecurePinHash);

    if (isTestEnvironment) return;

    try {
      await _secureStorage
          .delete(key: _keySecurePinSalt)
          .timeout(const Duration(milliseconds: 500));
      await _secureStorage
          .delete(key: _keySecurePinHash)
          .timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Aviso ao deletar do FlutterSecureStorage: $e');
    }
  }

  /// Verifica se existe um PIN seguro configurado
  static Future<bool> hasSecurePin() async {
    if (inMemorySecureStore.containsKey(_keySecurePinHash)) return true;
    if (isTestEnvironment) return false;

    try {
      final hash = await _secureStorage
          .read(key: _keySecurePinHash)
          .timeout(const Duration(milliseconds: 500));
      return hash != null && hash.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Valida o PIN informado pelo usuário contra o hash armazenado
  static Future<bool> verifyPin(String candidatePin) async {
    String? salt = inMemorySecureStore[_keySecurePinSalt];
    String? storedHash = inMemorySecureStore[_keySecurePinHash];

    if ((salt == null || storedHash == null) && !isTestEnvironment) {
      try {
        salt = await _secureStorage
            .read(key: _keySecurePinSalt)
            .timeout(const Duration(milliseconds: 500));
        storedHash = await _secureStorage
            .read(key: _keySecurePinHash)
            .timeout(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Erro ao ler PIN do secure storage: $e');
      }
    }

    if (salt == null || storedHash == null) return false;

    final candidateHash = hashPin(candidatePin.trim(), salt);
    return candidateHash == storedHash;
  }

  /// Migração transparente: converte PIN legado em texto puro para hash SHA-256 com salt
  static Future<void> migrateLegacyPinIfNecessary(SharedPreferences? prefs) async {
    const legacyKey = 'biostats_app_pin';
    final legacyPin = prefs?.getString(legacyKey);

    if (legacyPin != null && legacyPin.isNotEmpty) {
      final alreadySecured = await hasSecurePin();
      if (!alreadySecured) {
        await saveSecurePin(legacyPin);
      }
      // Remove o texto puro para não deixar credenciais expostas
      await prefs?.remove(legacyKey);
    }
  }

  // --- Gestão de Tentativas e Lockout ---

  /// Calcula a duração de bloqueio baseada no número de erros:
  /// - 5 erros: 30 segundos
  /// - 6 erros: 60 segundos (1 minuto)
  /// - 7+ erros: 300 segundos (5 minutos)
  static int calculateLockoutSeconds(int attempts) {
    if (attempts < 5) return 0;
    if (attempts == 5) return 30;
    if (attempts == 6) return 60;
    return 300;
  }

  /// Registra uma tentativa incorreta e retorna o novo DateTime de desbloqueio caso atinja lockout
  static Future<DateTime?> recordFailedAttempt(SharedPreferences? prefs) async {
    final currentAttempts = (prefs?.getInt(_keyFailedAttempts) ?? 0) + 1;
    await prefs?.setInt(_keyFailedAttempts, currentAttempts);

    final lockoutSeconds = calculateLockoutSeconds(currentAttempts);
    if (lockoutSeconds > 0) {
      final lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));
      await prefs?.setString(_keyLockoutUntil, lockoutUntil.toIso8601String());
      return lockoutUntil;
    }
    return null;
  }

  /// Reseta o contador de erros e o lockout após autenticação com sucesso
  static Future<void> resetFailedAttempts(SharedPreferences? prefs) async {
    await prefs?.remove(_keyFailedAttempts);
    await prefs?.remove(_keyLockoutUntil);
  }

  /// Retorna o número de falhas acumuladas
  static int getFailedAttempts(SharedPreferences? prefs) {
    return prefs?.getInt(_keyFailedAttempts) ?? 0;
  }

  /// Retorna o timestamp de término do lockout atual, se houver
  static DateTime? getLockoutUntil(SharedPreferences? prefs) {
    final raw = prefs?.getString(_keyLockoutUntil);
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw);
      if (dt.isAfter(DateTime.now())) {
        return dt;
      }
    } catch (_) {}
    return null;
  }

  /// Retorna quantos segundos faltam para liberar o lockout
  static int getRemainingLockoutSeconds(DateTime? lockoutUntil) {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  // --- Biometria Real (Digital / Rosto) ---

  /// Verifica se o dispositivo possui hardware biométrico configurado e suportado
  static Future<bool> canAuthenticateWithBiometrics() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Realiza o prompt de autenticação biométrica nativa do sistema operacional
  static Future<bool> authenticateBiometric({
    String localizedReason = 'Confirme sua biometria para acessar o BioStats',
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Aviso de erro na autenticação biométrica: $e');
      return false;
    }
  }

  // --- FLAG_SECURE (Ocultar nos recentes e bloquear prints) ---

  /// Liga ou desliga FLAG_SECURE na janela do Android via MethodChannel
  static Future<void> setFlagSecure(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _securityChannel.invokeMethod('setFlagSecure', {'enabled': enabled});
    } catch (_) {
      // Ignora silenciosamente em testes ou plataformas sem implementação nativa
    }
  }

  // --- Configurações de Preferência de Segurança ---

  static bool isBiometricsEnabled(SharedPreferences? prefs) {
    return prefs?.getBool(_keyBiometricsEnabled) ?? true;
  }

  static Future<void> setBiometricsEnabled(SharedPreferences? prefs, bool enabled) async {
    await prefs?.setBool(_keyBiometricsEnabled, enabled);
  }

  static bool isBlockScreenshotsEnabled(SharedPreferences? prefs) {
    // Por padrão ligado quando o usuário usa proteção
    return prefs?.getBool(_keyBlockScreenshots) ?? true;
  }

  static Future<void> setBlockScreenshotsEnabled(SharedPreferences? prefs, bool enabled) async {
    await prefs?.setBool(_keyBlockScreenshots, enabled);
    await setFlagSecure(enabled);
  }
}
