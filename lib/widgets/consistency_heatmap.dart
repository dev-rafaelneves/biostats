import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ConsistencyHeatmap extends StatelessWidget {
  final List<Pesagem> pesagens;

  const ConsistencyHeatmap({
    super.key,
    required this.pesagens,
  });

  /// Retorna um mapa [yyyy-MM-dd -> double peso] para acesso O(1)
  Map<String, double> _buildDateMap() {
    final Map<String, double> map = {};
    for (final p in pesagens) {
      final key = DateFormat('yyyy-MM-dd').format(p.data);
      map[key] = p.pesoKg;
    }
    return map;
  }

  /// Calcula a sequência atual (streak) de dias consecutivos
  int _calculateStreak(Map<String, double> dateMap) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayKey =
        DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    DateTime checkDate;
    if (dateMap.containsKey(todayKey)) {
      checkDate = today;
    } else if (dateMap.containsKey(yesterdayKey)) {
      // Se ainda não se pesou hoje, preserva a sequência a partir de ontem
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDate);
      if (dateMap.containsKey(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateMap = _buildDateMap();
    final streak = _calculateStreak(dateMap);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Início das 12 semanas (Segunda-feira de 11 semanas atrás)
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final startMonday = thisMonday.subtract(const Duration(days: 11 * 7));

    int totalLoggedDays = 0;
    int pastDaysCount = 0;

    // Matriz 7 linhas (dias da semana: 0 = Seg ... 6 = Dom) x 12 colunas (semanas)
    final List<List<DateTime>> grid = List.generate(7, (_) => []);

    for (int col = 0; col < 12; col++) {
      final weekStart = startMonday.add(Duration(days: col * 7));
      for (int row = 0; row < 7; row++) {
        final day = weekStart.add(Duration(days: row));
        grid[row].add(day);

        final isFuture = day.isAfter(today);
        if (!isFuture) {
          pastDaysCount++;
          final key = DateFormat('yyyy-MM-dd').format(day);
          if (dateMap.containsKey(key)) {
            totalLoggedDays++;
          }
        }
      }
    }

    final double adherencePct = pastDaysCount > 0
        ? (totalLoggedDays / pastDaysCount) * 100
        : 0.0;

    final shortFmt = DateFormat("dd 'de' MMM", 'pt_BR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Título + Badge de Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.indigoLight
                          : AppColors.indigoPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Consistência (12 Semanas)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: streak > 0
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streak > 0 ? '🔥 $streak ${streak == 1 ? 'dia' : 'dias'}' : '💤 0 dias',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: streak > 0
                            ? const Color(0xFFD97706)
                            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Grade de 12 colunas x 7 linhas estilo GitHub
          LayoutBuilder(
            builder: (context, constraints) {
              const double labelWidth = 26;
              final double availableWidth = constraints.maxWidth - labelWidth - 8;
              final double cellSize = (availableWidth / 12) - 3.5;
              final double finalCellSize = cellSize.clamp(10.0, 18.0);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rótulos de dias da semana (Seg, Qua, Sex)
                  SizedBox(
                    width: labelWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayLabel('Seg', finalCellSize, isDark),
                        SizedBox(height: finalCellSize + 4.0),
                        _buildDayLabel('Qua', finalCellSize, isDark),
                        SizedBox(height: finalCellSize + 4.0),
                        _buildDayLabel('Sex', finalCellSize, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // As 12 colunas
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true, // Mostra as semanas mais recentes visíveis
                      child: Row(
                        children: List.generate(12, (colIdx) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 3.5),
                            child: Column(
                              children: List.generate(7, (rowIdx) {
                                final day = grid[rowIdx][colIdx];
                                final isFuture = day.isAfter(today);
                                final isToday = day.year == today.year &&
                                    day.month == today.month &&
                                    day.day == today.day;
                                final key = DateFormat('yyyy-MM-dd').format(day);
                                final weight = dateMap[key];
                                final hasLogged = weight != null;

                                Color cellColor;
                                if (isFuture) {
                                  cellColor = Colors.transparent;
                                } else if (hasLogged) {
                                  cellColor = AppColors.indigoPrimary;
                                } else {
                                  cellColor = isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0);
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3.5),
                                  child: Tooltip(
                                    message: hasLogged
                                        ? '${shortFmt.format(day)}: ${weight.toStringAsFixed(1)} kg'
                                        : '${shortFmt.format(day)}: Sem registro',
                                    child: InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            duration:
                                                const Duration(milliseconds: 1400),
                                            content: Text(
                                              hasLogged
                                                  ? '${shortFmt.format(day)}: ${weight.toStringAsFixed(1)} kg registrado ⚖️'
                                                  : '${shortFmt.format(day)}: Nenhum peso registrado',
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(3),
                                      child: Container(
                                        width: finalCellSize,
                                        height: finalCellSize,
                                        decoration: BoxDecoration(
                                          color: cellColor,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          border: isToday
                                              ? Border.all(
                                                  color: const Color(0xFFF59E0B),
                                                  width: 1.5,
                                                )
                                              : (isFuture
                                                  ? null
                                                  : Border.all(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.04),
                                                      width: 0.5,
                                                    )),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Rodapé com estatísticas de adesão
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$totalLoggedDays de $pastDaysCount dias registrados (${adherencePct.toStringAsFixed(0)}% consistência)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    'Menos',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.indigoPrimary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.indigoPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mais',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String text, double size, bool isDark) {
    return SizedBox(
      height: size,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
              : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
