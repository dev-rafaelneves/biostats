import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  static Directory? _overridePhotosDirectory;

  /// Permite definir um diretório customizado em testes unitários
  static void setOverrideDirectory(Directory? dir) {
    _overridePhotosDirectory = dir;
  }

  /// Retorna o diretório persistente onde as fotos corporais são armazenadas
  static Future<Directory> getPhotosDirectory() async {
    if (_overridePhotosDirectory != null) {
      if (!await _overridePhotosDirectory!.exists()) {
        await _overridePhotosDirectory!.create(recursive: true);
      }
      return _overridePhotosDirectory!;
    }

    try {
      final docs = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(docs.path, 'biostats_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      return photosDir;
    } catch (e) {
      // Fallback para testes ou plataformas sem plugin ativo
      final temp = Directory.systemTemp.createTempSync('biostats_photos_fallback');
      return temp;
    }
  }

  /// Salva os bytes brutos de uma foto JPEG no sistema de arquivos e retorna o caminho absoluto
  static Future<String> savePhotoBytes(String photoId, Uint8List bytes) async {
    final dir = await getPhotosDirectory();
    final filePath = p.join(dir.path, '$photoId.jpg');
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Converte uma string Base64 em arquivo JPEG no disco e retorna o caminho
  static Future<String?> savePhotoFromBase64(String photoId, String base64Raw) async {
    if (base64Raw.trim().isEmpty) return null;
    try {
      final clean = base64Raw.contains(',') ? base64Raw.split(',').last : base64Raw;
      final bytes = base64Decode(clean);
      return await savePhotoBytes(photoId, bytes);
    } catch (e) {
      debugPrint('Erro ao decodificar Base64 da foto $photoId: $e');
      return null;
    }
  }

  /// Lê os bytes de uma foto do disco
  static Future<Uint8List?> readPhotoBytes(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Erro ao ler foto do caminho $filePath: $e');
    }
    return null;
  }

  /// Apaga o arquivo de foto do disco
  static Future<void> deletePhotoFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Erro ao deletar foto $filePath: $e');
    }
  }

  /// Limpa todos os arquivos de fotos do diretório (usado no reset geral)
  static Future<void> clearAllPhotos() async {
    try {
      final dir = await getPhotosDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao limpar diretório de fotos: $e');
    }
  }
}
