import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_theme.dart';

class GhostCameraScreen extends StatefulWidget {
  final FotoTipo tipo;
  final Uint8List? ghostPhotoBytes;

  const GhostCameraScreen({
    super.key,
    required this.tipo,
    this.ghostPhotoBytes,
  });

  @override
  State<GhostCameraScreen> createState() => _GhostCameraScreenState();
}

class _GhostCameraScreenState extends State<GhostCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  // Foto-Fantasma Overlay
  bool _showGhostOverlay = true;
  double _ghostOpacity = 0.30;
  bool _showAlignmentGrid = true;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Preferência para câmera traseira
        final backCamIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backCamIdx >= 0 ? backCamIdx : 0;
        await _initCameraController(_cameras[_selectedCameraIndex]);
      } else {
        setState(() => _isCameraInitialized = false);
      }
    } catch (e) {
      debugPrint('Erro ao listar câmeras: $e');
      setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final prev = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await prev?.dispose();

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _controller = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao inicializar câmera: $e');
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  Future<void> _toggleCameraLens() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    HapticFeedback.selectionClick();
    FlashMode next;
    switch (_flashMode) {
      case FlashMode.off:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
        next = FlashMode.always;
        break;
      case FlashMode.always:
      default:
        next = FlashMode.off;
        break;
    }
    try {
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    HapticFeedback.heavyImpact();

    try {
      final XFile rawFile = await _controller!.takePicture();
      final bytes = await rawFile.readAsBytes();

      // Salva imagem física no diretório do app
      final photoId = const Uuid().v4();
      final savedPath =
          await PhotoStorageService.savePhotoBytes(photoId, bytes);

      // Limpa arquivo temporário da câmera
      try {
        final tmp = File(rawFile.path);
        if (tmp.existsSync()) tmp.deleteSync();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop(savedPath);
      }
    } catch (e) {
      debugPrint('Erro ao capturar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao capturar foto. Tente novamente.'),
          ),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGalleryFallback() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 75,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      final photoId = const Uuid().v4();
      final savedPath =
          await PhotoStorageService.savePhotoBytes(photoId, bytes);
      if (mounted) {
        Navigator.of(context).pop(savedPath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isCameraInitialized && _controller != null
            ? _buildCameraView()
            : _buildFallbackView(),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Preview da Câmera
        Center(child: CameraPreview(_controller!)),

        // 2. Sobreposição Foto-Fantasma (Ghost Overlay da avaliação anterior)
        if (widget.ghostPhotoBytes != null &&
            widget.ghostPhotoBytes!.isNotEmpty &&
            _showGhostOverlay)
          Center(
            child: Opacity(
              opacity: _ghostOpacity,
              child: Image.memory(
                widget.ghostPhotoBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),

        // 3. Grade Guia de Alinhamento e Eixo Central
        if (_showAlignmentGrid) _buildAlignmentGrid(),

        // 4. Barra Superior (Controles rápidos e tipo da foto)
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Foto de ${widget.tipo.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _flashMode == FlashMode.always
                          ? Icons.flash_on_rounded
                          : (_flashMode == FlashMode.auto
                              ? Icons.flash_auto_rounded
                              : Icons.flash_off_rounded),
                      color: _flashMode == FlashMode.off
                          ? Colors.white70
                          : const Color(0xFFFBBF24),
                    ),
                  ),
                  if (_cameras.length > 1)
                    IconButton(
                      onPressed: _toggleCameraLens,
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 5. Painel Inferior de Controles e Foto-Fantasma
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Controles do Ghost Overlay (se houver foto anterior)
              if (widget.ghostPhotoBytes != null &&
                  widget.ghostPhotoBytes!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                              () => _showGhostOverlay = !_showGhostOverlay);
                        },
                        child: Row(
                          children: [
                            Icon(
                              _showGhostOverlay
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 18,
                              color: _showGhostOverlay
                                  ? AppColors.indigoLight
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Fantasma',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _showGhostOverlay
                                    ? AppColors.indigoLight
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            activeTrackColor: AppColors.indigoLight,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _ghostOpacity,
                            min: 0.1,
                            max: 0.7,
                            onChanged: _showGhostOverlay
                                ? (val) => setState(() => _ghostOpacity = val)
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '${(_ghostOpacity * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Botões de Ação: Galeria + Botão Disparador + Grade Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botão Galeria
                  IconButton(
                    onPressed: _pickFromGalleryFallback,
                    tooltip: 'Escolher da Galeria',
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // Botão Disparador (Shutter)
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isCapturing
                            ? Colors.grey
                            : AppColors.indigoPrimary,
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                    ),
                  ),

                  // Botão Grade de Alinhamento
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(
                          () => _showAlignmentGrid = !_showAlignmentGrid);
                    },
                    tooltip: 'Alternar Grade de Alinhamento',
                    icon: Icon(
                      _showAlignmentGrid
                          ? Icons.grid_on_rounded
                          : Icons.grid_off_rounded,
                      color: _showAlignmentGrid ? AppColors.indigoLight : Colors.white60,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentGrid() {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: CameraAlignmentGridPainter(),
      ),
    );
  }

  Widget _buildFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Câmera Indisponível',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Não foi possível inicializar a câmera do dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFromGalleryFallback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Escolher da Galeria'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Voltar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraAlignmentGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    final centerPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.45)
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Regra dos Terços (Verticais e Horizontais)
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), linePaint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), linePaint);

    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), linePaint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), linePaint);

    // Linha Central Vertical do Corpo (Simetria)
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
