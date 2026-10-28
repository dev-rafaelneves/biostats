import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ComparisonRowData {
  final String label;
  final String valA;
  final String valB;
  final double? delta;
  final String? deltaFormatted;
  final bool? isPositiveGood;

  ComparisonRowData({
    required this.label,
    required this.valA,
    required this.valB,
    this.delta,
    this.deltaFormatted,
    this.isPositiveGood,
  });
}

class ComparisonSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final String dateAStr;
  final String dateBStr;
  final List<ComparisonRowData> rows;

  const ComparisonSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isDark,
    required this.dateAStr,
    required this.dateBStr,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.indigoPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark
                          ? AppColors.indigoLight
                          : AppColors.indigoPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Métrica',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    dateAStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    dateBStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Evolução',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 14),
            itemBuilder: (ctx, idx) {
              final r = rows[idx];
              final delta = r.delta;
              final isZero = delta == null || delta.abs() < 0.001;
              final isGood = isZero || r.isPositiveGood == null
                  ? null
                  : (r.isPositiveGood! ? delta > 0 : delta < 0);

              final Color deltaColor;
              if (isZero || isGood == null) {
                deltaColor = isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B);
              } else if (isGood) {
                deltaColor = AppColors.emerald;
              } else {
                deltaColor = AppColors.rose;
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.valA,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.valB,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        r.deltaFormatted ??
                            (delta != null
                                ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}'
                                : '--'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
