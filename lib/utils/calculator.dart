import 'dart:math' as math;
import '../models/models.dart';

double _numToDouble(dynamic val) {
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int _numToInt(dynamic val) {
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return 0;
}

class IbwResult {
  final double devine;
  final double robinson;
  final double miller;
  final double hamwi;

  const IbwResult({
    required this.devine,
    required this.robinson,
    required this.miller,
    required this.hamwi,
  });

  Map<String, dynamic> toJson() => {
        'devine': devine,
        'robinson': robinson,
        'miller': miller,
        'hamwi': hamwi,
      };

  factory IbwResult.fromJson(Map<String, dynamic> json) => IbwResult(
        devine: _numToDouble(json['devine']),
        robinson: _numToDouble(json['robinson']),
        miller: _numToDouble(json['miller']),
        hamwi: _numToDouble(json['hamwi']),
      );
}

class MacroSplit {
  final int protein;
  final int carbs;
  final int fat;

  const MacroSplit({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory MacroSplit.fromJson(Map<String, dynamic> json) => MacroSplit(
        protein: _numToInt(json['protein']),
        carbs: _numToInt(json['carbs']),
        fat: _numToInt(json['fat']),
      );
}

class MacrosAndGoalsResult {
  final double targetCalories;
  final MacroSplit macros;
  final MacroSplit grams;

  const MacrosAndGoalsResult({
    required this.targetCalories,
    required this.macros,
    required this.grams,
  });

  Map<String, dynamic> toJson() => {
        'targetCalories': targetCalories,
        'macros': macros.toJson(),
        'grams': grams.toJson(),
      };

  factory MacrosAndGoalsResult.fromJson(Map<String, dynamic> json) =>
      MacrosAndGoalsResult(
        targetCalories: _numToDouble(json['targetCalories']),
        macros: json['macros'] != null
            ? MacroSplit.fromJson(
                Map<String, dynamic>.from(json['macros'] as Map))
            : const MacroSplit(protein: 0, carbs: 0, fat: 0),
        grams: json['grams'] != null
            ? MacroSplit.fromJson(Map<String, dynamic>.from(json['grams'] as Map))
            : const MacroSplit(protein: 0, carbs: 0, fat: 0),
      );
}

/// Snapshot tipado e imutável de todos os cálculos corporais e nutricionais
class CalculosSnapshot {
  final double imc;
  final double rcq;
  final double rcEst;
  final double bfNavy;
  final double bfRfm;
  final double bfDeurenberg;
  final double bfJp3;
  final double bfJp7;
  final double bfPrincipal;
  final String metodoPrincipal; // 'jp7', 'jp3', 'navy', 'rfm', 'deurenberg', 'none'
  final double lbmBoer;
  final double lbmFinal;
  final double bmrKatch;
  final double tdee;
  final IbwResult ibw;
  final MacrosAndGoalsResult macros;
  final double bai;
  final double bri;
  final double ci;
  final int calcVersion;

  const CalculosSnapshot({
    required this.imc,
    required this.rcq,
    required this.rcEst,
    required this.bfNavy,
    required this.bfRfm,
    required this.bfDeurenberg,
    this.bfJp3 = 0.0,
    this.bfJp7 = 0.0,
    required this.bfPrincipal,
    required this.metodoPrincipal,
    required this.lbmBoer,
    required this.lbmFinal,
    required this.bmrKatch,
    required this.tdee,
    required this.ibw,
    required this.macros,
    required this.bai,
    required this.bri,
    required this.ci,
    this.calcVersion = 2,
  });

  String get metodoPrincipalLabel {
    switch (metodoPrincipal.toLowerCase()) {
      case 'jp7':
        return 'Jackson-Pollock 7 Dobras';
      case 'jp3':
        return 'Jackson-Pollock 3 Dobras';
      case 'navy':
        return 'US Navy';
      case 'rfm':
        return 'RFM';
      case 'deurenberg':
        return 'Deurenberg';
      default:
        return metodoPrincipal.isEmpty ? 'N/A' : metodoPrincipal.toUpperCase();
    }
  }

  Map<String, dynamic> toJson() => {
        'imc': imc,
        'rcq': rcq,
        'rcEst': rcEst,
        'bfNavy': bfNavy,
        'bfRfm': bfRfm,
        'bfDeurenberg': bfDeurenberg,
        'bfJp3': bfJp3,
        'bfJp7': bfJp7,
        'bfPrincipal': bfPrincipal,
        'metodoPrincipal': metodoPrincipal,
        'lbmBoer': lbmBoer,
        'lbmFinal': lbmFinal,
        'bmrKatch': bmrKatch,
        'tdee': tdee,
        'ibw': ibw.toJson(),
        'macros': macros.toJson(),
        'bai': bai,
        'bri': bri,
        'ci': ci,
        'calcVersion': calcVersion,
      };

  factory CalculosSnapshot.fromJson(Map<String, dynamic> json) {
    final bfNavy = _numToDouble(json['bfNavy']);
    final bfRfm = _numToDouble(json['bfRfm']);
    final bfDeur = _numToDouble(json['bfDeurenberg']);
    final bfJp3 = _numToDouble(json['bfJp3']);
    final bfJp7 = _numToDouble(json['bfJp7']);

    String metodo = (json['metodoPrincipal'] as String?) ?? '';
    double bfPrinc = _numToDouble(json['bfPrincipal']);

    if (bfPrinc <= 0) {
      if (bfJp7 > 0) {
        bfPrinc = bfJp7;
        metodo = 'jp7';
      } else if (bfJp3 > 0) {
        bfPrinc = bfJp3;
        metodo = 'jp3';
      } else if (bfNavy > 0) {
        bfPrinc = bfNavy;
        metodo = 'navy';
      } else if (bfRfm > 0) {
        bfPrinc = bfRfm;
        metodo = 'rfm';
      } else if (bfDeur > 0) {
        bfPrinc = bfDeur;
        metodo = 'deurenberg';
      } else {
        bfPrinc = 0.0;
        metodo = 'none';
      }
    }
    if (metodo.isEmpty) {
      metodo = bfJp7 > 0
          ? 'jp7'
          : (bfJp3 > 0
              ? 'jp3'
              : (bfNavy > 0
                  ? 'navy'
                  : (bfRfm > 0
                      ? 'rfm'
                      : (bfDeur > 0 ? 'deurenberg' : 'none'))));
    }

    final lbmBoer = _numToDouble(json['lbmBoer']);
    final lbmFinal = json['lbmFinal'] != null
        ? _numToDouble(json['lbmFinal'])
        : lbmBoer;

    final ibwRaw = json['ibw'];
    final ibw = ibwRaw is Map<String, dynamic>
        ? IbwResult.fromJson(ibwRaw)
        : (ibwRaw is Map
            ? IbwResult.fromJson(Map<String, dynamic>.from(ibwRaw))
            : const IbwResult(devine: 0, robinson: 0, miller: 0, hamwi: 0));

    final macrosRaw = json['macros'];
    final macros = macrosRaw is Map<String, dynamic>
        ? MacrosAndGoalsResult.fromJson(macrosRaw)
        : (macrosRaw is Map
            ? MacrosAndGoalsResult.fromJson(
                Map<String, dynamic>.from(macrosRaw))
            : const MacrosAndGoalsResult(
                targetCalories: 0,
                macros: MacroSplit(protein: 0, carbs: 0, fat: 0),
                grams: MacroSplit(protein: 0, carbs: 0, fat: 0),
              ));

    return CalculosSnapshot(
      imc: _numToDouble(json['imc']),
      rcq: _numToDouble(json['rcq']),
      rcEst: _numToDouble(json['rcEst']),
      bfNavy: bfNavy,
      bfRfm: bfRfm,
      bfDeurenberg: bfDeur,
      bfJp3: bfJp3,
      bfJp7: bfJp7,
      bfPrincipal: bfPrinc,
      metodoPrincipal: metodo,
      lbmBoer: lbmBoer,
      lbmFinal: lbmFinal,
      bmrKatch: _numToDouble(json['bmrKatch']),
      tdee: _numToDouble(json['tdee']),
      ibw: ibw,
      macros: macros,
      bai: _numToDouble(json['bai']),
      bri: _numToDouble(json['bri']),
      ci: _numToDouble(json['ci']),
      calcVersion: json['calcVersion'] != null
          ? _numToInt(json['calcVersion'])
          : 1,
    );
  }
}

class BioCalculator {
  /// Arredonda para 2 casas decimais.
  static double round2(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return (value * 100).roundToDouble() / 100;
  }

  static double _log10(num x) => math.log(x) / math.ln10;

  /// Calcula o Índice de Massa Corporal (IMC)
  static double calculateIMC(double pesoKg, double alturaCm) {
    if (alturaCm <= 0 || pesoKg <= 0) return 0;
    final alturaM = alturaCm / 100.0;
    return round2(pesoKg / (alturaM * alturaM));
  }

  /// Calcula a Relação Cintura-Quadril (RCQ)
  static double calculateRCQ(double cinturaCm, double quadrilCm) {
    if (quadrilCm <= 0 || cinturaCm <= 0) return 0;
    return round2(cinturaCm / quadrilCm);
  }

  /// Calcula a Relação Cintura-Estatura (RCEst)
  static double calculateRCEst(double cinturaCm, double alturaCm) {
    if (alturaCm <= 0 || cinturaCm <= 0) return 0;
    return round2(cinturaCm / alturaCm);
  }

  /// Calcula o percentual de gordura pelo método US Navy.
  /// Retorna 0 caso as medidas necessárias estejam ausentes ou inválidas.
  static double calculateUSNavyBF(
    Sexo sexo,
    double alturaCm,
    double pescocoCm,
    double cinturaCm, [
    double quadrilCm = 0,
  ]) {
    if (alturaCm <= 0 || pescocoCm <= 0 || cinturaCm <= 0) return 0;
    double d = 0;

    if (sexo == Sexo.M) {
      final diff = cinturaCm - pescocoCm;
      if (diff <= 0) return 0;
      d = 1.0324 - 0.19077 * _log10(diff) + 0.15456 * _log10(alturaCm);
    } else {
      final sum = cinturaCm + quadrilCm - pescocoCm;
      if (sum <= 0 || quadrilCm <= 0) return 0;
      d = 1.29579 - 0.35004 * _log10(sum) + 0.22100 * _log10(alturaCm);
    }

    if (d <= 0) return 0;
    return round2(495 / d - 450);
  }

  /// Calcula a Relative Fat Mass (RFM)
  static double calculateRFM(Sexo sexo, double alturaCm, double cinturaCm) {
    if (cinturaCm <= 0 || alturaCm <= 0) return 0;
    final genderFactor = sexo == Sexo.M ? 0 : 1;
    return round2(64 - 20 * (alturaCm / cinturaCm) + 12 * genderFactor);
  }

  /// Calcula o percentual de gordura via fórmula de Deurenberg
  static double calculateDeurenbergBF(
    Sexo sexo,
    double pesoKg,
    double alturaCm,
    int idade,
  ) {
    final imc = calculateIMC(pesoKg, alturaCm);
    if (imc <= 0) return 0;
    final genderFactor = sexo == Sexo.M ? 1 : 0;
    return round2(1.2 * imc + 0.23 * idade - 10.8 * genderFactor - 5.4);
  }

  /// Converte densidade corporal (BD) para % de Gordura usando a equação de Siri:
  /// %BF = ((4.95 / BD) - 4.50) * 100
  static double siriEquation(double bodyDensity) {
    if (bodyDensity <= 0) return 0;
    final bf = ((4.95 / bodyDensity) - 4.50) * 100.0;
    return round2(math.max(0.0, bf));
  }

  /// Protocolo Jackson-Pollock 3 Dobras (JP3) + Equação de Siri
  /// - Homens: Peitoral, Abdômen, Coxa
  /// - Mulheres: Tríceps, Suprailíaca, Coxa
  static double calculateJacksonPollock3({
    required Sexo sexo,
    required int idade,
    double? peitoral,
    double? abdomen,
    double? coxa,
    double? triceps,
    double? suprailiaca,
  }) {
    if (idade <= 0) return 0;
    if (sexo == Sexo.M) {
      if (peitoral == null ||
          abdomen == null ||
          coxa == null ||
          peitoral <= 0 ||
          abdomen <= 0 ||
          coxa <= 0) {
        return 0;
      }
      final s = peitoral + abdomen + coxa;
      final bd = 1.109380 -
          (0.0008267 * s) +
          (0.0000016 * s * s) -
          (0.0002574 * idade);
      return siriEquation(bd);
    } else {
      if (triceps == null ||
          suprailiaca == null ||
          coxa == null ||
          triceps <= 0 ||
          suprailiaca <= 0 ||
          coxa <= 0) {
        return 0;
      }
      final s = triceps + suprailiaca + coxa;
      final bd = 1.0994921 -
          (0.0009929 * s) +
          (0.0000023 * s * s) -
          (0.0001392 * idade);
      return siriEquation(bd);
    }
  }

  /// Protocolo Jackson-Pollock 7 Dobras (JP7) + Equação de Siri
  /// 7 dobras: Peitoral, Axilar Média, Tríceps, Subescapular, Abdômen, Suprailíaca, Coxa
  static double calculateJacksonPollock7({
    required Sexo sexo,
    required int idade,
    required double? peitoral,
    required double? axilarMedia,
    required double? triceps,
    required double? subescapular,
    required double? abdomen,
    required double? suprailiaca,
    required double? coxa,
  }) {
    if (idade <= 0 ||
        peitoral == null ||
        peitoral <= 0 ||
        axilarMedia == null ||
        axilarMedia <= 0 ||
        triceps == null ||
        triceps <= 0 ||
        subescapular == null ||
        subescapular <= 0 ||
        abdomen == null ||
        abdomen <= 0 ||
        suprailiaca == null ||
        suprailiaca <= 0 ||
        coxa == null ||
        coxa <= 0) {
      return 0;
    }

    final s = peitoral +
        axilarMedia +
        triceps +
        subescapular +
        abdomen +
        suprailiaca +
        coxa;

    double bd;
    if (sexo == Sexo.M) {
      bd = 1.1120 -
          (0.00043499 * s) +
          (0.00000055 * s * s) -
          (0.00028826 * idade);
    } else {
      bd = 1.0970 -
          (0.00046971 * s) +
          (0.00000056 * s * s) -
          (0.00012828 * idade);
    }

    return siriEquation(bd);
  }

  /// Calcula a Massa Magra (Lean Body Mass - LBM) usando a fórmula de Boer (fallback)
  static double calculateBoerLBM(Sexo sexo, double pesoKg, double alturaCm) {
    if (pesoKg <= 0 || alturaCm <= 0) return 0;
    if (sexo == Sexo.M) {
      return round2(0.407 * pesoKg + 0.267 * alturaCm - 19.2);
    } else {
      return round2(0.252 * pesoKg + 0.473 * alturaCm - 48.3);
    }
  }

  /// Calcula a Taxa Metabólica Basal (BMR) usando a fórmula de Katch-McArdle sobre a massa magra (LBM).
  static double calculateKatchMcArdleBMR(double lbmKg) {
    if (lbmKg <= 0) return 0;
    return round2(370 + (21.6 * lbmKg));
  }

  /// Calcula o Gasto Energético Total Diário (TDEE).
  static double calculateTDEE(double bmr, double activityMultiplier) {
    if (bmr <= 0 || activityMultiplier <= 0) return 0;
    return round2(bmr * activityMultiplier);
  }

  /// Calcula o Peso Ideal (IBW) usando as 4 fórmulas principais (Devine, Robinson, Miller, Hamwi).
  static IbwResult calculateIBW(Sexo sexo, double alturaCm) {
    if (alturaCm <= 0) {
      return const IbwResult(devine: 0, robinson: 0, miller: 0, hamwi: 0);
    }

    const alturaBaseCm = 152.4;
    final cmExtras = math.max(0.0, alturaCm - alturaBaseCm);
    final inchesExtras = cmExtras / 2.54;

    double devine, robinson, miller, hamwi;

    if (sexo == Sexo.M) {
      devine = 50.0 + (2.3 * inchesExtras);
      robinson = 52.0 + (1.9 * inchesExtras);
      miller = 56.2 + (1.41 * inchesExtras);
      hamwi = 48.0 + (1.1 * cmExtras);
    } else {
      devine = 45.5 + (2.3 * inchesExtras);
      robinson = 49.0 + (1.7 * inchesExtras);
      miller = 53.1 + (1.36 * inchesExtras);
      hamwi = 45.0 + (0.9 * cmExtras);
    }

    return IbwResult(
      devine: round2(devine),
      robinson: round2(robinson),
      miller: round2(miller),
      hamwi: round2(hamwi),
    );
  }

  /// Calcula a meta de calorias diárias e a divisão de macronutrientes científica.
  /// - Proteína: 1,6 / 1,8 / 2,0 g/kg de massa magra (manutenção / emagrecimento / hipertrofia)
  /// - Gordura: 0,8 g/kg de peso corporal total
  /// - Carboidrato: restante das calorias
  /// - Piso calórico: 1200 kcal (F) / 1500 kcal (M)
  static MacrosAndGoalsResult calculateMacrosAndGoals(
    double tdee,
    Objetivo objetivo, {
    Sexo sexo = Sexo.M,
    double pesoKg = 0,
    double lbmKg = 0,
  }) {
    if (tdee <= 0) {
      return const MacrosAndGoalsResult(
        targetCalories: 0,
        macros: MacroSplit(protein: 0, carbs: 0, fat: 0),
        grams: MacroSplit(protein: 0, carbs: 0, fat: 0),
      );
    }

    double targetCalories = tdee;
    double proteinPerKgLbm = 1.6;

    switch (objetivo) {
      case Objetivo.emagrecimento:
        targetCalories = tdee - 500;
        proteinPerKgLbm = 1.8;
        break;
      case Objetivo.manutencao:
        targetCalories = tdee;
        proteinPerKgLbm = 1.6;
        break;
      case Objetivo.hipertrofia:
        targetCalories = tdee + 300;
        proteinPerKgLbm = 2.0;
        break;
    }

    // Piso calórico
    final floorCalories = sexo == Sexo.F ? 1200.0 : 1500.0;
    if (targetCalories < floorCalories) {
      targetCalories = floorCalories;
    }

    // Massa de referência para proteína: LBM se disponível (> 0), senão peso total
    final baseMassaProteina = lbmKg > 0 ? lbmKg : pesoKg;
    final proteinGrams = baseMassaProteina > 0
        ? (baseMassaProteina * proteinPerKgLbm).round()
        : 0;

    // Gordura: 0,8 g/kg de peso corporal total (ou lbm se peso ausente)
    final basePesoGordura = pesoKg > 0 ? pesoKg : lbmKg;
    final fatGrams =
        basePesoGordura > 0 ? (basePesoGordura * 0.8).round() : 0;

    final proteinCals = proteinGrams * 4.0;
    final fatCals = fatGrams * 9.0;

    // Carboidratos completam o restante das calorias planejadas
    final remainingCals = targetCalories - proteinCals - fatCals;
    final carbsGrams = remainingCals > 0 ? (remainingCals / 4.0).round() : 0;
    final carbsCals = carbsGrams * 4.0;

    final totalMacroCals = proteinCals + fatCals + carbsCals;

    int proteinPct = 0;
    int fatPct = 0;
    int carbsPct = 0;

    if (totalMacroCals > 0) {
      proteinPct = ((proteinCals / totalMacroCals) * 100).round();
      fatPct = ((fatCals / totalMacroCals) * 100).round();
      carbsPct = 100 - proteinPct - fatPct;
      if (carbsPct < 0) {
        carbsPct = 0;
      }
    }

    return MacrosAndGoalsResult(
      targetCalories: round2(targetCalories),
      macros: MacroSplit(
        protein: proteinPct,
        carbs: carbsPct,
        fat: fatPct,
      ),
      grams: MacroSplit(
        protein: proteinGrams,
        carbs: carbsGrams,
        fat: fatGrams,
      ),
    );
  }

  /// Body Adiposity Index (BAI)
  static double calculateBAI(double quadrilCm, double alturaCm) {
    if (quadrilCm <= 0 || alturaCm <= 0) return 0;
    final alturaM = alturaCm / 100.0;
    final bai = (quadrilCm / math.pow(alturaM, 1.5)) - 18;
    return round2(bai);
  }

  /// Body Roundness Index (BRI)
  static double calculateBRI(double cinturaCm, double alturaCm) {
    if (cinturaCm <= 0 || alturaCm <= 0) return 0;
    final cinturaM = cinturaCm / 100.0;
    final alturaM = alturaCm / 100.0;

    final base = cinturaM / (math.pi * alturaM);
    final valorRaiz = 1 - (base * base);
    if (valorRaiz < 0) return 0;

    final bri = 364.2 - 365.5 * math.sqrt(valorRaiz);
    return round2(bri);
  }

  /// Índice de Conicidade (CI)
  static double calculateCI(
    double cinturaCm,
    double pesoKg,
    double alturaCm,
  ) {
    if (cinturaCm <= 0 || pesoKg <= 0 || alturaCm <= 0) return 0;
    final cinturaM = cinturaCm / 100.0;
    final alturaM = alturaCm / 100.0;

    final denominator = 0.109 * math.sqrt(pesoKg / alturaM);
    if (denominator == 0) return 0;

    final ci = cinturaM / denominator;
    return round2(ci);
  }

  /// Gera o snapshot completo e tipado de cálculos para salvar junto com a Avaliação
  static CalculosSnapshot buildCalculosSnapshot({
    required UserProfile profile,
    required Avaliacao avaliacao,
  }) {
    final peso = avaliacao.pesoKg;
    final altura = profile.alturaCm;
    final sexo = profile.sexo;
    final idade = profile.idadeNaData(avaliacao.dataAvaliacao);

    final pescoco = avaliacao.medidas.pescoco ?? 0;
    final cintura = avaliacao.medidas.cintura ?? 0;
    final abdomen = avaliacao.medidas.abdomen ?? 0;
    final quadril = avaliacao.medidas.quadril ?? 0;

    // No protocolo oficial US Navy masculino (DoD 1308.3), a circunferência do tronco
    // deve ser medida no nível da cicatriz umbilical (abdômen). Se o abdômen foi informado
    // e for maior que a cintura alta (costelas), utilizamos a maior circunferência para
    // refletir a real adiposidade abdominal e evitar subestimar o BF%.
    final cinturaEfetiva = (sexo == Sexo.M && abdomen > 0)
        ? math.max(cintura, abdomen)
        : cintura;

    final bfNavyRaw =
        calculateUSNavyBF(sexo, altura, pescoco, cinturaEfetiva, quadril);
    final bfNavy = bfNavyRaw > 0 ? bfNavyRaw : 0.0;
    final bfRfm = calculateRFM(sexo, altura, cinturaEfetiva);
    final bfDeurenberg = calculateDeurenbergBF(sexo, peso, altura, idade);

    final bfJp7 = calculateJacksonPollock7(
      sexo: sexo,
      idade: idade,
      peitoral: avaliacao.medidas.dobraPeitoral,
      axilarMedia: avaliacao.medidas.dobraAxilarMedia,
      triceps: avaliacao.medidas.dobraTriceps,
      subescapular: avaliacao.medidas.dobraSubescapular,
      abdomen: avaliacao.medidas.dobraAbdomen,
      suprailiaca: avaliacao.medidas.dobraSuprailiaca,
      coxa: avaliacao.medidas.dobraCoxa,
    );

    final bfJp3 = calculateJacksonPollock3(
      sexo: sexo,
      idade: idade,
      peitoral: avaliacao.medidas.dobraPeitoral,
      abdomen: avaliacao.medidas.dobraAbdomen,
      coxa: avaliacao.medidas.dobraCoxa,
      triceps: avaliacao.medidas.dobraTriceps,
      suprailiaca: avaliacao.medidas.dobraSuprailiaca,
    );

    // Determina o BF principal e o método utilizado:
    // 1º JP7 (padrão ouro em dobras) -> 2º JP3 -> 3º Navy -> 4º RFM -> 5º Deurenberg
    double bfPrincipal = 0.0;
    String metodoPrincipal = 'none';

    if (bfJp7 > 0) {
      bfPrincipal = bfJp7;
      metodoPrincipal = 'jp7';
    } else if (bfJp3 > 0) {
      bfPrincipal = bfJp3;
      metodoPrincipal = 'jp3';
    } else if (bfNavy > 0) {
      bfPrincipal = bfNavy;
      metodoPrincipal = 'navy';
    } else if (bfRfm > 0) {
      bfPrincipal = bfRfm;
      metodoPrincipal = 'rfm';
    } else if (bfDeurenberg > 0) {
      bfPrincipal = bfDeurenberg;
      metodoPrincipal = 'deurenberg';
    }

    final lbmBoer = calculateBoerLBM(sexo, peso, altura);

    // Massa magra real baseada no BF% medido:
    // LBM = peso * (1 - BF%)
    double lbmReal = 0.0;
    if (peso > 0 && bfPrincipal > 0 && bfPrincipal < 100) {
      lbmReal = round2(peso * (1.0 - (bfPrincipal / 100.0)));
    }

    // Se lbmReal foi calculada por BF medido, usa ela; Boer só como último fallback
    final lbmFinal = lbmReal > 0 ? lbmReal : lbmBoer;

    // Katch-McArdle passa a usar a massa magra final real
    final bmrKatch = calculateKatchMcArdleBMR(lbmFinal);
    final tdee = calculateTDEE(bmrKatch, avaliacao.nivelAtividade);

    final ibw = calculateIBW(sexo, altura);
    final macrosAndGoals = calculateMacrosAndGoals(
      tdee,
      avaliacao.objetivo,
      sexo: sexo,
      pesoKg: peso,
      lbmKg: lbmFinal,
    );

    final bai = calculateBAI(quadril, altura);
    final bri = calculateBRI(cintura, altura);
    final ci = calculateCI(cintura, peso, altura);

    return CalculosSnapshot(
      imc: calculateIMC(peso, altura),
      rcq: calculateRCQ(cintura, quadril),
      rcEst: calculateRCEst(cintura, altura),
      bfNavy: bfNavy,
      bfRfm: bfRfm,
      bfDeurenberg: bfDeurenberg,
      bfJp3: bfJp3,
      bfJp7: bfJp7,
      bfPrincipal: bfPrincipal,
      metodoPrincipal: metodoPrincipal,
      lbmBoer: lbmBoer,
      lbmFinal: lbmFinal,
      bmrKatch: bmrKatch,
      tdee: tdee,
      ibw: ibw,
      macros: macrosAndGoals,
      bai: bai,
      bri: bri,
      ci: ci,
      calcVersion: 2,
    );
  }
}
