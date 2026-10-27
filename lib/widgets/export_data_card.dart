import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/report_pdf_generator.dart';

class ExportDataCard extends StatefulWidget {
  final UserProfile profile;
  final List<JoinedEvaluation> evaluations;
  final JoinedEvaluation? selectedEvaluation;

  const ExportDataCard({
    super.key,
    required this.profile,
    required this.evaluations,
    required this.selectedEvaluation,
  });

  @override
  State<ExportDataCard> createState() => _ExportDataCardState();
}

class _ExportDataCardState extends State<ExportDataCard> {
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  Future<void> _handleExportPdf() async {
    final sel = widget.selectedEvaluation;
    if (sel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados da avaliação não encontrados para gerar o PDF.'),
        ),
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await ReportPdfGenerator.generatePdfBytes(
        profile: widget.profile,
        avaliacao: sel.avaliacao,
        resultado: sel.resultado,
      );

      final cleanName = widget.profile.nome
          .trim()
          .replaceAll(RegExp(r'\s+'), '-')
          .toLowerCase();
      final fileName = 'relatorio-$cleanName.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar o PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _handleExportCsv() async {
    if (widget.evaluations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma avaliação encontrada.')),
      );
      return;
    }

    setState(() => _isExportingCsv = true);
    try {
      final headers = [
        'Data',
        'Peso (kg)',
        'Gordura Navy (%)',
        'Gordura RFM (%)',
        'Massa Magra (kg)',
        'Cintura (cm)',
        'Pescoço (cm)',
        'Quadril (cm)',
        'TMB (kcal)',
        'TDEE (kcal)',
      ];

      final dateFmt = DateFormat('dd/MM/yyyy');
      String fmtNum(dynamic val, [int decimals = 2]) {
        if (val == null) return '';
        final d = (val as num).toDouble();
        if (d <= 0) return '';
        return d.toStringAsFixed(decimals);
      }

      final rows = widget.evaluations.map((ev) {
        final av = ev.avaliacao;
        final calc = ev.resultado?.calculos ?? {};
        final cols = [
          dateFmt.format(av.dataAvaliacao),
          av.pesoKg.toStringAsFixed(2),
          fmtNum(calc['bfNavy']),
          fmtNum(calc['bfRfm']),
          fmtNum(ev.resultado?.snapshot.lbmFinal ?? calc['lbmBoer']),
          av.medidas.cintura?.toString() ?? '',
          av.medidas.pescoco?.toString() ?? '',
          av.medidas.quadril?.toString() ?? '',
          fmtNum(calc['bmrKatch'], 0),
          fmtNum(calc['tdee'], 0),
        ];
        return cols
            .map((v) => '"${v.replaceAll('.', ',')}"')
            .join(',');
      });

      final csvContent = '\ufeff${[headers.join(','), ...rows].join('\n')}';
      final bytes = Uint8List.fromList(utf8.encode(csvContent));

      final cleanName =
          widget.profile.nome.trim().replaceAll(RegExp(r'\s+'), '_');
      final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final filename = 'Historico_${cleanName}_$today.csv';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'text/csv',
          ),
        ],
        subject: 'Histórico de Evolução BioStats (CSV)',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planilha exportada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao gerar planilha.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exportar Meus Dados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gere um documento PDF da avaliação selecionada ou exporte seu histórico completo para Excel (.csv).',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Botão PDF
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExportingPdf ? null : _handleExportPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isExportingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _isExportingPdf
                    ? 'Gerando Relatório Premium...'
                    : 'Baixar Relatório (PDF)',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Botão CSV
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExportingCsv ? null : _handleExportCsv,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669), // emerald-600
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isExportingCsv
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.table_chart_outlined, size: 20),
              label: Text(
                _isExportingCsv
                    ? 'Processando Tabela...'
                    : 'Exportar Tabela (CSV)',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
