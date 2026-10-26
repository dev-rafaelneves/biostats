import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/models.dart';

class ReportPdfGenerator {
  static double _numVal(dynamic val) => (val as num?)?.toDouble() ?? 0.0;

  static Future<Uint8List> generatePdfBytes({
    required UserProfile profile,
    required Avaliacao avaliacao,
    required Resultados? resultado,
  }) async {
    await initializeDateFormatting('pt_BR', null);
    final doc = pw.Document();
    final c = resultado?.calculos ?? {};

    final dateFmt = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');
    final dataAvaliacaoStr = dateFmt.format(avaliacao.dataAvaliacao);

    final diffDays = avaliacao.dataAvaliacao
        .difference(profile.dataNascimento)
        .inDays
        .abs();
    final idadeNaAvaliacao = (diffDays / 365.25).floor();

    final metasLabel = avaliacao.objetivo == Objetivo.emagrecimento
        ? 'Emagrecimento (Déficit)'
        : avaliacao.objetivo == Objetivo.hipertrofia
            ? 'Hipertrofia (Superávit)'
            : 'Manutenção';

    final ibwMap = c['ibw'] is Map
        ? Map<String, dynamic>.from(c['ibw'] as Map)
        : null;
    final devine = ibwMap != null ? _numVal(ibwMap['devine']) : _numVal(c['ibw']);

    final macrosMap = c['macros'] is Map
        ? Map<String, dynamic>.from(c['macros'] as Map)
        : null;
    final targetCalories = macrosMap != null
        ? _numVal(macrosMap['targetCalories'])
        : _numVal(c['metaCalorica']);
    final gramsMap = (macrosMap?['grams'] is Map)
        ? Map<String, dynamic>.from(macrosMap!['grams'] as Map)
        : <String, dynamic>{};

    final bfNavy = _numVal(c['bfNavy']);
    final lbmBoer = _numVal(c['lbmBoer']);
    final imc = _numVal(c['imc']);
    final rcEst = _numVal(c['rcEst']);
    final bmrKatch = _numVal(c['bmrKatch']);
    final tdee = _numVal(c['tdee']);
    final bai = _numVal(c['bai']);
    final bri = _numVal(c['bri']);
    final ci = _numVal(c['ci']);
    final rcq = _numVal(c['rcq']);

    const slate900 = PdfColor.fromInt(0xFF0F172A);
    const slate800 = PdfColor.fromInt(0xFF1E293B);
    const slate700 = PdfColor.fromInt(0xFF334155);
    const slate500 = PdfColor.fromInt(0xFF64748B);
    const slate400 = PdfColor.fromInt(0xFF94A3B8);
    const slate100 = PdfColor.fromInt(0xFFF1F5F9);
    const slate50 = PdfColor.fromInt(0xFFF8FAFC);
    const indigo600 = PdfColor.fromInt(0xFF4F46E5);
    const blue50 = PdfColor.fromInt(0xFFEFF6FF);
    const blue500 = PdfColor.fromInt(0xFF3B82F6);
    const blue900 = PdfColor.fromInt(0xFF1E3A8A);
    const green600 = PdfColor.fromInt(0xFF16A34A);

    pw.Widget buildKeyValueCard(
      String label,
      String value, {
      PdfColor? valueColor,
    }) {
      return pw.Container(
        width: 240,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: slate100, width: 1),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: slate500),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: valueColor ?? slate900,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget buildHighlightCard(String title, String value) {
      return pw.Container(
        width: 240,
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: blue50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: const pw.TextStyle(fontSize: 9.5, color: blue500),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: blue900,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget buildSectionTitle(String text) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          color: slate50,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: slate700,
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 14),
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: indigo600, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Autoavaliação Corporal',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: slate800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Relatório Pessoal de Progresso Físico e Nutricional',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: slate500,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Data da Avaliação',
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: slate500,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          dataAvaliacaoStr,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 1. IDENTIFICAÇÃO PESSOAL
              buildSectionTitle('1. Meu Perfil e Medidas Base'),
              pw.Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  buildKeyValueCard('Nome', profile.nome),
                  buildKeyValueCard('Idade', '$idadeNaAvaliacao anos'),
                  buildKeyValueCard('Sexo', profile.sexo.label),
                  buildKeyValueCard(
                    'Altura',
                    '${profile.alturaCm.toStringAsFixed(0)} cm',
                  ),
                  buildKeyValueCard(
                    'Peso Atual',
                    '${avaliacao.pesoKg.toStringAsFixed(1)} kg',
                  ),
                  buildKeyValueCard(
                    'Peso Ideal (Devine)',
                    devine > 0 ? '${devine.toStringAsFixed(1)} kg' : '--',
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // 2. COMPOSIÇÃO CORPORAL
              buildSectionTitle('2. Composição Corporal'),
              pw.Wrap(
                spacing: 20,
                children: [
                  buildHighlightCard(
                    'Gordura Corporal (Navy)',
                    bfNavy > 0 ? '${bfNavy.toStringAsFixed(1)} %' : '--',
                  ),
                  buildHighlightCard(
                    'Massa Magra (Boer)',
                    lbmBoer > 0 ? '${lbmBoer.toStringAsFixed(1)} kg' : '--',
                  ),
                  buildHighlightCard(
                    'Índice de Massa Corporal',
                    imc > 0 ? imc.toStringAsFixed(1) : '--',
                  ),
                  buildHighlightCard(
                    'Relação Cintura-Estatura',
                    rcEst > 0 ? rcEst.toStringAsFixed(2) : '--',
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // 3. METABOLISMO E METAS
              buildSectionTitle('3. Metabolismo & Metas ($metasLabel)'),
              pw.Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  buildKeyValueCard(
                    'Taxa Metabólica Basal',
                    bmrKatch > 0 ? '${bmrKatch.toStringAsFixed(0)} kcal' : '--',
                  ),
                  buildKeyValueCard(
                    'Gasto Energético (TDEE)',
                    tdee > 0 ? '${tdee.toStringAsFixed(0)} kcal' : '--',
                  ),
                  if (targetCalories > 0)
                    buildKeyValueCard(
                      'Meta Diária de Calorias',
                      '${targetCalories.toStringAsFixed(0)} kcal',
                      valueColor: green600,
                    ),
                ],
              ),
              if (gramsMap.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: slate50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Sugestão de Macronutrientes Diários:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: slate700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Proteínas: ${gramsMap['protein'] ?? 0}g',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: slate700,
                            ),
                          ),
                          pw.Text(
                            'Carboidratos: ${gramsMap['carbs'] ?? 0}g',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: slate700,
                            ),
                          ),
                          pw.Text(
                            'Gorduras: ${gramsMap['fat'] ?? 0}g',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: slate700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              pw.SizedBox(height: 18),

              // 4. ÍNDICES CIENTÍFICOS
              buildSectionTitle('4. Índices Científicos e Risco Clínico'),
              pw.Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  buildKeyValueCard(
                    'Índice de Adiposidade (BAI)',
                    bai > 0 ? '${bai.toStringAsFixed(1)}%' : '--',
                  ),
                  buildKeyValueCard(
                    'Índice de Redondeza (BRI)',
                    bri > 0 ? bri.toStringAsFixed(2) : '--',
                  ),
                  buildKeyValueCard(
                    'Índice de Conicidade (CI)',
                    ci > 0 ? ci.toStringAsFixed(2) : '--',
                  ),
                  buildKeyValueCard(
                    'Rel. Cintura-Quadril',
                    rcq > 0 ? rcq.toStringAsFixed(2) : '--',
                  ),
                ],
              ),

              pw.Spacer(),

              // RODAPÉ
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: slate100, width: 1),
                  ),
                ),
                child: pw.Text(
                  'Este relatório foi gerado automaticamente pelo BioStats e traz estimativas de composição corporal baseadas em equações antropométricas validadas na literatura científica internacional. Os resultados apresentados não configuram diagnóstico médico definitivo e não substituem exames clínicos, laboratoriais ou de imagem padronizados (como DXA ou bioimpedância clínica).',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: slate400,
                    lineSpacing: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
