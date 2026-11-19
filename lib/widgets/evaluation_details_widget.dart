import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'evaluation_details/detail_cards_components.dart';

class EvaluationDetailsWidget extends StatefulWidget {
  final UserProfile profile;
  final Avaliacao avaliacao;
  final Resultados? resultado;
  final Avaliacao? previousAvaliacao;
  final void Function(String method)? onSelectBfMethod;

  const EvaluationDetailsWidget({
    super.key,
    required this.profile,
    required this.avaliacao,
    required this.resultado,
    this.previousAvaliacao,
    this.onSelectBfMethod,
  });

  @override
  State<EvaluationDetailsWidget> createState() =>
      _EvaluationDetailsWidgetState();
}

class _EvaluationDetailsWidgetState extends State<EvaluationDetailsWidget> {
  bool _showAllIbwFormulas = false;

  double _numVal(dynamic val) => (val as num?)?.toDouble() ?? 0.0;

  (String, Color) _evaluateImc(double imc, BioThemeColors colors) {
    if (imc <= 0) return ('--', colors.textMuted);
    if (imc < 18.5) return ('Baixo peso', colors.warningText);
    if (imc < 25) return ('Saudável', colors.successText);
    if (imc < 30) return ('Sobrepeso', colors.warningText);
    return ('Obesidade', colors.dangerText);
  }

  (String, Color) _evaluateRcEst(double rcEst, BioThemeColors colors) {
    if (rcEst <= 0) return ('Cintura/Estatura', colors.textMuted);
    if (rcEst < 0.50) return ('Saudável (<0.50)', colors.successText);
    if (rcEst < 0.60) return ('Atenção (0.50-0.59)', colors.warningText);
    return ('Risco Elevado', colors.dangerText);
  }

  (String, Color) _evaluateRcq(double rcq, Sexo sexo, BioThemeColors colors) {
    if (rcq <= 0) return ('Cintura/Quadril', colors.textMuted);
    final limit = sexo == Sexo.M ? 0.90 : 0.85;
    if (rcq < limit) return ('Baixo Risco', colors.successText);
    if (rcq < limit + 0.05) return ('Risco Moderado', colors.warningText);
    return ('Risco Alto', colors.dangerText);
  }

  (String, Color) _evaluateBri(double bri, BioThemeColors colors) {
    if (bri <= 0) return ('Redondeza Corp.', colors.textMuted);
    if (bri < 3.4) return ('Saudável', colors.successText);
    if (bri <= 4.4) return ('Atenção', colors.warningText);
    return ('Risco Visceral', colors.dangerText);
  }

  (String, Color) _evaluateCi(double ci, Sexo sexo, BioThemeColors colors) {
    if (ci <= 0) return ('Índice Conicidade', colors.textMuted);
    final limit = sexo == Sexo.M ? 1.25 : 1.18;
    if (ci < limit) return ('Normal', colors.successText);
    return ('Atenção Abdominal', colors.warningText);
  }

  void _showIndicesGuide(BuildContext context) {
    final colors = context.bioColors;
    const items = [
      (
        'RCEst (Relação Cintura-Estatura)',
        'Divide sua cintura pela sua altura. Manter abaixo de 0,50 (cintura menor que metade da altura) é um dos melhores preditores de longevidade e saúde cardiovascular.'
      ),
      (
        'RCQ (Relação Cintura-Quadril)',
        'Avalia a distribuição de gordura. Valores abaixo de 0,90 (homens) e 0,85 (mulheres) indicam baixo risco metabólico.'
      ),
      (
        'BAI (Body Adiposity Index)',
        'Estima a adiposidade corporal usando a relação entre quadril e estatura sem depender da balança.'
      ),
      (
        'BRI (Body Roundness Index)',
        'Modela o corpo humano como uma elipse para estimar gordura visceral. Valores entre 1 e 3,4 são considerados ótimos.'
      ),
      (
        'CI (Índice de Conicidade)',
        'Avalia se o formato corporal se aproxima de um cilindro (saudável, < 1,25 M / < 1,18 F) ou de um duplo cone (acúmulo abdominal).'
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Entenda os Índices de Risco Clínico',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: items.map((it) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.$1,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.accent,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                it.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigoPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Fechar'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    final snap = widget.resultado?.snapshot;
    final calc = widget.resultado?.calculos ?? {};
    final dataFormatada = DateFormat("dd 'de' MMMM", 'pt_BR')
        .format(widget.avaliacao.dataAvaliacao);

    final bfNavy = snap?.bfNavy ?? _numVal(calc['bfNavy']);
    final bfRfm = snap?.bfRfm ?? _numVal(calc['bfRfm']);
    final bfPrinc = snap?.bfPrincipal ?? (bfNavy > 0 ? bfNavy : bfRfm);
    final metodoLabel =
        snap?.metodoPrincipalLabel ?? (bfNavy > 0 ? 'US Navy' : 'RFM');
    final lbmFinal = snap?.lbmFinal ?? _numVal(calc['lbmBoer']);
    final imc = snap?.imc ?? _numVal(calc['imc']);
    final rcq = snap?.rcq ?? _numVal(calc['rcq']);
    final bai = snap?.bai ?? _numVal(calc['bai']);
    final bri = snap?.bri ?? _numVal(calc['bri']);
    final ci = snap?.ci ?? _numVal(calc['ci']);
    final bmrKatch = snap?.bmrKatch ?? _numVal(calc['bmrKatch']);
    final tdee = snap?.tdee ?? _numVal(calc['tdee']);

    final ibwMap = calc['ibw'] is Map
        ? Map<String, dynamic>.from(calc['ibw'] as Map)
        : null;
    final macrosMap = calc['macros'] is Map
        ? Map<String, dynamic>.from(calc['macros'] as Map)
        : null;

    final buffer = StringBuffer();
    buffer.writeln('*Resumo da Minha Avaliação Física* 📊');
    buffer.writeln('*Nome:* ${widget.profile.nome}');
    buffer.writeln('*Data:* $dataFormatada\n');
    buffer.writeln('*Composição Corporal:*');
    if (bfPrinc > 0) {
      buffer.writeln('• BF ($metodoLabel): ${bfPrinc.toStringAsFixed(1)}%');
    }
    buffer.writeln('• Massa Magra: ${lbmFinal.toStringAsFixed(1)} kg');
    buffer.writeln('• Peso Atual: ${widget.avaliacao.pesoKg.toStringAsFixed(1)} kg');

    if (ibwMap != null) {
      final devine = _numVal(ibwMap['devine']);
      buffer.writeln('• Peso Ideal (Devine): ${devine.toStringAsFixed(1)} kg');
    }

    buffer.writeln('\n*Índices de Risco:*');
    buffer.writeln('• IMC: ${imc.toStringAsFixed(1)}');
    buffer.writeln('• Relação Cintura-Quadril: ${rcq.toStringAsFixed(2)}');

    if (bai > 0) {
      buffer.writeln('• BAI (Adiposidade): ${bai.toStringAsFixed(1)}');
      buffer.writeln('• BRI (Redondeza): ${bri.toStringAsFixed(1)}');
      buffer.writeln('• Índice Conicidade: ${ci.toStringAsFixed(2)}');
    }

    if (bmrKatch > 0 && tdee > 0) {
      buffer.writeln('\n*Gasto Energético:*');
      buffer.writeln('• Basal (TMB): ${bmrKatch.toStringAsFixed(0)} kcal');
      buffer.writeln('• Diário (TDEE): ${tdee.toStringAsFixed(0)} kcal');
    }

    if (macrosMap != null) {
      final targetCal = _numVal(macrosMap['targetCalories']);
      final grams = macrosMap['grams'] is Map
          ? Map<String, dynamic>.from(macrosMap['grams'] as Map)
          : <String, dynamic>{};
      final pcts = macrosMap['macros'] is Map
          ? Map<String, dynamic>.from(macrosMap['macros'] as Map)
          : <String, dynamic>{};

      buffer.writeln(
          '\n*Plano Nutricional (${widget.avaliacao.objetivo.label}):*');
      buffer.writeln('• Meta Diária: ${targetCal.toStringAsFixed(0)} kcal');
      buffer.writeln(
          '• Proteínas: ${grams['protein'] ?? 0}g (${pcts['protein'] ?? 0}%)');
      buffer.writeln(
          '• Carboidratos: ${grams['carbs'] ?? 0}g (${pcts['carbs'] ?? 0}%)');
      buffer
          .writeln('• Gorduras: ${grams['fat'] ?? 0}g (${pcts['fat'] ?? 0}%)');
    }

    buffer.write('\n_Relatório gerado via BioStats_ 💪');

    await Share.share(
      buffer.toString(),
      subject: 'Resumo da Avaliação Física',
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.resultado?.snapshot;
    final calc = widget.resultado?.calculos ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.bioColors;

    final bmrKatch = snap?.bmrKatch ?? _numVal(calc['bmrKatch']);
    final tdee = snap?.tdee ?? _numVal(calc['tdee']);
    final bfJp7 = snap?.bfJp7 ?? _numVal(calc['bfJp7']);
    final bfJp3 = snap?.bfJp3 ?? _numVal(calc['bfJp3']);
    final bfNavy = snap?.bfNavy ?? _numVal(calc['bfNavy']);
    final bfRfm = snap?.bfRfm ?? _numVal(calc['bfRfm']);
    final bfDeurenberg = snap?.bfDeurenberg ?? _numVal(calc['bfDeurenberg']);
    final metodoPrincipal =
        snap?.metodoPrincipal ?? (bfNavy > 0 ? 'navy' : 'rfm');
    final hasDiscrepancy = snap?.hasBiometricDiscrepancy ?? false;
    final imc = snap?.imc ?? _numVal(calc['imc']);
    final rcq = snap?.rcq ?? _numVal(calc['rcq']);
    final rcEst = snap?.rcEst ?? _numVal(calc['rcEst']);
    final lbmFinal = snap?.lbmFinal ?? _numVal(calc['lbmBoer']);
    final lbmLabel = (snap != null && snap.lbmFinal != snap.lbmBoer)
        ? 'Real (${snap.metodoPrincipalLabel})'
        : 'Fórmula Boer';
    final bai = snap?.bai ?? _numVal(calc['bai']);
    final bri = snap?.bri ?? _numVal(calc['bri']);
    final ci = snap?.ci ?? _numVal(calc['ci']);

    final ibwMap = calc['ibw'] is Map
        ? Map<String, dynamic>.from(calc['ibw'] as Map)
        : null;
    final macrosMap = calc['macros'] is Map
        ? Map<String, dynamic>.from(calc['macros'] as Map)
        : null;

    final imcEval = _evaluateImc(imc, colors);
    final rcqEval = _evaluateRcq(rcq, widget.profile.sexo, colors);
    final rcEstEval = _evaluateRcEst(rcEst, colors);
    final briEval = _evaluateBri(bri, colors);
    final ciEval = _evaluateCi(ci, widget.profile.sexo, colors);

    final med = widget.avaliacao.medidas;
    final prevMed = widget.previousAvaliacao?.medidas;

    final circumferenceRows = <Widget>[
      GridHalfItem(
        child: MeasureRow(
          label: 'Peso',
          value: '${widget.avaliacao.pesoKg.toStringAsFixed(1)} kg',
          currentVal: widget.avaliacao.pesoKg,
          prevVal: widget.previousAvaliacao?.pesoKg,
          unit: 'kg',
          lowerIsBetter: widget.avaliacao.objetivo == Objetivo.emagrecimento,
        ),
      ),
      for (final item in [
        ('Pescoço', med.pescoco, prevMed?.pescoco, true),
        ('Cintura', med.cintura, prevMed?.cintura, true),
        (
          'Quadril',
          med.quadril,
          prevMed?.quadril,
          widget.avaliacao.objetivo == Objetivo.emagrecimento,
        ),
        ('Abdômen', med.abdomen, prevMed?.abdomen, true),
        ('Braço', med.braco, prevMed?.braco, false),
        ('Coxa', med.coxa, prevMed?.coxa, false),
        ('Panturrilha', med.panturrilha, prevMed?.panturrilha, false),
      ])
        if (item.$2 != null && item.$2! > 0)
          GridHalfItem(
            child: MeasureRow(
              label: item.$1,
              value: '${item.$2!.toStringAsFixed(1)} cm',
              currentVal: item.$2,
              prevVal: item.$3,
              lowerIsBetter: item.$4,
            ),
          ),
    ];

    final skinfoldRows = <Widget>[
      for (final item in [
        ('Peitoral', med.dobraPeitoral, prevMed?.dobraPeitoral),
        ('Axilar Média', med.dobraAxilarMedia, prevMed?.dobraAxilarMedia),
        ('Tríceps', med.dobraTriceps, prevMed?.dobraTriceps),
        ('Subescapular', med.dobraSubescapular, prevMed?.dobraSubescapular),
        ('Abdominal', med.dobraAbdomen, prevMed?.dobraAbdomen),
        ('Suprailíaca', med.dobraSuprailiaca, prevMed?.dobraSuprailiaca),
        ('Coxa', med.dobraCoxa, prevMed?.dobraCoxa),
      ])
        if (item.$2 != null && item.$2! > 0)
          GridHalfItem(
            child: MeasureRow(
              label: item.$1,
              value: '${item.$2!.toStringAsFixed(1)} mm',
              currentVal: item.$2,
              prevVal: item.$3,
              unit: 'mm',
              lowerIsBetter: true,
            ),
          ),
    ];

    final bmiCategory = imc >= 30 ? 'obesidade' : 'sobrepeso';
    final switchedFromNavy = metodoPrincipal != 'navy';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Composição Corporal (Gordura) no topo dos dados clínicos
        DetailSectionCard(
          icon: Icons.track_changes_rounded,
          iconColor: colors.accent,
          headerBg: colors.surfaceSubtle,
          title: 'Composição Corporal (Gordura)',
          trailing: widget.onSelectBfMethod != null
              ? Text(
                  'Toque p/ escolher',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDiscrepancy) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (switchedFromNavy ? colors.accent : AppColors.orange)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          (switchedFromNavy ? colors.accent : AppColors.orange)
                              .withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        switchedFromNavy
                            ? Icons.info_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: switchedFromNavy
                            ? colors.accent
                            : colors.warningText,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          switchedFromNavy
                              ? 'Referência ajustada: Seu IMC (${imc.toStringAsFixed(1)} • $bmiCategory) divergiu do US Navy (${bfNavy.toStringAsFixed(1)}%). Usando ${snap?.metodoPrincipalLabel ?? metodoPrincipal.toUpperCase()} como base.'
                              : 'Discrepância detectada: Seu IMC (${imc.toStringAsFixed(1)}) indica $bmiCategory, mas o US Navy calculou ${bfNavy.toStringAsFixed(1)}%. Verifique se o Abdômen foi medido na linha do umbigo ou toque em Deurenberg / RFM abaixo para usar como referência.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (bfJp7 > 0) ...[
                MethodologyRow(
                  name: 'Jackson-Pollock 7 Dobras',
                  desc: 'Protocolo clínico de 7 dobras cutâneas',
                  value: '${bfJp7.toStringAsFixed(1)}%',
                  highlight: metodoPrincipal == 'jp7',
                  onTap: widget.onSelectBfMethod != null
                      ? () => widget.onSelectBfMethod!('jp7')
                      : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
              ],
              if (bfJp3 > 0) ...[
                MethodologyRow(
                  name: 'Jackson-Pollock 3 Dobras',
                  desc: 'Protocolo clínico de 3 dobras cutâneas',
                  value: '${bfJp3.toStringAsFixed(1)}%',
                  highlight: metodoPrincipal == 'jp3',
                  onTap: widget.onSelectBfMethod != null
                      ? () => widget.onSelectBfMethod!('jp3')
                      : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
              ],
              MethodologyRow(
                name: 'Método US Navy',
                desc: 'Estimativa baseada em circunferências',
                value: bfNavy > 0 ? '${bfNavy.toStringAsFixed(1)}%' : '--',
                highlight: metodoPrincipal == 'navy',
                onTap: (widget.onSelectBfMethod != null && bfNavy > 0)
                    ? () => widget.onSelectBfMethod!('navy')
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              MethodologyRow(
                name: 'Relative Fat Mass (RFM)',
                desc: 'Equação altura e cintura',
                value: bfRfm > 0 ? '${bfRfm.toStringAsFixed(1)}%' : '--',
                highlight: metodoPrincipal == 'rfm',
                onTap: (widget.onSelectBfMethod != null && bfRfm > 0)
                    ? () => widget.onSelectBfMethod!('rfm')
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              MethodologyRow(
                name: 'Fórmula Deurenberg',
                desc: 'Estimativa baseada no IMC e Idade',
                value: '${bfDeurenberg.toStringAsFixed(1)}%',
                highlight: metodoPrincipal == 'deurenberg',
                onTap: (widget.onSelectBfMethod != null && bfDeurenberg > 0)
                    ? () => widget.onSelectBfMethod!('deurenberg')
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Metabolismo e Metas
        if (bmrKatch > 0 && tdee > 0) ...[
          DetailSectionCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: colors.warningText,
            headerBg: isDark
                ? const Color(0xFF431407).withValues(alpha: 0.4)
                : const Color(0xFFFFF7ED),
            title: 'Metabolismo e Metas',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RiskMiniCard(
                        title: 'Metabolismo Basal',
                        value: bmrKatch.toStringAsFixed(0),
                        label: 'kcal / dia',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RiskMiniCard(
                        title: 'Gasto Diário (TDEE)',
                        value: tdee.toStringAsFixed(0),
                        label: 'kcal / dia',
                      ),
                    ),
                  ],
                ),
                if (macrosMap != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Meta: '),
                                    TextSpan(
                                      text: widget.avaliacao.objetivo.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${_numVal(macrosMap['targetCalories']).toStringAsFixed(0)} ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'kcal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MacroBar(
                          label: 'Proteínas',
                          grams: ((macrosMap['grams'] as Map?)?['protein']
                                      as num?)
                                  ?.toInt() ??
                              0,
                          pct: ((macrosMap['macros'] as Map?)?['protein']
                                      as num?)
                                  ?.toInt() ??
                              0,
                          color: AppColors.blue,
                        ),
                        const SizedBox(height: 10),
                        MacroBar(
                          label: 'Carboidratos',
                          grams:
                              ((macrosMap['grams'] as Map?)?['carbs'] as num?)
                                      ?.toInt() ??
                                  0,
                          pct: ((macrosMap['macros'] as Map?)?['carbs'] as num?)
                                  ?.toInt() ??
                              0,
                          color: const Color(0xFFF59E0B), // amber-500
                        ),
                        const SizedBox(height: 10),
                        MacroBar(
                          label: 'Gorduras',
                          grams: ((macrosMap['grams'] as Map?)?['fat'] as num?)
                                  ?.toInt() ??
                              0,
                          pct: ((macrosMap['macros'] as Map?)?['fat'] as num?)
                                  ?.toInt() ??
                              0,
                          color: AppColors.rose,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 3. Índices de Risco à Saúde (com rótulos claros e Guia ?)
        DetailSectionCard(
          icon: Icons.error_outline_rounded,
          iconColor: colors.warningText,
          headerBg: colors.surfaceSubtle,
          title: 'Índices de Risco à Saúde',
          trailing: IconButton(
            onPressed: () => _showIndicesGuide(context),
            tooltip: 'O que significam estes índices?',
            icon: Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: colors.accent,
            ),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GridHalfItem(
                spacing: 12,
                child: RiskMiniCard(
                  title: 'IMC',
                  value: imc.toStringAsFixed(1),
                  label: imcEval.$1,
                  badgeColor: imcEval.$2,
                ),
              ),
              GridHalfItem(
                spacing: 12,
                child: RiskMiniCard(
                  title: 'Cintura / Quadril (RCQ)',
                  value: rcq > 0 ? rcq.toStringAsFixed(2) : '--',
                  label: rcqEval.$1,
                  badgeColor: rcq > 0 ? rcqEval.$2 : null,
                ),
              ),
              GridHalfItem(
                spacing: 12,
                child: RiskMiniCard(
                  title: 'Cintura / Altura (RCEst)',
                  value: rcEst > 0 ? rcEst.toStringAsFixed(2) : '--',
                  label: rcEstEval.$1,
                  badgeColor: rcEst > 0 ? rcEstEval.$2 : null,
                ),
              ),
              GridHalfItem(
                spacing: 12,
                child: RiskMiniCard(
                  title: 'Massa Magra',
                  value: '${lbmFinal.toStringAsFixed(1)} kg',
                  label: lbmLabel,
                ),
              ),
              if (bai > 0)
                GridHalfItem(
                  spacing: 12,
                  child: RiskMiniCard(
                    title: 'Adiposidade (BAI)',
                    value: '${bai.toStringAsFixed(1)}%',
                    label: 'Estimativa quadril/altura',
                  ),
                ),
              if (bri > 0)
                GridHalfItem(
                  spacing: 12,
                  child: RiskMiniCard(
                    title: 'Gordura Visceral (BRI)',
                    value: bri.toStringAsFixed(1),
                    label: briEval.$1,
                    badgeColor: briEval.$2,
                  ),
                ),
              if (ci > 0)
                GridHalfItem(
                  spacing: 12,
                  child: RiskMiniCard(
                    title: 'Conicidade (CI)',
                    value: ci.toStringAsFixed(2),
                    label: ciEval.$1,
                    badgeColor: ciEval.$2,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. Peso Ideal (IBW — Devine em destaque + demais fórmulas recolhíveis)
        if (ibwMap != null) ...[
          DetailSectionCard(
            icon: Icons.monitor_weight_outlined,
            iconColor: colors.successText,
            headerBg: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                : const Color(0xFFECFDF5),
            title: 'Peso Ideal (IBW)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MethodologyRow(
                  name: 'Fórmula de Devine',
                  desc: 'Padrão clínico mais utilizado (1974)',
                  value: '${_numVal(ibwMap['devine']).toStringAsFixed(1)} kg',
                  highlight: true,
                ),
                if (_showAllIbwFormulas) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  MethodologyRow(
                    name: 'Fórmula de Robinson',
                    desc: 'Revisão (1983)',
                    value:
                        '${_numVal(ibwMap['robinson']).toStringAsFixed(1)} kg',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  MethodologyRow(
                    name: 'Fórmula de Miller',
                    desc: 'Revisão (1983)',
                    value:
                        '${_numVal(ibwMap['miller']).toStringAsFixed(1)} kg',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  MethodologyRow(
                    name: 'Fórmula de Hamwi',
                    desc: 'Base clássica (1964)',
                    value:
                        '${_numVal(ibwMap['hamwi']).toStringAsFixed(1)} kg',
                  ),
                ],
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: _showAllIbwFormulas
                      ? 'Ocultar fórmulas secundárias de peso ideal'
                      : 'Ver outras 3 fórmulas de peso ideal',
                  child: InkWell(
                    key: const ValueKey('btn_toggle_ibw_formulas'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showAllIbwFormulas = !_showAllIbwFormulas);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _showAllIbwFormulas
                                  ? 'Ocultar outras fórmulas'
                                  : 'Ver outras 3 fórmulas (Robinson, Miller, Hamwi)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colors.accent,
                              ),
                            ),
                          ),
                          Icon(
                            _showAllIbwFormulas
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: colors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 5. Medidas Registradas (oculta campos vazios "-- cm" e exibe dobras se houver)
        DetailSectionCard(
          icon: Icons.assignment_outlined,
          iconColor: colors.textSecondary,
          headerBg: colors.surfaceSubtle,
          title: 'Medidas Registradas',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: circumferenceRows,
              ),
              if (skinfoldRows.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'DOBRAS CUTÂNEAS (MM)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: skinfoldRows,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Ação secundária de compartilhamento posicionada após os dados clínicos
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleShare(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.successText,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: BorderSide(
                  color: colors.successText.withValues(alpha: 0.45),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.share_rounded, size: 19),
              label: const Text(
                'Compartilhar no WhatsApp',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
