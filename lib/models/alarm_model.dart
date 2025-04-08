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
