import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class EvaluationDetailsWidget extends StatelessWidget {
  final UserProfile profile;
  final Avaliacao avaliacao;
  final Resultados? resultado;
  final Avaliacao? previousAvaliacao;

  const EvaluationDetailsWidget({
    super.key,
    required this.profile,
    required this.avaliacao,
    required this.resultado,
    this.previousAvaliacao,
  });

  double _numVal(dynamic val) => (val as num?)?.toDouble() ?? 0.0;

  (String, Color) _evaluateImc(double imc) {
    if (imc <= 0) return ('--', const Color(0xFF94A3B8));
    if (imc < 18.5) return ('Baixo peso', AppColors.orange);
    if (imc < 25) return ('Saudável', AppColors.emerald);
    if (imc < 30) return ('Sobrepeso', AppColors.orange);
    return ('Obesidade', AppColors.rose);
  }

  (String, Color) _evaluateRcEst(double rcEst) {
    if (rcEst <= 0) return ('Cintura/Estatura', const Color(0xFF94A3B8));
    if (rcEst < 0.50) return ('Saudável (<0.50)', AppColors.emerald);
    if (rcEst < 0.60) return ('Atenção (0.50-0.59)', AppColors.orange);
    return ('Risco Elevado', AppColors.rose);
  }

  (String, Color) _evaluateRcq(double rcq, Sexo sexo) {
    if (rcq <= 0) return ('Cintura/Quadril', const Color(0xFF94A3B8));
    final limit = sexo == Sexo.M ? 0.90 : 0.85;
    if (rcq < limit) return ('Baixo Risco', AppColors.emerald);
    if (rcq < limit + 0.05) return ('Risco Moderado', AppColors.orange);
    return ('Risco Alto', AppColors.rose);
  }

  (String, Color) _evaluateBri(double bri) {
    if (bri <= 0) return ('Redondeza Corp.', const Color(0xFF94A3B8));
    if (bri < 3.4) return ('Saudável', AppColors.emerald);
    if (bri <= 4.4) return ('Atenção', AppColors.orange);
    return ('Risco Visceral', AppColors.rose);
  }

  (String, Color) _evaluateCi(double ci, Sexo sexo) {
    if (ci <= 0) return ('Índice Conicidade', const Color(0xFF94A3B8));
    final limit = sexo == Sexo.M ? 1.25 : 1.18;
    if (ci < limit) return ('Normal', AppColors.emerald);
    return ('Atenção Abdominal', AppColors.orange);
  }

  void _showIndicesGuide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
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
                                  color: isDark
                                      ? AppColors.indigoLight
                                      : AppColors.indigoPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                it.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF475569),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigoPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Fechar'),
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
    final calc = resultado?.calculos ?? {};
    final dataFormatada =
        DateFormat("dd 'de' MMMM", 'pt_BR').format(avaliacao.dataAvaliacao);

    final bfNavy = _numVal(calc['bfNavy']);
    final bfRfm = _numVal(calc['bfRfm']);
    final lbmBoer = _numVal(calc['lbmBoer']);
    final imc = _numVal(calc['imc']);
    final rcq = _numVal(calc['rcq']);
    final bai = _numVal(calc['bai']);
    final bri = _numVal(calc['bri']);
    final ci = _numVal(calc['ci']);
    final bmrKatch = _numVal(calc['bmrKatch']);
    final tdee = _numVal(calc['tdee']);

    final ibwMap = calc['ibw'] is Map
        ? Map<String, dynamic>.from(calc['ibw'] as Map)
        : null;
    final macrosMap = calc['macros'] is Map
        ? Map<String, dynamic>.from(calc['macros'] as Map)
        : null;

    final buffer = StringBuffer();
    buffer.writeln('*Resumo da Minha Avaliação Física* 📊');
    buffer.writeln('*Nome:* ${profile.nome}');
    buffer.writeln('*Data:* $dataFormatada\n');
    buffer.writeln('*Composição Corporal:*');
    if (bfNavy > 0) {
      buffer.writeln('• BF (US Navy): ${bfNavy.toStringAsFixed(1)}%');
    } else if (bfRfm > 0) {
      buffer.writeln('• BF (RFM): ${bfRfm.toStringAsFixed(1)}%');
    }
    buffer.writeln('• Massa Magra: ${lbmBoer.toStringAsFixed(1)} kg');
    buffer.writeln('• Peso Atual: ${avaliacao.pesoKg.toStringAsFixed(1)} kg');

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

      buffer.writeln('\n*Plano Nutricional (${avaliacao.objetivo.label}):*');
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
    final calc = resultado?.calculos ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bmrKatch = _numVal(calc['bmrKatch']);
    final tdee = _numVal(calc['tdee']);
    final bfNavy = _numVal(calc['bfNavy']);
    final bfRfm = _numVal(calc['bfRfm']);
    final bfDeurenberg = _numVal(calc['bfDeurenberg']);
    final imc = _numVal(calc['imc']);
    final rcq = _numVal(calc['rcq']);
    final rcEst = _numVal(calc['rcEst']);
    final lbmBoer = _numVal(calc['lbmBoer']);
    final bai = _numVal(calc['bai']);
    final bri = _numVal(calc['bri']);
    final ci = _numVal(calc['ci']);

    final ibwMap = calc['ibw'] is Map
        ? Map<String, dynamic>.from(calc['ibw'] as Map)
        : null;
    final macrosMap = calc['macros'] is Map
        ? Map<String, dynamic>.from(calc['macros'] as Map)
        : null;

    String fmtMeasure(double? v) => v != null && v > 0 ? '$v cm' : '-- cm';

    final imcEval = _evaluateImc(imc);
    final rcqEval = _evaluateRcq(rcq, profile.sexo);
    final rcEstEval = _evaluateRcEst(rcEst);
    final briEval = _evaluateBri(bri);
    final ciEval = _evaluateCi(ci, profile.sexo);

    final prevMed = previousAvaliacao?.medidas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão Compartilhar no WhatsApp
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _handleShare(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E), // green-500
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text(
              'Compartilhar no WhatsApp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 1. Metabolismo e Metas
        if (bmrKatch > 0 && tdee > 0) ...[
          _DetailSectionCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.orange,
            headerBg: isDark
                ? const Color(0xFF431407).withValues(alpha: 0.4)
                : const Color(0xFFFFF7ED),
            title: 'Metabolismo e Metas',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RiskMiniCard(
                        title: 'Metabolismo Basal',
                        value: bmrKatch.toStringAsFixed(0),
                        label: 'kcal / dia',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RiskMiniCard(
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
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF475569),
                                  ),
                                  children: [
                                    const TextSpan(text: 'Meta: '),
                                    TextSpan(
                                      text: avaliacao.objetivo.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.indigoLight
                                            : AppColors.indigoPrimary,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'kcal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MacroBar(
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
                        _MacroBar(
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
                        _MacroBar(
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

        // 2. Peso Ideal (IBW)
        if (ibwMap != null) ...[
          _DetailSectionCard(
            icon: Icons.monitor_weight_outlined,
            iconColor: AppColors.emerald,
            headerBg: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                : const Color(0xFFECFDF5),
            title: 'Peso Ideal (IBW)',
            child: Column(
              children: [
                _MethodologyRow(
                  name: 'Fórmula de Devine',
                  desc: 'Padrão clínico mais utilizado (1974)',
                  value: '${_numVal(ibwMap['devine']).toStringAsFixed(1)} kg',
                  highlight: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _MethodologyRow(
                  name: 'Fórmula de Robinson',
                  desc: 'Revisão (1983)',
                  value: '${_numVal(ibwMap['robinson']).toStringAsFixed(1)} kg',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _MethodologyRow(
                  name: 'Fórmula de Miller',
                  desc: 'Revisão (1983)',
                  value: '${_numVal(ibwMap['miller']).toStringAsFixed(1)} kg',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _MethodologyRow(
                  name: 'Fórmula de Hamwi',
                  desc: 'Base clássica (1964)',
                  value: '${_numVal(ibwMap['hamwi']).toStringAsFixed(1)} kg',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 3. Composição Corporal (Gordura)
        _DetailSectionCard(
          icon: Icons.track_changes_rounded,
          iconColor: AppColors.indigoPrimary,
          headerBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          title: 'Composição Corporal (Gordura)',
          child: Column(
            children: [
              _MethodologyRow(
                name: 'Método US Navy',
                desc: 'Baseado em circunferências (Padrão ouro prático)',
                value: bfNavy > 0 ? '${bfNavy.toStringAsFixed(1)}%' : '--',
                highlight: bfNavy > 0,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              _MethodologyRow(
                name: 'Relative Fat Mass (RFM)',
                desc: 'Equação recente altura/cintura',
                value: bfRfm > 0 ? '${bfRfm.toStringAsFixed(1)}%' : '--',
                highlight: bfNavy <= 0 && bfRfm > 0,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              _MethodologyRow(
                name: 'Fórmula Deurenberg',
                desc: 'Estimativa baseada no IMC e Idade',
                value: '${bfDeurenberg.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. Índices de Risco à Saúde (com Semáforo Clínico e Guia ?)
        _DetailSectionCard(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.orange,
          headerBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          title: 'Índices de Risco à Saúde',
          trailing: IconButton(
            onPressed: () => _showIndicesGuide(context),
            tooltip: 'O que significam estes índices?',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppColors.indigoPrimary,
            ),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _GridHalfItem(
                child: _RiskMiniCard(
                  title: 'IMC',
                  value: imc.toStringAsFixed(1),
                  label: imcEval.$1,
                  badgeColor: imcEval.$2,
                ),
              ),
              _GridHalfItem(
                child: _RiskMiniCard(
                  title: 'RCQ',
                  value: rcq > 0 ? rcq.toStringAsFixed(2) : '--',
                  label: rcqEval.$1,
                  badgeColor: rcq > 0 ? rcqEval.$2 : null,
                ),
              ),
              _GridHalfItem(
                child: _RiskMiniCard(
                  title: 'RCEst',
                  value: rcEst > 0 ? rcEst.toStringAsFixed(2) : '--',
                  label: rcEstEval.$1,
                  badgeColor: rcEst > 0 ? rcEstEval.$2 : null,
                ),
              ),
              _GridHalfItem(
                child: _RiskMiniCard(
                  title: 'Massa Magra',
                  value: '${lbmBoer.toStringAsFixed(1)} kg',
                  label: 'Fórmula Boer',
                ),
              ),
              if (bai > 0)
                _GridHalfItem(
                  child: _RiskMiniCard(
                    title: 'BAI',
                    value: '${bai.toStringAsFixed(1)}%',
                    label: 'Adiposidade',
                  ),
                ),
              if (bri > 0)
                _GridHalfItem(
                  child: _RiskMiniCard(
                    title: 'BRI',
                    value: bri.toStringAsFixed(1),
                    label: briEval.$1,
                    badgeColor: briEval.$2,
                  ),
                ),
              if (ci > 0)
                _GridHalfItem(
                  child: _RiskMiniCard(
                    title: 'CI',
                    value: ci.toStringAsFixed(2),
                    label: ciEval.$1,
                    badgeColor: ciEval.$2,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 5. Medidas Registradas (com Deltas em cm vs. Avaliação Anterior)
        _DetailSectionCard(
          icon: Icons.assignment_outlined,
          iconColor: const Color(0xFF475569),
          headerBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          title: 'Medidas Registradas',
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Peso',
                  value: '${avaliacao.pesoKg} kg',
                  currentVal: avaliacao.pesoKg,
                  prevVal: previousAvaliacao?.pesoKg,
                  unit: 'kg',
                  lowerIsBetter:
                      avaliacao.objetivo == Objetivo.emagrecimento,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Pescoço',
                  value: fmtMeasure(avaliacao.medidas.pescoco),
                  currentVal: avaliacao.medidas.pescoco,
                  prevVal: prevMed?.pescoco,
                  lowerIsBetter: true,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Cintura',
                  value: fmtMeasure(avaliacao.medidas.cintura),
                  currentVal: avaliacao.medidas.cintura,
                  prevVal: prevMed?.cintura,
                  lowerIsBetter: true,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Quadril',
                  value: fmtMeasure(avaliacao.medidas.quadril),
                  currentVal: avaliacao.medidas.quadril,
                  prevVal: prevMed?.quadril,
                  lowerIsBetter:
                      avaliacao.objetivo == Objetivo.emagrecimento,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Abdômen',
                  value: fmtMeasure(avaliacao.medidas.abdomen),
                  currentVal: avaliacao.medidas.abdomen,
                  prevVal: prevMed?.abdomen,
                  lowerIsBetter: true,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Braço',
                  value: fmtMeasure(avaliacao.medidas.braco),
                  currentVal: avaliacao.medidas.braco,
                  prevVal: prevMed?.braco,
                  lowerIsBetter: false,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Coxa',
                  value: fmtMeasure(avaliacao.medidas.coxa),
                  currentVal: avaliacao.medidas.coxa,
                  prevVal: prevMed?.coxa,
                  lowerIsBetter: false,
                ),
              ),
              _GridHalfItem(
                child: _MeasureRow(
                  label: 'Panturrilha',
                  value: fmtMeasure(avaliacao.medidas.panturrilha),
                  currentVal: avaliacao.medidas.panturrilha,
                  prevVal: prevMed?.panturrilha,
                  lowerIsBetter: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color headerBg;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _DetailSectionCard({
    required this.icon,
    required this.iconColor,
    required this.headerBg,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int grams;
  final int pct;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF475569),
              ),
            ),
            Text(
              '${grams}g ($pct%)',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: (pct.clamp(0, 100)) / 100.0,
            minHeight: 8,
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MethodologyRow extends StatelessWidget {
  final String name;
  final String desc;
  final String value;
  final bool highlight;

  const _MethodologyRow({
    required this.name,
    required this.desc,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: highlight
                      ? (isDark
                          ? AppColors.indigoLight
                          : const Color(0xFF4338CA))
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: highlight
                ? (isDark ? AppColors.indigoLight : AppColors.indigoPrimary)
                : (isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}

class _RiskMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String label;
  final Color? badgeColor;

  const _RiskMiniCard({
    required this.title,
    required this.value,
    required this.label,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (badgeColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight:
                  badgeColor != null ? FontWeight.w600 : FontWeight.normal,
              color: badgeColor ??
                  (isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasureRow extends StatelessWidget {
  final String label;
  final String value;
  final double? currentVal;
  final double? prevVal;
  final String unit;
  final bool lowerIsBetter;

  const _MeasureRow({
    required this.label,
    required this.value,
    this.currentVal,
    this.prevVal,
    this.unit = 'cm',
    this.lowerIsBetter = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDelta = currentVal != null &&
        prevVal != null &&
        currentVal! > 0 &&
        prevVal! > 0 &&
        (currentVal! - prevVal!).abs() >= 0.1;

    final diff = hasDelta ? (currentVal! - prevVal!) : 0.0;
    final sign = diff > 0 ? '+' : '';
    final isGood = lowerIsBetter ? diff < 0 : diff > 0;
    final deltaColor = isGood ? AppColors.emerald : AppColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFF8FAFC),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF334155),
                ),
              ),
              if (hasDelta)
                Text(
                  '$sign${diff.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: deltaColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridHalfItem extends StatelessWidget {
  final Widget child;
  const _GridHalfItem({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width.clamp(300.0, 460.0) - 80) /
              2,
          child: child,
        );
      },
    );
  }
}
