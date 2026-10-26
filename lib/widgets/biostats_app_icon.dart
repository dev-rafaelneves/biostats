import 'package:flutter/material.dart';

/// Renderiza vetorialmente o mesmo ícone da balança de bioimpedância ("72.5")
/// utilizado no menu principal do celular (baseado no favicon.svg / pwa-512x512.png original).
class BioStatsAppIcon extends StatelessWidget {
  final double size;

  const BioStatsAppIcon({
    super.key,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final s = size / 512.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Squircle Background (#F8FAFC -> #E2E8F0)
          Container(
            width: 448 * s,
            height: 448 * s,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                ],
              ),
              borderRadius: BorderRadius.circular(100 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12 * s,
                  offset: Offset(0, 4 * s),
                ),
              ],
            ),
          ),

          // Scale Body (#6366F1 -> #4338CA)
          Container(
            width: 280 * s,
            height: 280 * s,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF4338CA),
                ],
              ),
              borderRadius: BorderRadius.circular(56 * s),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.28),
                  blurRadius: 20 * s,
                  offset: Offset(0, 14 * s),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Display Screen
                Positioned(
                  left: 70 * s,
                  top: 30 * s,
                  width: 140 * s,
                  height: 64 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20 * s),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '72.5',
                      style: TextStyle(
                        fontSize: 32 * s,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1 * s,
                        color: const Color(0xFF4338CA),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                // Left Bioimpedance Sensor Plate
                Positioned(
                  left: 30 * s,
                  top: 110 * s,
                  width: 64 * s,
                  height: 136 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(32 * s),
                    ),
                  ),
                ),

                // Right Bioimpedance Sensor Plate
                Positioned(
                  left: 186 * s,
                  top: 110 * s,
                  width: 64 * s,
                  height: 136 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(32 * s),
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
