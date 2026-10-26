import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/calculator.dart';

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

  // Cache em memória de fotos decodificadas (evita base64Decode a 60fps no slider)
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

  /// Retorna todas as avaliações unidas aos seus resultados em O(1) por item (sem trava de 15 itens)
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
    if (foto == null || foto.fotoBase64.isEmpty) return null;
    final cached = _decodedFotoCache[foto.id];
    if (cached != null) return cached;

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

  void _rebuildResultadosIndex() {
    _resultadosByAvaliacaoId.clear();
    for (final r in _resultados) {
      _resultadosByAvaliacaoId[r.avaliacaoId] = r;
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load Theme
    final savedTheme = _prefs?.getString(_keyThemeMode);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Load Flags & Security
    _onboardingDone = _prefs?.getBool(_keyOnboardingDone) ?? false;
    _disclaimerAccepted = _prefs?.getBool(_keyDisclaimerAccepted) ?? false;
    _appPin = _prefs?.getString(_keyAppPin);
    _isSessionUnlocked = _appPin == null || _appPin!.isEmpty;
    _discreetPhotos = _prefs?.getBool(_keyDiscreetPhotos) ?? false;

    // Load User Profile
    final profileRaw = _prefs?.getString(_keyUserProfile);
    if (profileRaw != null && profileRaw.isNotEmpty) {
      try {
        _userProfile = UserProfile.fromJson(
          jsonDecode(profileRaw) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('Erro ao carregar perfil: $e');
      }
    }

    // Load Collections
    _avaliacoes = _loadList(_keyAvaliacoes, Avaliacao.fromJson);
    _resultados = _loadList(_keyResultados, Resultados.fromJson);
    _fotos = _loadList(_keyFotos, FotoAvaliacao.fromJson);
    _pesagens = _loadList(_keyPesagens, Pesagem.fromJson);
    _rebuildResultadosIndex();

    _initialized = true;
    notifyListeners();
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
      debugPrint('Erro ao carregar lista $key: $e');
      return [];
    }
  }

  Future<void> _saveList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final encoded = jsonEncode(items.map(toJson).toList());
    await _prefs?.setString(key, encoded);
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs?.setString(
      _keyThemeMode,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }

  Future<void> toggleDiscreetPhotos() async {
    _discreetPhotos = !_discreetPhotos;
    await _prefs?.setBool(_keyDiscreetPhotos, _discreetPhotos);
    notifyListeners();
  }

  Future<void> setAppPin(String? pin) async {
    final cleaned = pin?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      _appPin = null;
      _isSessionUnlocked = true;
      await _prefs?.remove(_keyAppPin);
    } else {
      _appPin = cleaned;
      _isSessionUnlocked = true;
      await _prefs?.setString(_keyAppPin, cleaned);
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
    notifyListeners();
  }

  Future<void> acceptDisclaimer() async {
    _disclaimerAccepted = true;
    await _prefs?.setBool(_keyDisclaimerAccepted, true);
    notifyListeners();
  }

  /// Salva o perfil e recalcula automaticamente os snapshots históricos se altura/sexo/nascimento mudarem
  Future<void> saveUserProfile(UserProfile profile) async {
    final oldProfile = _userProfile;
    _userProfile = profile;
    await _prefs?.setString(_keyUserProfile, jsonEncode(profile.toJson()));

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
        updatedResultados.add(
          Resultados(
            id: existing?.id ?? uuid.v4(),
            avaliacaoId: av.id,
            calculos: newCalc,
          ),
        );
      }
      _resultados = updatedResultados;
      _rebuildResultadosIndex();
      await _saveList(_keyResultados, _resultados, (e) => e.toJson());
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _userProfile = null;
    _disclaimerAccepted = false;
    await _prefs?.remove(_keyUserProfile);
    await _prefs?.remove(_keyDisclaimerAccepted);
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

    await _prefs?.remove(_keyUserProfile);
    await _prefs?.remove(_keyOnboardingDone);
    await _prefs?.remove(_keyDisclaimerAccepted);
    await _prefs?.remove(_keyAppPin);
    await _prefs?.remove(_keyDiscreetPhotos);
    await _prefs?.remove(_keyAvaliacoes);
    await _prefs?.remove(_keyResultados);
    await _prefs?.remove(_keyFotos);
    await _prefs?.remove(_keyPesagens);
    notifyListeners();
  }

  // --- CRUD de Avaliações, Pesagens e Fotos ---

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _upsertPesagemInMemory({
    required String userId,
    required DateTime data,
    required double pesoKg,
  }) {
    final normalizedDate = DateTime(data.year, data.month, data.day);
    final existingIdx =
        _pesagens.indexWhere((p) => _isSameDay(p.data, normalizedDate));
    if (existingIdx >= 0) {
      final old = _pesagens[existingIdx];
      _pesagens[existingIdx] = Pesagem(
        id: old.id,
        userId: userId,
        data: normalizedDate,
        pesoKg: pesoKg,
      );
    } else {
      _pesagens.add(
        Pesagem(
          id: const Uuid().v4(),
          userId: userId,
          data: normalizedDate,
          pesoKg: pesoKg,
        ),
      );
    }
  }

  Future<void> addAvaliacao({
    required Avaliacao avaliacao,
    required Resultados resultado,
    List<FotoAvaliacao> novasFotos = const [],
    bool syncDailyWeight = true,
  }) async {
    _avaliacoes.add(avaliacao);
    _resultados.add(resultado);
    _resultadosByAvaliacaoId[avaliacao.id] = resultado;
    if (novasFotos.isNotEmpty) {
      _fotos.addAll(novasFotos);
    }
    if (syncDailyWeight) {
      _upsertPesagemInMemory(
        userId: avaliacao.userId,
        data: avaliacao.dataAvaliacao,
        pesoKg: avaliacao.pesoKg,
      );
      await _saveList(_keyPesagens, _pesagens, (e) => e.toJson());
    }
    await _saveList(_keyAvaliacoes, _avaliacoes, (e) => e.toJson());
    await _saveList(_keyResultados, _resultados, (e) => e.toJson());
    if (novasFotos.isNotEmpty) {
      await _saveList(_keyFotos, _fotos, (e) => e.toJson());
    }
    notifyListeners();
  }

  Future<void> updateAvaliacao({
    required Avaliacao avaliacao,
    required Resultados resultado,
    required List<FotoAvaliacao> fotosDaAvaliacao,
    bool syncDailyWeight = true,
  }) async {
    final idx = _avaliacoes.indexWhere((a) => a.id == avaliacao.id);
    if (idx >= 0) {
      _avaliacoes[idx] = avaliacao;
    } else {
      _avaliacoes.add(avaliacao);
    }

    _resultados.removeWhere((r) => r.avaliacaoId == avaliacao.id);
    _resultados.add(resultado);
    _resultadosByAvaliacaoId[avaliacao.id] = resultado;

    // Remove fotos antigas desta avaliação do cache e da lista
    for (final f in _fotos.where((f) => f.avaliacaoId == avaliacao.id)) {
      _decodedFotoCache.remove(f.id);
    }
    _fotos.removeWhere((f) => f.avaliacaoId == avaliacao.id);
    _fotos.addAll(fotosDaAvaliacao);

    if (syncDailyWeight) {
      _upsertPesagemInMemory(
        userId: avaliacao.userId,
        data: avaliacao.dataAvaliacao,
        pesoKg: avaliacao.pesoKg,
      );
      await _saveList(_keyPesagens, _pesagens, (e) => e.toJson());
    }

    await _saveList(_keyAvaliacoes, _avaliacoes, (e) => e.toJson());
    await _saveList(_keyResultados, _resultados, (e) => e.toJson());
    await _saveList(_keyFotos, _fotos, (e) => e.toJson());
    notifyListeners();
  }

  Future<void> deleteAvaliacao(String avaliacaoId) async {
    _avaliacoes.removeWhere((a) => a.id == avaliacaoId);
    _resultados.removeWhere((r) => r.avaliacaoId == avaliacaoId);
    _resultadosByAvaliacaoId.remove(avaliacaoId);
    for (final f in _fotos.where((f) => f.avaliacaoId == avaliacaoId)) {
      _decodedFotoCache.remove(f.id);
    }
    _fotos.removeWhere((f) => f.avaliacaoId == avaliacaoId);
    await _saveList(_keyAvaliacoes, _avaliacoes, (e) => e.toJson());
    await _saveList(_keyResultados, _resultados, (e) => e.toJson());
    await _saveList(_keyFotos, _fotos, (e) => e.toJson());
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

    if (updatedExisting) {
      final old = _pesagens[existingIdx];
      _pesagens[existingIdx] = Pesagem(
        id: old.id,
        userId: pesagem.userId,
        data: normalizedDate,
        pesoKg: pesagem.pesoKg,
      );
    } else {
      _pesagens.add(
        Pesagem(
          id: pesagem.id,
          userId: pesagem.userId,
          data: normalizedDate,
          pesoKg: pesagem.pesoKg,
        ),
      );
    }

    await _saveList(_keyPesagens, _pesagens, (e) => e.toJson());
    notifyListeners();
    return updatedExisting;
  }

  Future<void> deletePesagem(String pesagemId) async {
    _pesagens.removeWhere((p) => p.id == pesagemId);
    await _saveList(_keyPesagens, _pesagens, (e) => e.toJson());
    notifyListeners();
  }

  /// Exporta todo o banco de dados em formato JSON compatível com o BioStats
  Map<String, dynamic> exportBackupJson() {
    return {
      'version': 2,
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'perfil_pessoal': _userProfile?.toJson(),
        'clientes': _userProfile != null ? [_userProfile!.toJson()] : [],
        'avaliacoes': _avaliacoes.map((e) => e.toJson()).toList(),
        'resultados': _resultados.map((e) => e.toJson()).toList(),
        'fotos': _fotos.map((e) => e.toJson()).toList(),
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

  /// Importa JSON tanto do formato novo quanto do formato antigo (Dexie), suportando Substituir ou Mesclar
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
      await _prefs?.setString(
        _keyUserProfile,
        jsonEncode(importedProfile.toJson()),
      );
    }

    final incomingAvaliacoes = ((data['avaliacoes'] as List?) ?? [])
        .map((e) => Avaliacao.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((a) => a.pesoKg > 0 && a.pesoKg < 500)
        .toList();
    final incomingResultados = ((data['resultados'] as List?) ?? [])
        .map((e) => Resultados.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final incomingFotos = ((data['fotos'] as List?) ?? [])
        .map((e) => FotoAvaliacao.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
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
    } else {
      final avMap = {for (final a in _avaliacoes) a.id: a};
      for (final a in incomingAvaliacoes) {
        avMap[a.id] = a;
      }
      _avaliacoes = avMap.values.toList();

      final resMap = {for (final r in _resultados) r.avaliacaoId: r};
      for (final r in incomingResultados) {
        resMap[r.avaliacaoId] = r;
      }
      _resultados = resMap.values.toList();

      final fotoMap = {for (final f in _fotos) f.id: f};
      for (final f in incomingFotos) {
        fotoMap[f.id] = f;
      }
      _fotos = fotoMap.values.toList();

      final pesMap = {for (final p in _pesagens) p.id: p};
      for (final p in incomingPesagens) {
        pesMap[p.id] = p;
      }
      _pesagens = pesMap.values.toList();
    }

    _rebuildResultadosIndex();

    await _saveList(_keyAvaliacoes, _avaliacoes, (e) => e.toJson());
    await _saveList(_keyResultados, _resultados, (e) => e.toJson());
    await _saveList(_keyFotos, _fotos, (e) => e.toJson());
    await _saveList(_keyPesagens, _pesagens, (e) => e.toJson());
    notifyListeners();
  }
}
