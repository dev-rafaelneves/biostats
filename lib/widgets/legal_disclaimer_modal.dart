import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LegalDisclaimerModal extends StatelessWidget {
  final VoidCallback onAccept;

  const LegalDisclaimerModal({
    super.key,
    required this.onAccept,
  });

  static Future<void> showIfNeeded(
    BuildContext context, {
    required bool alreadyAccepted,
    required VoidCallback onAccept,
  }) async {
    if (alreadyAccepted) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Aviso Legal',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LegalDisclaimerModal(
                onAccept: () {
                  onAccept();
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Laranja (Atenção médica/legal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF431407).withValues(alpha: 0.5)
                    : const Color(0xFFFFF7ED),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF7C2D12)
                        : const Color(0xFFFFEDD5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF7C2D12).withValues(alpha: 0.6)
                          : const Color(0xFFFFEDD5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 36,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aviso Importante e Responsabilidade',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),

            // Content (Scrollable on smaller screens)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF475569),
                      ),
                      children: const [
                        TextSpan(text: 'O '),
                        TextSpan(
                          text: 'BioStats',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              ' é uma ferramenta desenhada exclusivamente para auxiliar no seu autoacompanhamento e evolução de métricas corporais preditivas.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF334155),
                        ),
                        children: const [
                          TextSpan(text: 'Este aplicativo gera '),
                          TextSpan(
                            text: 'estimativas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ' de composição corporal baseadas em equações antropométricas validadas na literatura científica (como o Método US Navy, RFM e Boer).',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _BulletItem(
                    text:
                        'Os resultados não representam diagnóstico médico ou prescrição clínica.',
                  ),
                  const SizedBox(height: 8),
                  const _BulletItem(
                    text:
                        'Não substitui exames de imagem (como DEXA Scan), bioimpedância clínica ou acompanhamento médico e nutricional.',
                  ),
                  const SizedBox(height: 8),
                  const _BulletItem(
                    text:
                        'O uso das informações e metas calóricas no seu dia a dia é de sua inteira responsabilidade.',
                  ),
                ],
              ),
            ),
            ),

            // Footer Action
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.indigoPrimary
                        : const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text(
                    'Eu li e compreendo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF64748B),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
