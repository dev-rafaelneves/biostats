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

      final fotosExistentes = widget.appState.getFotosForAvaliacao(initAv.id);
      for (final f in fotosExistentes) {
        switch (f.tipo) {
          case FotoTipo.frente:
            _fotoFrente = f.fotoBase64;
            break;
          case FotoTipo.lado:
            _fotoLado = f.fotoBase64;
            break;
          case FotoTipo.costas:
            _fotoCostas = f.fotoBase64;
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
    }
    return null;
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    final p = _parseField(_pesoCtrl);
    final c = _parseField(_cinturaCtrl);
    return p != null && c != null;
  }

  Map<String, dynamic>? _computeLivePreview() {
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

  void _showMeasurementGuide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const guides = [
      (
        'Pescoço',
        'Meça logo abaixo da laringe (pomo de Adão), mantendo a fita levemente inclinada para baixo na parte frontal e os ombros relaxados.'
      ),
      (
        'Cintura',
        'Meça no ponto mais estreito do tronco (geralmente 2 cm acima do umbigo), ao final de uma expiração normal, sem encolher a barriga.'
      ),
      (
        'Abdômen',
        'Meça exatamente na linha horizontal sobre a cicatriz umbilical (umbigo), mantendo o abdômen relaxado.'
      ),
      (
        'Quadril',
        'Meça na circunferência de maior volume dos glúteos, mantendo os pés juntos e a fita perfeitamente paralela ao chão.'
      ),
      (
        'Braço',
        'Meça no ponto médio entre o ombro (acrômio) e o cotovelo, mantendo o braço relaxado ao lado do corpo (ou contraído, desde que siga sempre o mesmo padrão).'
      ),
      (
        'Coxa',
        'Meça no ponto médio entre a linha inguinal (virilha) e a borda superior da patela (joelho), em pé com o peso distribuído igualmente.'
      ),
      (
        'Panturrilha',
        'Meça no ponto de maior circunferência da batata da perna, mantendo os calcanhares apoiados no chão.'
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      color: AppColors.indigoPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Guia Anatômico de Medição',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Meça sempre nas mesmas condições (preferencialmente pela manhã em jejum) para máxima precisão científica.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: guides.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.indigoPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF475569),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${item.$1}: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      TextSpan(text: item.$2),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigoPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Entendi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptPhotoSource(FotoTipo tipo) async {
    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Foto de ${tipo.label}'),
        message: const Text('Escolha de onde deseja adicionar sua foto:'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
            child: const Text('Tirar Foto com a Câmera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
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

    if (source != null) {
      await _pickPhoto(tipo, source: source);
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
        ),
      );

      final calculos = BioCalculator.buildCalculosSnapshot(
        profile: profile,
        avaliacao: novaAvaliacao,
      );

      final novoResultado = Resultados(
        id: existingResultado?.id ?? uuid.v4(),
        avaliacaoId: avaliacaoId,
        calculos: calculos,
      );

      final novasFotos = <FotoAvaliacao>[];
      if (_fotoFrente != null) {
        novasFotos.add(
          FotoAvaliacao(
            id: uuid.v4(),
            avaliacaoId: avaliacaoId,
            userId: profile.id,
            tipo: FotoTipo.frente,
            fotoBase64: _fotoFrente!,
            criadoEm: _dataAvaliacao,
          ),
        );
      }
      if (_fotoLado != null) {
        novasFotos.add(
          FotoAvaliacao(
            id: uuid.v4(),
            avaliacaoId: avaliacaoId,
            userId: profile.id,
            tipo: FotoTipo.lado,
            fotoBase64: _fotoLado!,
            criadoEm: _dataAvaliacao,
          ),
        );
      }
      if (_fotoCostas != null) {
        novasFotos.add(
          FotoAvaliacao(
            id: uuid.v4(),
            avaliacaoId: avaliacaoId,
            userId: profile.id,
            tipo: FotoTipo.costas,
            fotoBase64: _fotoCostas!,
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
          actions: [
            IconButton(
              onPressed: () => _showMeasurementGuide(context),
              tooltip: 'Como medir com a fita?',
              icon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.indigoPrimary,
              ),
            ),
          ],
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
                          const _SectionHeader(
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
                      Wrap(
                        spacing: 4,
                        children: [
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
                          TextButton.icon(
                            onPressed: () => _showMeasurementGuide(context),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF64748B),
                            ),
                            icon: const Icon(
                              Icons.straighten_rounded,
                              size: 15,
                            ),
                            label: const Text(
                              'Como medir?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                        _MeasureInputRow(
                          label: 'Peso',
                          controller: _pesoCtrl,
                          unit: 'kg',
                          requiredField: true,
                          hintText: _hintFromPrev(prev?.pesoKg),
                          warningText: _validateAnatomicalRange(
                            'Peso',
                            _parseField(_pesoCtrl),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        _MeasureInputRow(
                          label: 'Pescoço',
                          subtitle: 'Usado no BF% US Navy',
                          controller: _pescocoCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.pescoco),
                          warningText: _validateAnatomicalRange(
                            'Pescoço',
                            _parseField(_pescocoCtrl),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        _MeasureInputRow(
                          label: 'Cintura',
                          controller: _cinturaCtrl,
                          unit: 'cm',
                          requiredField: true,
                          hintText: _hintFromPrev(prev?.medidas.cintura),
                          warningText: _validateAnatomicalRange(
                            'Cintura',
                            _parseField(_cinturaCtrl),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (profile?.sexo == Sexo.F) ...[
                          const Divider(indent: 16, height: 1),
                          _MeasureInputRow(
                            label: 'Quadril',
                            subtitle: 'Necessário no BF% US Navy feminino',
                            controller: _quadrilCtrl,
                            unit: 'cm',
                            hintText: _hintFromPrev(prev?.medidas.quadril),
                            warningText: _validateAnatomicalRange(
                              'Quadril',
                              _parseField(_quadrilCtrl),
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
                      const _SectionHeader(
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
                        _MeasureInputRow(
                          label: 'Abdômen',
                          subtitle: 'Linha da cicatriz umbilical',
                          controller: _abdomenCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.abdomen),
                          warningText: _validateAnatomicalRange(
                            'Abdômen',
                            _parseField(_abdomenCtrl),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (profile?.sexo == Sexo.M) ...[
                          const Divider(indent: 16, height: 1),
                          _MeasureInputRow(
                            label: 'Quadril',
                            subtitle: 'Usado no RCQ e BAI',
                            controller: _quadrilCtrl,
                            unit: 'cm',
                            hintText: _hintFromPrev(prev?.medidas.quadril),
                            warningText: _validateAnatomicalRange(
                              'Quadril',
                              _parseField(_quadrilCtrl),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                        const Divider(indent: 16, height: 1),
                        _MeasureInputRow(
                          label: 'Braço',
                          subtitle: 'Ponto médio do bíceps',
                          controller: _bracoCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.braco),
                          warningText: _validateAnatomicalRange(
                            'Braço',
                            _parseField(_bracoCtrl),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        _MeasureInputRow(
                          label: 'Coxa',
                          subtitle: 'Ponto médio do quadríceps',
                          controller: _coxaCtrl,
                          unit: 'cm',
                          hintText: _hintFromPrev(prev?.medidas.coxa),
                          warningText: _validateAnatomicalRange(
                            'Coxa',
                            _parseField(_coxaCtrl),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const Divider(indent: 16, height: 1),
                        _MeasureInputRow(
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  // Card de Prévia em Tempo Real
                  if (livePreview != null) ...[
                    const SizedBox(height: 16),
                    _LivePreviewCard(
                      calculos: livePreview,
                      sexo: profile?.sexo ?? Sexo.M,
                      hasPescoco: _parseField(_pescocoCtrl) != null,
                      hasQuadril: _parseField(_quadrilCtrl) != null,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Seção 2: Metabolismo e Metas
                  const _SectionHeader(title: 'METABOLISMO E METAS'),
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
                          child: _PhotoUploaderSlot(
                            label: 'Frente',
                            photoBase64: _fotoFrente,
                            onSelect: () => _promptPhotoSource(FotoTipo.frente),
                            onClear: () => setState(() => _fotoFrente = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PhotoUploaderSlot(
                            label: 'Lado',
                            photoBase64: _fotoLado,
                            onSelect: () => _promptPhotoSource(FotoTipo.lado),
                            onClear: () => setState(() => _fotoLado = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PhotoUploaderSlot(
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

class _LivePreviewCard extends StatelessWidget {
  final Map<String, dynamic> calculos;
  final Sexo sexo;
  final bool hasPescoco;
  final bool hasQuadril;

  const _LivePreviewCard({
    required this.calculos,
    required this.sexo,
    required this.hasPescoco,
    required this.hasQuadril,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imc = (calculos['imc'] as num?)?.toDouble() ?? 0.0;
    final bfNavy = (calculos['bfNavy'] as num?)?.toDouble() ?? 0.0;
    final bfRfm = (calculos['bfRfm'] as num?)?.toDouble() ?? 0.0;
    final lbmBoer = (calculos['lbmBoer'] as num?)?.toDouble() ?? 0.0;
    final metaKcal = (calculos['metaCalorica'] as num?)?.toDouble() ?? 0.0;

    final missingNavyField =
        !hasPescoco || (sexo == Sexo.F && !hasQuadril);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indigoPrimary.withValues(alpha: isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.indigoPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 16,
                color: AppColors.indigoPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'PRÉVIA EM TEMPO REAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark
                      ? AppColors.indigoLight
                      : AppColors.indigoPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _PreviewMetric(
                label: 'IMC',
                value: imc > 0 ? imc.toStringAsFixed(1) : '--',
              ),
              _PreviewMetric(
                label: 'BF% (Navy)',
                value: bfNavy > 0 ? '${bfNavy.toStringAsFixed(1)}%' : '--',
              ),
              _PreviewMetric(
                label: 'BF% (RFM)',
                value: bfRfm > 0 ? '${bfRfm.toStringAsFixed(1)}%' : '--',
              ),
              _PreviewMetric(
                label: 'Massa Magra',
                value: lbmBoer > 0 ? '${lbmBoer.toStringAsFixed(1)}kg' : '--',
              ),
              _PreviewMetric(
                label: 'Meta',
                value: metaKcal > 0 ? '${metaKcal.toStringAsFixed(0)}kcal' : '--',
              ),
            ],
          ),
          if (missingNavyField) ...[
            const SizedBox(height: 8),
            Text(
              sexo == Sexo.F
                  ? '💡 Dica: Preencha Pescoço e Quadril para calcular também o % de Gordura US Navy.'
                  : '💡 Dica: Preencha o Pescoço para calcular também o % de Gordura US Navy.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.darkTextPrimary
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double bottomPadding;

  const _SectionHeader({
    required this.title,
    this.bottomPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(left: 14, bottom: bottomPadding),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _MeasureInputRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? warningText;
  final TextEditingController controller;
  final String unit;
  final bool requiredField;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;

  const _MeasureInputRow({
    required this.label,
    this.subtitle,
    this.warningText,
    required this.controller,
    required this.unit,
    this.requiredField = false,
    this.hintText = '0.0',
    this.textInputAction = TextInputAction.next,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (requiredField) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: AppColors.rose,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: TextField(
                  key: ValueKey('input_$label'),
                  controller: controller,
                  textInputAction: textInputAction,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16.5,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          if (warningText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      warningText!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoUploaderSlot extends StatelessWidget {
  final String label;
  final String? photoBase64;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const _PhotoUploaderSlot({
    required this.label,
    required this.photoBase64,
    required this.onSelect,
    required this.onClear,
  });

  Uint8List? _decodePhoto(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bytes = _decodePhoto(photoBase64);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: InkWell(
            onTap: bytes != null ? onClear : onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
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
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
