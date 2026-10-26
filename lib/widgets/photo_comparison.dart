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

  const PhotoComparison({
    super.key,
    required this.appState,
    required this.selectedAvaliacaoId,
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
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        children: [
                          const Text(
                            'DEPOIS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: modalSlider,
                              activeColor: AppColors.indigoLight,
                              inactiveColor: Colors.white24,
                              onChanged: (v) {
                                setModalState(() => modalSlider = v);
                              },
                            ),
                          ),
                          const Text(
                            'ANTES',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final avaliacoesDesc = widget.appState.avaliacoes;
    final fotos = widget.appState.fotos;

    if (avaliacoesDesc.isEmpty ||
        fotos.isEmpty ||
        widget.selectedAvaliacaoId == null) {
      return const SizedBox.shrink();
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

    final defaultBeforeAv = avaliacoesAsc.first;
    final defaultAfterAv = avaliacoesAsc.firstWhere(
      (a) => a.id == widget.selectedAvaliacaoId,
      orElse: () => avaliacoesAsc.last,
    );

    final effectiveBeforeAv = avaliacoesAsc.firstWhere(
      (a) => a.id == _customBeforeId,
      orElse: () => defaultBeforeAv,
    );
    final effectiveAfterAv = avaliacoesAsc.firstWhere(
      (a) => a.id == (_customAfterId ?? widget.selectedAvaliacaoId),
      orElse: () => defaultAfterAv,
    );

    // Verifica se existe alguma foto em qualquer ângulo
    final hasAnyPhotoInAnyAngle = fotos.isNotEmpty;
    if (!hasAnyPhotoInAnyAngle) return const SizedBox.shrink();

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                ),
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
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Evolução Visual',
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
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (temDuasFotos && !isDiscreet) ...[
                      Icon(
                        Icons.compare_rounded,
                        size: 15,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DESLIZE PARA COMPARAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.fullscreen_rounded,
                          size: 21,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF64748B),
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
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isDiscreet
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_outlined,
                        size: 19,
                        color: isDiscreet
                            ? AppColors.indigoPrimary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF64748B)),
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
                // Tabs Frente | Perfil | Costas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: FotoTipo.values.map((tipo) {
                    final active = _view == tipo;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _view = tipo);
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 40,
                            minWidth: 82,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.indigoPrimary
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            tipo.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Seletor Livre Antes x Depois (quando houver >= 2 avaliações)
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
                              '1ª AVALIAÇÃO (ANTES)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: effectiveBeforeAv.id,
                                isDense: true,
                                items: avaliacoesAsc.map((av) {
                                  return DropdownMenuItem<String>(
                                    value: av.id,
                                    child: Text(
                                      '${dateFmt.format(av.dataAvaliacao)} (${av.pesoKg.toStringAsFixed(1)}kg)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : const Color(0xFF334155),
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
                              'ATUAL (DEPOIS)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark
                                    ? AppColors.indigoLight
                                    : AppColors.indigoPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: effectiveAfterAv.id,
                                isDense: true,
                                alignment: AlignmentDirectional.centerEnd,
                                items: avaliacoesAsc.map((av) {
                                  return DropdownMenuItem<String>(
                                    value: av.id,
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Text(
                                      '${dateFmt.format(av.dataAvaliacao)} (${av.pesoKg.toStringAsFixed(1)}kg)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.indigoLight
                                            : AppColors.indigoPrimary,
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
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Nenhuma foto registrada para o ângulo "${_view.label}".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B),
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
                        return GestureDetector(
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
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E8F0),
                              ),
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
                        );
                      },
                    ),
                  )
                else
                  Column(
                    children: [
                      Text(
                        bytesSelecionada != null
                            ? 'FOTO ATUAL'
                            : 'PRIMEIRA FOTO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E8F0),
                            ),
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
