import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_lock_gate.dart';
import '../../widgets/data_backup_manager.dart';
import '../../widgets/ios_action_sheet.dart';
import '../onboarding_screen.dart';
import '../profile_setup_screen.dart';

class SettingsTab extends StatelessWidget {
  final AppState appState;

  const SettingsTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final profile = appState.userProfile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark
              ? AppColors.darkBackground.withValues(alpha: 0.9)
              : AppColors.lightBackground.withValues(alpha: 0.9),
          centerTitle: false,
          title: Text(
            'Ajustes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.6,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  appState.toggleTheme();
                },
                tooltip: isDark ? 'Ativar Modo Claro' : 'Ativar Modo Escuro',
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                ),
                icon: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Meu Perfil Pessoal
                    if (profile != null)
                      Material(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.indigoLight,
                                          AppColors.indigoPrimary,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      profile.nome[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.nome,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${profile.sexo.label} • ${profile.idade} anos • ${profile.alturaCm.toStringAsFixed(0)} cm',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => ProfileSetupScreen(
                                      initialProfile: profile,
                                      onSave: (updated) {
                                        appState.saveUserProfile(updated);
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Perfil e histórico recalculados com sucesso!',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              leading: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.indigoPrimary,
                                size: 20,
                              ),
                              title: const Text(
                                'Editar Meus Dados Pessoais',
                                style: TextStyle(
                                  color: AppColors.indigoPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => OnboardingScreen(
                                      onFinish: () => Navigator.of(ctx).pop(),
                                    ),
                                  ),
                                );
                              },
                              leading: const Icon(
                                Icons.auto_awesome_outlined,
                                color: AppColors.indigoPrimary,
                                size: 20,
                              ),
                              title: const Text(
                                'Rever Introdução do App',
                                style: TextStyle(
                                  color: AppColors.indigoPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Card de Privacidade e Segurança (Fase 4)
                    Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Privacidade e Segurança',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          ListTile(
                            onTap: () => AppLockGate.showConfigurePinDialog(
                              context,
                              appState,
                            ),
                            leading: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.indigoPrimary,
                              size: 20,
                            ),
                            title: const Text(
                              'Bloqueio por PIN (4 Dígitos)',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              appState.hasPinLock
                                  ? 'Ativado • Protege o app ao abrir e no multitarefas'
                                  : 'Desativado • Toque para configurar uma senha',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const Divider(indent: 16, height: 1),
                          SwitchListTile.adaptive(
                            value: appState.hasPinLock && appState.useBiometrics,
                            onChanged: appState.hasPinLock
                                ? (_) {
                                    HapticFeedback.selectionClick();
                                    appState.toggleBiometrics();
                                  }
                                : null,
                            activeTrackColor: AppColors.indigoPrimary,
                            secondary: const Icon(
                              Icons.fingerprint_rounded,
                              color: AppColors.indigoPrimary,
                              size: 20,
                            ),
                            title: const Text(
                              'Desbloqueio por Biometria',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              appState.hasPinLock
                                  ? 'Use impressão digital ou rosto como alternativa rápida ao PIN'
                                  : 'Requer PIN configurado previamente',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const Divider(indent: 16, height: 1),
                          SwitchListTile.adaptive(
                            value: appState.blockScreenshots,
                            onChanged: (_) {
                              HapticFeedback.selectionClick();
                              appState.toggleBlockScreenshots();
                            },
                            activeTrackColor: AppColors.indigoPrimary,
                            secondary: const Icon(
                              Icons.security_rounded,
                              color: AppColors.indigoPrimary,
                              size: 20,
                            ),
                            title: const Text(
                              'Ocultar em recentes e bloquear prints',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'Proteção FLAG_SECURE: tela fica preta no multitarefas e bloqueia capturas de tela',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          const Divider(indent: 16, height: 1),
                          SwitchListTile.adaptive(
                            value: appState.discreetPhotos,
                            onChanged: (_) {
                              HapticFeedback.selectionClick();
                              appState.toggleDiscreetPhotos();
                            },
                            activeTrackColor: AppColors.indigoPrimary,
                            secondary: const Icon(
                              Icons.visibility_off_outlined,
                              color: AppColors.indigoPrimary,
                              size: 20,
                            ),
                            title: const Text(
                              'Modo Discreto nas Fotos',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'Desfoca as fotos de evolução até você tocar para revelar',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gerenciador de Backup de Dados (JSON)
                    DataBackupManager(appState: appState),

                    const SizedBox(height: 20),

                    // Sair da Conta / Resetar Todos os Dados
                    Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gerenciamento da Conta Local',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ao apenas sair, suas avaliações e pesagens permanecem salvas no aparelho. Se desejar zerar o aplicativo por completo, use a opção Apagar Todos os Dados.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              IosActionSheet.show(
                                context: context,
                                title: 'Sair do Aplicativo',
                                description:
                                    'Deseja realmente sair do seu perfil atual? Suas avaliações continuarão salvas.',
                                confirmText: 'Sair do Aplicativo',
                                onConfirm: () => appState.logout(),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                    color: AppColors.rose,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sair do Aplicativo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              IosActionSheet.show(
                                context: context,
                                title: 'Apagar Todos os Dados',
                                description:
                                    'ATENÇÃO: Esta ação apagará permanentemente seu perfil, todas as suas avaliações, fotos e pesagens deste aparelho. Exporte um backup antes se desejar guardá-los.',
                                confirmText: 'Apagar Tudo Permanentemente',
                                onConfirm: () => appState.resetAllData(),
                              );
                            },
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_forever_rounded,
                                    size: 20,
                                    color: AppColors.rose,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Apagar Todos os Dados (Reset)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.rose,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
