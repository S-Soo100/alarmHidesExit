import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';

/// 텍스트를 입력하여 종료하는 화면
class TypingTextDismissScreen extends AlarmDismissScreen {
  const TypingTextDismissScreen({
    super.key,
    required super.alarm,
    required super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlarmDismissBaseLayout(
      alarm: alarm,
      onDismiss: onDismiss,
      title: '텍스트 입력하기',
      subtitle: '알람을 종료하려면 텍스트를 정확히 입력하세요',
      child: const Center(
        child: Text(
          '텍스트 입력 화면 구현 예정',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      actionButton: ElevatedButton(
        onPressed: onDismiss, // 실제 구현 시 텍스트 일치 확인 후 종료 처리
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('확인하기'),
      ),
    );
  }
}
