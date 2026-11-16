import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PhotoUploaderSlot extends StatefulWidget {
  final String label;
  final String? photoBase64;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const PhotoUploaderSlot({
    super.key,
    required this.label,
    required this.photoBase64,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<PhotoUploaderSlot> createState() => _PhotoUploaderSlotState();
}

class _PhotoUploaderSlotState extends State<PhotoUploaderSlot> {
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _cachedBytes = _decodePhoto(widget.photoBase64);
  }

  @override
  void didUpdateWidget(covariant PhotoUploaderSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoBase64 != widget.photoBase64) {
      _cachedBytes = _decodePhoto(widget.photoBase64);
    }
  }

  Uint8List? _decodePhoto(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      if (!kIsWeb && !raw.startsWith('data:') && raw.length < 500) {
        final file = File(raw);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
      }
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;
    final bytes = _cachedBytes;

    return Semantics(
      button: true,
      label: bytes != null
          ? 'Foto ${widget.label} selecionada. Toque para remover.'
          : 'Adicionar foto de ${widget.label}',
      child: Column(
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: InkWell(
              onTap: bytes != null ? widget.onClear : widget.onSelect,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.border,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: bytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            cacheWidth: 360,
                            gaplessPlayback: true,
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 26,
                          color: colors.textMuted,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
