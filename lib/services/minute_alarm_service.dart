import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:logger/web.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alarm_hides_exit/utils/logger_mixin.dart';
import 'package:alarm_hides_exit/services/alarm_sound_service.dart';
import 'package:alarm_hides_exit/services/alarm_dismiss_service.dart';

// 백그라운드 알람을 위한 콜백
@pragma('vm:entry-point')
void showMinuteAlarmCallback() async {
  var logger = Logger(printer: PrettyPrinter());
  logger.w("===== 1분 알람 백그라운드 콜백 시작 =====");

  // 알림 플러그인 인스턴스 생성
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 초기화
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  // 알림 응답 콜백 설정
  await notificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      logger.w("백그라운드 알림 응답 수신: ${response.payload}");

      // 알람 소리 중지
      final alarmSound = AlarmSoundService();
      await alarmSound.init();
      await alarmSound.stopAlarmSound();
      logger.w("백그라운드 알람 소리 중지 완료");

      // 알림 취소
      await notificationsPlugin.cancel(DateTime.now().second);
      logger.w("백그라운드 알림 취소 완료");

      // 알람 해제 화면 표시 요청
      final DateTime now = DateTime.now();
      final String timeStr = DateFormat('HH:mm:ss').format(now);
      final String alarmId = const Uuid().v4();

      // 메인 앱으로 해제 요청 전송
      AlarmDismissService.sendDismissRequest({
        'id': alarmId,
        'title': '1분 알람 (백그라운드)',
        'description': '$timeStr에 생성된 알람',
      });

      logger.w("알람 해제 요청 전송 완료: $alarmId");
    },
  );

  logger.w("백그라운드 알람: 알림 플러그인 초기화 완료");

  // 알림 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'minute_alarm_channel', // id
    '1분 알람', // name
    description: '1분마다 알람을 표시합니다',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('test_alarm'),
    playSound: true,
    enableVibration: true,
  );

  try {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    logger.w("백그라운드 알람: 알림 채널 생성 완료");
  } catch (e) {
    logger.w("백그라운드 알람: 알림 채널 생성 실패 - $e");
  }

  // 알림 표시
  final DateTime now = DateTime.now();
  final String timeStr = DateFormat('HH:mm:ss').format(now);
  logger.w("백그라운드 알람: 현재 시간 - $timeStr");

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'minute_alarm_channel',
    '1분 알람',
    channelDescription: '1분마다 알람을 표시합니다',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('test_alarm'),
    enableVibration: true,
    visibility: NotificationVisibility.public,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    ongoing: true,
    autoCancel: false,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  try {
    await notificationsPlugin.show(
      now.second, // 알림 ID (고유해야 함)
      '1분 알람 (백그라운드)',
      '현재 시간: $timeStr',
      notificationDetails,
      payload: now.second.toString(), // 알림 ID를 payload로 전달
    );
    logger.w("백그라운드 알람: 알림 표시 성공");

    // 알람 소리 재생 (무한 반복)
    final alarmSound = AlarmSoundService();
    await alarmSound.init();
    await alarmSound.playAlarmSound();
    logger.w("백그라운드 알람: 알람 소리 재생 시작");
  } catch (e) {
    logger.w("백그라운드 알람: 알림 표시 실패 - $e");
  }

  // 메인 isolate에 메시지 전송 (앱이 활성화 상태일 때만 작동)
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(
    'minute_alarm_port',
  );
  if (sendPort != null) {
    sendPort.send('show_alarm');
    logger.w("백그라운드 알람: 메인 isolate로 메시지 전송 성공");
  } else {
    logger.w("백그라운드 알람: 메인 isolate 포트를 찾을 수 없음");
  }

  logger.w("===== 1분 알람 백그라운드 콜백 종료 =====");
}

class MinuteAlarmService with LoggerMixin {
  static final MinuteAlarmService _instance = MinuteAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final int _alarmId = 42; // 1분 알람용 고유 ID
  final StreamController<AlarmModel> _alarmStreamController =
      StreamController<AlarmModel>.broadcast();
  Stream<AlarmModel> get alarmStream => _alarmStreamController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  // 백그라운드 통신용 포트
  ReceivePort? _receivePort;

  final AlarmSoundService _alarmSoundService = AlarmSoundService();
  final AlarmDismissService _alarmDismissService = AlarmDismissService();

  factory MinuteAlarmService() {
    return _instance;
  }

  MinuteAlarmService._internal();

  Future<void> init() async {
    log("MinuteAlarmService 초기화 시작");

    // 안드로이드 알람 매니저 초기화
    await AndroidAlarmManager.initialize();
    log("AndroidAlarmManager 초기화 완료");

    // 알람 소리 서비스 초기화
    await _alarmSoundService.init();
    log("AlarmSoundService 초기화 완료");

    // 알람 해제 서비스 초기화
    await _alarmDismissService.init();
    log("AlarmDismissService 초기화 완료");

    // 알람 해제 스트림 구독 - 백그라운드에서 들어오는 알람 해제 요청 처리
    _alarmDismissService.dismissStream.listen((alarm) {
      log("알람 해제 서비스로부터 해제 요청 수신: ${alarm.id}");
      _alarmStreamController.add(alarm);
    });

    // 권한 확인 및 요청
    await _checkAndRequestPermissions();

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

    // 알림 채널 생성 - 안드로이드 8.0 이상에서 필요
    await _createNotificationChannel();

    // 백그라운드 통신 설정
    _setupBackgroundChannel();
    log("MinuteAlarmService 초기화 완료");
  }

  Future<void> _checkAndRequestPermissions() async {
    // 알림 권한 확인
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      await Permission.notification.request();
    }

    // 알람 권한 확인 (Android 13+)
    final alertWindowStatus = await Permission.systemAlertWindow.status;
    if (alertWindowStatus.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    // 정확한 알람 권한 (Android 12+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (exactAlarmStatus.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> _createNotificationChannel() async {
    log("알림 채널 생성 시작");

    // 기존 채널 삭제 후 재생성
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.deleteNotificationChannel('minute_alarm_channel');
    }

    // 무한 반복을 위한 새 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'minute_alarm_channel',
      '1분 알람',
      description: '1분마다 알람을 표시합니다',
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

  void _setupBackgroundChannel() {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'minute_alarm_port',
    );

    _receivePort!.listen((message) {
      if (message == 'show_alarm') {
        _showAlarm();
      }
    });
  }

  void _onNotificationResponse(NotificationResponse response) {
    log("알림 응답 수신: ${response.payload}");
    if (response.payload != null) {
      // 알람 소리 중지 (하지만 알람은 아직 완전히 해제하지 않음)
      _alarmSoundService.stopAlarmSound();
      log("알람 소리 임시 중지");

      // 알림 ID 가져오기
      final int notificationId = int.tryParse(response.payload!) ?? 0;

      // 현재 시간 정보로 알람 모델 생성
      final DateTime now = DateTime.now();
      final String timeStr = DateFormat('HH:mm:ss').format(now);

      // 해제 화면에 전달할 알람 모델 생성
      final AlarmModel alarm = AlarmModel(
        id: const Uuid().v4(), // 고유 ID 생성
        title: '1분 알람',
        description: '$timeStr에 생성된 알람',
        time: now,
        repeatDays: List.filled(7, false),
      );

      // 알람 모델을 스트림에 추가하여 해제 화면 표시
      _alarmStreamController.add(alarm);
      log("알람 해제 화면 표시 요청: ${alarm.id}");
    }
  }

  Future<void> startMinuteAlarm() async {
    if (_isRunning) {
      await stopMinuteAlarm();
    }

    _isRunning = true;

    // 즉시 첫 번째 알람 표시
    await _showAlarm();

    // 1분마다 알람 반복 설정 (wakeup: true로 설정하여 기기가 잠자기 모드일 때도 알람 작동)
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      _alarmId,
      showMinuteAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  Future<void> stopMinuteAlarm() async {
    log("1분 알람 중지 시작");

    // 백그라운드 알람 매니저 취소
    try {
      await AndroidAlarmManager.cancel(_alarmId);
      log("AndroidAlarmManager 알람 취소 완료");
    } catch (e) {
      log("AndroidAlarmManager 알람 취소 실패: $e");
    }

    // 모든 알림 취소
    try {
      await _notificationsPlugin.cancelAll();
      log("모든 알림 취소 완료");
    } catch (e) {
      log("알림 취소 실패: $e");
    }

    // 알람 소리 중지 (최대 3번 시도)
    for (int i = 0; i < 3; i++) {
      try {
        await _alarmSoundService.stopAlarmSound();
        log("알람 소리 중지 완료 (시도 ${i + 1})");
        break; // 성공하면 반복 종료
      } catch (e) {
        log("알람 소리 중지 실패 (시도 ${i + 1}): $e");
        // 마지막 시도가 아니면 잠시 대기 후 재시도
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    // 상태 업데이트
    _isRunning = false;

    // Android 시스템 단에서도 알람 취소 확인
    try {
      await AndroidAlarmManager.cancel(_alarmId);
      log("알람 ID $_alarmId 한번 더 취소 확인");
    } catch (e) {
      log("추가 취소 시도 중 오류: $e");
    }

    log("1분 알람 중지 완료");
  }

  Future<void> _showAlarm() async {
    final String id = const Uuid().v4();
    final DateTime now = DateTime.now();
    final String timeStr = DateFormat('HH:mm:ss').format(now);
    log("1분 알람 표시 시작 - 시간: $timeStr, ID: $id");

    // 알림에 사용할 ID (0-59 사이의 값, 초 단위로 사용)
    final int notificationId = now.second;
    log("알림 ID: $notificationId");

    // 알림 설정
    AndroidNotificationDetails androidDetails =
        const AndroidNotificationDetails(
          'minute_alarm_channel',
          '1분 알람',
          channelDescription: '1분마다 알람을 표시합니다',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('test_alarm'),
          enableVibration: true,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          ongoing: true, // 사용자가 취소할 때까지 계속 표시
          autoCancel: false, // 사용자가 탭해도 자동으로 취소되지 않음
          ticker: '새로운 1분 알람이 발생했습니다',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'test_alarm.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 알림 표시
    try {
      await _notificationsPlugin.show(
        notificationId, // 알림 ID (0-59 사이)
        '1분 알람',
        '현재 시간: $timeStr',
        notificationDetails,
        payload: "$notificationId", // 알림 ID를 payload로 전달
      );
      log("알림 표시 성공, ID: $notificationId");

      // 알람 소리 재생 (무한 반복)
      await _alarmSoundService.playAlarmSound();
      log("알람 소리 재생 시작");
    } catch (e) {
      log("알림 표시 실패: $e");
    }

    // 알람 모델 생성 및 스트림에 추가
    final AlarmModel alarm = AlarmModel(
      id: id,
      title: '1분 알람',
      description: '$timeStr에 생성된 알람',
      time: now,
      repeatDays: List.filled(7, false),
    );

    _alarmStreamController.add(alarm);
    log("알람 스트림에 알람 추가 완료");
  }

  void dispose() {
    log("MinuteAlarmService 종료 시작");

    // 알람 중지
    stopMinuteAlarm();

    // 스트림 컨트롤러 닫기
    try {
      if (!_alarmStreamController.isClosed) {
        _alarmStreamController.close();
        log("알람 스트림 컨트롤러 닫기 완료");
      }
    } catch (e) {
      log("알람 스트림 컨트롤러 닫기 실패: $e");
    }

    // 알람 소리 서비스 정리
    try {
      _alarmSoundService.dispose();
      log("알람 소리 서비스 종료 완료");
    } catch (e) {
      log("알람 소리 서비스 종료 실패: $e");
    }

    // 백그라운드 통신 정리
    try {
      if (_receivePort != null) {
        _receivePort!.close();
        IsolateNameServer.removePortNameMapping('minute_alarm_port');
        log("백그라운드 통신 채널 정리 완료");
      }
    } catch (e) {
      log("백그라운드 통신 채널 정리 실패: $e");
    }

    log("MinuteAlarmService 종료 완료");
  }
}
