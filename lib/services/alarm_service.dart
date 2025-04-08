import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/repositories/alarm_repository.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';
import 'package:intl/intl.dart';

// 알람 실행 시 사용할 백그라운드 포트 이름
const String ALARM_PORT_NAME = "alarm_port";

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  final AlarmRepository _repository = AlarmRepository();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 앱이 실행 중일 때 알람을 처리하기 위한 컨트롤러
  final StreamController<AlarmModel> _alarmStreamController =
      StreamController<AlarmModel>.broadcast();
  Stream<AlarmModel> get alarmStream => _alarmStreamController.stream;

  factory AlarmService() {
    return _instance;
  }

  AlarmService._internal();

  // 알람 서비스 초기화
  Future<void> init() async {
    // 저장소 초기화
    await _repository.initialize();

    // 안드로이드 알람 매니저 초기화
    await AndroidAlarmManager.initialize();

    // 백그라운드 포트 설정
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, ALARM_PORT_NAME);

    // 포트 리스너 설정
    port.listen((message) {
      // 메시지를 통해 알람 ID를 받으면, 해당 알람 정보 조회
      if (message is String) {
        final alarm = _repository.getAlarm(message);
        if (alarm != null) {
          _alarmStreamController.add(alarm);
        }
      }
    });

    // 로컬 알림 초기화
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings
    iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: _onDidReceiveLocalNotification, //todo 업데이트로 인해 변경됨
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  // iOS에서 알림 수신 시 호출될 콜백
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // iOS에서 알림을 받았을 때 처리
    if (payload != null) {
      final port = IsolateNameServer.lookupPortByName(ALARM_PORT_NAME);
      port?.send(payload);
    }
  }

  // 알림 응답 처리 콜백
  void _onNotificationResponse(NotificationResponse response) {
    // 알림 터치 시 알람 정보 조회하여 스트림에 추가
    if (response.payload != null) {
      final alarm = _repository.getAlarm(response.payload!);
      if (alarm != null) {
        _alarmStreamController.add(alarm);
      }
    }
  }

  // 모든 알람 스케줄링
  Future<void> scheduleAllAlarms() async {
    final alarms = _repository.getAllAlarms();
    for (final alarm in alarms) {
      if (alarm.isActive) {
        await scheduleAlarm(alarm);
      } else {
        await cancelAlarm(alarm.id);
      }
    }
  }

  // 알람 스케줄링
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    // 이전 알람 취소
    await cancelAlarm(alarm.id);

    if (!alarm.isActive) return;

    // 알람 ID 생성 (고유값) - UUID를 해시코드로 변환하여 정수 ID 생성
    final int alarmId = alarm.id.hashCode;

    // 알람 시간 계산
    final DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // 반복 설정이 있는 경우
    if (alarm.repeatDays.contains(true)) {
      // 현재 요일 (1: 월요일, 7: 일요일)
      final int today = now.weekday;
      bool isScheduledForToday = false;

      // 오늘 이후의 날짜 중에서 반복 설정된 날짜 찾기
      for (int i = 0; i < 7; i++) {
        final int checkDay = (today + i - 1) % 7;
        if (alarm.repeatDays[checkDay]) {
          scheduledTime = now.add(Duration(days: i));
          scheduledTime = DateTime(
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
            alarm.time.hour,
            alarm.time.minute,
          );

          // 시간이 현재보다 이후인 경우
          if (scheduledTime.isAfter(now)) {
            isScheduledForToday = true;
            break;
          }
        }
      }

      // 오늘 설정된 시간이 이미 지난 경우, 다음 반복 설정된 날짜로 설정
      if (!isScheduledForToday) {
        for (int i = 1; i <= 7; i++) {
          final int checkDay = (today + i - 1) % 7;
          if (alarm.repeatDays[checkDay]) {
            scheduledTime = now.add(Duration(days: i));
            scheduledTime = DateTime(
              scheduledTime.year,
              scheduledTime.month,
              scheduledTime.day,
              alarm.time.hour,
              alarm.time.minute,
            );
            break;
          }
        }
      }
    } else {
      // 일회성 알람이고 시간이 지난 경우 다음 날로 설정
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    }

    // 안드로이드 알람 매니저로 백그라운드 알람 설정
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      alarmId,
      _showAlarmNotification,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'id': alarm.id,
        'title': alarm.title,
        'description': alarm.description,
      },
    );
  }

  // 알람 취소
  Future<void> cancelAlarm(String id) async {
    final int alarmId = id.hashCode;
    await AndroidAlarmManager.cancel(alarmId);
    await _notificationsPlugin.cancel(alarmId);
  }

  // 알람 추가
  Future<void> addAlarm(AlarmModel alarm) async {
    await _repository.saveAlarm(alarm);
    await scheduleAlarm(alarm);
  }

  // 알람 업데이트
  Future<void> updateAlarm(AlarmModel alarm) async {
    await _repository.saveAlarm(alarm);
    if (alarm.isActive) {
      await scheduleAlarm(alarm);
    } else {
      await cancelAlarm(alarm.id);
    }
  }

  // 알람 삭제
  Future<void> deleteAlarm(String id) async {
    await _repository.deleteAlarm(id);
    await cancelAlarm(id);
  }

  // 알람 토글
  Future<void> toggleAlarm(String id, bool isActive) async {
    await _repository.toggleAlarm(id, isActive);
    final alarm = _repository.getAlarm(id);
    if (alarm != null) {
      if (isActive) {
        await scheduleAlarm(alarm);
      } else {
        await cancelAlarm(id);
      }
    }
  }

  // 알람 알림 표시 (콜백)
  static Future<void> _showAlarmNotification(
    int id,
    Map<String, dynamic> data,
  ) async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // 알림 설정
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'alarm_channel',
          '알람',
          channelDescription: '알람 앱 알림 채널',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 알림 표시
    await notifications.show(
      id,
      data['title'] ?? '알람',
      data['description'] ?? '알람이 울립니다!',
      notificationDetails,
      payload: data['id'],
    );

    // 백그라운드에서 실행 중인 앱에 알람 ID 전달
    final sendPort = IsolateNameServer.lookupPortByName(ALARM_PORT_NAME);
    sendPort?.send(data['id']);

    // 알람 리포지토리에서 알람 정보 업데이트 (일회성 알람인 경우 비활성화)
    final AlarmRepository repository = AlarmRepository();
    await repository.initialize();
    final AlarmModel? alarm = repository.getAlarm(data['id']);

    if (alarm != null && !alarm.repeatDays.contains(true)) {
      alarm.isActive = false;
      await repository.saveAlarm(alarm);
    }
  }

  // 알람 시간 포맷팅
  String formatAlarmTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // 알람 종료
  void dismissAlarm(String id) {
    // 알람 소리 및 알림 종료
    cancelAlarm(id);

    // 일회성 알람인 경우 자동으로 비활성화
    final alarm = _repository.getAlarm(id);
    if (alarm != null && !alarm.repeatDays.contains(true)) {
      alarm.isActive = false;
      _repository.saveAlarm(alarm);
    }
  }

  // 자원 해제
  void dispose() {
    _alarmStreamController.close();
  }
}
