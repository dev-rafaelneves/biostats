import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'biostats_app_icon.dart';

class AppLockGate extends StatefulWidget {
  final AppState appState;
  final Widget child;

  const AppLockGate({
    super.key,
    required this.appState,
    required this.child,
  });

  static Future<void> showConfigurePinDialog(
    BuildContext context,
    AppState appState,
  ) async {
    final pinCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            appState.hasPinLock
                ? 'Alterar ou Desativar PIN'
                : 'Configurar PIN de 4 Dígitos',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proteja suas avaliações e fotos corporais com uma senha rápida de 4 números ao abrir o aplicativo.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (appState.hasPinLock)
              TextButton(
                onPressed: () async {
                  await appState.setAppPin(null);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bloqueio por PIN desativado.'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Desativar PIN',
                  style: TextStyle(color: AppColors.rose),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = pinCtrl.text.trim();
                if (text.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Digite exatamente 4 números.'),
                    ),
                  );
                  return;
                }
                await appState.setAppPin(text);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN de segurança ativado com sucesso!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Salvar PIN'),
            ),
          ],
        );
      },
    );
  }

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _inBackground = false;
  String _typedPin = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.appState.hasPinLock && !widget.appState.discreetPhotos) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      setState(() => _inBackground = true);
      if (state == AppLifecycleState.paused && widget.appState.hasPinLock) {
        widget.appState.lockSession();
      }
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _inBackground = false);
    }
  }

  void _onDigitTap(String digit) {
    if (_typedPin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _hasError = false;
      _typedPin += digit;
    });

    if (_typedPin.length == 4) {
      final ok = widget.appState.unlockSession(_typedPin);
      if (!ok) {
        HapticFeedback.heavyImpact();
        setState(() {
          _hasError = true;
          _typedPin = '';
        });
      } else {
        HapticFeedback.mediumImpact();
        setState(() => _typedPin = '');
      }
    }
  }

  void _onBackspace() {
    if (_typedPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _hasError = false;
      _typedPin = _typedPin.substring(0, _typedPin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.appState.isLocked) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BioStatsAppIcon(size: 72),
                    const SizedBox(height: 18),
                    Text(
                      'BioStats Protegido',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasError
                          ? 'PIN incorreto. Tente novamente.'
                          : 'Digite seu PIN de 4 dígitos para continuar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            _hasError ? FontWeight.w600 : FontWeight.normal,
                        color: _hasError
                            ? AppColors.rose
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4 Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (idx) {
                        final filled = idx < _typedPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppColors.indigoPrimary
                                : Colors.transparent,
                            border: Border.all(
                              color: _hasError
                                  ? AppColors.rose
                                  : (filled
                                      ? AppColors.indigoPrimary
                                      : const Color(0xFF94A3B8)),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Keypad 1-9, 0, backspace
                    Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                          _PinKeyButton(
                            label: d,
                            onTap: () => _onDigitTap(d),
                          ),
                        const SizedBox(width: 68, height: 68),
                        _PinKeyButton(
                          label: '0',
                          onTap: () => _onDigitTap('0'),
                        ),
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: IconButton(
                            onPressed: _onBackspace,
                            icon: const Icon(Icons.backspace_outlined),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_inBackground)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: (isDark ? AppColors.darkBackground : Colors.white)
                  .withValues(alpha: 0.7),
              alignment: Alignment.center,
              child: const BioStatsAppIcon(size: 80),
            ),
          ),
      ],
    );
  }
}

class _PinKeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: CircleBorder(
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 68,
          height: 68,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
