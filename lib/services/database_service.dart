import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _database;

  static bool get isAvailable => _database != null && _database!.isOpen;

  static Database? get db => _database;

  // Fallback em memória para testes unitários ou ambientes sem driver SQLite
  @visibleForTesting
  static final Map<String, String> inMemoryAiInsights = {};

  /// Inicializa o banco de dados. Permite injetar customDb (útil em testes unitários).
  static Future<void> init({Database? customDb}) async {
    if (customDb != null) {
      _database = customDb;
      return;
    }

    if (_database != null && _database!.isOpen) return;

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'biostats.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );

      // Garante criação da tabela de IA mesmo em bancos existentes da v1
      await _database?.execute('''
        CREATE TABLE IF NOT EXISTS ai_insights (
          id TEXT PRIMARY KEY,
          tipo TEXT NOT NULL,
          referencia_id TEXT NOT NULL,
          conteudo_md TEXT NOT NULL,
          modelo TEXT NOT NULL,
          criado_em TEXT NOT NULL
        )
      ''');
    } catch (e) {
      // Quando executado em host sem sqflite nativo (ex. testes no Windows)
      _database = null;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        data_nascimento TEXT NOT NULL,
        sexo TEXT NOT NULL,
        altura_cm REAL NOT NULL,
        meta_peso_kg REAL,
        meta_bf_pct REAL,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE avaliacoes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        data_avaliacao TEXT NOT NULL,
        peso_kg REAL NOT NULL,
        nivel_atividade REAL NOT NULL,
        objetivo TEXT NOT NULL,
        medidas_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE resultados (
        id TEXT PRIMARY KEY,
        avaliacao_id TEXT NOT NULL UNIQUE,
        calculos_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fotos (
        id TEXT PRIMARY KEY,
        avaliacao_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        tipo TEXT NOT NULL,
        file_path TEXT NOT NULL,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pesagens (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        data TEXT NOT NULL,
        peso_kg REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_insights (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        referencia_id TEXT NOT NULL,
        conteudo_md TEXT NOT NULL,
        modelo TEXT NOT NULL,
        criado_em TEXT NOT NULL
      )
    ''');
  }

  // --- Profile ---

  static Future<UserProfile?> getProfile() async {
    if (!isAvailable) return null;
    final rows = await _database!.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserProfile(
      id: r['id'] as String,
      nome: r['nome'] as String,
      dataNascimento: DateTime.parse(r['data_nascimento'] as String),
      sexo: (r['sexo'] as String) == 'F' ? Sexo.F : Sexo.M,
      alturaCm: (r['altura_cm'] as num).toDouble(),
      metaPesoKg: (r['meta_peso_kg'] as num?)?.toDouble(),
      metaBfPct: (r['meta_bf_pct'] as num?)?.toDouble(),
      criadoEm: DateTime.tryParse(r['criado_em'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static Future<void> saveProfile(UserProfile profile) async {
    if (!isAvailable) return;
    await _database!.insert(
      'user_profile',
      {
        'id': profile.id,
        'nome': profile.nome,
        'data_nascimento': profile.dataNascimento.toIso8601String(),
        'sexo': profile.sexo.name,
        'altura_cm': profile.alturaCm,
        'meta_peso_kg': profile.metaPesoKg,
        'meta_bf_pct': profile.metaBfPct,
        'criado_em': profile.criadoEm.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteProfile() async {
    if (!isAvailable) return;
    await _database!.delete('user_profile');
  }

  // --- Avaliacoes ---

  static Future<List<Avaliacao>> getAvaliacoes() async {
    if (!isAvailable) return [];
    final rows = await _database!.query('avaliacoes', orderBy: 'data_avaliacao DESC');
    return rows.map((r) {
      final objStr = r['objetivo'] as String? ?? 'manutencao';
      final obj = Objetivo.values.firstWhere(
        (e) => e.name == objStr,
        orElse: () => Objetivo.manutencao,
      );
      final medidasMap = jsonDecode(r['medidas_json'] as String? ?? '{}') as Map<String, dynamic>;
      return Avaliacao(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        dataAvaliacao: DateTime.parse(r['data_avaliacao'] as String),
        pesoKg: (r['peso_kg'] as num).toDouble(),
        nivelAtividade: (r['nivel_atividade'] as num).toDouble(),
        objetivo: obj,
        medidas: MedidasCorporais.fromJson(medidasMap),
      );
    }).toList();
  }

  static Future<void> upsertAvaliacao(Avaliacao a) async {
    if (!isAvailable) return;
    await _database!.insert(
      'avaliacoes',
      {
        'id': a.id,
        'user_id': a.userId,
        'data_avaliacao': a.dataAvaliacao.toIso8601String(),
        'peso_kg': a.pesoKg,
        'nivel_atividade': a.nivelAtividade,
        'objetivo': a.objetivo.name,
        'medidas_json': jsonEncode(a.medidas.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteAvaliacao(String id) async {
    if (!isAvailable) return;
    await _database!.delete('avaliacoes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Resultados ---

  static Future<List<Resultados>> getResultados() async {
    if (!isAvailable) return [];
    final rows = await _database!.query('resultados');
    return rows.map((r) {
      final calcMap = jsonDecode(r['calculos_json'] as String? ?? '{}') as Map<String, dynamic>;
      return Resultados(
        id: r['id'] as String,
        avaliacaoId: r['avaliacao_id'] as String,
        calculos: calcMap,
      );
    }).toList();
  }

  static Future<void> upsertResultado(Resultados r) async {
    if (!isAvailable) return;
    await _database!.insert(
      'resultados',
      {
        'id': r.id,
        'avaliacao_id': r.avaliacaoId,
        'calculos_json': jsonEncode(r.calculos),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteResultado(String avaliacaoId) async {
    if (!isAvailable) return;
    await _database!.delete('resultados', where: 'avaliacao_id = ?', whereArgs: [avaliacaoId]);
  }

  // --- Fotos ---

  static Future<List<FotoAvaliacao>> getFotos() async {
    if (!isAvailable) return [];
    final rows = await _database!.query('fotos');
    return rows.map((r) {
      final tipoStr = r['tipo'] as String? ?? 'frente';
      final tipo = FotoTipo.values.firstWhere(
        (e) => e.name == tipoStr,
        orElse: () => FotoTipo.frente,
      );
      return FotoAvaliacao(
        id: r['id'] as String,
        avaliacaoId: r['avaliacao_id'] as String,
        userId: r['user_id'] as String,
        tipo: tipo,
        fotoBase64: '',
        filePath: r['file_path'] as String?,
        criadoEm: DateTime.tryParse(r['criado_em'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  static Future<void> upsertFoto(FotoAvaliacao f) async {
    if (!isAvailable) return;
    await _database!.insert(
      'fotos',
      {
        'id': f.id,
        'avaliacao_id': f.avaliacaoId,
        'user_id': f.userId,
        'tipo': f.tipo.name,
        'file_path': f.filePath ?? '',
        'criado_em': f.criadoEm.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteFoto(String id) async {
    if (!isAvailable) return;
    await _database!.delete('fotos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteFotosByAvaliacaoId(String avaliacaoId) async {
    if (!isAvailable) return;
    await _database!.delete('fotos', where: 'avaliacao_id = ?', whereArgs: [avaliacaoId]);
  }

  // --- Pesagens ---

  static Future<List<Pesagem>> getPesagens() async {
    if (!isAvailable) return [];
    final rows = await _database!.query('pesagens', orderBy: 'data ASC');
    return rows.map((r) {
      return Pesagem(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        data: DateTime.parse(r['data'] as String),
        pesoKg: (r['peso_kg'] as num).toDouble(),
      );
    }).toList();
  }

  static Future<void> upsertPesagem(Pesagem p) async {
    if (!isAvailable) return;
    await _database!.insert(
      'pesagens',
      {
        'id': p.id,
        'user_id': p.userId,
        'data': p.data.toIso8601String(),
        'peso_kg': p.pesoKg,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deletePesagem(String id) async {
    if (!isAvailable) return;
    await _database!.delete('pesagens', where: 'id = ?', whereArgs: [id]);
  }

  // --- Settings ---

  static Future<String?> getSetting(String key) async {
    if (!isAvailable) return null;
    final rows = await _database!.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> setSetting(String key, String value) async {
    if (!isAvailable) return;
    await _database!.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeSetting(String key) async {
    if (!isAvailable) return;
    await _database!.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  // --- AI Insights (Gemini) ---

  static Future<String?> getAiInsight(String tipo, String referenciaId) async {
    final key = '$tipo:$referenciaId';
    if (!isAvailable) {
      return inMemoryAiInsights[key];
    }
    try {
      final rows = await _database!.query(
        'ai_insights',
        where: 'tipo = ? AND referencia_id = ?',
        whereArgs: [tipo, referenciaId],
        orderBy: 'criado_em DESC',
        limit: 1,
      );
      if (rows.isEmpty) return inMemoryAiInsights[key];
      return rows.first['conteudo_md'] as String?;
    } catch (_) {
      return inMemoryAiInsights[key];
    }
  }

  static Future<void> saveAiInsight({
    required String tipo,
    required String referenciaId,
    required String conteudoMd,
    required String modelo,
  }) async {
    final key = '$tipo:$referenciaId';
    inMemoryAiInsights[key] = conteudoMd;
    if (!isAvailable) return;
    try {
      final id =
          '${tipo}_${referenciaId}_${DateTime.now().millisecondsSinceEpoch}';
      await _database!.insert(
        'ai_insights',
        {
          'id': id,
          'tipo': tipo,
          'referencia_id': referenciaId,
          'conteudo_md': conteudoMd,
          'modelo': modelo,
          'criado_em': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  static Future<void> deleteAiInsight(String tipo, String referenciaId) async {
    final key = '$tipo:$referenciaId';
    inMemoryAiInsights.remove(key);
    if (!isAvailable) return;
    try {
      await _database!.delete(
        'ai_insights',
        where: 'tipo = ? AND referencia_id = ?',
        whereArgs: [tipo, referenciaId],
      );
    } catch (_) {}
  }

  // --- Bulk & Reset ---

  static Future<void> clearAll() async {
    inMemoryAiInsights.clear();
    if (!isAvailable) return;
    await _database!.transaction((txn) async {
      await txn.delete('user_profile');
      await txn.delete('avaliacoes');
      await txn.delete('resultados');
      await txn.delete('fotos');
      await txn.delete('pesagens');
      await txn.delete('app_settings');
      try {
        await txn.delete('ai_insights');
      } catch (_) {}
    });
  }
}
