import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biostats/main.dart';
import 'package:biostats/services/app_state.dart';

void main() {
  testWidgets(
      'Fluxo Completo Parte 1 a 6: Login -> Introdução -> Avaliações -> Gráficos -> Exportação e Ajustes/Backup',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(BioStatsApp(appState: appState));
    await tester.pumpAndSettle();

    // 1. Login / Perfil Pessoal & Botão Restaurar Backup Direto
    expect(find.text('Já tenho um Backup (.json)'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Rafael Souza');
    await tester.enterText(find.byType(TextField).last, '178');
    await tester.pumpAndSettle();

    final btnAcessar = find.text('Acessar Meu BioStats');
    await tester.ensureVisible(btnAcessar);
    await tester.pumpAndSettle();
    await tester.tap(btnAcessar);
    await tester.pumpAndSettle();

    // 2. Introdução -> Pular
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    // 3. Aviso Legal -> Aceitar
    final btnAceitar = find.text('Eu li e compreendo');
    await tester.ensureVisible(btnAceitar);
    await tester.tap(btnAceitar);
    await tester.pumpAndSettle();

    // 4. Primeira Avaliação (80kg, Cintura 88cm, Pescoço 38cm)
    final btnNovaAvaliacao = find.text('Nova Avaliação');
    await tester.ensureVisible(btnNovaAvaliacao);
    await tester.tap(btnNovaAvaliacao);
    await tester.pumpAndSettle();

    // 4.0 Validação da Fase 3: Formulário Modular e Validação Anatômica
    expect(find.text('MEDIDAS ESSENCIAIS'), findsOneWidget);
    expect(find.text('MEMBROS E DETALHES'), findsOneWidget);
    expect(find.text('Composição & Metas'), findsOneWidget);

    // Testa aviso de validação anatômica não-bloqueante
    await tester.enterText(find.byKey(const ValueKey('input_Peso')), '15');
    await tester.pumpAndSettle();
    expect(find.textContaining('Valor incomum'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('input_Peso')), '80');
    await tester.enterText(find.byKey(const ValueKey('input_Pescoço')), '38');
    await tester.enterText(find.byKey(const ValueKey('input_Cintura')), '88');
    await tester.pumpAndSettle();

    // 4.1 Valida proteção contra saída acidental (PopScope)
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Continuar Editando'));
    await tester.pumpAndSettle();

    final btnCalcular = find.text('Calcular Resultados');
    await tester.ensureVisible(btnCalcular);
    await tester.pumpAndSettle();
    await tester.tap(btnCalcular);
    await tester.pumpAndSettle();

    // Verifica Card de Exportação (PDF e CSV)
    expect(find.text('Exportar Meus Dados'), findsOneWidget);
    expect(find.text('Baixar Relatório (PDF)'), findsOneWidget);
    expect(find.text('Exportar Tabela (CSV)'), findsOneWidget);

    // 4.2 Testa FAB de Quick-Log de Pesagem Matinal (Fase 2)
    final fab = find.byKey(const ValueKey('fab_quick_actions'));
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Seleciona Registrar Peso de Hoje
    await tester.tap(find.byKey(const ValueKey('action_quick_weight')));
    await tester.pumpAndSettle();

    // Digita nova pesagem expressa de 79.5
    final inputQuickWeight = find.byKey(const ValueKey('input_quick_weight'));
    expect(inputQuickWeight, findsOneWidget);
    await tester.enterText(inputQuickWeight, '79.5');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('btn_save_quick_weight')));
    await tester.pumpAndSettle();

    expect(appState.pesagens.any((p) => p.pesoKg == 79.5), isTrue);

    // 5. Navega para a aba Ajustes e valida Backup JSON + Modo Escuro
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Backup de Dados'), findsOneWidget);
    expect(find.text('Exportar Backup (JSON)'), findsOneWidget);
    expect(find.text('Importar Backup (JSON)'), findsOneWidget);
    expect(find.text('Editar Meus Dados Pessoais'), findsOneWidget);

    // Alterna Modo Escuro
    await tester.tap(find.byTooltip('Ativar Modo Escuro'));
    await tester.pumpAndSettle();
    expect(appState.isDarkMode, isTrue);
  });
}
