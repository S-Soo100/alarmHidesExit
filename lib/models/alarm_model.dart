import 'package:hive/hive.dart';
import 'package:alarm_hides_exit/models/alarm_dismiss_type.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime time;

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  List<bool> repeatDays; // [월, 화, 수, 목, 금, 토, 일]

  @HiveField(6)
  String soundPath;

  @HiveField(7)
  bool vibrate;

  @HiveField(8)
  AlarmDismissType dismissType;

  AlarmModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.time,
    this.isActive = true,
    required this.repeatDays,
    this.soundPath = 'default',
    this.vibrate = true,
    this.dismissType = AlarmDismissType.none,
  });
}

// Hive 어댑터 수동 생성 (build_runner 사용 시 자동 생성됨)
class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      time: fields[3] as DateTime,
      isActive: fields[4] as bool,
      repeatDays: (fields[5] as List).cast<bool>(),
      soundPath: fields[6] as String,
      vibrate: fields[7] as bool,
      dismissType: fields[8] as AlarmDismissType? ?? AlarmDismissType.none,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.description);
    writer.writeByte(3);
    writer.write(obj.time);
    writer.writeByte(4);
    writer.write(obj.isActive);
    writer.writeByte(5);
    writer.write(obj.repeatDays);
    writer.writeByte(6);
    writer.write(obj.soundPath);
    writer.writeByte(7);
    writer.write(obj.vibrate);
    writer.writeByte(8);
    writer.write(obj.dismissType);
  }
}
