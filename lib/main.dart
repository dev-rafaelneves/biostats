import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final appState = AppState();
  await appState.init();
  runApp(BioStatsApp(appState: appState));
}

class BioStatsApp extends StatelessWidget {
  final AppState appState;

  const BioStatsApp({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'BioStats',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('pt', 'BR'),
          home: _RootRouter(appState: appState),
        );
      },
    );
  }
}

class _RootRouter extends StatelessWidget {
  final AppState appState;

  const _RootRouter({required this.appState});

  @override
  Widget build(BuildContext context) {
    // 1. Começa pelo Login / Configuração do Perfil Pessoal
    if (!appState.isLoggedIn) {
      return ProfileSetupScreen(
        onSave: (profile) => appState.saveUserProfile(profile),
      );
    }

    // 2. Em seguida, exibe a Introdução do App (Onboarding)
    if (!appState.onboardingDone) {
      return OnboardingScreen(
        onFinish: () => appState.completeOnboarding(),
      );
    }

    // 3. Vai para o Painel Pessoal (com Aviso Legal e Barra Inferior iOS)
    return MainShell(appState: appState);
  }
}
