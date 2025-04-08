import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/models/alarm_dismiss_type.dart';
import 'package:alarm_hides_exit/screens/dismiss/simple_dismiss_screen.dart';
import 'package:alarm_hides_exit/screens/dismiss/math_problem_dismiss_screen.dart';
import 'package:alarm_hides_exit/screens/dismiss/typing_text_dismiss_screen.dart';
import 'package:alarm_hides_exit/screens/dismiss/english_word_dismiss_screen.dart';

/// 알람 종료 상호작용의 기본 인터페이스
abstract class AlarmDismissScreen extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onDismiss;

  const AlarmDismissScreen({
    super.key,
    required this.alarm,
    required this.onDismiss,
  });

  /// 알람 종료 화면 팩토리 메서드
  static Widget create({
    required AlarmModel alarm,
    required VoidCallback onDismiss,
  }) {
    switch (alarm.dismissType) {
      case AlarmDismissType.mathProblem:
        return MathProblemDismissScreen(alarm: alarm, onDismiss: onDismiss);
      case AlarmDismissType.typingText:
        return TypingTextDismissScreen(alarm: alarm, onDismiss: onDismiss);
      case AlarmDismissType.englishWord:
        return EnglishWordDismissScreen(alarm: alarm, onDismiss: onDismiss);
      case AlarmDismissType.none:
      default:
        return SimpleDismissScreen(alarm: alarm, onDismiss: onDismiss);
    }
  }
}

/// 알람 종료 화면의 기본 레이아웃
class AlarmDismissBaseLayout extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onDismiss;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? actionButton;

  const AlarmDismissBaseLayout({
    super.key,
    required this.alarm,
    required this.onDismiss,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // 알람 시간 및 제목
              Text(
                alarm.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // 종료 상호작용 컨텐츠
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // 상호작용 내용
                      Expanded(child: child),

                      // 액션 버튼
                      if (actionButton != null) actionButton!,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
