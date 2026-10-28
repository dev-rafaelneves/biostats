import '../utils/calculator.dart';

enum Sexo {
  M,
  F;

  String get label => this == Sexo.M ? 'Masculino' : 'Feminino';
  String get shortLabel => this == Sexo.M ? 'Masc' : 'Fem';
}

enum Objetivo {
  emagrecimento,
  manutencao,
  hipertrofia;

  String get label {
    switch (this) {
      case Objetivo.emagrecimento:
        return 'Emagrecimento';
      case Objetivo.manutencao:
        return 'Manutenção';
      case Objetivo.hipertrofia:
        return 'Hipertrofia';
    }
  }
}

enum FotoTipo {
  frente,
  lado,
  costas;

  String get label {
    switch (this) {
      case FotoTipo.frente:
        return 'Frente';
      case FotoTipo.lado:
        return 'Perfil';
      case FotoTipo.costas:
        return 'Costas';
    }
  }
}

/// Perfil Único Pessoal (substitui Profissional + Cliente para autoavaliação)
class UserProfile {
  final String id;
  final String nome;
  final DateTime dataNascimento;
  final Sexo sexo;
  final double alturaCm;
  final double? metaPesoKg;
  final double? metaBfPct;
  final DateTime criadoEm;

  const UserProfile({
    required this.id,
    required this.nome,
    required this.dataNascimento,
    required this.sexo,
    required this.alturaCm,
    this.metaPesoKg,
    this.metaBfPct,
    required this.criadoEm,
  });

  int get idade => idadeNaData(DateTime.now());

  int idadeNaData(DateTime data) {
    int age = data.year - dataNascimento.year;
    final mesDiff = data.month - dataNascimento.month;
    if (mesDiff < 0 || (mesDiff == 0 && data.day < dataNascimento.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  String get primeiroNome => nome.trim().split(' ').first;

  UserProfile copyWith({
    String? id,
    String? nome,
    DateTime? dataNascimento,
    Sexo? sexo,
    double? alturaCm,
    double? metaPesoKg,
    double? metaBfPct,
    bool clearMetas = false,
    DateTime? criadoEm,
  }) {
    return UserProfile(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      sexo: sexo ?? this.sexo,
      alturaCm: alturaCm ?? this.alturaCm,
      metaPesoKg: clearMetas ? null : (metaPesoKg ?? this.metaPesoKg),
      metaBfPct: clearMetas ? null : (metaBfPct ?? this.metaBfPct),
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'data_nascimento': dataNascimento.toIso8601String(),
      'sexo': sexo.name,
      'altura_cm': alturaCm,
      if (metaPesoKg != null) 'meta_peso_kg': metaPesoKg,
      if (metaBfPct != null) 'meta_bf_pct': metaBfPct,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    double? toPositiveDouble(dynamic val) {
      if (val == null) return null;
      final d = (val as num).toDouble();
      return d > 0 ? d : null;
    }

    return UserProfile(
      id: json['id'] as String,
      nome: json['nome'] as String,
      dataNascimento: DateTime.parse(json['data_nascimento'] as String),
      sexo: (json['sexo'] as String) == 'F' ? Sexo.F : Sexo.M,
      alturaCm: (json['altura_cm'] as num).toDouble(),
      metaPesoKg: toPositiveDouble(json['meta_peso_kg']),
      metaBfPct: toPositiveDouble(json['meta_bf_pct']),
      criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class MedidasCorporais {
  final double? pescoco;
  final double? cintura;
  final double? quadril;
  final double? abdomen;
  final double? braco;
  final double? coxa;
  final double? panturrilha;

  const MedidasCorporais({
    this.pescoco,
    this.cintura,
    this.quadril,
    this.abdomen,
    this.braco,
    this.coxa,
    this.panturrilha,
  });

  Map<String, dynamic> toJson() => {
        'pescoco': pescoco,
        'cintura': cintura,
        'quadril': quadril,
        'abdomen': abdomen,
        'braco': braco,
        'coxa': coxa,
        'panturrilha': panturrilha,
      };

  factory MedidasCorporais.fromJson(Map<String, dynamic> json) {
    double? toDoubleOrNull(dynamic val) {
      if (val == null) return null;
      final d = (val as num).toDouble();
      return d > 0 ? d : null;
    }

    return MedidasCorporais(
      pescoco: toDoubleOrNull(json['pescoco']),
      cintura: toDoubleOrNull(json['cintura']),
      quadril: toDoubleOrNull(json['quadril']),
      abdomen: toDoubleOrNull(json['abdomen']),
      braco: toDoubleOrNull(json['braco']),
      coxa: toDoubleOrNull(json['coxa']),
      panturrilha: toDoubleOrNull(json['panturrilha']),
    );
  }
}

class Avaliacao {
  final String id;
  final String userId;
  final DateTime dataAvaliacao;
  final double pesoKg;
  final double nivelAtividade;
  final Objetivo objetivo;
  final MedidasCorporais medidas;

  const Avaliacao({
    required this.id,
    required this.userId,
    required this.dataAvaliacao,
    required this.pesoKg,
    this.nivelAtividade = 1.2,
    this.objetivo = Objetivo.manutencao,
    required this.medidas,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente_id': userId,
        'data_avaliacao': dataAvaliacao.toIso8601String(),
        'peso_kg': pesoKg,
        'nivel_atividade': nivelAtividade,
        'objetivo': objetivo.name,
        'medidas': medidas.toJson(),
      };

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    final objStr = json['objetivo'] as String? ?? 'manutencao';
    final obj = Objetivo.values.firstWhere(
      (e) => e.name == objStr,
      orElse: () => Objetivo.manutencao,
    );
    final dateRaw = (json['data_avaliacao'] ?? json['dataAvaliacao'] ?? json['data']) as String?;
    final date = dateRaw != null ? DateTime.tryParse(dateRaw) ?? DateTime.now() : DateTime.now();
    final pesoRaw = (json['peso_kg'] ?? json['pesoKg'] ?? 0.0) as num;
    final userId = (json['cliente_id'] ?? json['user_id'] ?? json['userId'] ?? '') as String;
    return Avaliacao(
      id: (json['id'] ?? '') as String,
      userId: userId,
      dataAvaliacao: date,
      pesoKg: pesoRaw.toDouble(),
      nivelAtividade: (json['nivel_atividade'] ?? json['nivelAtividade'] as num?)?.toDouble() ?? 1.2,
      objetivo: obj,
      medidas: MedidasCorporais.fromJson(
        Map<String, dynamic>.from(json['medidas'] as Map? ?? {}),
      ),
    );
  }
}

class Resultados {
  final String id;
  final String avaliacaoId;
  final Map<String, dynamic> calculos;
  final int calcVersion;

  const Resultados({
    required this.id,
    required this.avaliacaoId,
    required this.calculos,
    this.calcVersion = 2,
  });

  CalculosSnapshot get snapshot => CalculosSnapshot.fromJson(calculos);

  Map<String, dynamic> toJson() => {
        'id': id,
        'avaliacao_id': avaliacaoId,
        'calculos': calculos,
        'calcVersion': calcVersion,
      };

  factory Resultados.fromJson(Map<String, dynamic> json) {
    final calculosMap =
        Map<String, dynamic>.from(json['calculos'] as Map? ?? {});
    final version = (json['calcVersion'] as num?)?.toInt() ??
        (calculosMap['calcVersion'] as num?)?.toInt() ??
        1;
    return Resultados(
      id: json['id'] as String,
      avaliacaoId: json['avaliacao_id'] as String,
      calculos: calculosMap,
      calcVersion: version,
    );
  }

  Resultados copyWith({
    String? id,
    String? avaliacaoId,
    Map<String, dynamic>? calculos,
    int? calcVersion,
  }) {
    return Resultados(
      id: id ?? this.id,
      avaliacaoId: avaliacaoId ?? this.avaliacaoId,
      calculos: calculos ?? this.calculos,
      calcVersion: calcVersion ?? this.calcVersion,
    );
  }
}

class FotoAvaliacao {
  final String id;
  final String avaliacaoId;
  final String userId;
  final FotoTipo tipo;
  final String fotoBase64;
  final String? filePath;
  final DateTime criadoEm;

  const FotoAvaliacao({
    required this.id,
    required this.avaliacaoId,
    required this.userId,
    required this.tipo,
    this.fotoBase64 = '',
    this.filePath,
    required this.criadoEm,
  });

  FotoAvaliacao copyWith({
    String? id,
    String? avaliacaoId,
    String? userId,
    FotoTipo? tipo,
    String? fotoBase64,
    String? filePath,
    DateTime? criadoEm,
  }) {
    return FotoAvaliacao(
      id: id ?? this.id,
      avaliacaoId: avaliacaoId ?? this.avaliacaoId,
      userId: userId ?? this.userId,
      tipo: tipo ?? this.tipo,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
      filePath: filePath ?? this.filePath,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toJson({String? resolvedBase64}) => {
        'id': id,
        'avaliacao_id': avaliacaoId,
        'cliente_id': userId,
        'tipo': tipo.name,
        'foto_base64': resolvedBase64 ?? fotoBase64,
        if (filePath != null) 'file_path': filePath,
        'criado_em': criadoEm.toIso8601String(),
      };

  factory FotoAvaliacao.fromJson(Map<String, dynamic> json) {
    final tipoStr = json['tipo'] as String? ?? 'frente';
    final tipo = FotoTipo.values.firstWhere(
      (e) => e.name == tipoStr,
      orElse: () => FotoTipo.frente,
    );
    return FotoAvaliacao(
      id: json['id'] as String,
      avaliacaoId: json['avaliacao_id'] as String,
      userId: (json['cliente_id'] ?? json['user_id'] ?? '') as String,
      tipo: tipo,
      fotoBase64: (json['foto_base64'] as String?) ?? '',
      filePath: json['file_path'] as String?,
      criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Pesagem {
  final String id;
  final String userId;
  final DateTime data;
  final double pesoKg;

  const Pesagem({
    required this.id,
    required this.userId,
    required this.data,
    required this.pesoKg,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente_id': userId,
        'data': data.toIso8601String(),
        'peso_kg': pesoKg,
      };

  factory Pesagem.fromJson(Map<String, dynamic> json) {
    return Pesagem(
      id: json['id'] as String,
      userId: (json['cliente_id'] ?? json['user_id'] ?? '') as String,
      data: DateTime.parse(json['data'] as String),
      pesoKg: (json['peso_kg'] as num).toDouble(),
    );
  }
}

class JoinedEvaluation {
  final Avaliacao avaliacao;
  final Resultados? resultado;

  const JoinedEvaluation({
    required this.avaliacao,
    this.resultado,
  });
}
