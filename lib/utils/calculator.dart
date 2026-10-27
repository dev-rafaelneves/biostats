import 'dart:math' as math;
import '../models/models.dart';

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
        devine: (json['devine'] as num?)?.toDouble() ?? 0.0,
        robinson: (json['robinson'] as num?)?.toDouble() ?? 0.0,
        miller: (json['miller'] as num?)?.toDouble() ?? 0.0,
        hamwi: (json['hamwi'] as num?)?.toDouble() ?? 0.0,
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
        protein: (json['protein'] as num?)?.toInt() ?? 0,
        carbs: (json['carbs'] as num?)?.toInt() ?? 0,
        fat: (json['fat'] as num?)?.toInt() ?? 0,
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
        targetCalories: (json['targetCalories'] as num?)?.toDouble() ?? 0.0,
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
  final double bfPrincipal;
  final String metodoPrincipal; // 'navy', 'rfm', 'deurenberg', 'none'
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
    final bfNavy = (json['bfNavy'] as num?)?.toDouble() ?? 0.0;
    final bfRfm = (json['bfRfm'] as num?)?.toDouble() ?? 0.0;
    final bfDeur = (json['bfDeurenberg'] as num?)?.toDouble() ?? 0.0;

    String metodo = (json['metodoPrincipal'] as String?) ?? '';
    double bfPrinc = (json['bfPrincipal'] as num?)?.toDouble() ?? 0.0;

    if (bfPrinc <= 0) {
      if (bfNavy > 0) {
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
      metodo = bfNavy > 0
          ? 'navy'
          : (bfRfm > 0 ? 'rfm' : (bfDeur > 0 ? 'deurenberg' : 'none'));
    }

    final lbmBoer = (json['lbmBoer'] as num?)?.toDouble() ?? 0.0;
    final lbmFinal = (json['lbmFinal'] as num?)?.toDouble() ?? lbmBoer;

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
      imc: (json['imc'] as num?)?.toDouble() ?? 0.0,
      rcq: (json['rcq'] as num?)?.toDouble() ?? 0.0,
      rcEst: (json['rcEst'] as num?)?.toDouble() ?? 0.0,
      bfNavy: bfNavy,
      bfRfm: bfRfm,
      bfDeurenberg: bfDeur,
      bfPrincipal: bfPrinc,
      metodoPrincipal: metodo,
      lbmBoer: lbmBoer,
      lbmFinal: lbmFinal,
      bmrKatch: (json['bmrKatch'] as num?)?.toDouble() ?? 0.0,
      tdee: (json['tdee'] as num?)?.toDouble() ?? 0.0,
      ibw: ibw,
      macros: macros,
      bai: (json['bai'] as num?)?.toDouble() ?? 0.0,
      bri: (json['bri'] as num?)?.toDouble() ?? 0.0,
      ci: (json['ci'] as num?)?.toDouble() ?? 0.0,
      calcVersion: (json['calcVersion'] as num?)?.toInt() ?? 1,
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
    final quadril = avaliacao.medidas.quadril ?? 0;

    final bfNavyRaw =
        calculateUSNavyBF(sexo, altura, pescoco, cintura, quadril);
    final bfNavy = bfNavyRaw > 0 ? bfNavyRaw : 0.0;
    final bfRfm = calculateRFM(sexo, altura, cintura);
    final bfDeurenberg = calculateDeurenbergBF(sexo, peso, altura, idade);

    // Determina o BF principal e o método utilizado:
    // 1º Navy (se medidas presentes) -> 2º RFM (se cintura presente) -> 3º Deurenberg (IMC + idade)
    double bfPrincipal = 0.0;
    String metodoPrincipal = 'none';

    if (bfNavy > 0) {
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
