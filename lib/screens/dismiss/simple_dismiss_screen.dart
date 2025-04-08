import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';

/// 버튼을 눌러 종료하는 간단한 종료 화면
class SimpleDismissScreen extends AlarmDismissScreen {
  const SimpleDismissScreen({
    super.key,
    required super.alarm,
    required super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlarmDismissBaseLayout(
      alarm: alarm,
      onDismiss: onDismiss,
      title: '알람 종료',
      subtitle: '알람을 종료하려면 버튼을 누르세요',
      child: const Center(
        child: Text(
          '버튼을 눌러 알람을 종료하세요',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      actionButton: ElevatedButton(
        onPressed: onDismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('알람 종료하기'),
      ),
    );
  }
}
