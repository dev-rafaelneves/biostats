import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_state.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

enum _RestoreChoice { merge, overwrite }

class DataBackupManager extends StatefulWidget {
  final AppState appState;

  const DataBackupManager({
    super.key,
    required this.appState,
  });

  @override
  State<DataBackupManager> createState() => _DataBackupManagerState();
}

class _DataBackupManagerState extends State<DataBackupManager> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _messageText;
  bool _isSuccess = true;

  Future<void> _handleExportData() async {
    setState(() {
      _isExporting = true;
      _messageText = null;
    });

    try {
      final backupData = widget.appState.exportBackupJson();
      final jsonStr = jsonEncode(backupData);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final filename = 'backup-biostats-$dateStr.json';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'application/json',
          ),
        ],
        subject: 'Backup BioStats ($dateStr)',
      );

      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _messageText = 'Backup exportado com sucesso!';
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageText = 'Falha ao exportar os dados.';
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleShareOneTouch() async {
    setState(() {
      _isExporting = true;
      _messageText = null;
    });
    try {
      final shared = await BackupService.instance.shareBackup(widget.appState);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _messageText = shared
            ? 'Backup compartilhado com sucesso!'
            : 'Compartilhamento cancelado.';
        _isSuccess = shared;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageText = 'Erro ao compartilhar backup: $e';
        _isSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleSaveToDocuments() async {
    setState(() {
      _isExporting = true;
      _messageText = null;
    });
    try {
      final res =
          await BackupService.instance.generateLocalBackup(widget.appState);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _messageText = res.success
            ? 'Backup salvo em Documentos/backups!'
            : (res.message ?? 'Falha ao salvar backup.');
        _isSuccess = res.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageText = 'Erro ao salvar backup: $e';
        _isSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<_RestoreChoice?> _confirmRestoreModal(
    BuildContext context,
    BackupPreviewInfo preview,
  ) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final dateLabel = preview.timestamp != null
        ? 'Gerado em ${dateFmt.format(preview.timestamp!.toLocal())}\n'
        : '';

    return showCupertinoModalPopup<_RestoreChoice>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Restaurar Backup de ${preview.profileName}'),
        message: Text(
          '${dateLabel}O arquivo contém ${preview.avaliacoesCount} avaliações, '
          '${preview.fotosCount} fotos e ${preview.pesagensCount} pesagens diárias.\n\n'
          'Como deseja restaurar estes dados?',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(_RestoreChoice.merge),
            child: const Text('Mesclar com Dados Atuais'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(_RestoreChoice.overwrite),
            child: const Text('Substituir Todos os Dados Atuais'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _handleImportData() async {
    setState(() {
      _isImporting = true;
      _messageText = null;
    });

    try {
      const typeGroup = XTypeGroup(
        label: 'JSON Backup',
        extensions: ['json'],
        mimeTypes: ['application/json', 'text/json', 'text/plain'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final jsonContent = await file.readAsString();
      final parsed = jsonDecode(jsonContent) as Map<String, dynamic>;
      final preview = widget.appState.inspectBackupJson(parsed);

      if (!mounted) return;
      final choice = await _confirmRestoreModal(context, preview);
      if (choice == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      await widget.appState.importBackupJson(
        parsed,
        merge: choice == _RestoreChoice.merge,
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _messageText = choice == _RestoreChoice.merge
            ? 'Dados mesclados com sucesso!'
            : 'Dados restaurados com sucesso!';
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageText = 'Arquivo inválido ou corrompido.';
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup de Dados',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Salve uma cópia de segurança do seu progresso no seu dispositivo ou restaure dados antigos (mesclando ou substituindo).',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: (_isExporting || _isImporting) ? null : _handleShareOneTouch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.indigoLight
                        : AppColors.indigoPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Compartilhar Backup em 1 Toque',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 16, height: 1),
          InkWell(
            onTap: (_isExporting || _isImporting)
                ? null
                : _handleSaveToDocuments,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_zip_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.indigoLight
                        : AppColors.indigoPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Salvar Cópia em Documentos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 16, height: 1),
          InkWell(
            onTap: (_isExporting || _isImporting) ? null : _handleExportData,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_download_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.indigoLight
                        : AppColors.indigoPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exportar Backup (JSON)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 16, height: 1),
          InkWell(
            onTap: (_isExporting || _isImporting) ? null : _handleImportData,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.indigoLight
                        : AppColors.indigoPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Importar Backup (JSON)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_messageText != null) ...[
            const Divider(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: _isSuccess
                  ? const Color(0xFF10B981)
                      .withValues(alpha: isDark ? 0.16 : 0.1)
                  : const Color(0xFFF43F5E)
                      .withValues(alpha: isDark ? 0.16 : 0.1),
              child: Row(
                children: [
                  Icon(
                    _isSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    size: 20,
                    color: _isSuccess
                        ? const Color(0xFF10B981)
                        : AppColors.rose,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _messageText!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _isSuccess
                            ? const Color(0xFF059669)
                            : AppColors.rose,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
