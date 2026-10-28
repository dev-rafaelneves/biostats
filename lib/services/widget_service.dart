import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/models.dart';
import '../utils/weight_trend_calculator.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const String appGroupId = 'group.com.rafaelneves.biostats';
  static const String androidWidgetProvider = 'BiostatsWidgetProvider';

  static bool get isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (isTestEnvironment || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Aviso ao inicializar HomeWidget: $e');
    }
  }

  /// Sincroniza dados com o widget da tela inicial
  Future<void> updateWidgetData({
    required List<Pesagem> pesagens,
    UserProfile? profile,
  }) async {
    if (isTestEnvironment || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      if (pesagens.isEmpty) {
        await HomeWidget.saveWidgetData<String>('weight_value', '--');
        await HomeWidget.saveWidgetData<String>('weight_unit', 'kg');
        await HomeWidget.saveWidgetData<String>('trend_label', 'Sem registros');
        await HomeWidget.saveWidgetData<String>('streak_label', '0 dias');
      } else {
        // Ordena por data decrescente
        final sorted = List<Pesagem>.from(pesagens)
          ..sort((a, b) => b.data.compareTo(a.data));
        final latest = sorted.first;

        // Tendência EMA
        final emaSeries = WeightTrendCalculator.computeEma(pesagens, alpha: 0.1);
        final latestEma =
            emaSeries.isNotEmpty ? emaSeries.last.emaWeight : null;

        // Projeção
        final projection = WeightTrendCalculator.computeProjection(
          pesagens: pesagens,
          metaPesoKg: profile?.metaPesoKg,
        );

        String trendText = 'Tendência estável';
        if (latestEma != null) {
          final diff = latest.pesoKg - latestEma;
          final diffStr = (diff >= 0 ? '+' : '') + diff.toStringAsFixed(1);
          trendText = 'EMA: ${latestEma.toStringAsFixed(1)}kg ($diffStr)';
        }

        if (projection.ratePerWeek != null &&
            projection.daysRemaining != null &&
            projection.daysRemaining! > 0) {
          trendText =
              '${projection.ratePerWeek!.toStringAsFixed(1)} kg/sem • ${projection.daysRemaining}d';
        }

        // Streak
        final streak = _computeCurrentStreak(pesagens);

        await HomeWidget.saveWidgetData<String>(
          'weight_value',
          latest.pesoKg.toStringAsFixed(1),
        );
        await HomeWidget.saveWidgetData<String>('weight_unit', 'kg');
        await HomeWidget.saveWidgetData<String>('trend_label', trendText);
        await HomeWidget.saveWidgetData<String>(
          'streak_label',
          streak > 0 ? '🔥 $streak dia${streak > 1 ? 's' : ''}' : 'Comece hoje',
        );
      }

      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        androidName: androidWidgetProvider,
        qualifiedAndroidName: 'com.rafaelneves.biostats.$androidWidgetProvider',
      );
    } catch (e) {
      debugPrint('Aviso ao atualizar widget nativo: $e');
    }
  }

  int _computeCurrentStreak(List<Pesagem> pesagens) {
    if (pesagens.isEmpty) return 0;
    final dates = pesagens
        .map((p) => DateTime(p.data.year, p.data.month, p.data.day))
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor = dates.contains(today)
        ? today
        : (dates.contains(yesterday) ? yesterday : today);

    if (!dates.contains(cursor)) return 0;

    int streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
