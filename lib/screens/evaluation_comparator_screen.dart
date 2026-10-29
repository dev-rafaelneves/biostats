import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_insight_card.dart';
import 'evaluation_comparator/comparison_section_card.dart';
import 'evaluation_comparator/evaluation_selector_chip.dart';
import 'evaluation_comparator/fractional_horizontal_clipper.dart';
import 'evaluation_comparator/photos_comparison_tab.dart';
import 'evaluation_comparator/summary_metric_pill.dart';
import 'evaluation_comparator/tab_button.dart';

class EvaluationComparatorScreen extends StatefulWidget {
  final AppState appState;
  final String? initialBaseId;
  final String? initialCompareId;

  const EvaluationComparatorScreen({
    super.key,
    required this.appState,
    this.initialBaseId,
    this.initialCompareId,
  });

  @override
  State<EvaluationComparatorScreen> createState() =>
      _EvaluationComparatorScreenState();
}

class _EvaluationComparatorScreenState
    extends State<EvaluationComparatorScreen> {
  late String _baseId;
  late String _compareId;
  int _tabIndex = 0; // 0: Métricas, 1: Fotos
  FotoTipo _selectedFotoTipo = FotoTipo.frente;

  @override
  void initState() {
    super.initState();
    final evals = widget.appState.joinedEvaluations;
    if (evals.length >= 2) {
      // Default: base = oldest (evals.last), compare = latest (evals.first)
      _baseId = widget.initialBaseId ?? evals.last.avaliacao.id;
      _compareId = widget.initialCompareId ?? evals.first.avaliacao.id;
    } else if (evals.isNotEmpty) {
      _baseId = evals.first.avaliacao.id;
      _compareId = evals.first.avaliacao.id;
    } else {
      _baseId = '';
      _compareId = '';
    }
  }

  void _swapSelections() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _baseId;
      _baseId = _compareId;
      _compareId = temp;
    });
  }

  Future<void> _selectEvaluation({
    required BuildContext context,
    required bool isBase,
    required List<JoinedEvaluation> evals,
  }) async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentId = isBase ? _baseId : _compareId;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isBase ? 'Selecionar Marco Base (A)' : 'Selecionar Marco de Comparação (B)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: evals.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = evals[idx];
                      final isCurrent = item.avaliacao.id == currentId;
                      final dateStr = DateFormat('dd/MM/yyyy')
                          .format(item.avaliacao.dataAvaliacao);
                      return ListTile(
                        selected: isCurrent,
                        selectedTileColor:
                            AppColors.indigoPrimary.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? AppColors.indigoPrimary
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: isCurrent
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                        title: Text(
                          dateStr,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${item.avaliacao.pesoKg.toStringAsFixed(1)} kg • ${idx == 0 ? "Última registrada" : "Avaliação #$idx"}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF64748B),
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.indigoPrimary,
                              )
                            : null,
                        onTap: () => Navigator.of(ctx).pop(item.avaliacao.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        if (isBase) {
          _baseId = selected;
        } else {
          _compareId = selected;
        }
      });
    }
  }

  void _openInteractiveZoom(
    BuildContext context, {
    required Uint8List? bytesA,
    required Uint8List? bytesB,
    required String labelA,
    required String labelB,
  }) {
    HapticFeedback.lightImpact();
    final hasBoth = bytesA != null && bytesB != null;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (ctx) {
        double modalSlider = 0.5;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                title: Text(
                  'Comparador Visual (${_selectedFotoTipo.label})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (hasBoth)
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          modalSlider = modalSlider == 0.5
                              ? 1.0
                              : (modalSlider == 1.0 ? 0.0 : 0.5);
                        });
                      },
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        modalSlider == 0.0
                            ? 'Atual (100%)'
                            : (modalSlider == 1.0 ? 'Base (100%)' : '50 / 50'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              body: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Use dois dedos para zoom de até 4x e arraste o controle para comparar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: InteractiveViewer(
                        clipBehavior: Clip.none,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          constraints: const BoxConstraints(
                            maxWidth: 420,
                            maxHeight: 520,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (bytesB != null)
                                Image.memory(
                                  bytesB,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              if (bytesA != null)
                                ClipRect(
                                  clipper: FractionalHorizontalClipper(
                                    fraction: hasBoth ? modalSlider : 1.0,
                                  ),
                                  child: Image.memory(
                                    bytesA,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              if (hasBoth)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final handleX =
                                        constraints.maxWidth * modalSlider;
                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: handleX - 1,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Positioned(
                                          left: handleX - 18,
                                          top: constraints.maxHeight / 2 - 18,
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.indigoPrimary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black45,
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.compare_arrows_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasBoth)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                labelA,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 9,
                                  ),
                                  activeTrackColor: AppColors.indigoLight,
                                  inactiveTrackColor: Colors.white30,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: modalSlider,
                                  onChanged: (val) {
                                    setModalState(() => modalSlider = val);
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                labelB,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Uint8List? _getPhotoBytes(JoinedEvaluation? ev, FotoTipo tipo) {
    if (ev == null) return null;
    final photos = widget.appState.getFotosForAvaliacao(ev.avaliacao.id);
    for (final p in photos) {
      if (p.tipo == tipo) {
        return widget.appState.getDecodedPhotoBytes(p);
      }
    }
    return null;
  }

  double _getBf(JoinedEvaluation? ev) {
    if (ev == null) return 0.0;
    return ev.resultado?.snapshot.bfPrincipal ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.appState.userProfile;
    final evals = widget.appState.joinedEvaluations;

    if (evals.length < 2 || profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Comparador de Avaliações'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.indigoPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    size: 36,
                    color: AppColors.indigoPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Necessário pelo menos 2 avaliações',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cadastre pelo menos duas avaliações corporais no histórico para comparar livremente as métricas, circunferências e fotos lado a lado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigoPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Voltar ao Painel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    JoinedEvaluation? evalA;
    JoinedEvaluation? evalB;
    for (final e in evals) {
      if (e.avaliacao.id == _baseId) evalA = e;
      if (e.avaliacao.id == _compareId) evalB = e;
    }
    evalA ??= evals.last;
    evalB ??= evals.first;

    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateA = evalA.avaliacao.dataAvaliacao;
    final dateB = evalB.avaliacao.dataAvaliacao;
    final dateAStr = dateFmt.format(dateA);
    final dateBStr = dateFmt.format(dateB);

    final daysDiff = dateB.difference(dateA).inDays;
    final isSameDate = daysDiff == 0 && evalA.avaliacao.id == evalB.avaliacao.id;

    // Deltas de Composição
    final pesoA = evalA.avaliacao.pesoKg;
    final pesoB = evalB.avaliacao.pesoKg;
    final deltaPeso = pesoB - pesoA;
    final pctPeso = pesoA > 0 ? (deltaPeso / pesoA) * 100 : 0.0;

    final bfA = _getBf(evalA);
    final bfB = _getBf(evalB);
    final deltaBf = (bfA > 0 && bfB > 0) ? (bfB - bfA) : null;

    final leanA = (bfA > 0) ? pesoA * (1.0 - (bfA / 100.0)) : null;
    final leanB = (bfB > 0) ? pesoB * (1.0 - (bfB / 100.0)) : null;
    final deltaLean = (leanA != null && leanB != null) ? (leanB - leanA) : null;

    final fatA = (bfA > 0) ? pesoA * (bfA / 100.0) : null;
    final fatB = (bfB > 0) ? pesoB * (bfB / 100.0) : null;
    final deltaFat = (fatA != null && fatB != null) ? (fatB - fatA) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparador de Avaliações'),
        leading: const BackButton(),
        actions: [
          IconButton(
            key: const ValueKey('btn_swap_comparator'),
            tooltip: 'Inverter Marco A e B',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: _swapSelections,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // 1. Card de Seleção dos Marcos A e B
                Material(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: EvaluationSelectorChip(
                                key: const ValueKey('selector_base_a'),
                                label: 'MARCO BASE (A)',
                                dateStr: dateAStr,
                                weightKg: pesoA,
                                isDark: isDark,
                                color: AppColors.indigoPrimary,
                                onTap: () => _selectEvaluation(
                                  context: context,
                                  isBase: true,
                                  evals: evals,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: AppColors.indigoPrimary,
                                ),
                                tooltip: 'Inverter seleção',
                                onPressed: _swapSelections,
                              ),
                            ),
                            Expanded(
                              child: EvaluationSelectorChip(
                                key: const ValueKey('selector_compare_b'),
                                label: 'COMPARAÇÃO (B)',
                                dateStr: dateBStr,
                                weightKg: pesoB,
                                isDark: isDark,
                                color: AppColors.emerald,
                                onTap: () => _selectEvaluation(
                                  context: context,
                                  isBase: false,
                                  evals: evals,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSameDate) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Selecione duas avaliações distintas para comparar a evolução ao longo do tempo.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Banner de Linha do Tempo & Resumo da Jornada
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF334155).withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timelapse_rounded,
                                size: 16,
                                color: AppColors.indigoLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                daysDiff == 0
                                    ? 'Mesmo dia'
                                    : (daysDiff > 0
                                        ? '$daysDiff dias de evolução'
                                        : '${daysDiff.abs()} dias em ordem decrescente'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '$dateAStr ➔ $dateBStr',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SummaryMetricPill(
                              label: 'Peso',
                              value:
                                  '${deltaPeso >= 0 ? "+" : ""}${deltaPeso.toStringAsFixed(1)} kg',
                              subText:
                                  '${pctPeso >= 0 ? "+" : ""}${pctPeso.toStringAsFixed(1)}%',
                              isPositiveGood:
                                  profile.sexo == Sexo.M ? false : false,
                              delta: deltaPeso,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SummaryMetricPill(
                              label: 'Gordura (BF)',
                              value: deltaBf != null
                                  ? '${deltaBf >= 0 ? "+" : ""}${deltaBf.toStringAsFixed(1)}%'
                                  : '--',
                              subText: deltaFat != null
                                  ? '${deltaFat >= 0 ? "+" : ""}${deltaFat.toStringAsFixed(1)}kg'
                                  : null,
                              isPositiveGood: false,
                              delta: deltaBf ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SummaryMetricPill(
                              label: 'Massa Magra',
                              value: deltaLean != null
                                  ? '${deltaLean >= 0 ? "+" : ""}${deltaLean.toStringAsFixed(1)} kg'
                                  : '--',
                              subText: 'Músculo',
                              isPositiveGood: true,
                              delta: deltaLean ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      if (profile.metaPesoKg != null) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF334155), height: 1),
                        const SizedBox(height: 10),
                        Builder(builder: (ctx) {
                          final meta = profile.metaPesoKg!;
                          final distB = (pesoB - meta).abs();
                          final atingiu = (pesoB - meta).abs() <= 0.3;
                          return Row(
                            children: [
                              Icon(
                                atingiu
                                    ? Icons.stars_rounded
                                    : Icons.flag_rounded,
                                size: 15,
                                color: atingiu
                                    ? AppColors.emerald
                                    : AppColors.indigoLight,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  atingiu
                                      ? '🎯 Meta de peso atingida em $dateBStr! (${meta.toStringAsFixed(1)} kg)'
                                      : 'Meta: ${meta.toStringAsFixed(1)} kg • Faltam ${distB.toStringAsFixed(1)} kg para o objetivo',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: atingiu
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Segmented Control de Abas (Métricas vs. Fotos)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabButton(
                          label: 'Métricas & Medidas',
                          icon: Icons.table_chart_rounded,
                          isSelected: _tabIndex == 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _tabIndex = 0);
                          },
                        ),
                      ),
                      Expanded(
                        child: TabButton(
                          label: 'Fotos Lado a Lado',
                          icon: Icons.photo_library_outlined,
                          isSelected: _tabIndex == 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _tabIndex = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Conteúdo da Aba Selecionada
                if (_tabIndex == 0) ...[
                  if (evalA.resultado != null &&
                      evalB.resultado != null) ...[
                    AiInsightCard.comparison(
                      appState: widget.appState,
                      profile: profile,
                      anterior: evalA.avaliacao,
                      resultadoAnt: evalA.resultado,
                      atual: evalB.avaliacao,
                      resultadoAtual: evalB.resultado,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Seção A: Composição Corporal
                  ComparisonSectionCard(
                    title: 'COMPOSIÇÃO CORPORAL',
                    icon: Icons.pie_chart_outline_rounded,
                    isDark: isDark,
                    dateAStr: dateAStr,
                    dateBStr: dateBStr,
                    rows: [
                      ComparisonRowData(
                        label: 'Peso Corporal',
                        valA: '${pesoA.toStringAsFixed(1)} kg',
                        valB: '${pesoB.toStringAsFixed(1)} kg',
                        delta: deltaPeso,
                        deltaFormatted:
                            '${deltaPeso >= 0 ? "+" : ""}${deltaPeso.toStringAsFixed(1)} kg (${pctPeso >= 0 ? "+" : ""}${pctPeso.toStringAsFixed(1)}%)',
                        isPositiveGood: false,
                      ),
                      if (bfA > 0 || bfB > 0)
                        ComparisonRowData(
                          label: 'Percentual de Gordura',
                          valA: bfA > 0 ? '${bfA.toStringAsFixed(1)}%' : '--',
                          valB: bfB > 0 ? '${bfB.toStringAsFixed(1)}%' : '--',
                          delta: deltaBf,
                          deltaFormatted: deltaBf != null
                              ? '${deltaBf >= 0 ? "+" : ""}${deltaBf.toStringAsFixed(1)}%'
                              : null,
                          isPositiveGood: false,
                        ),
                      if (leanA != null || leanB != null)
                        ComparisonRowData(
                          label: 'Massa Magra Estimada',
                          valA: leanA != null
                              ? '${leanA.toStringAsFixed(1)} kg'
                              : '--',
                          valB: leanB != null
                              ? '${leanB.toStringAsFixed(1)} kg'
                              : '--',
                          delta: deltaLean,
                          deltaFormatted: deltaLean != null
                              ? '${deltaLean >= 0 ? "+" : ""}${deltaLean.toStringAsFixed(1)} kg'
                              : null,
                          isPositiveGood: true,
                        ),
                      if (fatA != null || fatB != null)
                        ComparisonRowData(
                          label: 'Massa Gorda Estimada',
                          valA: fatA != null
                              ? '${fatA.toStringAsFixed(1)} kg'
                              : '--',
                          valB: fatB != null
                              ? '${fatB.toStringAsFixed(1)} kg'
                              : '--',
                          delta: deltaFat,
                          deltaFormatted: deltaFat != null
                              ? '${deltaFat >= 0 ? "+" : ""}${deltaFat.toStringAsFixed(1)} kg'
                              : null,
                          isPositiveGood: false,
                        ),
                      ComparisonRowData(
                        label: 'Índice IMC',
                        valA: (evalA.resultado?.snapshot.imc ?? 0.0)
                            .toStringAsFixed(1),
                        valB: (evalB.resultado?.snapshot.imc ?? 0.0)
                            .toStringAsFixed(1),
                        delta: (evalB.resultado?.snapshot.imc ?? 0.0) -
                            (evalA.resultado?.snapshot.imc ?? 0.0),
                        isPositiveGood: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Seção B: Circunferências Corporais (Fita Métrica)
                  ComparisonSectionCard(
                    title: 'CIRCUNFERÊNCIAS CORPORAIS (cm)',
                    icon: Icons.straighten_rounded,
                    isDark: isDark,
                    dateAStr: dateAStr,
                    dateBStr: dateBStr,
                    rows: [
                      _buildCircunferenciaRow(
                        'Cintura',
                        evalA.avaliacao.medidas.cintura,
                        evalB.avaliacao.medidas.cintura,
                        isPositiveGood: false,
                      ),
                      _buildCircunferenciaRow(
                        'Abdômen',
                        evalA.avaliacao.medidas.abdomen,
                        evalB.avaliacao.medidas.abdomen,
                        isPositiveGood: false,
                      ),
                      _buildCircunferenciaRow(
                        'Pescoço',
                        evalA.avaliacao.medidas.pescoco,
                        evalB.avaliacao.medidas.pescoco,
                        isPositiveGood: null,
                      ),
                      _buildCircunferenciaRow(
                        'Quadril',
                        evalA.avaliacao.medidas.quadril,
                        evalB.avaliacao.medidas.quadril,
                        isPositiveGood: null,
                      ),
                      _buildCircunferenciaRow(
                        'Braço',
                        evalA.avaliacao.medidas.braco,
                        evalB.avaliacao.medidas.braco,
                        isPositiveGood: true,
                      ),
                      _buildCircunferenciaRow(
                        'Coxa',
                        evalA.avaliacao.medidas.coxa,
                        evalB.avaliacao.medidas.coxa,
                        isPositiveGood: true,
                      ),
                      _buildCircunferenciaRow(
                        'Panturrilha',
                        evalA.avaliacao.medidas.panturrilha,
                        evalB.avaliacao.medidas.panturrilha,
                        isPositiveGood: true,
                      ),
                    ].whereType<ComparisonRowData>().toList(),
                  ),
                  const SizedBox(height: 16),

                  // Seção: Dobras Cutâneas (Adipômetro em mm)
                  if (_hasAnyDobras(evalA) || _hasAnyDobras(evalB)) ...[
                    ComparisonSectionCard(
                      title: 'DOBRAS CUTÂNEAS (mm)',
                      icon: Icons.straighten_rounded,
                      isDark: isDark,
                      dateAStr: dateAStr,
                      dateBStr: dateBStr,
                      rows: [
                        _buildDobraRow(
                          'Peitoral',
                          evalA.avaliacao.medidas.dobraPeitoral,
                          evalB.avaliacao.medidas.dobraPeitoral,
                        ),
                        _buildDobraRow(
                          'Axilar Média',
                          evalA.avaliacao.medidas.dobraAxilarMedia,
                          evalB.avaliacao.medidas.dobraAxilarMedia,
                        ),
                        _buildDobraRow(
                          'Tríceps',
                          evalA.avaliacao.medidas.dobraTriceps,
                          evalB.avaliacao.medidas.dobraTriceps,
                        ),
                        _buildDobraRow(
                          'Subescapular',
                          evalA.avaliacao.medidas.dobraSubescapular,
                          evalB.avaliacao.medidas.dobraSubescapular,
                        ),
                        _buildDobraRow(
                          'Abdômen',
                          evalA.avaliacao.medidas.dobraAbdomen,
                          evalB.avaliacao.medidas.dobraAbdomen,
                        ),
                        _buildDobraRow(
                          'Suprailíaca',
                          evalA.avaliacao.medidas.dobraSuprailiaca,
                          evalB.avaliacao.medidas.dobraSuprailiaca,
                        ),
                        _buildDobraRow(
                          'Coxa',
                          evalA.avaliacao.medidas.dobraCoxa,
                          evalB.avaliacao.medidas.dobraCoxa,
                        ),
                      ].whereType<ComparisonRowData>().toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Seção C: Risco Metabólico & Saúde
                  ComparisonSectionCard(
                    title: 'ÍNDICES CLÍNICOS E RISCO',
                    icon: Icons.health_and_safety_outlined,
                    isDark: isDark,
                    dateAStr: dateAStr,
                    dateBStr: dateBStr,
                    rows: [
                      _buildCalcRow(
                        'RCQ (Cintura/Quadril)',
                        evalA.resultado?.snapshot.rcq,
                        evalB.resultado?.snapshot.rcq,
                        isPositiveGood: false,
                      ),
                      _buildCalcRow(
                        'RCEst (Cintura/Altura)',
                        evalA.resultado?.snapshot.rcEst,
                        evalB.resultado?.snapshot.rcEst,
                        isPositiveGood: false,
                      ),
                      _buildCalcRow(
                        'BRI (Redondeza Corp.)',
                        evalA.resultado?.snapshot.bri,
                        evalB.resultado?.snapshot.bri,
                        isPositiveGood: false,
                      ),
                      _buildCalcRow(
                        'CI (Conicidade)',
                        evalA.resultado?.snapshot.ci,
                        evalB.resultado?.snapshot.ci,
                        isPositiveGood: false,
                      ),
                    ].whereType<ComparisonRowData>().toList(),
                  ),
                ] else ...[
                  // 5. Comparativo Fotográfico Lado a Lado
                  PhotosComparisonTab(
                    appState: widget.appState,
                    evalA: evalA,
                    evalB: evalB,
                    selectedTipo: _selectedFotoTipo,
                    isDark: isDark,
                    onSelectTipo: (tipo) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFotoTipo = tipo);
                    },
                    onOpenZoom: () {
                      final bytesA = _getPhotoBytes(evalA, _selectedFotoTipo);
                      final bytesB = _getPhotoBytes(evalB, _selectedFotoTipo);
                      _openInteractiveZoom(
                        context,
                        bytesA: bytesA,
                        bytesB: bytesB,
                        labelA: 'Base: $dateAStr',
                        labelB: 'Atual: $dateBStr',
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ComparisonRowData? _buildCircunferenciaRow(
    String label,
    double? a,
    double? b, {
    required bool? isPositiveGood,
  }) {
    if (a == null && b == null) return null;
    final valA = a != null ? '${a.toStringAsFixed(1)} cm' : '--';
    final valB = b != null ? '${b.toStringAsFixed(1)} cm' : '--';
    final delta = (a != null && b != null) ? (b - a) : null;
    return ComparisonRowData(
      label: label,
      valA: valA,
      valB: valB,
      delta: delta,
      deltaFormatted: delta != null
          ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} cm'
          : null,
      isPositiveGood: isPositiveGood,
    );
  }

  ComparisonRowData? _buildCalcRow(
    String label,
    dynamic rawA,
    dynamic rawB, {
    required bool isPositiveGood,
  }) {
    final a = (rawA as num?)?.toDouble() ?? 0.0;
    final b = (rawB as num?)?.toDouble() ?? 0.0;
    if (a <= 0 && b <= 0) return null;
    final delta = (a > 0 && b > 0) ? (b - a) : null;
    return ComparisonRowData(
      label: label,
      valA: a > 0 ? a.toStringAsFixed(2) : '--',
      valB: b > 0 ? b.toStringAsFixed(2) : '--',
      delta: delta,
      deltaFormatted:
          delta != null ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(2)}' : null,
      isPositiveGood: isPositiveGood,
    );
  }

  bool _hasAnyDobras(JoinedEvaluation? ev) {
    if (ev == null) return false;
    final m = ev.avaliacao.medidas;
    return (m.dobraPeitoral != null && m.dobraPeitoral! > 0) ||
        (m.dobraAxilarMedia != null && m.dobraAxilarMedia! > 0) ||
        (m.dobraTriceps != null && m.dobraTriceps! > 0) ||
        (m.dobraSubescapular != null && m.dobraSubescapular! > 0) ||
        (m.dobraAbdomen != null && m.dobraAbdomen! > 0) ||
        (m.dobraSuprailiaca != null && m.dobraSuprailiaca! > 0) ||
        (m.dobraCoxa != null && m.dobraCoxa! > 0);
  }

  ComparisonRowData? _buildDobraRow(String label, double? a, double? b) {
    if ((a == null || a <= 0) && (b == null || b <= 0)) return null;
    final delta = (a != null && a > 0 && b != null && b > 0) ? (b - a) : null;
    return ComparisonRowData(
      label: label,
      valA: (a != null && a > 0) ? '${a.toStringAsFixed(1)} mm' : '--',
      valB: (b != null && b > 0) ? '${b.toStringAsFixed(1)} mm' : '--',
      delta: delta,
      deltaFormatted: delta != null
          ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} mm'
          : null,
      isPositiveGood: false,
    );
  }
}




