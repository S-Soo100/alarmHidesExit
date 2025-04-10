import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/utils/logger_mixin.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// 알람 해제 서비스
/// 백그라운드 알람에서도 메인 UI로 알람 해제 요청을 전달하기 위한 서비스
class AlarmDismissService with LoggerMixin {
  static final AlarmDismissService _instance = AlarmDismissService._internal();

  // 알람 해제 요청을 위한 스트림 컨트롤러
  final StreamController<AlarmModel> _dismissStreamController =
      StreamController<AlarmModel>.broadcast();

  // 알람 해제 요청을 받기 위한 스트림
  Stream<AlarmModel> get dismissStream => _dismissStreamController.stream;

  // 백그라운드 통신을 위한 포트 이름
  static const String portName = 'alarm_dismiss_port';

  // 백그라운드에서 메인으로 메시지를 전달하기 위한 포트
  ReceivePort? _receivePort;

  factory AlarmDismissService() {
    return _instance;
  }

  AlarmDismissService._internal();

  /// 서비스 초기화
  Future<void> init() async {
    log("AlarmDismissService 초기화 시작");

    // 백그라운드 통신 설정
    _setupBackgroundChannel();

    log("AlarmDismissService 초기화 완료");
  }

  /// 백그라운드 통신 채널 설정
  void _setupBackgroundChannel() {
    log("백그라운드 통신 채널 설정 시작");

    // 이미 설정된 경우 재설정
    if (_receivePort != null) {
      _receivePort!.close();
      IsolateNameServer.removePortNameMapping(portName);
    }

    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, portName);

    _receivePort!.listen((message) {
      log("백그라운드에서 메시지 수신: $message");

      if (message is Map<String, dynamic>) {
        // 알람 모델 생성
        final DateTime now = DateTime.now();
        final String timeStr = DateFormat('HH:mm:ss').format(now);

        final AlarmModel alarm = AlarmModel(
          id: message['id'] ?? const Uuid().v4(),
          title: message['title'] ?? '알람',
          description: message['description'] ?? '$timeStr에 생성된 알람',
          time: now,
          repeatDays: List.filled(7, false),
        );

        // 알람 해제 스트림에 추가
        _dismissStreamController.add(alarm);
        log("알람 해제 스트림에 알람 추가: ${alarm.id}");
      }
    });

    log("백그라운드 통신 채널 설정 완료");
  }

  /// 알람 해제 요청
  void requestDismiss(AlarmModel alarm) {
    log("알람 해제 요청: ${alarm.id}");
    _dismissStreamController.add(alarm);
  }

  /// 백그라운드에서 해제 요청 전송
  static void sendDismissRequest(Map<String, dynamic> alarmData) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(portName);
    if (sendPort != null) {
      sendPort.send(alarmData);
    }
  }

  /// 서비스 종료
  void dispose() {
    log("AlarmDismissService 종료 시작");

    // 스트림 컨트롤러 닫기
    if (!_dismissStreamController.isClosed) {
      _dismissStreamController.close();
    }

    // 백그라운드 통신 정리
    if (_receivePort != null) {
      _receivePort!.close();
      IsolateNameServer.removePortNameMapping(portName);
    }

    log("AlarmDismissService 종료 완료");
  }
}
