import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

enum AiInsightType { evaluation, comparison }

/// Card moderno estilo Apple Health para exibição e geração de pareceres
/// inteligentes com o Google Gemini. Possui cache automático local em SQLite.
class AiInsightCard extends StatefulWidget {
  final AppState appState;
  final UserProfile profile;
  final AiInsightType type;

  // Parâmetros para avaliação única
  final Avaliacao? avaliacao;
  final Resultados? resultado;

  // Parâmetros para comparação
  final Avaliacao? anterior;
  final Resultados? resultadoAnt;
  final Avaliacao? atual;
  final Resultados? resultadoAtual;

  const AiInsightCard.evaluation({
    super.key,
    required this.appState,
    required this.profile,
    required this.avaliacao,
    required this.resultado,
  })  : type = AiInsightType.evaluation,
        anterior = null,
        resultadoAnt = null,
        atual = null,
        resultadoAtual = null;

  const AiInsightCard.comparison({
    super.key,
    required this.appState,
    required this.profile,
    required this.anterior,
    required this.resultadoAnt,
    required this.atual,
    required this.resultadoAtual,
  })  : type = AiInsightType.comparison,
        avaliacao = null,
        resultado = null;

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _insightText;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCachedInsight();
  }

  @override
  void didUpdateWidget(covariant AiInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type == AiInsightType.evaluation) {
      if (oldWidget.avaliacao?.id != widget.avaliacao?.id) {
        _loadCachedInsight();
      }
    } else {
      if (oldWidget.anterior?.id != widget.anterior?.id ||
          oldWidget.atual?.id != widget.atual?.id) {
        _loadCachedInsight();
      }
    }
  }

  String get _refId {
    if (widget.type == AiInsightType.evaluation) {
      return widget.avaliacao?.id ?? '';
    } else {
      return '${widget.anterior?.id}_${widget.atual?.id}';
    }
  }

  String get _tipoString =>
      widget.type == AiInsightType.evaluation ? 'evaluation_summary' : 'comparison';

  Future<void> _loadCachedInsight() async {
    final ref = _refId;
    if (ref.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cached = await DatabaseService.getAiInsight(_tipoString, ref);
    if (mounted) {
      setState(() {
        _insightText = cached;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInsight({bool forceRefresh = false}) async {
    final hasKey = await GeminiService.hasApiKey();
    if (!hasKey) {
      _showKeyRequiredDialog();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      String result;
      if (widget.type == AiInsightType.evaluation) {
        if (widget.avaliacao == null || widget.resultado == null) {
          throw StateError('Dados da avaliação incompletos.');
        }
        result = await GeminiService.generateEvaluationInsight(
          profile: widget.profile,
          avaliacao: widget.avaliacao!,
          resultado: widget.resultado!,
          forceRefresh: forceRefresh,
        );
      } else {
        if (widget.anterior == null ||
            widget.resultadoAnt == null ||
            widget.atual == null ||
            widget.resultadoAtual == null) {
          throw StateError('Dados das avaliações para comparação incompletos.');
        }
        result = await GeminiService.generateComparisonInsight(
          profile: widget.profile,
          anterior: widget.anterior!,
          resultadoAnt: widget.resultadoAnt!,
          atual: widget.atual!,
          resultadoAtual: widget.resultadoAtual!,
          forceRefresh: forceRefresh,
        );
      }

      if (mounted) {
        setState(() {
          _insightText = result;
          _isGenerating = false;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('StateError: ', '');
          _isGenerating = false;
        });
      }
    }
  }

  void _showKeyRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.indigoPrimary,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Ativar IA do Gemini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Para gerar diagnósticos clínicos e análises comparativas com IA, insira sua chave da API do Google Gemini. Ela fica salva com criptografia apenas no seu celular.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Navega ou orienta para a aba de Ajustes
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Acesse Ajustes > Inteligência Artificial para configurar sua chave.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigoPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Ir para Ajustes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEval = widget.type == AiInsightType.evaluation;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header estilo Apple Health
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEval
                            ? 'Parecer Bio-Coach (IA)'
                            : 'Análise Comparativa (IA)',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Diagnóstico inteligente com Google Gemini',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_insightText != null && !_isGenerating)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Recalcular Análise',
                    onPressed: () => _generateInsight(forceRefresh: true),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Conteúdo Dinâmico
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(context, isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isDark}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_isGenerating) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.indigoPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'O Bio-Coach está analisando sua composição corporal...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cruzando dobras cutâneas, circunferências e gasto energético',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _generateInsight(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tentar Novamente'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_insightText != null && _insightText!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Salvo no aparelho (0 tokens)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copiar Parecer',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: _insightText!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parecer copiado para a área de transferência!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MarkdownFormattedView(
            text: _insightText!,
            isDark: isDark,
          ),
        ],
      );
    }

    // Estado inicial: convite para gerar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.type == AiInsightType.evaluation
              ? 'Receba uma análise médica e esportiva personalizada interpretando suas métricas, proporção de massa magra e distribuição de gordura.'
              : 'Descubra a qualidade da sua evolução entre estas duas datas: preservação de massa muscular, queima real de gordura e próximos passos.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _generateInsight(forceRefresh: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigoPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              widget.type == AiInsightType.evaluation
                  ? 'Gerar Parecer Inteligente ✨'
                  : 'Analisar Progresso com IA ✨',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renderizador simples e elegante de Markdown nativo sem dependências externas
class _MarkdownFormattedView extends StatelessWidget {
  final String text;
  final bool isDark;

  const _MarkdownFormattedView({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Títulos Markdown (#, ##, ###)
      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              line.substring(4).replaceAll('**', ''),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF818CF8) : AppColors.indigoPrimary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              line.substring(3).replaceAll('**', ''),
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF818CF8) : AppColors.indigoPrimary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              line.substring(2).replaceAll('**', ''),
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        );
      } else if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        // Tópicos com marcadores
        final bulletContent = line.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : AppColors.indigoPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichSpan(bulletContent, isDark),
                ),
              ],
            ),
          ),
        );
      } else {
        // Parágrafo comum
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: _buildRichSpan(line, isDark),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichSpan(String input, bool isDark) {
    // Processamento de **negrito** inline
    final parts = input.split('**');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDark
                ? (isBold ? Colors.white : AppColors.darkTextPrimary)
                : (isBold ? const Color(0xFF0F172A) : AppColors.lightTextPrimary),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
