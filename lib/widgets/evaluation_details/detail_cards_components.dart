import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class DetailSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color headerBg;
  final String title;
  final Widget? trailing;
  final Widget child;

  const DetailSectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.headerBg,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class MacroBar extends StatelessWidget {
  final String label;
  final int grams;
  final int pct;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;

    return Semantics(
      label: '$label: $grams gramas, $pct por cento',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${grams}g ($pct%)',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: (pct.clamp(0, 100)) / 100.0,
              minHeight: 8,
              backgroundColor: colors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class MethodologyRow extends StatelessWidget {
  final String name;
  final String desc;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;

  const MethodologyRow({
    super.key,
    required this.name,
    required this.desc,
    required this.value,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;
    final canSelect = onTap != null && value != '--';

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canSelect) ...[
            Icon(
              highlight
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: highlight ? colors.accent : colors.textMuted,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: highlight ? colors.accent : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (highlight && canSelect) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Referência',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: highlight ? colors.accent : colors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (!canSelect) {
      return Semantics(
        label: '$name: $value. $desc',
        child: content,
      );
    }

    return Semantics(
      button: true,
      selected: highlight,
      label: '$name: $value. Toque para usar como método de referência',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      ),
    );
  }
}

class RiskMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String label;
  final Color? badgeColor;

  const RiskMiniCard({
    super.key,
    required this.title,
    required this.value,
    required this.label,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;

    return Semantics(
      label: '$title: $value, classificação $label',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (badgeColor != null)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                    badgeColor != null ? FontWeight.w600 : FontWeight.normal,
                color: badgeColor ?? colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasureRow extends StatelessWidget {
  final String label;
  final String value;
  final double? currentVal;
  final double? prevVal;
  final String unit;
  final bool lowerIsBetter;

  const MeasureRow({
    super.key,
    required this.label,
    required this.value,
    this.currentVal,
    this.prevVal,
    this.unit = 'cm',
    this.lowerIsBetter = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;
    final hasDelta = currentVal != null &&
        prevVal != null &&
        currentVal! > 0 &&
        prevVal! > 0 &&
        (currentVal! - prevVal!).abs() >= 0.1;

    final diff = hasDelta ? (currentVal! - prevVal!) : 0.0;
    final sign = diff > 0 ? '+' : '';
    final isGood = lowerIsBetter ? diff < 0 : diff > 0;
    final deltaColor = isGood ? colors.successText : colors.warningText;

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (hasDelta)
                  Text(
                    '$sign${diff.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: deltaColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GridHalfItem extends StatelessWidget {
  final Widget child;
  final double spacing;

  const GridHalfItem({
    super.key,
    required this.child,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (MediaQuery.sizeOf(context).width.clamp(300.0, 460.0) - 66);
        final itemWidth = ((maxW - spacing) / 2 - 0.5).clamp(110.0, 220.0);
        return SizedBox(
          width: itemWidth,
          child: child,
        );
      },
    );
  }
}
