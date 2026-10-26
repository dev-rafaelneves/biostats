import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class WeeklyWeightTracker extends StatefulWidget {
  final AppState appState;

  const WeeklyWeightTracker({
    super.key,
    required this.appState,
  });

  @override
  State<WeeklyWeightTracker> createState() => _WeeklyWeightTrackerState();
}

class _WeeklyWeightTrackerState extends State<WeeklyWeightTracker> {
  final _weightCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showHistory = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleAddWeight() async {
    final profile = widget.appState.userProfile;
    if (profile == null) return;

    final raw = _weightCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return;

    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira um peso válido.')),
      );
      return;
    }

    final localDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final novaPesagem = Pesagem(
      id: const Uuid().v4(),
      userId: profile.id,
      data: localDate,
      pesoKg: parsed,
    );

    final updatedExisting = await widget.appState.addPesagem(novaPesagem);
    HapticFeedback.lightImpact();
    _weightCtrl.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedExisting
              ? 'Peso desta data atualizado!'
              : 'Peso diário registrado!',
        ),
      ),
    );
  }

  Future<void> _handleDelete(String id) async {
    await widget.appState.deletePesagem(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesagem removida.')),
    );
  }

  List<_WeekSummary> _computeWeeklyData(List<Pesagem> pesagens) {
    if (pesagens.isEmpty) return [];

    final Map<String, _WeekSummary> groups = {};

    for (final p in pesagens) {
      final d = DateTime(p.data.year, p.data.month, p.data.day);
      // Segunda-feira como início da semana (weekday 1 = Monday)
      final weekStart = d.subtract(Duration(days: d.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final key =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final group = groups.putIfAbsent(
        key,
        () => _WeekSummary(start: weekStart, end: weekEnd, weights: []),
      );
      group.weights.add(p.pesoKg);
    }

    final sortedWeeks = groups.values.toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    for (final w in sortedWeeks) {
      final sum = w.weights.fold<double>(0.0, (acc, curr) => acc + curr);
      w.avg = sum / w.weights.length;
    }

    return sortedWeeks;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pesagens = widget.appState.pesagens;
    final weeklyData = _computeWeeklyData(pesagens);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final shortDateFmt = DateFormat('dd MMM', 'pt_BR');
    final fullDateFmt = DateFormat("dd 'de' MMM, yyyy", 'pt_BR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.indigoPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.indigoPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesagens Diárias & Média Semanal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Só foca na média! O peso oscila todos os dias devido a líquidos e treinos. A média semanal é o único número confiável.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Form (Data + Peso + Salvar)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Data Picker
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 5),
                      child: Text(
                        'DATA',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _pickDate(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateFmt.format(_selectedDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Input Peso
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 5),
                      child: Text(
                        'PESO (KG)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        key: const ValueKey('daily_weight_input'),
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ex: 72,5',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botão Salvar
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  key: const ValueKey('save_daily_weight_btn'),
                  onPressed: _handleAddWeight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigoPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Lista de Médias Semanais ou Estado Vazio
          if (weeklyData.isNotEmpty)
            Column(
              children: List.generate(weeklyData.length, (index) {
                final week = weeklyData[index];
                final prevWeek =
                    index + 1 < weeklyData.length ? weeklyData[index + 1] : null;
                final diff = prevWeek != null ? week.avg - prevWeek.avg : 0.0;

                final currentGoal =
                    widget.appState.avaliacoes.firstOrNull?.objetivo ??
                        Objetivo.emagrecimento;
                final isHypertrophy = currentGoal == Objetivo.hipertrofia;

                Color badgeBg = isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9);
                Color badgeBorder = isDark
                    ? AppColors.darkBorder
                    : const Color(0xFFE2E8F0);
                Color badgeText = isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B);
                IconData badgeIcon = Icons.remove_rounded;

                if (diff > 0.1) {
                  final isGood = isHypertrophy;
                  badgeBg = (isGood
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E))
                      .withValues(alpha: isDark ? 0.18 : 0.08);
                  badgeBorder = (isGood
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E))
                      .withValues(alpha: 0.25);
                  badgeText = isGood
                      ? const Color(0xFF059669)
                      : const Color(0xFFE11D48);
                  badgeIcon = Icons.trending_up_rounded;
                } else if (diff < -0.1) {
                  final isGood = !isHypertrophy;
                  badgeBg = (isGood
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E))
                      .withValues(alpha: isDark ? 0.18 : 0.08);
                  badgeBorder = (isGood
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E))
                      .withValues(alpha: 0.25);
                  badgeText = isGood
                      ? const Color(0xFF059669)
                      : const Color(0xFFE11D48);
                  badgeIcon = Icons.trending_down_rounded;
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == weeklyData.length - 1 ? 0 : 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${shortDateFmt.format(week.start)} a ${shortDateFmt.format(week.end)}'
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    week.avg.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'kg',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${week.weights.length} ${week.weights.length == 1 ? 'pesagem nesta semana' : 'pesagens nesta semana'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (prevWeek != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: badgeBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(badgeIcon, size: 15, color: badgeText),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${diff.abs().toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: badgeText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'VS SEM. ANT.',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: badgeText.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                'Adicione sua primeira pesagem diária para começar a calcular a média semanal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
                ),
              ),
            ),

          // Histórico Expansível de Registros
          if (pesagens.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _showHistory = !_showHistory),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _showHistory
                      ? '- Ocultar histórico'
                      : '+ Mostrar histórico de registros',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.indigoLight
                        : AppColors.indigoPrimary,
                  ),
                ),
              ),
            ),
            if (_showHistory) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pesagens.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    // Ordem decrescente (mais recente primeiro)
                    final p = pesagens[pesagens.length - 1 - idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              fullDateFmt.format(p.data),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${p.pesoKg.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 14),
                              InkWell(
                                onTap: () => _handleDelete(p.id),
                                child: const Text(
                                  'Excluir',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.rose,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WeekSummary {
  final DateTime start;
  final DateTime end;
  final List<double> weights;
  double avg = 0;

  _WeekSummary({
    required this.start,
    required this.end,
    required this.weights,
  });
}
