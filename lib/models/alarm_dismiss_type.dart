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

// AlarmDismissType 어댑터
class AlarmDismissTypeAdapter extends TypeAdapter<AlarmDismissType> {
  @override
  final int typeId = 1;

  @override
  AlarmDismissType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmDismissType.none;
      case 1:
        return AlarmDismissType.mathProblem;
      case 2:
        return AlarmDismissType.typingText;
      case 3:
        return AlarmDismissType.englishWord;
      default:
        return AlarmDismissType.none;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmDismissType obj) {
    switch (obj) {
      case AlarmDismissType.none:
        writer.writeByte(0);
        break;
      case AlarmDismissType.mathProblem:
        writer.writeByte(1);
        break;
      case AlarmDismissType.typingText:
        writer.writeByte(2);
        break;
      case AlarmDismissType.englishWord:
        writer.writeByte(3);
        break;
    }
  }
}
