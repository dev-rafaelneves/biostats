import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/weight_trend_calculator.dart';
import 'consistency_heatmap.dart';
import 'quick_weight_dialog.dart';

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
  final _weightFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  bool _showHistory = false;
  int _historyLimit = 10;
  bool _isSyncing = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  BoxDecoration _cardDecoration(BioThemeColors colors, bool isDark) {
    return BoxDecoration(
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
    );
  }

  Future<void> _syncSmartScale() async {
    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();
    try {
      final count = await widget.appState.syncSmartScaleWeights();
      if (!mounted) return;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 $count nova${count > 1 ? 's' : ''} pesage${count > 1 ? 'ns importadas' : 'm importada'} da balança!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Nenhuma nova pesagem encontrada na balança inteligente.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar balança: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível sincronizar com a balança inteligente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
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
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o peso em kg antes de salvar.'),
        ),
      );
      _weightFocusNode.requestFocus();
      return;
    }

    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 30 || parsed > 350) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um peso válido entre 30 kg e 350 kg.'),
        ),
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
    if (id.startsWith('av_')) return;
    final removed =
        widget.appState.pesagens.where((p) => p.id == id).firstOrNull;
    await widget.appState.deletePesagem(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pesagem removida.'),
        action: removed != null
            ? SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  widget.appState.addPesagem(removed);
                },
              )
            : null,
      ),
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

  Widget _buildQuickFormCard(
    BuildContext context,
    BioThemeColors colors,
    bool isDark,
    DateFormat dateFmt,
  ) {
    final datePickerField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            'DATA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.textMuted,
            ),
          ),
        ),
        Semantics(
          button: true,
          label:
              'Selecionar data da pesagem. Atual: ${dateFmt.format(_selectedDate)}',
          child: InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: colors.textSecondary,
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
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final weightField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            'PESO (KG)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.textMuted,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          alignment: Alignment.center,
          child: TextField(
            key: const ValueKey('daily_weight_input'),
            controller: _weightCtrl,
            focusNode: _weightFocusNode,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleAddWeight(),
            style: TextStyle(
              fontSize: 14.5,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: 72,5',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: colors.textMuted,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );

    final saveBtn = ElevatedButton(
      key: const ValueKey('save_daily_weight_btn'),
      onPressed: _handleAddWeight,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigoPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Salvar',
          maxLines: 1,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(colors, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: colors.accent,
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
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acompanhe a média semanal e a tendência para filtrar oscilações diárias de água.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _isSyncing ? null : _syncSmartScale,
                tooltip: 'Sincronizar balança inteligente (Health Connect)',
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.sync_rounded,
                        color: colors.accent,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final scaledFont = MediaQuery.textScalerOf(context).scale(14.5);
              final stackSave =
                  constraints.maxWidth < 330 || scaledFont > 17.5;
              if (stackSave) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(flex: 5, child: datePickerField),
                        const SizedBox(width: 8),
                        Expanded(flex: 4, child: weightField),
                      ],
                    ),
                    const SizedBox(height: 10),
                    saveBtn,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 5, child: datePickerField),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: weightField),
                  const SizedBox(width: 8),
                  saveBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAndHistoryCard(
    BuildContext context,
    BioThemeColors colors,
    bool isDark,
    List<Pesagem> pesagens,
    List<_WeekSummary> weeklyData,
    DateFormat shortDateFmt,
    DateFormat fullDateFmt,
  ) {
    if (weeklyData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
        decoration: _cardDecoration(colors, isDark),
        child: Text(
          'Adicione sua primeira pesagem diária para calcular a média semanal e a tendência.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final currentGoal =
        widget.appState.avaliacoes.firstOrNull?.objetivo ??
            Objetivo.emagrecimento;
    final isHypertrophy = currentGoal == Objetivo.hipertrofia;

    final int visibleHistoryCount =
        math.min(_historyLimit, pesagens.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(colors, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MÉDIAS SEMANAIS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(weeklyData.length, (index) {
              final week = weeklyData[index];
              final prevWeek =
                  index + 1 < weeklyData.length ? weeklyData[index + 1] : null;
              final diff = prevWeek != null ? week.avg - prevWeek.avg : 0.0;

              Color badgeBg = colors.surfaceSubtle;
              Color badgeBorder = colors.border;
              Color badgeText = colors.textSecondary;
              IconData badgeIcon = Icons.remove_rounded;

              if (diff > 0.1) {
                final isGood = isHypertrophy;
                badgeBg = (isGood ? AppColors.emerald : AppColors.rose)
                    .withValues(alpha: isDark ? 0.18 : 0.10);
                badgeBorder = (isGood ? AppColors.emerald : AppColors.rose)
                    .withValues(alpha: 0.25);
                badgeText = isGood ? colors.successText : colors.dangerText;
                badgeIcon = Icons.trending_up_rounded;
              } else if (diff < -0.1) {
                final isGood = !isHypertrophy;
                badgeBg = (isGood ? AppColors.emerald : AppColors.rose)
                    .withValues(alpha: isDark ? 0.18 : 0.10);
                badgeBorder = (isGood ? AppColors.emerald : AppColors.rose)
                    .withValues(alpha: 0.25);
                badgeText = isGood ? colors.successText : colors.dangerText;
                badgeIcon = Icons.trending_down_rounded;
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == weeklyData.length - 1 ? 0 : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: colors.textMuted,
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
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'kg',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
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
                                color: colors.textSecondary,
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
                                'vs sem. anterior',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: badgeText,
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
          ),

          // Histórico Expansível de Registros (inline sem scroll aninhado)
          if (pesagens.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: _showHistory
                  ? 'Ocultar registros individuais'
                  : 'Ver registros individuais (${pesagens.length})',
              child: InkWell(
                key: const ValueKey('btn_toggle_weight_history'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showHistory = !_showHistory);
                },
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _showHistory
                                ? 'Ocultar registros individuais'
                                : 'Ver registros individuais (${pesagens.length})',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                        ),
                        Icon(
                          _showHistory
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: colors.accent,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showHistory) ...[
              const SizedBox(height: 4),
              for (int idx = 0; idx < visibleHistoryCount; idx++) ...[
                if (idx > 0) const Divider(height: 1),
                Builder(
                  builder: (context) {
                    final p = pesagens[pesagens.length - 1 - idx];
                    final isFromEvaluation = p.id.startsWith('av_');

                    final rowContent = ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    fullDateFmt.format(p.data),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  if (!isFromEvaluation)
                                    Text(
                                      'Toque para editar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${p.pesoKg.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (isFromEvaluation)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Avaliação',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: colors.accent,
                                      ),
                                    ),
                                  )
                                else ...[
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: colors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Semantics(
                                    button: true,
                                    label:
                                        'Excluir pesagem de ${fullDateFmt.format(p.data)}',
                                    child: InkWell(
                                      onTap: () => _handleDelete(p.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 44,
                                          minWidth: 48,
                                        ),
                                        child: Center(
                                          widthFactor: 1.0,
                                          heightFactor: 1.0,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              'Excluir',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: colors.dangerText,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isFromEvaluation) {
                      return rowContent;
                    }

                    return Semantics(
                      button: true,
                      label:
                          'Editar pesagem de ${fullDateFmt.format(p.data)}, ${p.pesoKg.toStringAsFixed(1)} quilos',
                      child: InkWell(
                        onTap: () => QuickWeightDialog.show(
                          context,
                          appState: widget.appState,
                          initialDate: p.data,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: rowContent,
                      ),
                    );
                  },
                ),
              ],
              if (pesagens.length > _historyLimit)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _historyLimit += 10);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.accent,
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      'Carregar mais (${pesagens.length - _historyLimit} restantes)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.bioColors;

    final pesagens = () {
      final list = List<Pesagem>.from(widget.appState.pesagens);
      for (final av in widget.appState.avaliacoes) {
        final d = DateTime(
          av.dataAvaliacao.year,
          av.dataAvaliacao.month,
          av.dataAvaliacao.day,
        );
        if (!list.any(
          (p) =>
              p.data.year == d.year &&
              p.data.month == d.month &&
              p.data.day == d.day,
        )) {
          list.add(
            Pesagem(
              id: 'av_${av.id}',
              userId: av.userId,
              data: d,
              pesoKg: av.pesoKg,
            ),
          );
        }
      }
      list.sort((a, b) => a.data.compareTo(b.data));
      return list;
    }();
    final weeklyData = _computeWeeklyData(pesagens);
    final profile = widget.appState.userProfile;
    final projection = WeightTrendCalculator.computeProjection(
      pesagens: pesagens,
      metaPesoKg: profile?.metaPesoKg,
    );
    final dateFmt = DateFormat('dd/MM/yyyy');
    final shortDateFmt = DateFormat('dd MMM', 'pt_BR');
    final fullDateFmt = DateFormat("dd 'de' MMM, yyyy", 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Card de Registro Rápido
        _buildQuickFormCard(context, colors, isDark, dateFmt),
        const SizedBox(height: 16),

        // 2. Card de Projeção & Meta
        if (pesagens.isNotEmpty) ...[
          _buildProjectionCard(context, projection, colors, isDark),
          const SizedBox(height: 16),
        ],

        // 3. Card Gráfico de Tendência Suavizada
        if (pesagens.length >= 2) ...[
          _buildTrendChart(
            context,
            pesagens,
            profile?.metaPesoKg,
            colors,
            isDark,
          ),
          const SizedBox(height: 16),
        ],

        // 4. Card Heatmap de Consistência (12 Semanas)
        if (pesagens.isNotEmpty) ...[
          ConsistencyHeatmap(pesagens: pesagens),
          const SizedBox(height: 16),
        ],

        // 5. Card de Médias Semanais & Histórico
        _buildWeeklyAndHistoryCard(
          context,
          colors,
          isDark,
          pesagens,
          weeklyData,
          shortDateFmt,
          fullDateFmt,
        ),
      ],
    );
  }

  Widget _buildProjectionCard(
    BuildContext context,
    WeightProjectionResult projection,
    BioThemeColors colors,
    bool isDark,
  ) {
    Color cardBg;
    Color borderCol;
    Color iconCol;
    IconData iconData;

    switch (projection.direction) {
      case TrendDirection.losing:
      case TrendDirection.gaining:
        cardBg = AppColors.emerald.withValues(alpha: isDark ? 0.16 : 0.08);
        borderCol = AppColors.emerald.withValues(alpha: 0.30);
        iconCol = colors.successText;
        iconData = Icons.flag_rounded;
        break;
      case TrendDirection.diverging:
        cardBg = AppColors.orange.withValues(alpha: isDark ? 0.16 : 0.08);
        borderCol = AppColors.orange.withValues(alpha: 0.32);
        iconCol = colors.warningText;
        iconData = Icons.warning_amber_rounded;
        break;
      case TrendDirection.stable:
        cardBg = colors.accent.withValues(alpha: isDark ? 0.16 : 0.08);
        borderCol = colors.accent.withValues(alpha: 0.28);
        iconCol = colors.accent;
        iconData = Icons.balance_rounded;
        break;
      case TrendDirection.insufficientData:
        cardBg = colors.surface;
        borderCol = colors.border;
        iconCol = colors.textSecondary;
        iconData = Icons.insights_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconCol.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconCol, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projection.message,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  projection.detailMessage,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    List<Pesagem> pesagens,
    double? metaPesoKg,
    BioThemeColors colors,
    bool isDark,
  ) {
    final points = WeightTrendCalculator.computeEma(pesagens, alpha: 0.1);
    if (points.length < 2) return const SizedBox.shrink();

    // Limita aos últimos 30 pontos para o gráfico ficar legível e rápido
    final displayPoints =
        points.length > 30 ? points.sublist(points.length - 30) : points;

    final rawSpots = <FlSpot>[];
    final emaSpots = <FlSpot>[];
    final allValues = <double>[];

    for (int i = 0; i < displayPoints.length; i++) {
      final p = displayPoints[i];
      rawSpots.add(FlSpot(i.toDouble(), p.rawWeight));
      emaSpots.add(FlSpot(i.toDouble(), p.emaWeight));
      allValues.add(p.rawWeight);
      allValues.add(p.emaWeight);
    }

    if (metaPesoKg != null && metaPesoKg > 0) {
      allValues.add(metaPesoKg);
    }

    final double minY = (allValues.reduce(math.min) - 1.0).floorToDouble();
    final double maxY = (allValues.reduce(math.max) + 1.0).ceilToDouble();

    final dateFmt = DateFormat('dd/MM');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(colors, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução e Tendência do Peso',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Tendência',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Pesagem',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (metaPesoKg != null && metaPesoKg > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 2,
                      color: colors.successText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Meta',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.successText,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label:
                'Gráfico de tendência de peso com ${displayPoints.length} registros',
            excludeSemantics: true,
            child: SizedBox(
              height: 185,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: 0,
                  maxX: (displayPoints.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1.0,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: colors.border.withValues(alpha: 0.7),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: math.max(
                          1.0,
                          ((maxY - minY) / 4).roundToDouble(),
                        ),
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()} kg',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: math.max(
                          1,
                          (displayPoints.length / 4).floorToDouble(),
                        ),
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= displayPoints.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            dateFmt.format(displayPoints[idx].date),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final pt = idx < displayPoints.length
                              ? displayPoints[idx]
                              : null;
                          if (spot.barIndex == 0) {
                            return LineTooltipItem(
                              'Peso: ${spot.y.toStringAsFixed(1)} kg\n${pt != null ? dateFmt.format(pt.date) : ''}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          } else if (spot.barIndex == 1) {
                            return LineTooltipItem(
                              'Tendência: ${spot.y.toStringAsFixed(1)} kg',
                              const TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return null;
                        }).whereType<LineTooltipItem>().toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Linha de pesagens brutas
                    LineChartBarData(
                      spots: rawSpots,
                      isCurved: false,
                      color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                      barWidth: 1.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 2.5,
                          color: colors.textMuted,
                          strokeWidth: 0,
                        ),
                      ),
                    ),
                    // Linha de tendência suavizada
                    LineChartBarData(
                      spots: emaSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: colors.accent,
                      barWidth: 3.0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.accent.withValues(
                              alpha: isDark ? 0.25 : 0.12,
                            ),
                            colors.accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // Linha da Meta
                    if (metaPesoKg != null && metaPesoKg > 0)
                      LineChartBarData(
                        spots: [
                          FlSpot(0, metaPesoKg),
                          FlSpot(
                            (displayPoints.length - 1).toDouble(),
                            metaPesoKg,
                          ),
                        ],
                        isCurved: false,
                        dashArray: [6, 4],
                        color: colors.successText,
                        barWidth: 2.0,
                        dotData: const FlDotData(show: false),
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
