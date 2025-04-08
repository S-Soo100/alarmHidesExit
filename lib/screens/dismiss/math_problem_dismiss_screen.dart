import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';

/// 수학 문제를 풀어 종료하는 화면
class MathProblemDismissScreen extends AlarmDismissScreen {
  const MathProblemDismissScreen({
    super.key,
    required super.alarm,
    required super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlarmDismissBaseLayout(
      alarm: alarm,
      onDismiss: onDismiss,
      title: '수학 문제 풀기',
      subtitle: '알람을 종료하려면 수학 문제를 푸세요',
      child: const Center(
        child: Text(
          '수학 문제 화면 구현 예정',
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
