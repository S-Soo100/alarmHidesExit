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
import 'package:alarm_hides_exit/services/alarm_sound_service.dart';
import 'package:alarm_hides_exit/utils/logger_mixin.dart';
import 'package:alarm_hides_exit/services/alarm_dismiss_service.dart';

// 알람 실행 시 사용할 백그라운드 포트 이름
const String ALARM_PORT_NAME = "alarm_port";

// 백그라운드에서 알람 표시 콜백
@pragma('vm:entry-point')
Future<void> _showAlarmNotification(int id, Map<String, dynamic> data) async {
  print("===== 알람 백그라운드 콜백 시작 =====");
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  // 초기화
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  // 알림 응답 콜백 설정
  await notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print("알람 백그라운드: 알림 응답 수신 - ${response.payload}");

      // 알람 소리 중지
      final alarmSound = AlarmSoundService();
      await alarmSound.init();
      await alarmSound.stopAlarmSound();
      print("알람 백그라운드: 알람 소리 중지 완료");

      // 알람 ID 가져오기
      final String alarmId = response.payload ?? data['id'] ?? '';

      // 알람 해제 화면 표시 요청 전송
      if (alarmId.isNotEmpty) {
        // 메인 앱으로 해제 요청 전송
        AlarmDismissService.sendDismissRequest({
          'id': alarmId,
          'title': data['title'] ?? '알람',
          'description': data['description'] ?? '알람이 울립니다!',
        });

        print("알람 백그라운드: 알람 해제 요청 전송 완료 - ID: $alarmId");
      }
    },
  );
  print("알람 백그라운드: 알림 플러그인 초기화 완료");

  // 알림 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'alarm_channel',
    '알람',
    description: '알람 앱 알림 채널',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('test_alarm'),
    playSound: true,
    enableVibration: true,
  );

  try {
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    print("알람 백그라운드: 알림 채널 생성 완료");
  } catch (e) {
    print("알람 백그라운드: 알림 채널 생성 실패 - $e");
  }

  // 알림 설정
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    '알람',
    channelDescription: '알람 앱 알림 채널',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('test_alarm'),
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    fullScreenIntent: true,
    ongoing: true,
    autoCancel: false,
    category: AndroidNotificationCategory.alarm,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    sound: 'test_alarm.mp3',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  try {
    // 알림 표시
    await notifications.show(
      id,
      data['title'] ?? '알람',
      data['description'] ?? '알람이 울립니다!',
      notificationDetails,
      payload: data['id'],
    );
    print("알람 백그라운드: 알림 표시 성공");

    // 알람 소리 재생 (무한 반복)
    final alarmSound = AlarmSoundService();
    await alarmSound.init();
    await alarmSound.playAlarmSound();
    print("알람 백그라운드: 알람 소리 재생 시작");
  } catch (e) {
    print("알람 백그라운드: 알림 표시 실패 - $e");
  }

  // 백그라운드에서 실행 중인 앱에 알람 ID 전달
  final sendPort = IsolateNameServer.lookupPortByName(ALARM_PORT_NAME);
  if (sendPort != null) {
    sendPort.send(data['id']);
    print("알람 백그라운드: 메인 isolate로 메시지 전송 성공");
  } else {
    print("알람 백그라운드: 메인 isolate 포트를 찾을 수 없음");
  }

  // 알람 리포지토리에서 알람 정보 업데이트 (일회성 알람인 경우 비활성화)
  final AlarmRepository repository = AlarmRepository();
  await repository.initialize();
  final AlarmModel? alarm = repository.getAlarm(data['id']);

  if (alarm != null && !alarm.repeatDays.contains(true)) {
    alarm.isActive = false;
    await repository.saveAlarm(alarm);
    print("알람 백그라운드: 일회성 알람 비활성화 완료");
  }

  print("===== 알람 백그라운드 콜백 종료 =====");
}

class AlarmService with LoggerMixin {
  static final AlarmService _instance = AlarmService._internal();
  final AlarmRepository _repository = AlarmRepository();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 알람 소리 서비스
  final AlarmSoundService _alarmSoundService = AlarmSoundService();

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
    log("AlarmService 초기화 시작");

    // 저장소 초기화
    await _repository.initialize();
    log("알람 저장소 초기화 완료");

    // 안드로이드 알람 매니저 초기화
    await AndroidAlarmManager.initialize();
    log("AndroidAlarmManager 초기화 완료");

    // 알람 소리 서비스 초기화
    await _alarmSoundService.init();
    log("AlarmSoundService 초기화 완료");

    // 백그라운드 포트 설정
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, ALARM_PORT_NAME);
    log("백그라운드 통신 포트 설정 완료");

    // 포트 리스너 설정
    port.listen((message) {
      // 메시지를 통해 알람 ID를 받으면, 해당 알람 정보 조회
      if (message is String) {
        log("알람 ID 수신: $message");
        final alarm = _repository.getAlarm(message);
        if (alarm != null) {
          _alarmStreamController.add(alarm);
          log("알람 스트림에 알람 추가: ${alarm.id}");
        }
      }
    });

    // 로컬 알림 초기화
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    log("로컬 알림 초기화 완료");

    // 알림 채널 생성
    await _createNotificationChannel();

    // 알람 해제 서비스 스트림 구독
    AlarmDismissService().dismissStream.listen((alarm) {
      log("알람 해제 서비스로부터 해제 요청 수신: ${alarm.id}");
      _alarmStreamController.add(alarm);
    });
    log("알람 해제 서비스 스트림 구독 완료");

    log("AlarmService 초기화 완료");
  }

  // 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    log("알림 채널 생성 시작");

    // 기존 채널 삭제 후 재생성
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.deleteNotificationChannel('alarm_channel');
    }

    // 무한 반복을 위한 새 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      '알람',
      description: '알람 앱 알림 채널',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('test_alarm'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    // 채널 등록
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      log("알림 채널 생성 완료: ${channel.id}");
    }
  }

  // 알림 응답 처리 콜백
  void _onNotificationResponse(NotificationResponse response) {
    log("알림 응답 수신: ${response.payload}");

    // 알람 소리 중지
    _alarmSoundService.stopAlarmSound();
    log("알람 소리 중지");

    // 알림 터치 시 알람 정보 조회하여 스트림에 추가
    if (response.payload != null) {
      // 기존 알람 조회
      final alarm = _repository.getAlarm(response.payload!);

      if (alarm != null) {
        _alarmStreamController.add(alarm);
        log("기존 알람 스트림에 추가: ${alarm.id}");
      } else {
        // 알람 정보가 없는 경우 (백그라운드에서 시작된 알람일 수 있음)
        // 임시 알람 생성
        final DateTime now = DateTime.now();
        final AlarmModel tempAlarm = AlarmModel(
          id: response.payload!,
          title: '알람',
          description: '${DateFormat('HH:mm:ss').format(now)}에 생성된 알람',
          time: now,
          repeatDays: List.filled(7, false),
        );

        _alarmStreamController.add(tempAlarm);
        log("임시 알람 스트림에 추가: ${tempAlarm.id}");
      }
    }
  }

  // 모든 알람 스케줄링
  Future<void> scheduleAllAlarms() async {
    log("모든 알람 스케줄링 시작");

    final alarms = _repository.getAllAlarms();
    log("총 ${alarms.length}개 알람 검색됨");

    for (final alarm in alarms) {
      if (alarm.isActive) {
        await scheduleAlarm(alarm);
        log("알람 스케줄링 완료: ${alarm.id}, 시간: ${formatAlarmTime(alarm.time)}");
      } else {
        await cancelAlarm(alarm.id);
        log("비활성 알람 취소: ${alarm.id}");
      }
    }

    log("모든 알람 스케줄링 완료");
  }

  // 알람 스케줄링
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    log("알람 스케줄링 시작: ${alarm.id}, 제목: ${alarm.title}");

    // 이전 알람 취소
    await cancelAlarm(alarm.id);

    if (!alarm.isActive) {
      log("알람이 비활성 상태여서 스케줄링 취소");
      return;
    }

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

    log("초기 예정 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}");

    // 반복 설정이 있는 경우
    if (alarm.repeatDays.contains(true)) {
      log("반복 알람 감지됨: ${alarm.repeatDays}");

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
            log(
              "다음 알람 시간 계산됨: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}",
            );
            break;
          }
        }
      }

      // 오늘 설정된 시간이 이미 지난 경우, 다음 반복 설정된 날짜로 설정
      if (!isScheduledForToday) {
        log("오늘 설정된 시간이 이미 지남, 다음 반복 알람 찾는 중");
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
            log(
              "다음 알람 날짜 계산됨: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}",
            );
            break;
          }
        }
      }
    } else {
      log("일회성 알람 감지됨");
      // 일회성 알람이고 시간이 지난 경우 다음 날로 설정
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        log(
          "알람 시간이 지나서 내일로 설정: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}",
        );
      }
    }

    log("최종 알람 예정 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledTime)}");

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

    log("알람 스케줄링 완료: ID ${alarmId}");
  }

  // 알람 취소
  Future<void> cancelAlarm(String id) async {
    log("알람 취소 시작: $id");
    final int alarmId = id.hashCode;
    await AndroidAlarmManager.cancel(alarmId);
    await _notificationsPlugin.cancel(alarmId);

    // 알람 소리 중지
    await _alarmSoundService.stopAlarmSound();
    log("알람 소리 중지 완료");

    log("알람 취소 완료: $id (해시: $alarmId)");
  }

  // 알람 추가
  Future<void> addAlarm(AlarmModel alarm) async {
    log(
      "알람 추가: ${alarm.id}, 제목: ${alarm.title}, 시간: ${formatAlarmTime(alarm.time)}",
    );
    await _repository.saveAlarm(alarm);
    await scheduleAlarm(alarm);
    log("알람 추가 완료");
  }

  // 알람 업데이트
  Future<void> updateAlarm(AlarmModel alarm) async {
    log("알람 업데이트: ${alarm.id}, 제목: ${alarm.title}, 활성: ${alarm.isActive}");
    await _repository.saveAlarm(alarm);
    if (alarm.isActive) {
      await scheduleAlarm(alarm);
      log("업데이트된 알람 재스케줄링 완료");
    } else {
      await cancelAlarm(alarm.id);
      log("업데이트된 알람 비활성화로 인해 취소됨");
    }
  }

  // 알람 삭제
  Future<void> deleteAlarm(String id) async {
    log("알람 삭제: $id");
    await _repository.deleteAlarm(id);
    await cancelAlarm(id);
    log("알람 삭제 및 취소 완료");
  }

  // 알람 토글
  Future<void> toggleAlarm(String id, bool isActive) async {
    log("알람 토글: $id, 활성화: $isActive");
    await _repository.toggleAlarm(id, isActive);
    final alarm = _repository.getAlarm(id);
    if (alarm != null) {
      if (isActive) {
        await scheduleAlarm(alarm);
        log("알람 활성화 및 스케줄링 완료");
      } else {
        await cancelAlarm(id);
        log("알람 비활성화 및 취소 완료");
      }
    }
  }

  // 알람 시간 포맷팅
  String formatAlarmTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // 알람 종료
  void dismissAlarm(String id) {
    log("알람 종료 시작: $id");

    try {
      // 알람 소리 중지 (최대 3번 시도)
      for (int i = 0; i < 3; i++) {
        try {
          _alarmSoundService.stopAlarmSound();
          log("알람 소리 중지 완료 (시도 ${i + 1})");
          break; // 성공하면 반복 종료
        } catch (e) {
          log("알람 소리 중지 실패 (시도 ${i + 1}): $e");
          // 마지막 시도가 아니면 잠시 대기
          if (i < 2) {
            Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      // 알람 소리 및 알림 종료
      cancelAlarm(id);

      // 모든 알림 취소 (추가 안전 장치)
      _notificationsPlugin.cancelAll();
      log("모든 알림 취소 완료");

      // 알람 ID에 해당하는 알림 취소
      final int alarmId = id.hashCode;
      _notificationsPlugin.cancel(alarmId);
      log("알림 ID $alarmId 취소 완료");

      // 일회성 알람인 경우 자동으로 비활성화
      final alarm = _repository.getAlarm(id);
      if (alarm != null && !alarm.repeatDays.contains(true)) {
        alarm.isActive = false;
        _repository.saveAlarm(alarm);
        log("일회성 알람 비활성화 완료");
      }

      // Android 시스템 단에서도 알람 취소 확인
      final int systemAlarmId = id.hashCode;
      AndroidAlarmManager.cancel(systemAlarmId);
      log("알람 ID $systemAlarmId 한번 더 취소 확인");

      log("알람 종료 완료: $id");
    } catch (e) {
      log("알람 종료 중 오류 발생: $e");

      // 오류가 발생해도 알람은 반드시 중지
      try {
        final int alarmId = id.hashCode;
        AndroidAlarmManager.cancel(alarmId);
        _notificationsPlugin.cancelAll();
        _alarmSoundService.stopAlarmSound();
        log("오류 발생 후 모든 알람 및 알림 강제 취소");
      } catch (e2) {
        log("강제 취소 중 오류: $e2");
      }
    }
  }

  // 자원 해제
  void dispose() {
    log("AlarmService 종료");
    _alarmStreamController.close();
    _alarmSoundService.dispose();
    log("알람 서비스 완전 종료");
  }
}
