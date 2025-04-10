import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/models/alarm_dismiss_type.dart';
import 'package:alarm_hides_exit/services/alarm_service.dart';
import 'package:alarm_hides_exit/services/minute_alarm_service.dart';
import 'package:alarm_hides_exit/services/alarm_dismiss_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

/// 앱 초기화를 담당하는 클래스
class AppInitializer {
  /// 앱 실행 전 필요한 초기화 작업 수행
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // AndroidAlarmManager 초기화
    await AndroidAlarmManager.initialize();

    // 알람 서비스 초기화
    final alarmService = AlarmService();
    await alarmService.init();

    // 1분 알람 서비스 초기화
    final minuteAlarmService = MinuteAlarmService();
    await minuteAlarmService.init();

    // 알람 해제 서비스 초기화
    final alarmDismissService = AlarmDismissService();
    await alarmDismissService.init();

    // 저장된 모든 알람 일정 설정
    await alarmService.scheduleAllAlarms();
  }
}
