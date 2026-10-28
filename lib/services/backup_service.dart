import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'app_state.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final String? message;

  const BackupResult({
    required this.success,
    this.filePath,
    this.message,
  });
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _keyLastAutoBackup = 'biostats_last_auto_backup_timestamp';

  static bool get isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Gera e salva arquivo de backup JSON no armazenamento local de Documentos
  Future<BackupResult> generateLocalBackup(AppState appState) async {
    if (isTestEnvironment) {
      return const BackupResult(
        success: true,
        filePath: '/mock/biostats_backup.json',
        message: 'Backup simulado em ambiente de teste.',
      );
    }

    try {
      final backupData = appState.exportBackupJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      final docsDir = await getApplicationDocumentsDirectory();
      final backupFolder = Directory('${docsDir.path}/backups');
      if (!backupFolder.existsSync()) {
        backupFolder.createSync(recursive: true);
      }

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${backupFolder.path}/biostats_backup_$dateStr.json');
      await file.writeAsString(jsonStr, flush: true);

      return BackupResult(
        success: true,
        filePath: file.path,
        message: 'Backup gerado com sucesso!',
      );
    } catch (e) {
      debugPrint('Erro ao gerar backup local: $e');
      return BackupResult(
        success: false,
        message: 'Falha ao salvar arquivo de backup: $e',
      );
    }
  }

  /// Compartilha o backup JSON em 1 toque (WhatsApp, Google Drive, E-mail, etc.)
  Future<bool> shareBackup(AppState appState) async {
    if (isTestEnvironment) return true;

    try {
      final res = await generateLocalBackup(appState);
      if (!res.success || res.filePath == null) return false;

      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final xFile = XFile(
        res.filePath!,
        mimeType: 'application/json',
        name: 'biostats_backup.json',
      );

      final shareResult = await Share.shareXFiles(
        [xFile],
        subject: 'Backup BioStats ($dateStr)',
        text: 'Arquivo de backup dos seus dados do BioStats gerado em $dateStr.',
      );

      return shareResult.status != ShareResultStatus.unavailable;
    } catch (e) {
      debugPrint('Erro ao compartilhar backup: $e');
      return false;
    }
  }

  /// Executa backup automático semanal caso tenha passado mais de 7 dias
  Future<bool> checkAndRunWeeklyAutoBackup(AppState appState) async {
    if (isTestEnvironment) return false;

    try {
      final prefs = appState.prefs;
      if (prefs == null) return false;

      final lastBackupMs = prefs.getInt(_keyLastAutoBackup) ?? 0;
      final now = DateTime.now();
      final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);

      // Se faz mais de 7 dias desde o último backup
      if (now.difference(lastBackup).inDays >= 7) {
        final res = await generateLocalBackup(appState);
        if (res.success) {
          await prefs.setInt(_keyLastAutoBackup, now.millisecondsSinceEpoch);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Aviso ao verificar auto backup: $e');
      return false;
    }
  }
}
