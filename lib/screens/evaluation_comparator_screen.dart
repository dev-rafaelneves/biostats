import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

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
                                  clipper: _FractionalHorizontalClipper(
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
    final navy = (ev.resultado?.calculos['bfNavy'] as num?)?.toDouble() ?? 0.0;
    if (navy > 0) return navy;
    return (ev.resultado?.calculos['bfRfm'] as num?)?.toDouble() ?? 0.0;
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
                              child: _EvaluationSelectorChip(
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
                              child: _EvaluationSelectorChip(
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
                            child: _SummaryMetricPill(
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
                            child: _SummaryMetricPill(
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
                            child: _SummaryMetricPill(
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
                        child: _TabButton(
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
                        child: _TabButton(
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
                  // Seção A: Composição Corporal
                  _ComparisonSectionCard(
                    title: 'COMPOSIÇÃO CORPORAL',
                    icon: Icons.pie_chart_outline_rounded,
                    isDark: isDark,
                    dateAStr: dateAStr,
                    dateBStr: dateBStr,
                    rows: [
                      _ComparisonRowData(
                        label: 'Peso Corporal',
                        valA: '${pesoA.toStringAsFixed(1)} kg',
                        valB: '${pesoB.toStringAsFixed(1)} kg',
                        delta: deltaPeso,
                        deltaFormatted:
                            '${deltaPeso >= 0 ? "+" : ""}${deltaPeso.toStringAsFixed(1)} kg (${pctPeso >= 0 ? "+" : ""}${pctPeso.toStringAsFixed(1)}%)',
                        isPositiveGood: false,
                      ),
                      if (bfA > 0 || bfB > 0)
                        _ComparisonRowData(
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
                        _ComparisonRowData(
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
                        _ComparisonRowData(
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
                      _ComparisonRowData(
                        label: 'Índice IMC',
                        valA: ((evalA.resultado?.calculos['imc'] as num?)
                                    ?.toDouble() ??
                                0.0)
                            .toStringAsFixed(1),
                        valB: ((evalB.resultado?.calculos['imc'] as num?)
                                    ?.toDouble() ??
                                0.0)
                            .toStringAsFixed(1),
                        delta: (((evalB.resultado?.calculos['imc'] as num?)
                                        ?.toDouble() ??
                                    0.0) -
                                ((evalA.resultado?.calculos['imc'] as num?)
                                        ?.toDouble() ??
                                    0.0)),
                        isPositiveGood: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Seção B: Circunferências Corporais (Fita Métrica)
                  _ComparisonSectionCard(
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
                    ].whereType<_ComparisonRowData>().toList(),
                  ),
                  const SizedBox(height: 16),

                  // Seção C: Risco Metabólico & Saúde
                  _ComparisonSectionCard(
                    title: 'ÍNDICES CLÍNICOS E RISCO',
                    icon: Icons.health_and_safety_outlined,
                    isDark: isDark,
                    dateAStr: dateAStr,
                    dateBStr: dateBStr,
                    rows: [
                      _buildCalcRow(
                        'RCQ (Cintura/Quadril)',
                        evalA.resultado?.calculos['rcq'],
                        evalB.resultado?.calculos['rcq'],
                        isPositiveGood: false,
                      ),
                      _buildCalcRow(
                        'RCEst (Cintura/Altura)',
                        evalA.resultado?.calculos['rcEst'],
                        evalB.resultado?.calculos['rcEst'],
                        isPositiveGood: false,
                      ),
                      _buildCalcRow(
                        'BRI (Redondeza Corp.)',
                        evalA.resultado?.calculos['bri'],
                        evalB.resultado?.calculos['bri'],
                        isPositiveGood: false,
                      ),
                      _buildCalcRow(
                        'CI (Conicidade)',
                        evalA.resultado?.calculos['ci'],
                        evalB.resultado?.calculos['ci'],
                        isPositiveGood: false,
                      ),
                    ].whereType<_ComparisonRowData>().toList(),
                  ),
                ] else ...[
                  // 5. Comparativo Fotográfico Lado a Lado
                  _PhotosComparisonTab(
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

  _ComparisonRowData? _buildCircunferenciaRow(
    String label,
    double? a,
    double? b, {
    required bool? isPositiveGood,
  }) {
    if (a == null && b == null) return null;
    final valA = a != null ? '${a.toStringAsFixed(1)} cm' : '--';
    final valB = b != null ? '${b.toStringAsFixed(1)} cm' : '--';
    final delta = (a != null && b != null) ? (b - a) : null;
    return _ComparisonRowData(
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

  _ComparisonRowData? _buildCalcRow(
    String label,
    dynamic rawA,
    dynamic rawB, {
    required bool isPositiveGood,
  }) {
    final a = (rawA as num?)?.toDouble() ?? 0.0;
    final b = (rawB as num?)?.toDouble() ?? 0.0;
    if (a <= 0 && b <= 0) return null;
    final delta = (a > 0 && b > 0) ? (b - a) : null;
    return _ComparisonRowData(
      label: label,
      valA: a > 0 ? a.toStringAsFixed(2) : '--',
      valB: b > 0 ? b.toStringAsFixed(2) : '--',
      delta: delta,
      deltaFormatted:
          delta != null ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(2)}' : null,
      isPositiveGood: isPositiveGood,
    );
  }
}

// ==========================================
// Subcomponentes Auxiliares
// ==========================================

class _EvaluationSelectorChip extends StatelessWidget {
  final String label;
  final String dateStr;
  final double weightKg;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _EvaluationSelectorChip({
    super.key,
    required this.label,
    required this.dateStr,
    required this.weightKg,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: color,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              '${weightKg.toStringAsFixed(1)} kg',
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
    );
  }
}

class _SummaryMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String? subText;
  final bool isPositiveGood;
  final double delta;

  const _SummaryMetricPill({
    required this.label,
    required this.value,
    this.subText,
    required this.isPositiveGood,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = delta.abs() < 0.01;
    final isGood = isZero ? null : (isPositiveGood ? delta > 0 : delta < 0);
    final color = isZero
        ? Colors.white70
        : (isGood == true
            ? const Color(0xFF34D399) // emerald-400
            : const Color(0xFFFB7185)); // rose-400

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subText != null)
            Text(
              subText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.indigoLight : AppColors.indigoPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRowData {
  final String label;
  final String valA;
  final String valB;
  final double? delta;
  final String? deltaFormatted;
  final bool? isPositiveGood;

  _ComparisonRowData({
    required this.label,
    required this.valA,
    required this.valB,
    this.delta,
    this.deltaFormatted,
    this.isPositiveGood,
  });
}

class _ComparisonSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final String dateAStr;
  final String dateBStr;
  final List<_ComparisonRowData> rows;

  const _ComparisonSectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.dateAStr,
    required this.dateBStr,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.indigoPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? AppColors.indigoLight
                          : AppColors.indigoPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Métrica',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    dateAStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    dateBStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Evolução',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 14),
            itemBuilder: (ctx, idx) {
              final r = rows[idx];
              final delta = r.delta;
              final isZero = delta == null || delta.abs() < 0.001;
              final isGood = isZero || r.isPositiveGood == null
                  ? null
                  : (r.isPositiveGood! ? delta > 0 : delta < 0);

              final Color deltaColor;
              if (isZero || isGood == null) {
                deltaColor = isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B);
              } else if (isGood) {
                deltaColor = AppColors.emerald;
              } else {
                deltaColor = AppColors.rose;
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.valA,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.valB,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        r.deltaFormatted ??
                            (delta != null
                                ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}'
                                : '--'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhotosComparisonTab extends StatelessWidget {
  final AppState appState;
  final JoinedEvaluation evalA;
  final JoinedEvaluation evalB;
  final FotoTipo selectedTipo;
  final bool isDark;
  final ValueChanged<FotoTipo> onSelectTipo;
  final VoidCallback onOpenZoom;

  const _PhotosComparisonTab({
    required this.appState,
    required this.evalA,
    required this.evalB,
    required this.selectedTipo,
    required this.isDark,
    required this.onSelectTipo,
    required this.onOpenZoom,
  });

  Uint8List? _getPhoto(JoinedEvaluation ev) {
    final photos = appState.getFotosForAvaliacao(ev.avaliacao.id);
    for (final p in photos) {
      if (p.tipo == selectedTipo) {
        return appState.getDecodedPhotoBytes(p);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateAStr = dateFmt.format(evalA.avaliacao.dataAvaliacao);
    final dateBStr = dateFmt.format(evalB.avaliacao.dataAvaliacao);

    final bytesA = _getPhoto(evalA);
    final bytesB = _getPhoto(evalB);
    final hasBoth = bytesA != null && bytesB != null;

    return Column(
      children: [
        // Seletor de Ângulo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: FotoTipo.values.map((tipo) {
              final isSel = tipo == selectedTipo;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tipo.label),
                  selected: isSel,
                  showCheckmark: false,
                  selectedColor: AppColors.indigoPrimary,
                  backgroundColor:
                      isDark ? AppColors.darkSurface : Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSel
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B)),
                  ),
                  onSelected: (_) => onSelectTipo(tipo),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Comparação Lado a Lado
        Row(
          children: [
            Expanded(
              child: _PhotoPreviewCard(
                bytes: bytesA,
                tag: 'Base (A) • $dateAStr',
                subTag: '${evalA.avaliacao.pesoKg.toStringAsFixed(1)} kg',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PhotoPreviewCard(
                bytes: bytesB,
                tag: 'Atual (B) • $dateBStr',
                subTag: '${evalB.avaliacao.pesoKg.toStringAsFixed(1)} kg',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Botão para Modo Tela Cheia / Slider
        ElevatedButton.icon(
          key: const ValueKey('btn_open_zoom_comparator'),
          onPressed: onOpenZoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.indigoPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.fullscreen_rounded, size: 20),
          label: Text(
            hasBoth
                ? 'Abrir Slider Antes/Depois & Zoom 4x'
                : 'Visualizar em Tela Cheia',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PhotoPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  final String tag;
  final String subTag;
  final bool isDark;

  const _PhotoPreviewCard({
    required this.bytes,
    required this.tag,
    required this.subTag,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subTag,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: bytes != null
                ? Image.memory(
                    bytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : Container(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.no_photography_outlined,
                            size: 28,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sem foto',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FractionalHorizontalClipper extends CustomClipper<Rect> {
  final double fraction;

  _FractionalHorizontalClipper({required this.fraction});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_FractionalHorizontalClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}
