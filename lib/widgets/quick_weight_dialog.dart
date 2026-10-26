import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class QuickWeightDialog extends StatefulWidget {
  final AppState appState;

  const QuickWeightDialog({
    super.key,
    required this.appState,
  });

  static Future<void> show(
    BuildContext context, {
    required AppState appState,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickWeightDialog(appState: appState),
    );
  }

  @override
  State<QuickWeightDialog> createState() => _QuickWeightDialogState();
}

class _QuickWeightDialogState extends State<QuickWeightDialog> {
  final _weightCtrl = TextEditingController();
  final _focusNode = FocusNode();
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExistingOrSuggestedWeight();
  }

  void _loadExistingOrSuggestedWeight() {
    final norm = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // Se já houver pesagem nesta data, carrega o valor existente
    Pesagem? existing;
    for (final p in widget.appState.pesagens) {
      if (p.data.year == norm.year &&
          p.data.month == norm.month &&
          p.data.day == norm.day) {
        existing = p;
        break;
      }
    }

    if (existing != null) {
      _weightCtrl.text = existing.pesoKg.toStringAsFixed(1);
    } else {
      // Caso contrário, sugere a pesagem mais recente anterior a esta data
      final sorted = [...widget.appState.pesagens]
        ..sort((a, b) => b.data.compareTo(a.data));
      final prev = sorted.firstOrNull;
      if (prev != null) {
        _weightCtrl.text = prev.pesoKg.toStringAsFixed(1);
      }
    }

    // Seleciona todo o texto para facilitar digitar novo valor por cima
    _weightCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _weightCtrl.text.length,
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 1)),
      helpText: 'Data da Pesagem',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedDate = picked;
        _loadExistingOrSuggestedWeight();
      });
    }
  }

  void _applyQuickOffset(double delta) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    if (current != null) {
      final updated = (current + delta).clamp(30.0, 300.0);
      setState(() {
        _weightCtrl.text = updated.toStringAsFixed(1);
        _weightCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _weightCtrl.text.length,
        );
      });
    }
  }

  Pesagem? _findPreviousWeightBefore(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    final prior = widget.appState.pesagens.where((p) {
      final pDate = DateTime(p.data.year, p.data.month, p.data.day);
      return pDate.isBefore(norm);
    }).toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    return prior.firstOrNull;
  }

  Future<void> _handleSave() async {
    final profile = widget.appState.userProfile;
    if (profile == null) return;

    final raw = _weightCtrl.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 30 || parsed > 350) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um peso válido entre 30 kg e 350 kg.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final localDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final previous = _findPreviousWeightBefore(localDate);
    final novaPesagem = Pesagem(
      id: const Uuid().v4(),
      userId: profile.id,
      data: localDate,
      pesoKg: parsed,
    );

    await widget.appState.addPesagem(novaPesagem);
    HapticFeedback.mediumImpact();

    // Monta o Micro-feedback
    String feedback = 'Pesagem registrada: ${parsed.toStringAsFixed(1)} kg';
    if (previous != null) {
      final diff = parsed - previous.pesoKg;
      final diffSignal = diff > 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);
      final isYesterday = localDate.difference(DateTime(previous.data.year, previous.data.month, previous.data.day)).inDays == 1;
      final refLabel = isYesterday ? 'vs ontem' : 'vs última';
      feedback = 'Peso: ${parsed.toStringAsFixed(1)} kg ($diffSignal kg $refLabel)';
    }

    if (profile.metaPesoKg != null && profile.metaPesoKg! > 0) {
      final dist = (parsed - profile.metaPesoKg!).abs();
      if (dist < 0.1) {
        feedback += ' 🎉 Parabéns! Você atingiu sua meta!';
      } else {
        feedback += ' • Faltam ${dist.toStringAsFixed(1)} kg para sua meta (${profile.metaPesoKg!.toStringAsFixed(1)} kg)';
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          feedback,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.indigoPrimary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR');
    final isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar superior
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cabeçalho com Ícone e Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.indigoPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monitor_weight_outlined,
                        color: AppColors.indigoPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Pesagem de Hoje' : 'Registro de Peso',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          dateFmt.format(_selectedDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.indigoPrimary,
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 15),
                  label: const Text(
                    'Mudar data',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo de Entrada Expressa (Grande e Focado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      key: const ValueKey('input_quick_weight'),
                      controller: _weightCtrl,
                      focusNode: _focusNode,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '00.0',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onSubmitted: (_) => _handleSave(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Chips de Ajuste Rápido (+/- 0.2kg, +/- 0.5kg)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickChip('-0.5', () => _applyQuickOffset(-0.5)),
                const SizedBox(width: 8),
                _buildQuickChip('-0.2', () => _applyQuickOffset(-0.2)),
                const SizedBox(width: 8),
                _buildQuickChip('+0.2', () => _applyQuickOffset(0.2)),
                const SizedBox(width: 8),
                _buildQuickChip('+0.5', () => _applyQuickOffset(0.5)),
              ],
            ),
            const SizedBox(height: 22),

            // Botão Principal Salvar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                key: const ValueKey('btn_save_quick_weight'),
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigoPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Salvando...' : 'Confirmar e Salvar',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.indigoLight
                : AppColors.indigoPrimary,
          ),
        ),
      ),
    );
  }
}
