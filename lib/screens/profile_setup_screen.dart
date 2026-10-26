import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/biostats_app_icon.dart';

class ProfileSetupScreen extends StatefulWidget {
  final AppState? appState;
  final UserProfile? initialProfile;
  final ValueChanged<UserProfile> onSave;
  final VoidCallback? onCancel;

  const ProfileSetupScreen({
    super.key,
    this.appState,
    this.initialProfile,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _alturaController;
  late final TextEditingController _metaPesoController;
  late final TextEditingController _metaBfController;
  late DateTime _dataNascimento;
  late Sexo _sexo;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialProfile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nomeController = TextEditingController(text: p?.nome ?? '');
    _alturaController = TextEditingController(
      text: p != null ? p.alturaCm.toStringAsFixed(0) : '',
    );
    _metaPesoController = TextEditingController(
      text: p?.metaPesoKg != null ? p!.metaPesoKg!.toStringAsFixed(1) : '',
    );
    _metaBfController = TextEditingController(
      text: p?.metaBfPct != null ? p!.metaBfPct!.toStringAsFixed(1) : '',
    );
    _dataNascimento = p?.dataNascimento ?? DateTime(1995, 6, 15);
    _sexo = p?.sexo ?? Sexo.M;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _alturaController.dispose();
    _metaPesoController.dispose();
    _metaBfController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5, now.month, now.day),
      helpText: 'Data de Nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      setState(() => _dataNascimento = picked);
    }
  }

  double? _parseOptional(TextEditingController ctrl) {
    final raw = ctrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final val = double.tryParse(raw);
    return (val != null && val > 0) ? val : null;
  }

  void _handleSubmit() {
    final nome = _nomeController.text.trim();
    final alturaRaw = _alturaController.text.trim().replaceAll(',', '.');
    final altura = double.tryParse(alturaRaw);

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome para continuar.')),
      );
      return;
    }
    if (altura == null || altura < 100 || altura > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Informe uma altura válida em cm (ex: 175).')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final profile = UserProfile(
      id: widget.initialProfile?.id ?? const Uuid().v4(),
      nome: nome,
      dataNascimento: _dataNascimento,
      sexo: _sexo,
      alturaCm: altura,
      metaPesoKg: _isEditing
          ? _parseOptional(_metaPesoController)
          : widget.initialProfile?.metaPesoKg,
      metaBfPct: _isEditing
          ? _parseOptional(_metaBfController)
          : widget.initialProfile?.metaBfPct,
      criadoEm: widget.initialProfile?.criadoEm ?? DateTime.now(),
    );

    widget.onSave(profile);
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDirectRestore() async {
    final state = widget.appState;
    if (state == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        throw const FormatException('Não foi possível ler o arquivo.');
      }

      final jsonContent = utf8.decode(fileBytes);
      final parsed = jsonDecode(jsonContent) as Map<String, dynamic>;
      final preview = state.inspectBackupJson(parsed);

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog.adaptive(
          title: Text('Restaurar Backup de ${preview.profileName}?'),
          content: Text(
            'Encontramos ${preview.avaliacoesCount} avaliações, '
            '${preview.fotosCount} fotos e ${preview.pesagensCount} pesagens.\n\n'
            'Deseja restaurar este perfil agora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurar Dados'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      HapticFeedback.mediumImpact();
      await state.importBackupJson(parsed, merge: false);
      await state.completeOnboarding();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bem-vindo de volta, ${preview.profileName}! Dados restaurados.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao processar arquivo de backup: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  String _formatDateBr(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _isEditing
          ? AppBar(
              leading: IconButton(
                onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.indigoPrimary,
                  size: 20,
                ),
              ),
              title: const Text('Editar Meu Perfil'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isEditing) ...[
                      // Ícone Oficial do Aplicativo BioStats (Balança 72.5)
                      const BioStatsAppIcon(size: 88),
                      const SizedBox(height: 16),
                      Text(
                        'BioStats',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Configure seu perfil pessoal para começar a acompanhar sua evolução corporal e metas. Funciona 100% offline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Section Header (Apple HIG Inset Grouped List)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14, bottom: 8),
                        child: Text(
                          'SEUS DADOS BASE',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),

                    // Grouped Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Nome
                          _GroupedRow(
                            label: 'Seu Nome',
                            child: TextField(
                              controller: _nomeController,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.right,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(
                                fontSize: 17,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ex: Rafael Souza',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const Divider(indent: 16),

                          // Data de Nascimento
                          _GroupedRow(
                            label: 'Nascimento',
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatDateBr(_dataNascimento),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Divider(indent: 16),

                          // Sexo Biológico (usado nas equações US Navy / Boer / RFM)
                          _GroupedRow(
                            label: 'Sexo Biológico',
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoSlidingSegmentedControl<Sexo>(
                                groupValue: _sexo,
                                children: const {
                                  Sexo.M: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: Text(
                                      'Masculino',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Sexo.F: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: Text(
                                      'Feminino',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                },
                                onValueChanged: (val) {
                                  if (val != null) {
                                    setState(() => _sexo = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const Divider(indent: 16),

                          // Altura (cm)
                          _GroupedRow(
                            label: 'Sua Altura',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _alturaController,
                                    textInputAction: _isEditing
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '175',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'cm',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14, bottom: 8),
                          child: Text(
                            'MINHAS METAS PESSOAIS (OPCIONAL)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            _GroupedRow(
                              label: 'Peso Alvo',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _metaPesoController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Ex: 75.0',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF475569)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'kg',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(indent: 16),
                            _GroupedRow(
                              label: 'Gordura Alvo',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _metaBfController,
                                      textInputAction: TextInputAction.done,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Ex: 14.0',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF475569)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Sua altura, idade e sexo biológico são utilizados exclusivamente pelas equações antropométricas (US Navy, Boer, Devine e RFM).',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting ||
                                _nomeController.text.trim().isEmpty ||
                                _alturaController.text.trim().isEmpty)
                            ? null
                            : _handleSubmit,
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
                              ? 'Salvando...'
                              : (_isEditing
                                  ? 'Salvar Alterações'
                                  : 'Acessar Meu BioStats'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    if (!_isEditing && widget.appState != null) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _handleDirectRestore,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.settings_backup_restore_rounded,
                          color: AppColors.indigoPrimary,
                          size: 20,
                        ),
                        label: const Text(
                          'Já tenho um Backup (.json)',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.indigoPrimary,
                          ),
                        ),
                      ),
                    ],
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

class _GroupedRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _GroupedRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
