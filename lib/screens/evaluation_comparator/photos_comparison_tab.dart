import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class PhotosComparisonTab extends StatelessWidget {
  final AppState appState;
  final JoinedEvaluation evalA;
  final JoinedEvaluation evalB;
  final FotoTipo selectedTipo;
  final bool isDark;
  final ValueChanged<FotoTipo> onSelectTipo;
  final VoidCallback onOpenZoom;

  const PhotosComparisonTab({
    super.key,
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
              child: PhotoPreviewCard(
                bytes: bytesA,
                tag: 'Base (A) • $dateAStr',
                subTag: '${evalA.avaliacao.pesoKg.toStringAsFixed(1)} kg',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PhotoPreviewCard(
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

class PhotoPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  final String tag;
  final String subTag;
  final bool isDark;

  const PhotoPreviewCard({
    super.key,
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
