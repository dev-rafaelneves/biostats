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

  /// Calcula o percentual de gordura pelo método US Navy
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

  /// Calcula a Massa Magra (Lean Body Mass - LBM) usando a fórmula de Boer
  static double calculateBoerLBM(Sexo sexo, double pesoKg, double alturaCm) {
    if (pesoKg <= 0 || alturaCm <= 0) return 0;
    if (sexo == Sexo.M) {
      return round2(0.407 * pesoKg + 0.267 * alturaCm - 19.2);
    } else {
      return round2(0.252 * pesoKg + 0.473 * alturaCm - 48.3);
    }
  }

  /// Calcula a Taxa Metabólica Basal (BMR) usando a fórmula de Katch-McArdle.
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

  /// Calcula a meta de calorias diárias e a divisão de macronutrientes com base no TDEE e no objetivo.
  static MacrosAndGoalsResult calculateMacrosAndGoals(
    double tdee,
    Objetivo objetivo,
  ) {
    if (tdee <= 0) {
      return const MacrosAndGoalsResult(
        targetCalories: 0,
        macros: MacroSplit(protein: 0, carbs: 0, fat: 0),
        grams: MacroSplit(protein: 0, carbs: 0, fat: 0),
      );
    }

    double targetCalories = tdee;
    double proteinPct = 0;
    double carbsPct = 0;
    double fatPct = 0;

    switch (objetivo) {
      case Objetivo.emagrecimento:
        targetCalories = tdee - 500;
        proteinPct = 0.40;
        carbsPct = 0.30;
        fatPct = 0.30;
        break;
      case Objetivo.manutencao:
        targetCalories = tdee;
        proteinPct = 0.30;
        carbsPct = 0.40;
        fatPct = 0.30;
        break;
      case Objetivo.hipertrofia:
        targetCalories = tdee + 300;
        proteinPct = 0.25;
        carbsPct = 0.50;
        fatPct = 0.25;
        break;
    }

    if (targetCalories < 1200) targetCalories = 1200;

    final proteinCals = targetCalories * proteinPct;
    final carbsCals = targetCalories * carbsPct;
    final fatCals = targetCalories * fatPct;

    return MacrosAndGoalsResult(
      targetCalories: round2(targetCalories),
      macros: MacroSplit(
        protein: (proteinPct * 100).round(),
        carbs: (carbsPct * 100).round(),
        fat: (fatPct * 100).round(),
      ),
      grams: MacroSplit(
        protein: (proteinCals / 4).round(),
        carbs: (carbsCals / 4).round(),
        fat: (fatCals / 9).round(),
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

  /// Gera o snapshot completo de cálculos para salvar junto com a Avaliação
  static Map<String, dynamic> buildCalculosSnapshot({
    required UserProfile profile,
    required Avaliacao avaliacao,
  }) {
    final peso = avaliacao.pesoKg;
    final altura = profile.alturaCm;
    final sexo = profile.sexo;
    final idade = profile.idade;

    final pescoco = avaliacao.medidas.pescoco ?? 0;
    final cintura = avaliacao.medidas.cintura ?? 0;
    final quadril = avaliacao.medidas.quadril ?? 0;

    final lbmBoer = calculateBoerLBM(sexo, peso, altura);
    final bmrKatch = calculateKatchMcArdleBMR(lbmBoer);
    final tdee = calculateTDEE(bmrKatch, avaliacao.nivelAtividade);

    final ibw = calculateIBW(sexo, altura);
    final macrosAndGoals = calculateMacrosAndGoals(tdee, avaliacao.objetivo);

    final bai = calculateBAI(quadril, altura);
    final bri = calculateBRI(cintura, altura);
    final ci = calculateCI(cintura, peso, altura);

    final bfRfm = calculateRFM(sexo, altura, cintura);
    final bfNavyRaw =
        calculateUSNavyBF(sexo, altura, pescoco, cintura, quadril);
    // Se a pessoa não preencheu pescoço (ou quadril no sexo F), usamos RFM como fallback inteligente para bfNavy não ficar 0
    final bfNavy = bfNavyRaw > 0 ? bfNavyRaw : bfRfm;

    return {
      'imc': calculateIMC(peso, altura),
      'rcq': calculateRCQ(cintura, quadril),
      'rcEst': calculateRCEst(cintura, altura),
      'bfNavy': bfNavy,
      'bfRfm': bfRfm,
      'bfDeurenberg': calculateDeurenbergBF(sexo, peso, altura, idade),
      'lbmBoer': lbmBoer,
      'bmrKatch': bmrKatch,
      'tdee': tdee,
      'ibw': ibw.toJson(),
      'macros': macrosAndGoals.toJson(),
      'bai': bai,
      'bri': bri,
      'ci': ci,
    };
  }
}
