import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/calculator.dart';
import 'database_service.dart';
import 'photo_storage_service.dart';

class BackupPreviewInfo {
  final String profileName;
  final DateTime? timestamp;
  final int avaliacoesCount;
  final int resultadosCount;
  final int fotosCount;
  final int pesagensCount;

  const BackupPreviewInfo({
    required this.profileName,
    this.timestamp,
    required this.avaliacoesCount,
    required this.resultadosCount,
    required this.fotosCount,
    required this.pesagensCount,
  });
}

class AppState extends ChangeNotifier {
  static const String _keyUserProfile = 'biostats_user_profile';
  static const String _keyOnboardingDone = 'biostats_onboarding_done';
  static const String _keyDisclaimerAccepted = 'disclaimer_accepted';
  static const String _keyThemeMode = 'biostats-theme';
  static const String _keyAvaliacoes = 'biostats_avaliacoes';
  static const String _keyResultados = 'biostats_resultados';
  static const String _keyFotos = 'biostats_fotos';
  static const String _keyPesagens = 'biostats_pesagens';
  static const String _keyAppPin = 'biostats_app_pin';
  static const String _keyDiscreetPhotos = 'biostats_discreet_photos';
  static const String _keyStorageMigrated = 'storage_migrated_v2';

  SharedPreferences? _prefs;
  bool _initialized = false;

  UserProfile? _userProfile;
  bool _onboardingDone = false;
  bool _disclaimerAccepted = false;
  ThemeMode _themeMode = ThemeMode.light;
  String? _appPin;
  bool _isSessionUnlocked = true;
  bool _discreetPhotos = false;

  List<Avaliacao> _avaliacoes = [];
  List<Resultados> _resultados = [];
  List<FotoAvaliacao> _fotos = [];
  List<Pesagem> _pesagens = [];

  // Índice O(1) de Resultados por avaliacaoId
  final Map<String, Resultados> _resultadosByAvaliacaoId = {};

  // Cache em memória de fotos decodificadas (evita I/O e base64Decode a 60/120fps no slider)
  final Map<String, Uint8List> _decodedFotoCache = {};

  bool get isInitialized => _initialized;
  UserProfile? get userProfile => _userProfile;
  bool get isLoggedIn => _userProfile != null;
  bool get onboardingDone => _onboardingDone;
  bool get disclaimerAccepted => _disclaimerAccepted;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  String? get appPin => _appPin;
  bool get hasPinLock => _appPin != null && _appPin!.isNotEmpty;
  bool get isLocked => hasPinLock && !_isSessionUnlocked;
  bool get discreetPhotos => _discreetPhotos;

  List<Avaliacao> get avaliacoes {
    final sorted = [..._avaliacoes]
      ..sort((a, b) => b.dataAvaliacao.compareTo(a.dataAvaliacao));
    return sorted;
  }

  List<Resultados> get resultados => List.unmodifiable(_resultados);
  List<FotoAvaliacao> get fotos => List.unmodifiable(_fotos);

  List<Pesagem> get pesagens {
    final sorted = [..._pesagens]..sort((a, b) => a.data.compareTo(b.data));
    return sorted;
  }

  /// Retorna todas as avaliações unidas aos seus resultados em O(1) por item
  List<JoinedEvaluation> get joinedEvaluations {
    return avaliacoes.map((av) {
      return JoinedEvaluation(
        avaliacao: av,
        resultado: _resultadosByAvaliacaoId[av.id],
      );
    }).toList();
  }

  Resultados? getResultadoForAvaliacao(String avaliacaoId) {
    return _resultadosByAvaliacaoId[avaliacaoId];
  }

  List<FotoAvaliacao> getFotosForAvaliacao(String avaliacaoId) {
    return _fotos.where((f) => f.avaliacaoId == avaliacaoId).toList();
  }

  /// Decodifica e faz cache em memória dos bytes da foto (60/120 FPS no slider)
  Uint8List? getDecodedPhotoBytes(FotoAvaliacao? foto) {
    if (foto == null) return null;
    final cached = _decodedFotoCache[foto.id];
    if (cached != null) return cached;

    // 1. Tenta carregar do arquivo em disco (SQLite v2)
    if (foto.filePath != null && foto.filePath!.isNotEmpty) {
      try {
        final file = File(foto.filePath!);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          _decodedFotoCache[foto.id] = bytes;
          return bytes;
        }
      } catch (e) {
        debugPrint('Erro ao ler bytes da foto em disco: $e');
      }
    }

    // 2. Fallback para Base64 em memória (dados legados ou temporários)
    if (foto.fotoBase64.isNotEmpty) {
      try {
        final raw = foto.fotoBase64;
        final clean = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(clean);
        _decodedFotoCache[foto.id] = bytes;
        return bytes;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  void _rebuildResultadosIndex() {
    _resultadosByAvaliacaoId.clear();
    for (final r in _resultados) {
      _resultadosByAvaliacaoId[r.avaliacaoId] = r;
    }
  }

  /// Inicializa o AppState, conectando ao SQLite e executando a migração automática se necessário
  Future<void> init({dynamic customDb}) async {
    _prefs = await SharedPreferences.getInstance();

    // 1. Inicializa o banco SQLite
    try {
      await DatabaseService.init(customDb: customDb);
    } catch (e) {
      debugPrint('Aviso ao inicializar DatabaseService: $e');
    }

    // 2. Carrega Tema e Flags
    String? savedTheme;
    try {
      savedTheme = await DatabaseService.getSetting(_keyThemeMode);
    } catch (_) {}
    savedTheme ??= _prefs?.getString(_keyThemeMode);
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    bool? onboarding;
    try {
      final val = await DatabaseService.getSetting(_keyOnboardingDone);
      if (val != null) onboarding = val == 'true';
    } catch (_) {}
    _onboardingDone = onboarding ?? _prefs?.getBool(_keyOnboardingDone) ?? false;

    bool? disclaimer;
    try {
      final val = await DatabaseService.getSetting(_keyDisclaimerAccepted);
      if (val != null) disclaimer = val == 'true';
    } catch (_) {}
    _disclaimerAccepted = disclaimer ?? _prefs?.getBool(_keyDisclaimerAccepted) ?? false;

    try {
      _appPin = await DatabaseService.getSetting(_keyAppPin);
    } catch (_) {}
    _appPin ??= _prefs?.getString(_keyAppPin);
    _isSessionUnlocked = _appPin == null || _appPin!.isEmpty;

    bool? discreet;
    try {
      final val = await DatabaseService.getSetting(_keyDiscreetPhotos);
      if (val != null) discreet = val == 'true';
    } catch (_) {}
    _discreetPhotos = discreet ?? _prefs?.getBool(_keyDiscreetPhotos) ?? false;

    // 3. Executa migração não destrutiva do SharedPreferences para SQLite se aplicável
    bool isMigrated = false;
    try {
      isMigrated = await DatabaseService.getSetting(_keyStorageMigrated) == 'true';
    } catch (_) {}
    isMigrated = isMigrated || (_prefs?.getBool(_keyStorageMigrated) ?? false);

    if (!isMigrated) {
      await _migrateFromSharedPreferences();
    }

    // 4. Carrega Collections do SQLite para a memória se disponível
    if (DatabaseService.isAvailable) {
      final dbProfile = await DatabaseService.getProfile();
      if (dbProfile != null) _userProfile = dbProfile;

      final dbAvaliacoes = await DatabaseService.getAvaliacoes();
      if (dbAvaliacoes.isNotEmpty) _avaliacoes = dbAvaliacoes;

      final dbResultados = await DatabaseService.getResultados();
      if (dbResultados.isNotEmpty) _resultados = dbResultados;

      final dbFotos = await DatabaseService.getFotos();
      if (dbFotos.isNotEmpty) _fotos = dbFotos;

      final dbPesagens = await DatabaseService.getPesagens();
      if (dbPesagens.isNotEmpty) _pesagens = dbPesagens;
    } else {
      if (_userProfile == null) {
        final profileRaw = _prefs?.getString(_keyUserProfile);
        if (profileRaw != null && profileRaw.isNotEmpty) {
          try {
            _userProfile = UserProfile.fromJson(jsonDecode(profileRaw) as Map<String, dynamic>);
          } catch (_) {}
        }
      }
      if (_avaliacoes.isEmpty) {
        _avaliacoes = _loadList(_keyAvaliacoes, Avaliacao.fromJson);
      }
      if (_resultados.isEmpty) {
        _resultados = _loadList(_keyResultados, Resultados.fromJson);
      }
      if (_fotos.isEmpty) {
        _fotos = _loadList(_keyFotos, FotoAvaliacao.fromJson);
      }
      if (_pesagens.isEmpty) {
        _pesagens = _loadList(_keyPesagens, Pesagem.fromJson);
      }
    }

    _rebuildResultadosIndex();

    // 5. Auto-recalcula resultados com versão antiga (calcVersion < 2) com fórmulas científicas
    if (_userProfile != null && _avaliacoes.isNotEmpty) {
      bool recalculouAlgum = false;
      const uuid = Uuid();
      for (int i = 0; i < _avaliacoes.length; i++) {
        final ev = _avaliacoes[i];
        final res = _resultadosByAvaliacaoId[ev.id];
        if (res == null ||
            res.calcVersion < 2 ||
            !res.calculos.containsKey('bfPrincipal')) {
          final novoSnapshot = BioCalculator.buildCalculosSnapshot(
            profile: _userProfile!,
            avaliacao: ev,
          );
          final novoResultado = Resultados(
            id: res?.id ?? uuid.v4(),
            avaliacaoId: ev.id,
            calculos: novoSnapshot.toJson(),
            calcVersion: 2,
          );
          try {
            await DatabaseService.upsertResultado(novoResultado);
          } catch (_) {}

          final idx = _resultados.indexWhere((r) => r.avaliacaoId == ev.id);
          if (idx >= 0) {
            _resultados[idx] = novoResultado;
          } else {
            _resultados.add(novoResultado);
          }
          recalculouAlgum = true;
        }
      }
      if (recalculouAlgum) {
        _rebuildResultadosIndex();
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> _migrateFromSharedPreferences() async {
    try {
      // 1. Perfil
      final profileRaw = _prefs?.getString(_keyUserProfile);
      if (profileRaw != null && profileRaw.isNotEmpty) {
        final profile = UserProfile.fromJson(jsonDecode(profileRaw) as Map<String, dynamic>);
        _userProfile = profile;
        await DatabaseService.saveProfile(profile);
      }

      // 2. Avaliações
      final legacyAvaliacoes = _loadList(_keyAvaliacoes, Avaliacao.fromJson);
      for (final a in legacyAvaliacoes) {
        await DatabaseService.upsertAvaliacao(a);
      }
      _avaliacoes = legacyAvaliacoes;

      // 3. Resultados
      final legacyResultados = _loadList(_keyResultados, Resultados.fromJson);
      for (final r in legacyResultados) {
        await DatabaseService.upsertResultado(r);
      }
      _resultados = legacyResultados;

      // 4. Fotos: Salva cada foto Base64 em arquivo físico JPEG no disco e grava o file_path no SQLite
      final legacyFotos = _loadList(_keyFotos, FotoAvaliacao.fromJson);
      final migratedFotos = <FotoAvaliacao>[];
      for (final f in legacyFotos) {
        String? filePath = f.filePath;
        if ((filePath == null || filePath.isEmpty) && f.fotoBase64.isNotEmpty) {
          filePath = await PhotoStorageService.savePhotoFromBase64(f.id, f.fotoBase64);
        }
        final updatedFoto = f.copyWith(filePath: filePath, fotoBase64: '');
        migratedFotos.add(updatedFoto);
        await DatabaseService.upsertFoto(updatedFoto);
      }
      _fotos = migratedFotos;

      // 5. Pesagens
      final legacyPesagens = _loadList(_keyPesagens, Pesagem.fromJson);
      for (final p in legacyPesagens) {
        await DatabaseService.upsertPesagem(p);
      }
      _pesagens = legacyPesagens;

      // 6. Settings
      await DatabaseService.setSetting(_keyThemeMode, _themeMode == ThemeMode.dark ? 'dark' : 'light');
      await DatabaseService.setSetting(_keyOnboardingDone, _onboardingDone.toString());
      await DatabaseService.setSetting(_keyDisclaimerAccepted, _disclaimerAccepted.toString());
      if (_appPin != null) {
        await DatabaseService.setSetting(_keyAppPin, _appPin!);
      }
      await DatabaseService.setSetting(_keyDiscreetPhotos, _discreetPhotos.toString());

      // 7. Marca como migrado e remove as strings gigantes do SharedPreferences (libera RAM)
      await DatabaseService.setSetting(_keyStorageMigrated, 'true');
      await _prefs?.setBool(_keyStorageMigrated, true);
      await _prefs?.remove(_keyAvaliacoes);
      await _prefs?.remove(_keyResultados);
      await _prefs?.remove(_keyFotos);
      await _prefs?.remove(_keyPesagens);
      debugPrint('Migração do SharedPreferences para SQLite concluída com sucesso!');
    } catch (e, stack) {
      debugPrint('Aviso durante migração para SQLite: $e\n$stack');
    }
  }

  List<T> _loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveList<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final encoded = jsonEncode(list.map((item) => toJson(item)).toList());
    await _prefs?.setString(key, encoded);
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final val = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs?.setString(_keyThemeMode, val);
    try {
      await DatabaseService.setSetting(_keyThemeMode, val);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleDiscreetPhotos() async {
    _discreetPhotos = !_discreetPhotos;
    await _prefs?.setBool(_keyDiscreetPhotos, _discreetPhotos);
    try {
      await DatabaseService.setSetting(_keyDiscreetPhotos, _discreetPhotos.toString());
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setAppPin(String? pin) async {
    final cleaned = pin?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      _appPin = null;
      _isSessionUnlocked = true;
      await _prefs?.remove(_keyAppPin);
      try {
        await DatabaseService.removeSetting(_keyAppPin);
      } catch (_) {}
    } else {
      _appPin = cleaned;
      _isSessionUnlocked = true;
      await _prefs?.setString(_keyAppPin, cleaned);
      try {
        await DatabaseService.setSetting(_keyAppPin, cleaned);
      } catch (_) {}
    }
    notifyListeners();
  }

  bool unlockSession(String candidatePin) {
    if (_appPin == null || candidatePin.trim() == _appPin) {
      _isSessionUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockSession() {
    if (hasPinLock && _isSessionUnlocked) {
      _isSessionUnlocked = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _prefs?.setBool(_keyOnboardingDone, true);
    try {
      await DatabaseService.setSetting(_keyOnboardingDone, 'true');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> acceptDisclaimer() async {
    _disclaimerAccepted = true;
    await _prefs?.setBool(_keyDisclaimerAccepted, true);
    try {
      await DatabaseService.setSetting(_keyDisclaimerAccepted, 'true');
    } catch (_) {}
    notifyListeners();
  }

  /// Salva o perfil e recalcula automaticamente os snapshots históricos se altura/sexo/nascimento mudarem
  Future<void> saveUserProfile(UserProfile profile) async {
    final oldProfile = _userProfile;
    _userProfile = profile;

    await _prefs?.setString(_keyUserProfile, jsonEncode(profile.toJson()));
    try {
      await DatabaseService.saveProfile(profile);
    } catch (_) {}

    final needsRecalc = oldProfile != null &&
        _avaliacoes.isNotEmpty &&
        (oldProfile.alturaCm != profile.alturaCm ||
            oldProfile.sexo != profile.sexo ||
            oldProfile.dataNascimento != profile.dataNascimento);

    if (needsRecalc) {
      const uuid = Uuid();
      final updatedResultados = <Resultados>[];
      for (final av in _avaliacoes) {
        final existing = _resultadosByAvaliacaoId[av.id];
        final newCalc = BioCalculator.buildCalculosSnapshot(
          profile: profile,
          avaliacao: av,
        );
        final res = Resultados(
          id: existing?.id ?? uuid.v4(),
          avaliacaoId: av.id,
          calculos: newCalc.toJson(),
          calcVersion: 2,
        );
        updatedResultados.add(res);
        try {
          await DatabaseService.upsertResultado(res);
        } catch (_) {}
      }
      _resultados = updatedResultados;
      _rebuildResultadosIndex();
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _userProfile = null;
    _disclaimerAccepted = false;
    await _prefs?.remove(_keyUserProfile);
    await _prefs?.remove(_keyDisclaimerAccepted);
    try {
      await DatabaseService.deleteProfile();
      await DatabaseService.removeSetting(_keyDisclaimerAccepted);
    } catch (_) {}
    notifyListeners();
  }

  /// Apaga absolutamente todos os dados salvos no dispositivo (Factory Reset)
  Future<void> resetAllData() async {
    _userProfile = null;
    _onboardingDone = false;
    _disclaimerAccepted = false;
    _appPin = null;
    _isSessionUnlocked = true;
    _discreetPhotos = false;
    _avaliacoes = [];
    _resultados = [];
    _fotos = [];
    _pesagens = [];
    _resultadosByAvaliacaoId.clear();
    _decodedFotoCache.clear();

    try {
      await DatabaseService.clearAll();
      await PhotoStorageService.clearAllPhotos();
    } catch (_) {}

    await _prefs?.clear();
    notifyListeners();
  }

  // --- CRUD de Avaliações, Pesagens e Fotos ---

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Pesagem _upsertPesagemInMemory({
    required String userId,
    required DateTime data,
    required double pesoKg,
  }) {
    final normalizedDate = DateTime(data.year, data.month, data.day);
    final existingIdx =
        _pesagens.indexWhere((p) => _isSameDay(p.data, normalizedDate));
    if (existingIdx >= 0) {
      final old = _pesagens[existingIdx];
      final updated = Pesagem(
        id: old.id,
        userId: userId,
        data: normalizedDate,
        pesoKg: pesoKg,
      );
      _pesagens[existingIdx] = updated;
      return updated;
    } else {
      final created = Pesagem(
        id: const Uuid().v4(),
        userId: userId,
        data: normalizedDate,
        pesoKg: pesoKg,
      );
      _pesagens.add(created);
      return created;
    }
  }

  Future<void> addAvaliacao({
    required Avaliacao avaliacao,
    required Resultados resultado,
    List<FotoAvaliacao> novasFotos = const [],
    bool syncDailyWeight = true,
  }) async {
    // Processa e salva fotos novas no disco
    final processedFotos = <FotoAvaliacao>[];
    for (final f in novasFotos) {
      String? filePath = f.filePath;
      if ((filePath == null || filePath.isEmpty) && f.fotoBase64.isNotEmpty) {
        filePath = await PhotoStorageService.savePhotoFromBase64(f.id, f.fotoBase64);
      }
      processedFotos.add(f.copyWith(filePath: filePath, fotoBase64: ''));
    }

    _avaliacoes.add(avaliacao);
    _resultados.add(resultado);
    _resultadosByAvaliacaoId[avaliacao.id] = resultado;
    if (processedFotos.isNotEmpty) {
      _fotos.addAll(processedFotos);
    }

    // Persistência incremental no SQLite
    try {
      await DatabaseService.upsertAvaliacao(avaliacao);
      await DatabaseService.upsertResultado(resultado);
      for (final f in processedFotos) {
        await DatabaseService.upsertFoto(f);
      }
    } catch (e) {
      debugPrint('Aviso ao persistir avaliacao no SQLite: $e');
    }

    if (syncDailyWeight) {
      final pesagem = _upsertPesagemInMemory(
        userId: avaliacao.userId,
        data: avaliacao.dataAvaliacao,
        pesoKg: avaliacao.pesoKg,
      );
      try {
        await DatabaseService.upsertPesagem(pesagem);
      } catch (_) {}
    }

    if (!DatabaseService.isAvailable) {
      await _saveList(_keyAvaliacoes, _avaliacoes, (a) => a.toJson());
      await _saveList(_keyResultados, _resultados, (r) => r.toJson());
      await _saveList(_keyFotos, _fotos, (f) => f.toJson());
      await _saveList(_keyPesagens, _pesagens, (p) => p.toJson());
    }

    notifyListeners();
  }

  Future<void> updateAvaliacao({
    required Avaliacao avaliacao,
    required Resultados resultado,
    required List<FotoAvaliacao> fotosDaAvaliacao,
    bool syncDailyWeight = true,
  }) async {
    // Processa e salva fotos no disco
    final processedFotos = <FotoAvaliacao>[];
    for (final f in fotosDaAvaliacao) {
      String? filePath = f.filePath;
      if ((filePath == null || filePath.isEmpty) && f.fotoBase64.isNotEmpty) {
        filePath = await PhotoStorageService.savePhotoFromBase64(f.id, f.fotoBase64);
      }
      processedFotos.add(f.copyWith(filePath: filePath, fotoBase64: ''));
    }

    final idx = _avaliacoes.indexWhere((a) => a.id == avaliacao.id);
    if (idx >= 0) {
      _avaliacoes[idx] = avaliacao;
    } else {
      _avaliacoes.add(avaliacao);
    }

    _resultados.removeWhere((r) => r.avaliacaoId == avaliacao.id);
    _resultados.add(resultado);
    _resultadosByAvaliacaoId[avaliacao.id] = resultado;

    // Remove do disco e do cache fotos antigas desta avaliação que foram removidas
    final newPhotoIds = processedFotos.map((f) => f.id).toSet();
    for (final oldFoto in _fotos.where((f) => f.avaliacaoId == avaliacao.id)) {
      if (!newPhotoIds.contains(oldFoto.id)) {
        _decodedFotoCache.remove(oldFoto.id);
        await PhotoStorageService.deletePhotoFile(oldFoto.filePath);
      }
    }

    _fotos.removeWhere((f) => f.avaliacaoId == avaliacao.id);
    _fotos.addAll(processedFotos);

    // Persistência incremental no SQLite
    try {
      await DatabaseService.upsertAvaliacao(avaliacao);
      await DatabaseService.upsertResultado(resultado);
      await DatabaseService.deleteFotosByAvaliacaoId(avaliacao.id);
      for (final f in processedFotos) {
        await DatabaseService.upsertFoto(f);
      }
    } catch (e) {
      debugPrint('Aviso ao atualizar avaliacao no SQLite: $e');
    }

    if (syncDailyWeight) {
      final pesagem = _upsertPesagemInMemory(
        userId: avaliacao.userId,
        data: avaliacao.dataAvaliacao,
        pesoKg: avaliacao.pesoKg,
      );
      try {
        await DatabaseService.upsertPesagem(pesagem);
      } catch (_) {}
    }

    if (!DatabaseService.isAvailable) {
      await _saveList(_keyAvaliacoes, _avaliacoes, (a) => a.toJson());
      await _saveList(_keyResultados, _resultados, (r) => r.toJson());
      await _saveList(_keyFotos, _fotos, (f) => f.toJson());
      await _saveList(_keyPesagens, _pesagens, (p) => p.toJson());
    }

    notifyListeners();
  }

  Future<void> deleteAvaliacao(String avaliacaoId) async {
    _avaliacoes.removeWhere((a) => a.id == avaliacaoId);
    _resultados.removeWhere((r) => r.avaliacaoId == avaliacaoId);
    _resultadosByAvaliacaoId.remove(avaliacaoId);

    for (final f in _fotos.where((f) => f.avaliacaoId == avaliacaoId)) {
      _decodedFotoCache.remove(f.id);
      await PhotoStorageService.deletePhotoFile(f.filePath);
    }
    _fotos.removeWhere((f) => f.avaliacaoId == avaliacaoId);

    try {
      await DatabaseService.deleteAvaliacao(avaliacaoId);
      await DatabaseService.deleteResultado(avaliacaoId);
      await DatabaseService.deleteFotosByAvaliacaoId(avaliacaoId);
    } catch (e) {
      debugPrint('Aviso ao deletar avaliacao no SQLite: $e');
    }

    if (!DatabaseService.isAvailable) {
      await _saveList(_keyAvaliacoes, _avaliacoes, (a) => a.toJson());
      await _saveList(_keyResultados, _resultados, (r) => r.toJson());
      await _saveList(_keyFotos, _fotos, (f) => f.toJson());
    }

    notifyListeners();
  }

  /// Adiciona ou atualiza a pesagem caso já exista registro no mesmo dia
  Future<bool> addPesagem(Pesagem pesagem) async {
    final normalizedDate = DateTime(
      pesagem.data.year,
      pesagem.data.month,
      pesagem.data.day,
    );
    final existingIdx =
        _pesagens.indexWhere((p) => _isSameDay(p.data, normalizedDate));
    final bool updatedExisting = existingIdx >= 0;

    Pesagem toSave;
    if (updatedExisting) {
      final old = _pesagens[existingIdx];
      toSave = Pesagem(
        id: old.id,
        userId: pesagem.userId,
        data: normalizedDate,
        pesoKg: pesagem.pesoKg,
      );
      _pesagens[existingIdx] = toSave;
    } else {
      toSave = Pesagem(
        id: pesagem.id,
        userId: pesagem.userId,
        data: normalizedDate,
        pesoKg: pesagem.pesoKg,
      );
      _pesagens.add(toSave);
    }

    try {
      await DatabaseService.upsertPesagem(toSave);
    } catch (_) {}

    notifyListeners();
    return updatedExisting;
  }

  Future<void> deletePesagem(String pesagemId) async {
    _pesagens.removeWhere((p) => p.id == pesagemId);
    try {
      await DatabaseService.deletePesagem(pesagemId);
    } catch (_) {}
    notifyListeners();
  }

  /// Exporta todo o banco de dados em formato JSON compatível com o BioStats (com fotos em Base64 para portabilidade)
  Map<String, dynamic> exportBackupJson() {
    final exportedFotos = <Map<String, dynamic>>[];
    for (final f in _fotos) {
      String base64Str = f.fotoBase64;
      if (base64Str.isEmpty) {
        final bytes = getDecodedPhotoBytes(f);
        if (bytes != null) {
          base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }
      exportedFotos.add(f.toJson(resolvedBase64: base64Str));
    }

    return {
      'version': 2,
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'perfil_pessoal': _userProfile?.toJson(),
        'clientes': _userProfile != null ? [_userProfile!.toJson()] : [],
        'avaliacoes': _avaliacoes.map((e) => e.toJson()).toList(),
        'resultados': _resultados.map((e) => e.toJson()).toList(),
        'fotos': exportedFotos,
        'pesagens': _pesagens.map((e) => e.toJson()).toList(),
      },
    };
  }

  /// Valida a integridade do arquivo JSON antes de restaurar e retorna um resumo
  BackupPreviewInfo inspectBackupJson(Map<String, dynamic> parsed) {
    final data = parsed['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Estrutura "data" ausente no arquivo JSON.');
    }

    UserProfile? importedProfile;
    if (data['perfil_pessoal'] != null) {
      importedProfile = UserProfile.fromJson(
        Map<String, dynamic>.from(data['perfil_pessoal'] as Map),
      );
    } else if (data['clientes'] is List &&
        (data['clientes'] as List).isNotEmpty) {
      importedProfile = UserProfile.fromJson(
        Map<String, dynamic>.from((data['clientes'] as List).first as Map),
      );
    }

    final avList = ((data['avaliacoes'] as List?) ?? [])
        .map((e) => Avaliacao.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((a) => a.pesoKg > 0 && a.pesoKg < 500)
        .toList();
    final resList = ((data['resultados'] as List?) ?? [])
        .map((e) => Resultados.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final fotosList = ((data['fotos'] as List?) ?? [])
        .map((e) => FotoAvaliacao.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final pesList = ((data['pesagens'] as List?) ?? [])
        .map((e) => Pesagem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((p) => p.pesoKg > 0 && p.pesoKg < 500)
        .toList();

    DateTime? ts;
    if (parsed['timestamp'] != null) {
      ts = DateTime.tryParse(parsed['timestamp'].toString());
    }

    return BackupPreviewInfo(
      profileName: importedProfile?.nome ?? _userProfile?.nome ?? 'Perfil',
      timestamp: ts,
      avaliacoesCount: avList.length,
      resultadosCount: resList.length,
      fotosCount: fotosList.length,
      pesagensCount: pesList.length,
    );
  }

  /// Importa JSON tanto do formato novo quanto do formato legado, suportando Substituir ou Mesclar
  Future<void> importBackupJson(
    Map<String, dynamic> parsed, {
    bool merge = false,
  }) async {
    final data = parsed['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Formato de backup inválido.');
    }

    UserProfile? importedProfile;
    if (data['perfil_pessoal'] != null) {
      importedProfile = UserProfile.fromJson(
        Map<String, dynamic>.from(data['perfil_pessoal'] as Map),
      );
    } else if (data['clientes'] is List &&
        (data['clientes'] as List).isNotEmpty) {
      importedProfile = UserProfile.fromJson(
        Map<String, dynamic>.from((data['clientes'] as List).first as Map),
      );
    }

    if (importedProfile != null && (!merge || _userProfile == null)) {
      _userProfile = importedProfile;
      await _prefs?.setString(_keyUserProfile, jsonEncode(importedProfile.toJson()));
      try {
        await DatabaseService.saveProfile(importedProfile);
      } catch (_) {}
    }

    final incomingAvaliacoes = ((data['avaliacoes'] as List?) ?? [])
        .map((e) => Avaliacao.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((a) => a.pesoKg > 0 && a.pesoKg < 500)
        .toList();
    final incomingResultados = ((data['resultados'] as List?) ?? [])
        .map((e) => Resultados.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Salva fotos no disco físico
    final incomingFotos = <FotoAvaliacao>[];
    for (final rawItem in (data['fotos'] as List?) ?? []) {
      final f = FotoAvaliacao.fromJson(Map<String, dynamic>.from(rawItem as Map));
      String? filePath = f.filePath;
      if (f.fotoBase64.isNotEmpty) {
        filePath = await PhotoStorageService.savePhotoFromBase64(f.id, f.fotoBase64);
      }
      incomingFotos.add(f.copyWith(filePath: filePath, fotoBase64: ''));
    }

    final incomingPesagens = ((data['pesagens'] as List?) ?? [])
        .map((e) => Pesagem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((p) => p.pesoKg > 0 && p.pesoKg < 500)
        .toList();

    if (!merge) {
      _avaliacoes = incomingAvaliacoes;
      _resultados = incomingResultados;
      _fotos = incomingFotos;
      _pesagens = incomingPesagens;
      _decodedFotoCache.clear();

      try {
        await DatabaseService.clearAll();
        if (_userProfile != null) {
          await DatabaseService.saveProfile(_userProfile!);
        }
        for (final a in _avaliacoes) {
          await DatabaseService.upsertAvaliacao(a);
        }
        for (final r in _resultados) {
          await DatabaseService.upsertResultado(r);
        }
        for (final f in _fotos) {
          await DatabaseService.upsertFoto(f);
        }
        for (final p in _pesagens) {
          await DatabaseService.upsertPesagem(p);
        }
      } catch (_) {}
    } else {
      final avMap = {for (final a in _avaliacoes) a.id: a};
      for (final a in incomingAvaliacoes) {
        avMap[a.id] = a;
        try {
          await DatabaseService.upsertAvaliacao(a);
        } catch (_) {}
      }
      _avaliacoes = avMap.values.toList();

      final resMap = {for (final r in _resultados) r.avaliacaoId: r};
      for (final r in incomingResultados) {
        resMap[r.avaliacaoId] = r;
        try {
          await DatabaseService.upsertResultado(r);
        } catch (_) {}
      }
      _resultados = resMap.values.toList();

      final fotoMap = {for (final f in _fotos) f.id: f};
      for (final f in incomingFotos) {
        fotoMap[f.id] = f;
        try {
          await DatabaseService.upsertFoto(f);
        } catch (_) {}
      }
      _fotos = fotoMap.values.toList();

      final pesMap = {for (final p in _pesagens) p.id: p};
      for (final p in incomingPesagens) {
        pesMap[p.id] = p;
        try {
          await DatabaseService.upsertPesagem(p);
        } catch (_) {}
      }
      _pesagens = pesMap.values.toList();
    }

    _rebuildResultadosIndex();
    notifyListeners();
  }
}
