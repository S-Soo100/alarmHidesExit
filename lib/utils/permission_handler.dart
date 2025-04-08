import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// 알람 앱에 필요한 권한을 처리하는 유틸리티 클래스
class PermissionHandler {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// 알림 및 알람 권한 요청
  static Future<bool> requestNotificationPermissions(
    BuildContext context,
  ) async {
    bool permissionsGranted = false;

    if (Platform.isIOS) {
      // iOS 권한 요청
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      permissionsGranted = result ?? false;
    } else if (Platform.isAndroid) {
      // Android 권한 요청
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // 알림 권한 요청
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      permissionsGranted = granted ?? false;

      // Android 12 이상인 경우 정확한 알람 권한 확인
      if (await _isAlarmPermissionRequired()) {
        final status = await Permission.scheduleExactAlarm.status;

        if (status.isDenied) {
          if (await Permission.scheduleExactAlarm.request().isGranted) {
            permissionsGranted = true;
          } else {
            _showAlarmPermissionDialog(context);
            permissionsGranted = false;
          }
        } else if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog(context);
          permissionsGranted = false;
        } else {
          permissionsGranted = true;
        }
      }
    }

    return permissionsGranted;
  }

  /// Android 12 이상인지 확인 (정확한 알람 권한 필요)
  static Future<bool> _isAlarmPermissionRequired() async {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt >= 31; // Android 12 (API 31) 이상
    }
    return false;
  }

  /// 권한 거부 다이얼로그 표시
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('권한 필요'),
          content: const Text('알람 기능을 사용하기 위해서는 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  /// 알람 권한 요청 다이얼로그 표시
  static void _showAlarmPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('정확한 알람 권한 필요'),
          content: const Text('알람 앱이 정확한 시간에 알람을 울리기 위해서는 추가 권한이 필요합니다.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Permission.scheduleExactAlarm.request();
              },
              child: const Text('권한 요청'),
            ),
          ],
        );
      },
    );
  }
}
