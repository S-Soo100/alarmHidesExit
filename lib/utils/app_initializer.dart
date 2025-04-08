import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/models/alarm_dismiss_type.dart';
import 'package:alarm_hides_exit/services/alarm_service.dart';

/// 앱 초기화를 담당하는 클래스
class AppInitializer {
  /// 앱 실행 전 필요한 초기화 작업 수행
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 알람 서비스 초기화
    final alarmService = AlarmService();
    await alarmService.init();

    // 저장된 모든 알람 일정 설정
    await alarmService.scheduleAllAlarms();
  }
}
