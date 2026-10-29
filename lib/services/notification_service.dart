import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Retorna true se estiver rodando em ambiente de testes automatizados
  static bool get isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (isTestEnvironment) {
      _isInitialized = true;
      return;
    }
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (isTestEnvironment) return true;
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted =
            await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao solicitar permissões de notificação: $e');
      return false;
    }
  }

  Future<void> scheduleDailyWeightReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (isTestEnvironment) return;
    try {
      const int notificationId = 101;
      await _notificationsPlugin.cancel(id: notificationId);
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'biostats_daily_weight',
        'Pesagem Diária',
        channelDescription:
            'Lembretes matinais para registro de pesagem em jejum',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Hora da pesagem matinal ⚖️',
        body: 'Suba na balança em jejum para registrar seu peso e acompanhar sua tendência.',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Erro ao agendar lembrete diário de peso: $e');
    }
  }

  Future<void> scheduleWeeklyEvaluationReminder({
    required bool enabled,
    required int weekday, // 1 = Monday ... 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    if (isTestEnvironment) return;
    try {
      const int notificationId = 102;
      await _notificationsPlugin.cancel(id: notificationId);
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'biostats_weekly_evaluation',
        'Avaliação Semanal',
        channelDescription: 'Lembrete semanal para medição corporal e fotos',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Dia de Avaliação Física 📏',
        body: 'Registre suas medidas corporais e fotos para atualizar seu BF% e evolução.',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Erro ao agendar lembrete semanal de avaliação: $e');
    }
  }
}
