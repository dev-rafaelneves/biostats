import 'package:flutter/material.dart';

class SummaryMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String? subText;
  final bool isPositiveGood;
  final double delta;

  const SummaryMetricPill({
    super.key,
    required this.label,
    required this.value,
    this.subText,
    required this.isPositiveGood,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = delta.abs() < 0.01;
    final isGood = isZero ? null : (isPositiveGood ? delta > 0 : delta < 0);
    final color = isZero
        ? Colors.white70
        : (isGood == true
            ? const Color(0xFF34D399) // emerald-400
            : const Color(0xFFFB7185)); // rose-400

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subText != null)
            Text(
              subText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}
