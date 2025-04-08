// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_dismiss_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmDismissTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
