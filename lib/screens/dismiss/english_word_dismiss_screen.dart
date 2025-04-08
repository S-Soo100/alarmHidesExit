import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';

/// 영어 단어 뜻을 맞춰 종료하는 화면
class EnglishWordDismissScreen extends AlarmDismissScreen {
  const EnglishWordDismissScreen({
    super.key,
    required super.alarm,
    required super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlarmDismissBaseLayout(
      alarm: alarm,
      onDismiss: onDismiss,
      title: '영어 단어 맞추기',
      subtitle: '알람을 종료하려면 영어 단어의 뜻을 맞추세요',
      child: const Center(
        child: Text(
          '영어 단어 퀴즈 화면 구현 예정',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      actionButton: ElevatedButton(
        onPressed: onDismiss, // 실제 구현 시 정답 확인 후 종료 처리
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('정답 제출하기'),
      ),
    );
  }
}
