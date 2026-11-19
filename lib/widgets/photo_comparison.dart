import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class PhotoComparison extends StatefulWidget {
  final AppState appState;
  final String? selectedAvaliacaoId;
  final VoidCallback? onNewEvaluation;

  const PhotoComparison({
    super.key,
    required this.appState,
    required this.selectedAvaliacaoId,
    this.onNewEvaluation,
  });

  @override
  State<PhotoComparison> createState() => _PhotoComparisonState();
}

class _PhotoComparisonState extends State<PhotoComparison> {
  FotoTipo _view = FotoTipo.frente;
  double _sliderPos = 0.5; // 0.0 to 1.0
  String? _customBeforeId;
  String? _customAfterId;

  void _openFullScreenZoom(
    BuildContext context, {
    required Uint8List? bytesPrimeira,
    required Uint8List? bytesSelecionada,
    required bool temDuasFotos,
    required String titleLabel,
  }) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        double modalSlider = _sliderPos;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                title: Text(
                  titleLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (temDuasFotos)
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
                            ? 'Depois (100%)'
                            : (modalSlider == 1.0 ? 'Antes (100%)' : '50/50'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Fechar tela cheia',
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              body: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Faça movimento de pinça com dois dedos para dar zoom de até 4x',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              if (temDuasFotos &&
                                  bytesPrimeira != null &&
                                  bytesSelecionada != null) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      bytesPrimeira,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                    ClipRect(
                                      clipper:
                                          _RightPortionClipper(modalSlider),
                                      child: Image.memory(
                                        bytesSelecionada,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                    Positioned(
                                      left: (w * modalSlider) - 1,
                                      top: 0,
                                      bottom: 0,
                                      width: 2,
                                      child: Container(color: Colors.white),
                                    ),
                                  ],
                                );
                              }
                              return Image.memory(
                                (bytesSelecionada ?? bytesPrimeira)!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (temDuasFotos)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Row(
                        children: [
                          const Text(
                            '100% Depois',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: modalSlider,
                              activeColor: const Color(0xFF818CF8),
                              inactiveColor: Colors.white24,
                              onChanged: (v) {
                                setModalState(() => modalSlider = v);
                              },
                            ),
                          ),
                          const Text(
                            '100% Antes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

  Widget _buildPhotoCornerBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avaliacoesDesc = widget.appState.avaliacoes;
    final fotos = widget.appState.fotos;
    final colors = context.bioColors;
    final isDark = context.isDarkMode;

    if (avaliacoesDesc.isEmpty) {
      return const SizedBox.shrink();
    }

    if (fotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 24,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Evolução Visual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adicione fotos de frente, perfil ou costas ao registrar avaliações para comparar sua evolução com a cortina antes e depois.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            if (widget.onNewEvaluation != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const ValueKey('btn_photos_empty_add'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onNewEvaluation!();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accent,
                  side: BorderSide(color: colors.accent, width: 1.4),
                  minimumSize: const Size(190, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text(
                  'Registrar com Fotos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // avaliacoes ordenadas por data crescente (primeira = mais antiga)
    final avaliacoesAsc = [...avaliacoesDesc]
      ..sort((a, b) => a.dataAvaliacao.compareTo(b.dataAvaliacao));

    FotoAvaliacao? findFoto(String avId, FotoTipo tipo) {
      for (final f in fotos) {
        if (f.avaliacaoId == avId && f.tipo == tipo) return f;
      }
      return null;
    }

    bool hasAnyPhotoForType(FotoTipo tipo) {
      return fotos.any((f) => f.tipo == tipo);
    }

    int beforeIdx = avaliacoesAsc.indexWhere((a) => a.id == _customBeforeId);
    if (beforeIdx < 0) beforeIdx = 0;

    final targetAfterId = _customAfterId ?? widget.selectedAvaliacaoId;
    int afterIdx = avaliacoesAsc.indexWhere((a) => a.id == targetAfterId);
    if (afterIdx < 0) afterIdx = avaliacoesAsc.length - 1;

    if (avaliacoesAsc.length >= 2 && beforeIdx >= afterIdx) {
      beforeIdx = 0;
      if (afterIdx <= 0) {
        afterIdx = avaliacoesAsc.length - 1;
      }
    }

    final effectiveBeforeAv = avaliacoesAsc[beforeIdx];
    final effectiveAfterAv = avaliacoesAsc[afterIdx];

    final beforeOptions = avaliacoesAsc.length >= 2
        ? avaliacoesAsc.sublist(0, afterIdx)
        : avaliacoesAsc;
    final afterOptions = avaliacoesAsc.length >= 2
        ? avaliacoesAsc.sublist(beforeIdx + 1)
        : avaliacoesAsc;

    final primeiraFoto = findFoto(effectiveBeforeAv.id, _view);
    final selecionadaFoto = findFoto(effectiveAfterAv.id, _view);

    // Usa cache em memória O(1) do AppState (sem decodificar base64 no build!)
    final bytesPrimeira = widget.appState.getDecodedPhotoBytes(primeiraFoto);
    final bytesSelecionada =
        widget.appState.getDecodedPhotoBytes(selecionadaFoto);

    final temFotoNoAngulo = bytesPrimeira != null || bytesSelecionada != null;
    final temDuasFotos = bytesPrimeira != null &&
        bytesSelecionada != null &&
        effectiveBeforeAv.id != effectiveAfterAv.id;

    final dateFmt = DateFormat('dd/MM/yy', 'pt_BR');
    final isDiscreet = widget.appState.discreetPhotos;

    Widget wrapDiscreetBlur(Widget child) {
      if (!isDiscreet) return child;
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: child,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.25),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_off_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Modo Discreto Ativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.appState.toggleDiscreetPhotos();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text(
                    'Toque para revelar',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header limpo (sem texto longo competindo com título)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle.withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Evolução Visual',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (temDuasFotos && !isDiscreet)
                              Text(
                                'Arraste a barra na foto para comparar',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (temFotoNoAngulo && !isDiscreet)
                      IconButton(
                        onPressed: () => _openFullScreenZoom(
                          context,
                          bytesPrimeira: bytesPrimeira,
                          bytesSelecionada: bytesSelecionada,
                          temDuasFotos: temDuasFotos,
                          titleLabel:
                              '${_view.label} • ${dateFmt.format(effectiveBeforeAv.dataAvaliacao)} vs ${dateFmt.format(effectiveAfterAv.dataAvaliacao)}',
                        ),
                        tooltip: 'Tela Cheia com Zoom',
                        icon: Icon(
                          Icons.fullscreen_rounded,
                          size: 22,
                          color: colors.textSecondary,
                        ),
                      ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        widget.appState.toggleDiscreetPhotos();
                      },
                      tooltip: isDiscreet
                          ? 'Revelar Fotos'
                          : 'Modo Discreto (Ocultar Fotos)',
                      icon: Icon(
                        isDiscreet
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_outlined,
                        size: 20,
                        color: isDiscreet ? colors.accent : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tabs Frente | Perfil | Costas responsivas com indicador de foto
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: FotoTipo.values.map((tipo) {
                      final active = _view == tipo;
                      final hasPhoto = hasAnyPhotoForType(tipo);
                      return Semantics(
                        button: true,
                        selected: active,
                        label:
                            '${tipo.label}${hasPhoto ? ", com foto registrada" : ", sem foto"}',
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _view = tipo);
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 44,
                              minWidth: 84,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.indigoPrimary
                                  : colors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasPhoto) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : colors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  tipo.label,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Seletor Antes x Depois sem sobreposição nem inversão cronológica
                if (avaliacoesAsc.length >= 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Seletor ANTES (Esquerda)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FOTO ANTERIOR (ANTES)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: effectiveBeforeAv.id,
                                  isExpanded: true,
                                  items: beforeOptions.map((av) {
                                    return DropdownMenuItem<String>(
                                      value: av.id,
                                      child: Text(
                                        '${dateFmt.format(av.dataAvaliacao)} (${av.pesoKg.toStringAsFixed(1)}kg)',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _customBeforeId = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Seletor DEPOIS (Direita)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'FOTO POSTERIOR (DEPOIS)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: effectiveAfterAv.id,
                                  isExpanded: true,
                                  alignment: AlignmentDirectional.centerEnd,
                                  items: afterOptions.map((av) {
                                    return DropdownMenuItem<String>(
                                      value: av.id,
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Text(
                                        '${dateFmt.format(av.dataAvaliacao)} (${av.pesoKg.toStringAsFixed(1)}kg)',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: colors.accent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _customAfterId = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                if (!temFotoNoAngulo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Nenhuma foto registrada para o ângulo "${_view.label}".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else if (temDuasFotos)
                  // Interactive Before/After Slider (60/120 FPS com cache Uint8List)
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return Semantics(
                          slider: true,
                          label: 'Comparador de fotos antes e depois',
                          value: '${(_sliderPos * 100).round()}%',
                          increasedValue: isDiscreet
                              ? null
                              : '${((_sliderPos + 0.1).clamp(0.0, 1.0) * 100).round()}%',
                          decreasedValue: isDiscreet
                              ? null
                              : '${((_sliderPos - 0.1).clamp(0.0, 1.0) * 100).round()}%',
                          onIncrease: isDiscreet
                              ? null
                              : () => setState(
                                    () => _sliderPos =
                                        (_sliderPos + 0.1).clamp(0.0, 1.0),
                                  ),
                          onDecrease: isDiscreet
                              ? null
                              : () => setState(
                                    () => _sliderPos =
                                        (_sliderPos - 0.1).clamp(0.0, 1.0),
                                  ),
                          child: GestureDetector(
                            onHorizontalDragUpdate: isDiscreet
                                ? null
                                : (details) {
                                    final newPos =
                                        (details.localPosition.dx / width)
                                            .clamp(0.0, 1.0);
                                    if ((_sliderPos < 0.5 && newPos >= 0.5) ||
                                        (_sliderPos > 0.5 && newPos <= 0.5)) {
                                      HapticFeedback.selectionClick();
                                    }
                                    setState(() => _sliderPos = newPos);
                                  },
                            onTapDown: isDiscreet
                                ? null
                                : (details) {
                                    final newPos =
                                        (details.localPosition.dx / width)
                                            .clamp(0.0, 1.0);
                                    HapticFeedback.lightImpact();
                                    setState(() => _sliderPos = newPos);
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: colors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: wrapDiscreetBlur(
                                Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Foto 1 (Base - Antes)
                                    Image.memory(
                                      bytesPrimeira,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),

                                    // Foto 2 (Overlay - Depois, recortada da posição do slider até 100%)
                                    ClipRect(
                                      clipper: _RightPortionClipper(_sliderPos),
                                      child: Image.memory(
                                        bytesSelecionada,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                      ),
                                    ),

                                    // Badges discretos Antes / Depois nos cantos superiores
                                    if (!isDiscreet) ...[
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: _buildPhotoCornerBadge(
                                          'Antes • ${dateFmt.format(effectiveBeforeAv.dataAvaliacao)}',
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: _buildPhotoCornerBadge(
                                          'Depois • ${dateFmt.format(effectiveAfterAv.dataAvaliacao)}',
                                        ),
                                      ),
                                    ],

                                    // Barra divisória e botão central
                                    Positioned(
                                      left: (width * _sliderPos) - 16,
                                      top: 0,
                                      bottom: 0,
                                      width: 32,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 2.5,
                                            color: Colors.white,
                                          ),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.chevron_left_rounded,
                                                  size: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Column(
                    children: [
                      Text(
                        bytesSelecionada != null
                            ? 'FOTO POSTERIOR'
                            : 'FOTO ANTERIOR',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: wrapDiscreetBlur(
                            Image.memory(
                              (bytesSelecionada ?? bytesPrimeira)!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPortionClipper extends CustomClipper<Rect> {
  final double splitFraction;

  _RightPortionClipper(this.splitFraction);

  @override
  Rect getClip(Size size) {
    final startX = size.width * splitFraction;
    return Rect.fromLTRB(startX, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _RightPortionClipper oldClipper) {
    return oldClipper.splitFraction != splitFraction;
  }
}
