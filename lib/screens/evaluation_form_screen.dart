import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../widgets/measurement_guide_modal.dart';
import 'evaluation_form/live_preview_card.dart';
import 'evaluation_form/measure_input_row.dart';
import 'evaluation_form/photo_uploader_slot.dart';
import 'evaluation_form/section_header.dart';
import 'ghost_camera_screen.dart';

class EvaluationFormScreen extends StatefulWidget {
  final AppState appState;
  final Avaliacao? initialAvaliacao;

  const EvaluationFormScreen({
    super.key,
    required this.appState,
    this.initialAvaliacao,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _pesoCtrl = TextEditingController();
  final _pescocoCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _quadrilCtrl = TextEditingController();
  final _abdomenCtrl = TextEditingController();
  final _bracoCtrl = TextEditingController();
  final _coxaCtrl = TextEditingController();
  final _panturrilhaCtrl = TextEditingController();

  // Dobras cutâneas (Adipômetro em mm)
  final _dobraPeitoralCtrl = TextEditingController();
  final _dobraAxilarMediaCtrl = TextEditingController();
  final _dobraTricepsCtrl = TextEditingController();
  final _dobraSubescapularCtrl = TextEditingController();
  final _dobraAbdomenCtrl = TextEditingController();
  final _dobraSuprailiacaCtrl = TextEditingController();
  final _dobraCoxaCtrl = TextEditingController();
  bool _showDobras = false;

  late DateTime _dataAvaliacao;
  double _nivelAtividade = 1.2;
  Objetivo _objetivo = Objetivo.manutencao;

  String? _fotoFrente;
  String? _fotoLado;
  String? _fotoCostas;

  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.initialAvaliacao != null;

  static final Map<double, String> _activityLabels = {
    1.2: 'Sedentário (Pouco/Nenhum)',
    1.375: 'Leve (1-3 dias/sem)',
    1.55: 'Moderado (3-5 dias/sem)',
    1.725: 'Muito (6-7 dias/sem)',
    1.9: 'Extremo (Trabalho físico)',
  };

  Avaliacao? get _previousEvaluation {
    final all = widget.appState.avaliacoes;
    if (all.isEmpty) return null;
    if (_isEditing) {
      final others =
          all.where((a) => a.id != widget.initialAvaliacao!.id).toList();
      return others.firstOrNull;
    }
    return all.first;
  }

  @override
  void initState() {
    super.initState();
    final initAv = widget.initialAvaliacao;
    if (initAv != null) {
      _dataAvaliacao = initAv.dataAvaliacao;
      _nivelAtividade = _activityLabels.containsKey(initAv.nivelAtividade)
          ? initAv.nivelAtividade
          : 1.2;
      _objetivo = initAv.objetivo;
      _pesoCtrl.text = _fmtEdit(initAv.pesoKg);
      _pescocoCtrl.text = _fmtEdit(initAv.medidas.pescoco);
      _cinturaCtrl.text = _fmtEdit(initAv.medidas.cintura);
      _quadrilCtrl.text = _fmtEdit(initAv.medidas.quadril);
      _abdomenCtrl.text = _fmtEdit(initAv.medidas.abdomen);
      _bracoCtrl.text = _fmtEdit(initAv.medidas.braco);
      _coxaCtrl.text = _fmtEdit(initAv.medidas.coxa);
      _panturrilhaCtrl.text = _fmtEdit(initAv.medidas.panturrilha);
      _dobraPeitoralCtrl.text = _fmtEdit(initAv.medidas.dobraPeitoral);
      _dobraAxilarMediaCtrl.text = _fmtEdit(initAv.medidas.dobraAxilarMedia);
      _dobraTricepsCtrl.text = _fmtEdit(initAv.medidas.dobraTriceps);
      _dobraSubescapularCtrl.text = _fmtEdit(initAv.medidas.dobraSubescapular);
      _dobraAbdomenCtrl.text = _fmtEdit(initAv.medidas.dobraAbdomen);
      _dobraSuprailiacaCtrl.text = _fmtEdit(initAv.medidas.dobraSuprailiaca);
      _dobraCoxaCtrl.text = _fmtEdit(initAv.medidas.dobraCoxa);

      if (_dobraPeitoralCtrl.text.isNotEmpty ||
          _dobraAxilarMediaCtrl.text.isNotEmpty ||
          _dobraTricepsCtrl.text.isNotEmpty ||
          _dobraSubescapularCtrl.text.isNotEmpty ||
          _dobraAbdomenCtrl.text.isNotEmpty ||
          _dobraSuprailiacaCtrl.text.isNotEmpty ||
          _dobraCoxaCtrl.text.isNotEmpty) {
        _showDobras = true;
      }

      final fotosExistentes = widget.appState.getFotosForAvaliacao(initAv.id);
      for (final f in fotosExistentes) {
        final ref = (f.filePath != null && f.filePath!.isNotEmpty)
            ? f.filePath
            : f.fotoBase64;
        switch (f.tipo) {
          case FotoTipo.frente:
            _fotoFrente = ref;
            break;
          case FotoTipo.lado:
            _fotoLado = ref;
            break;
          case FotoTipo.costas:
            _fotoCostas = ref;
            break;
        }
      }
    } else {
      _dataAvaliacao = DateTime.now();
      final ultima = widget.appState.avaliacoes.firstOrNull;
      if (ultima != null) {
        _nivelAtividade = _activityLabels.containsKey(ultima.nivelAtividade)
            ? ultima.nivelAtividade
            : 1.2;
        _objetivo = ultima.objetivo;
      }
    }
  }

  String _fmtEdit(double? val) {
    if (val == null || val <= 0) return '';
    return val.truncateToDouble() == val
        ? val.toStringAsFixed(0)
        : val.toStringAsFixed(1);
  }

  String _hintFromPrev(double? prevVal) {
    if (prevVal == null || prevVal <= 0) return '0.0';
    return 'Ant: ${prevVal.toStringAsFixed(1)}';
  }

  void _prefillFromLastEvaluation() {
    final prev = _previousEvaluation;
    if (prev == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_pesoCtrl.text.trim().isEmpty) {
        _pesoCtrl.text = _fmtEdit(prev.pesoKg);
      }
      if (_pescocoCtrl.text.trim().isEmpty && prev.medidas.pescoco != null) {
        _pescocoCtrl.text = _fmtEdit(prev.medidas.pescoco);
      }
      if (_cinturaCtrl.text.trim().isEmpty && prev.medidas.cintura != null) {
        _cinturaCtrl.text = _fmtEdit(prev.medidas.cintura);
      }
      if (_quadrilCtrl.text.trim().isEmpty && prev.medidas.quadril != null) {
        _quadrilCtrl.text = _fmtEdit(prev.medidas.quadril);
      }
      if (_abdomenCtrl.text.trim().isEmpty && prev.medidas.abdomen != null) {
        _abdomenCtrl.text = _fmtEdit(prev.medidas.abdomen);
      }
      if (_bracoCtrl.text.trim().isEmpty && prev.medidas.braco != null) {
        _bracoCtrl.text = _fmtEdit(prev.medidas.braco);
      }
      if (_coxaCtrl.text.trim().isEmpty && prev.medidas.coxa != null) {
        _coxaCtrl.text = _fmtEdit(prev.medidas.coxa);
      }
      if (_panturrilhaCtrl.text.trim().isEmpty &&
          prev.medidas.panturrilha != null) {
        _panturrilhaCtrl.text = _fmtEdit(prev.medidas.panturrilha);
      }
      if (_dobraPeitoralCtrl.text.trim().isEmpty &&
          prev.medidas.dobraPeitoral != null) {
        _dobraPeitoralCtrl.text = _fmtEdit(prev.medidas.dobraPeitoral);
      }
      if (_dobraAxilarMediaCtrl.text.trim().isEmpty &&
          prev.medidas.dobraAxilarMedia != null) {
        _dobraAxilarMediaCtrl.text = _fmtEdit(prev.medidas.dobraAxilarMedia);
      }
      if (_dobraTricepsCtrl.text.trim().isEmpty &&
          prev.medidas.dobraTriceps != null) {
        _dobraTricepsCtrl.text = _fmtEdit(prev.medidas.dobraTriceps);
      }
      if (_dobraSubescapularCtrl.text.trim().isEmpty &&
          prev.medidas.dobraSubescapular != null) {
        _dobraSubescapularCtrl.text = _fmtEdit(prev.medidas.dobraSubescapular);
      }
      if (_dobraAbdomenCtrl.text.trim().isEmpty &&
          prev.medidas.dobraAbdomen != null) {
        _dobraAbdomenCtrl.text = _fmtEdit(prev.medidas.dobraAbdomen);
      }
      if (_dobraSuprailiacaCtrl.text.trim().isEmpty &&
          prev.medidas.dobraSuprailiaca != null) {
        _dobraSuprailiacaCtrl.text = _fmtEdit(prev.medidas.dobraSuprailiaca);
      }
      if (_dobraCoxaCtrl.text.trim().isEmpty &&
          prev.medidas.dobraCoxa != null) {
        _dobraCoxaCtrl.text = _fmtEdit(prev.medidas.dobraCoxa);
      }
    });
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _pescocoCtrl.dispose();
    _cinturaCtrl.dispose();
    _quadrilCtrl.dispose();
    _abdomenCtrl.dispose();
    _bracoCtrl.dispose();
    _coxaCtrl.dispose();
    _panturrilhaCtrl.dispose();
    _dobraPeitoralCtrl.dispose();
    _dobraAxilarMediaCtrl.dispose();
    _dobraTricepsCtrl.dispose();
    _dobraSubescapularCtrl.dispose();
    _dobraAbdomenCtrl.dispose();
    _dobraSuprailiacaCtrl.dispose();
    _dobraCoxaCtrl.dispose();
    super.dispose();
  }

  double? _parseField(TextEditingController ctrl) {
    final text = ctrl.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final val = double.tryParse(text);
    return (val != null && val > 0) ? val : null;
  }

  bool get _hasUnsavedChanges {
    if (_isSubmitting) return false;
    final initAv = widget.initialAvaliacao;
    if (initAv == null) {
      return _pesoCtrl.text.trim().isNotEmpty ||
          _pescocoCtrl.text.trim().isNotEmpty ||
          _cinturaCtrl.text.trim().isNotEmpty ||
          _quadrilCtrl.text.trim().isNotEmpty ||
          _abdomenCtrl.text.trim().isNotEmpty ||
          _bracoCtrl.text.trim().isNotEmpty ||
          _coxaCtrl.text.trim().isNotEmpty ||
          _panturrilhaCtrl.text.trim().isNotEmpty ||
          _dobraPeitoralCtrl.text.trim().isNotEmpty ||
          _dobraAxilarMediaCtrl.text.trim().isNotEmpty ||
          _dobraTricepsCtrl.text.trim().isNotEmpty ||
          _dobraSubescapularCtrl.text.trim().isNotEmpty ||
          _dobraAbdomenCtrl.text.trim().isNotEmpty ||
          _dobraSuprailiacaCtrl.text.trim().isNotEmpty ||
          _dobraCoxaCtrl.text.trim().isNotEmpty ||
          _fotoFrente != null ||
          _fotoLado != null ||
          _fotoCostas != null;
    }
    if (_pesoCtrl.text.trim() != _fmtEdit(initAv.pesoKg)) return true;
    if (_pescocoCtrl.text.trim() != _fmtEdit(initAv.medidas.pescoco)) {
      return true;
    }
    if (_cinturaCtrl.text.trim() != _fmtEdit(initAv.medidas.cintura)) {
      return true;
    }
    if (_quadrilCtrl.text.trim() != _fmtEdit(initAv.medidas.quadril)) {
      return true;
    }
    if (_abdomenCtrl.text.trim() != _fmtEdit(initAv.medidas.abdomen)) {
      return true;
    }
    if (_bracoCtrl.text.trim() != _fmtEdit(initAv.medidas.braco)) {
      return true;
    }
    if (_coxaCtrl.text.trim() != _fmtEdit(initAv.medidas.coxa)) {
      return true;
    }
    if (_panturrilhaCtrl.text.trim() != _fmtEdit(initAv.medidas.panturrilha)) {
      return true;
    }
    if (_dobraPeitoralCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraPeitoral)) {
      return true;
    }
    if (_dobraAxilarMediaCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraAxilarMedia)) {
      return true;
    }
    if (_dobraTricepsCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraTriceps)) {
      return true;
    }
    if (_dobraSubescapularCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraSubescapular)) {
      return true;
    }
    if (_dobraAbdomenCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraAbdomen)) {
      return true;
    }
    if (_dobraSuprailiacaCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraSuprailiaca)) {
      return true;
    }
    if (_dobraCoxaCtrl.text.trim() !=
        _fmtEdit(initAv.medidas.dobraCoxa)) {
      return true;
    }
    if (_dataAvaliacao != initAv.dataAvaliacao) return true;
    if (_nivelAtividade != initAv.nivelAtividade) return true;
    if (_objetivo != initAv.objetivo) return true;
    return false;
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem medições preenchidas. Se sair agora, todas as informações não salvas serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar Editando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.rose,
            ),
            child: const Text('Descartar e Sair'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static String? _validateAnatomicalRange(String label, double? val) {
    if (val == null || val <= 0) return null;
    switch (label) {
      case 'Peso':
        if (val < 30 || val > 300) {
          return 'Valor incomum (${val}kg). Confira a pontuação/vírgula.';
        }
        break;
      case 'Pescoço':
        if (val < 20 || val > 65) {
          return 'Valor incomum (${val}cm). Faixa esperada: 20 a 65cm.';
        }
        break;
      case 'Cintura':
        if (val < 45 || val > 200) {
          return 'Valor incomum (${val}cm). Faixa esperada: 45 a 200cm.';
        }
        break;
      case 'Quadril':
        if (val < 50 || val > 220) {
          return 'Valor incomum (${val}cm). Faixa esperada: 50 a 220cm.';
        }
        break;
      case 'Abdômen':
        if (val < 45 || val > 200) {
          return 'Valor incomum (${val}cm). Faixa esperada: 45 a 200cm.';
        }
        break;
      case 'Braço':
        if (val < 15 || val > 70) {
          return 'Valor incomum (${val}cm). Faixa esperada: 15 a 70cm.';
        }
        break;
      case 'Coxa':
        if (val < 25 || val > 110) {
          return 'Valor incomum (${val}cm). Faixa esperada: 25 a 110cm.';
        }
        break;
      case 'Panturrilha':
        if (val < 20 || val > 70) {
          return 'Valor incomum (${val}cm). Faixa esperada: 20 a 70cm.';
        }
        break;
      case 'Dobra':
        if (val < 2 || val > 70) {
          return 'Valor incomum (${val}mm). Faixa esperada: 2 a 70mm.';
        }
        break;
    }
    return null;
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    final p = _parseField(_pesoCtrl);
    final c = _parseField(_cinturaCtrl);
    return p != null && c != null;
  }

  CalculosSnapshot? _computeLivePreview() {
    final profile = widget.appState.userProfile;
    final peso = _parseField(_pesoCtrl);
    final cintura = _parseField(_cinturaCtrl);
    if (profile == null || peso == null || cintura == null) return null;

    final tempAvaliacao = Avaliacao(
      id: 'preview',
      userId: profile.id,
      dataAvaliacao: _dataAvaliacao,
      pesoKg: peso,
      nivelAtividade: _nivelAtividade,
      objetivo: _objetivo,
      medidas: MedidasCorporais(
        pescoco: _parseField(_pescocoCtrl),
        cintura: cintura,
        quadril: _parseField(_quadrilCtrl),
        abdomen: _parseField(_abdomenCtrl),
        braco: _parseField(_bracoCtrl),
        coxa: _parseField(_coxaCtrl),
        panturrilha: _parseField(_panturrilhaCtrl),
        dobraPeitoral: _parseField(_dobraPeitoralCtrl),
        dobraAxilarMedia: _parseField(_dobraAxilarMediaCtrl),
        dobraTriceps: _parseField(_dobraTricepsCtrl),
        dobraSubescapular: _parseField(_dobraSubescapularCtrl),
        dobraAbdomen: _parseField(_dobraAbdomenCtrl),
        dobraSuprailiaca: _parseField(_dobraSuprailiacaCtrl),
        dobraCoxa: _parseField(_dobraCoxaCtrl),
      ),
    );

    return BioCalculator.buildCalculosSnapshot(
      profile: profile,
      avaliacao: tempAvaliacao,
    );
  }

  Future<void> _selectEvaluationDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataAvaliacao,
      firstDate: DateTime(now.year - 10),
      lastDate: now.add(const Duration(days: 1)),
      helpText: 'Data da Avaliação Física',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _dataAvaliacao = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dataAvaliacao.hour,
          _dataAvaliacao.minute,
        );
      });
    }
  }

  Future<void> _promptPhotoSource(FotoTipo tipo) async {
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Foto de ${tipo.label}'),
        message: const Text('Escolha de onde deseja adicionar sua foto:'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('ghost'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('👻 '),
                Text('Câmera com Foto-Fantasma'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('camera'),
            child: const Text('Câmera Padrão'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('gallery'),
            child: const Text('Escolher da Galeria'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );

    if (choice == 'ghost') {
      Uint8List? previousGhostBytes;
      for (final av in widget.appState.avaliacoes) {
        if (widget.initialAvaliacao != null &&
            av.id == widget.initialAvaliacao!.id) {
          continue;
        }
        final fotos = widget.appState.getFotosForAvaliacao(av.id);
        final f = fotos.where((item) => item.tipo == tipo).firstOrNull;
        if (f != null) {
          previousGhostBytes = widget.appState.getDecodedPhotoBytes(f);
          if (previousGhostBytes != null && previousGhostBytes.isNotEmpty) {
            break;
          }
        }
      }

      if (!mounted) return;
      final path = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => GhostCameraScreen(
            tipo: tipo,
            ghostPhotoBytes: previousGhostBytes,
          ),
        ),
      );
      if (path != null && path.isNotEmpty) {
        setState(() {
          switch (tipo) {
            case FotoTipo.frente:
              _fotoFrente = path;
              break;
            case FotoTipo.lado:
              _fotoLado = path;
              break;
            case FotoTipo.costas:
              _fotoCostas = path;
              break;
          }
        });
      }
    } else if (choice == 'camera') {
      await _pickPhoto(tipo, source: ImageSource.camera);
    } else if (choice == 'gallery') {
      await _pickPhoto(tipo, source: ImageSource.gallery);
    }
  }

  Future<void> _pickPhoto(
    FotoTipo tipo, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        switch (tipo) {
          case FotoTipo.frente:
            _fotoFrente = base64Str;
            break;
          case FotoTipo.lado:
            _fotoLado = base64Str;
            break;
          case FotoTipo.costas:
            _fotoCostas = base64Str;
            break;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar a imagem. Tente outra foto.'),
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final profile = widget.appState.userProfile;
    if (profile == null || !_canSubmit) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      const uuid = Uuid();
      final avaliacaoId = widget.initialAvaliacao?.id ?? uuid.v4();
      final existingResultado =
          widget.appState.getResultadoForAvaliacao(avaliacaoId);

      final novaAvaliacao = Avaliacao(
        id: avaliacaoId,
        userId: profile.id,
        dataAvaliacao: _dataAvaliacao,
        pesoKg: _parseField(_pesoCtrl)!,
        nivelAtividade: _nivelAtividade,
        objetivo: _objetivo,
        medidas: MedidasCorporais(
          pescoco: _parseField(_pescocoCtrl),
          cintura: _parseField(_cinturaCtrl),
          quadril: _parseField(_quadrilCtrl),
          abdomen: _parseField(_abdomenCtrl),
          braco: _parseField(_bracoCtrl),
          coxa: _parseField(_coxaCtrl),
          panturrilha: _parseField(_panturrilhaCtrl),
          dobraPeitoral: _parseField(_dobraPeitoralCtrl),
          dobraAxilarMedia: _parseField(_dobraAxilarMediaCtrl),
          dobraTriceps: _parseField(_dobraTricepsCtrl),
          dobraSubescapular: _parseField(_dobraSubescapularCtrl),
          dobraAbdomen: _parseField(_dobraAbdomenCtrl),
          dobraSuprailiaca: _parseField(_dobraSuprailiacaCtrl),
          dobraCoxa: _parseField(_dobraCoxaCtrl),
        ),
      );

      final calculos = BioCalculator.buildCalculosSnapshot(
        profile: profile,
        avaliacao: novaAvaliacao,
      );

      final novoResultado = Resultados(
        id: existingResultado?.id ?? uuid.v4(),
        avaliacaoId: avaliacaoId,
        calculos: calculos.toJson(),
        calcVersion: 2,
      );

      final novasFotos = <FotoAvaliacao>[];
      if (_fotoFrente != null && _fotoFrente!.isNotEmpty) {
        final isPath = !_fotoFrente!.startsWith('data:') && _fotoFrente!.length < 500;
        novasFotos.add(
          FotoAvaliacao(
            id: uuid.v4(),
            avaliacaoId: avaliacaoId,
            userId: profile.id,
            tipo: FotoTipo.frente,
            filePath: isPath ? _fotoFrente : null,
            fotoBase64: isPath ? '' : _fotoFrente!,
            criadoEm: _dataAvaliacao,
          ),
        );
      }
      if (_fotoLado != null && _fotoLado!.isNotEmpty) {
        final isPath = !_fotoLado!.startsWith('data:') && _fotoLado!.length < 500;
        novasFotos.add(
          FotoAvaliacao(
            id: uuid.v4(),
            avaliacaoId: avaliacaoId,
            userId: profile.id,
            tipo: FotoTipo.lado,
            filePath: isPath ? _fotoLado : null,
            fotoBase64: isPath ? '' : _fotoLado!,
            criadoEm: _dataAvaliacao,
          ),
        );
      }
      if (_fotoCostas != null && _fotoCostas!.isNotEmpty) {
        final isPath = !_fotoCostas!.startsWith('data:') && _fotoCostas!.length < 500;
        novasFotos.add(
          FotoAvaliacao(
            id: uuid.v4(),
            avaliacaoId: avaliacaoId,
            userId: profile.id,
            tipo: FotoTipo.costas,
            filePath: isPath ? _fotoCostas : null,
            fotoBase64: isPath ? '' : _fotoCostas!,
            criadoEm: _dataAvaliacao,
          ),
        );
      }

      if (_isEditing) {
        await widget.appState.updateAvaliacao(
          avaliacao: novaAvaliacao,
          resultado: novoResultado,
          fotosDaAvaliacao: novasFotos,
        );
      } else {
        await widget.appState.addAvaliacao(
          avaliacao: novaAvaliacao,
          resultado: novoResultado,
          novasFotos: novasFotos,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Avaliação atualizada com sucesso!'
                : 'Avaliação salva com sucesso!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(novaAvaliacao.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar avaliação.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.appState.userProfile;
    final prev = _previousEvaluation;
    final livePreview = _computeLivePreview();
    final dateFmt = DateFormat('dd/MM/yyyy');

    int filledMembersCount = 0;
    if (_parseField(_abdomenCtrl) != null) filledMembersCount++;
    if (profile?.sexo == Sexo.M && _parseField(_quadrilCtrl) != null) {
      filledMembersCount++;
    }
    if (_parseField(_bracoCtrl) != null) filledMembersCount++;
    if (_parseField(_coxaCtrl) != null) filledMembersCount++;
    if (_parseField(_panturrilhaCtrl) != null) filledMembersCount++;
    final totalMembersCount = profile?.sexo == Sexo.M ? 5 : 4;

    int filledDobrasCount = 0;
    if (_parseField(_dobraPeitoralCtrl) != null) filledDobrasCount++;
    if (_parseField(_dobraAxilarMediaCtrl) != null) filledDobrasCount++;
    if (_parseField(_dobraTricepsCtrl) != null) filledDobrasCount++;
    if (_parseField(_dobraSubescapularCtrl) != null) filledDobrasCount++;
    if (_parseField(_dobraAbdomenCtrl) != null) filledDobrasCount++;
    if (_parseField(_dobraSuprailiacaCtrl) != null) filledDobrasCount++;
    if (_parseField(_dobraCoxaCtrl) != null) filledDobrasCount++;

    final tempMedidas = MedidasCorporais(
      dobraPeitoral: _parseField(_dobraPeitoralCtrl),
      dobraAxilarMedia: _parseField(_dobraAxilarMediaCtrl),
      dobraTriceps: _parseField(_dobraTricepsCtrl),
      dobraSubescapular: _parseField(_dobraSubescapularCtrl),
      dobraAbdomen: _parseField(_dobraAbdomenCtrl),
      dobraSuprailiaca: _parseField(_dobraSuprailiacaCtrl),
      dobraCoxa: _parseField(_dobraCoxaCtrl),
    );

    final bool isJp7Ready = tempMedidas.hasJacksonPollock7;
    final bool isJp3Ready = profile?.sexo == Sexo.F
        ? tempMedidas.hasJacksonPollock3Female
        : tempMedidas.hasJacksonPollock3Male;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard(context);
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              if (!_hasUnsavedChanges) {
                Navigator.of(context).pop();
                return;
              }
              final shouldDiscard = await _confirmDiscard(context);
              if (shouldDiscard && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Voltar',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.indigoPrimary,
            ),
          ),
          title: Text(
            _isEditing
                ? 'Editar Avaliação'
                : (profile != null
                    ? '${profile.primeiroNome} - Nova Avaliação'
                    : 'Nova Avaliação'),
          ),
        ),
        body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção 0: Ações Rápidas de Apoio
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          const SectionHeader(
                            title: 'MEDIDAS ESSENCIAIS',
                            bottomPadding: 0,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigoPrimary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Composição & Metas',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigoPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (prev != null && !_isEditing)
                        TextButton.icon(
                          onPressed: _prefillFromLastEvaluation,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.indigoPrimary,
                          ),
                          icon: const Icon(Icons.history_rounded, size: 15),
                          label: const Text(
                            'Repetir últimas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Card 1: Medidas Essenciais (Alimenta o motor científico de gordura e metabolismo)
                  Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Seletor de Data da Avaliação
                        InkWell(
                          onTap: () => _selectEvaluationDate(context),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Data da Avaliação',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: AppColors.indigoPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateFmt.format(_dataAvaliacao),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(indent: 16, height: 1),
                        MeasureInputRow(
                          label: 'Peso',
                          controller: _pesoCtrl,
                          unit: 'kg',
                          requiredField: true,
                          hintText: _hintFromPrev(prev?.pesoKg),
                          warningText: _validateAnatomicalRange(
                            'Peso',
                            _parseField(_pesoCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.peso,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        MeasureInputRow(
                          label: 'Pescoço',
                          subtitle: 'Usado no BF% US Navy',
                          controller: _pescocoCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.pescoco),
                          warningText: _validateAnatomicalRange(
                            'Pescoço',
                            _parseField(_pescocoCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.pescoco,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        MeasureInputRow(
                          label: 'Cintura',
                          controller: _cinturaCtrl,
                          unit: 'cm',
                          requiredField: true,
                          hintText: _hintFromPrev(prev?.medidas.cintura),
                          warningText: _validateAnatomicalRange(
                            'Cintura',
                            _parseField(_cinturaCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.cintura,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (profile?.sexo == Sexo.F) ...[
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Quadril',
                            subtitle: 'Necessário no BF% US Navy feminino',
                            controller: _quadrilCtrl,
                            unit: 'cm',
                            hintText: _hintFromPrev(prev?.medidas.quadril),
                            warningText: _validateAnatomicalRange(
                              'Quadril',
                              _parseField(_quadrilCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.quadril,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Seção 1: Membros e Circunferências Periféricas
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const SectionHeader(
                        title: 'MEMBROS E DETALHES',
                        bottomPadding: 0,
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$filledMembersCount de $totalMembersCount preenchidos',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Card 2: Membros e Detalhes Musculares
                  Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        MeasureInputRow(
                          label: 'Abdômen',
                          subtitle: 'Linha da cicatriz umbilical',
                          controller: _abdomenCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.abdomen),
                          warningText: _validateAnatomicalRange(
                            'Abdômen',
                            _parseField(_abdomenCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.abdomen,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (profile?.sexo == Sexo.M) ...[
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Quadril',
                            subtitle: 'Usado no RCQ e BAI',
                            controller: _quadrilCtrl,
                            unit: 'cm',
                            hintText: _hintFromPrev(prev?.medidas.quadril),
                            warningText: _validateAnatomicalRange(
                              'Quadril',
                              _parseField(_quadrilCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.quadril,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                        const Divider(indent: 16, height: 1),
                        MeasureInputRow(
                          label: 'Braço',
                          subtitle: 'Ponto médio do bíceps',
                          controller: _bracoCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.braco),
                          warningText: _validateAnatomicalRange(
                            'Braço',
                            _parseField(_bracoCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.braco,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        MeasureInputRow(
                          label: 'Coxa',
                          subtitle: 'Ponto médio do quadríceps',
                          controller: _coxaCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.coxa),
                          warningText: _validateAnatomicalRange(
                            'Coxa',
                            _parseField(_coxaCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.coxa,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        MeasureInputRow(
                          label: 'Panturrilha',
                          subtitle: 'Maior circunferência',
                          controller: _panturrilhaCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.panturrilha),
                          textInputAction: TextInputAction.done,
                          warningText: _validateAnatomicalRange(
                            'Panturrilha',
                            _parseField(_panturrilhaCtrl),
                          ),
                          onHelpTap: () => MeasurementGuideModal.show(
                            context,
                            MeasurementGuideType.panturrilha,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Seção: Dobras Cutâneas (Adipômetro)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const SectionHeader(
                        title: 'DOBRAS CUTÂNEAS (ADIPÔMETRO)',
                        bottomPadding: 0,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isJp7Ready || isJp3Ready)
                              ? AppColors.emerald.withValues(alpha: 0.12)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isJp7Ready
                              ? '✨ JP 7 Ativo'
                              : (isJp3Ready
                                  ? '✨ JP 3 Ativo'
                                  : '$filledDobrasCount de 7 preenchidas'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: (isJp7Ready || isJp3Ready)
                                ? AppColors.emerald
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showDobras = !_showDobras);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.straighten_rounded,
                                  size: 18,
                                  color: AppColors.indigoPrimary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Protocolos Jackson-Pollock',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile?.sexo == Sexo.F
                                            ? 'JP3: Tríceps, Suprailíaca, Coxa • JP7: Todas'
                                            : 'JP3: Peitoral, Abdômen, Coxa • JP7: Todas',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _showDobras
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showDobras) ...[
                          const Divider(height: 1),
                          MeasureInputRow(
                            label: 'Peitoral',
                            subtitle: profile?.sexo == Sexo.M
                                ? 'Essencial no JP3 masculino'
                                : null,
                            controller: _dobraPeitoralCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraPeitoral),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraPeitoralCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Axilar Média',
                            subtitle: 'Necessária para o JP7',
                            controller: _dobraAxilarMediaCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraAxilarMedia),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraAxilarMediaCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Tríceps',
                            subtitle: profile?.sexo == Sexo.F
                                ? 'Essencial no JP3 feminino'
                                : 'Necessária para o JP7',
                            controller: _dobraTricepsCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraTriceps),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraTricepsCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Subescapular',
                            subtitle: 'Necessária para o JP7',
                            controller: _dobraSubescapularCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraSubescapular),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraSubescapularCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Abdômen',
                            subtitle: profile?.sexo == Sexo.M
                                ? 'Essencial no JP3 masculino'
                                : 'Necessária para o JP7',
                            controller: _dobraAbdomenCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraAbdomen),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraAbdomenCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Suprailíaca',
                            subtitle: profile?.sexo == Sexo.F
                                ? 'Essencial no JP3 feminino'
                                : 'Necessária para o JP7',
                            controller: _dobraSuprailiacaCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraSuprailiaca),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraSuprailiacaCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const Divider(indent: 16, height: 1),
                          MeasureInputRow(
                            label: 'Coxa',
                            subtitle: 'Essencial no JP3 e JP7',
                            controller: _dobraCoxaCtrl,
                            unit: 'mm',
                            hintText:
                                _hintFromPrev(prev?.medidas.dobraCoxa),
                            warningText: _validateAnatomicalRange(
                              'Dobra',
                              _parseField(_dobraCoxaCtrl),
                            ),
                            onHelpTap: () => MeasurementGuideModal.show(
                              context,
                              MeasurementGuideType.dobraCutanea,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Card de Prévia em Tempo Real
                  if (livePreview != null) ...[
                    const SizedBox(height: 16),
                    LivePreviewCard(
                      calculos: livePreview,
                      sexo: profile?.sexo ?? Sexo.M,
                      hasPescoco: _parseField(_pescocoCtrl) != null,
                      hasQuadril: _parseField(_quadrilCtrl) != null,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Seção 2: Metabolismo e Metas
                  const SectionHeader(title: 'METABOLISMO E METAS'),
                  Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Nível de Atividade
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Atividade',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<double>(
                                    value: _nivelAtividade,
                                    isExpanded: true,
                                    alignment: AlignmentDirectional.centerEnd,
                                    items: _activityLabels.entries
                                        .map(
                                          (e) => DropdownMenuItem<double>(
                                            value: e.key,
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: Text(
                                              e.value,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                        .lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _nivelAtividade = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(indent: 16, height: 1),

                        // Objetivo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Objetivo',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Objetivo>(
                                    value: _objetivo,
                                    isExpanded: true,
                                    alignment: AlignmentDirectional.centerEnd,
                                    items: Objetivo.values
                                        .map(
                                          (obj) => DropdownMenuItem<Objetivo>(
                                            value: obj,
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: Text(
                                              obj.label,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                        .lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _objetivo = val);
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
                  ),

                  const SizedBox(height: 24),

                  // Seção 3: Galeria de Fotos (Opcional)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GALERIA DE FOTOS (OPCIONAL)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PhotoUploaderSlot(
                            label: 'Frente',
                            photoBase64: _fotoFrente,
                            onSelect: () => _promptPhotoSource(FotoTipo.frente),
                            onClear: () => setState(() => _fotoFrente = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PhotoUploaderSlot(
                            label: 'Lado',
                            photoBase64: _fotoLado,
                            onSelect: () => _promptPhotoSource(FotoTipo.lado),
                            onClear: () => setState(() => _fotoLado = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PhotoUploaderSlot(
                            label: 'Costas',
                            photoBase64: _fotoCostas,
                            onSelect: () => _promptPhotoSource(FotoTipo.costas),
                            onClear: () => setState(() => _fotoCostas = null),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Botão Calcular Resultados / Salvar Alterações
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _handleSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigoPrimary,
                        disabledBackgroundColor:
                            AppColors.indigoPrimary.withValues(alpha: 0.45),
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? 'Calculando...'
                            : (_isEditing
                                ? 'Salvar Alterações'
                                : 'Calcular Resultados'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
