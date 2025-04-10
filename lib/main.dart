import 'package:alarm_hides_exit/models/alarm_dismiss_type.dart';
import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';
import 'package:alarm_hides_exit/screens/home_screen.dart';
import 'package:alarm_hides_exit/services/alarm_service.dart';
import 'package:alarm_hides_exit/services/minute_alarm_service.dart';
import 'package:alarm_hides_exit/utils/app_initializer.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();

  // Hive 어댑터 등록 - typeId가 참조되는 순서대로 등록 필요
  Hive.registerAdapter(AlarmDismissTypeAdapter()); // typeId: 1
  Hive.registerAdapter(AlarmModelAdapter()); // typeId: 0
  await Hive.openBox<AlarmModel>('alarms');

  // 앱 초기화
  await AppInitializer.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AlarmService _alarmService = AlarmService();
  final MinuteAlarmService _minuteAlarmService = MinuteAlarmService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // 일반 알람 스트림 리스너 설정
    _alarmService.alarmStream.listen(_showAlarmDismissScreen);

    // 1분 알람 스트림 리스너 설정
    _minuteAlarmService.alarmStream.listen(_showMinuteAlarmDismissScreen);
  }

  @override
  void dispose() {
    _alarmService.dispose();
    _minuteAlarmService.dispose();
    super.dispose();
  }

  // 일반 알람 종료 화면 표시
  void _showAlarmDismissScreen(AlarmModel alarm) {
    // dismissType이 null이면 none으로 설정
    final AlarmModel alarmWithDismissType =
        alarm.dismissType != null
            ? alarm
            : AlarmModel(
              id: alarm.id,
              title: alarm.title,
              description: alarm.description,
              time: alarm.time,
              isActive: alarm.isActive,
              repeatDays: alarm.repeatDays,
              soundPath: alarm.soundPath,
              vibrate: alarm.vibrate,
              dismissType: AlarmDismissType.none,
            );

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (context) => AlarmDismissScreen.create(
              alarm: alarmWithDismissType,
              onDismiss: () {
                // 알람 종료
                _alarmService.dismissAlarm(alarm.id);

                // 추가 안전장치: 알람 소리 다시 한번 중지 시도
                Future.delayed(const Duration(milliseconds: 500), () {
                  _alarmService.dismissAlarm(alarm.id);
                });

                // 종료 화면 닫기
                _navigatorKey.currentState?.pop();
              },
            ),
      ),
    );
  }

  // 1분 알람 종료 화면 표시
  void _showMinuteAlarmDismissScreen(AlarmModel alarm) {
    // dismissType이 null이면 none으로 설정
    final AlarmModel alarmWithDismissType =
        // ignore: unnecessary_null_comparison
        alarm.dismissType != null
            ? alarm
            : AlarmModel(
              id: alarm.id,
              title: alarm.title,
              description: alarm.description,
              time: alarm.time,
              isActive: alarm.isActive,
              repeatDays: alarm.repeatDays,
              soundPath: alarm.soundPath,
              vibrate: alarm.vibrate,
              dismissType: AlarmDismissType.none,
            );

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (context) => AlarmDismissScreen.create(
              alarm: alarmWithDismissType,
              onDismiss: () {
                // 알림 취소 및 알람 중지
                _minuteAlarmService.stopMinuteAlarm();

                // 추가 안전장치: 알람 소리 다시 한번 중지 시도
                Future.delayed(const Duration(milliseconds: 500), () {
                  _minuteAlarmService.stopMinuteAlarm();
                });

                // 종료 화면 닫기
                _navigatorKey.currentState?.pop();
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '알람 앱',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
