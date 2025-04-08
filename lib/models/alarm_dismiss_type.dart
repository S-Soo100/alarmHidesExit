import 'package:hive/hive.dart';

part 'alarm_dismiss_type.g.dart';

/// 알람 종료 상호작용 유형 정의
@HiveType(typeId: 1)
enum AlarmDismissType {
  @HiveField(0)
  none, // 버튼 눌러서 종료

  @HiveField(1)
  mathProblem, // 수학 문제 풀기

  @HiveField(2)
  typingText, // 텍스트 따라서 치기

  @HiveField(3)
  englishWord, // 영어 단어 뜻 맞추기
}
