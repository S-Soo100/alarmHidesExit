import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';

class AlarmRepository {
  static const String _boxName = 'alarms';
  late Box<AlarmModel> _box;

  // 초기화 메서드
  Future<void> initialize() async {
    // 이미 열려있는지 확인
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<AlarmModel>(_boxName);
    } else {
      _box = Hive.box<AlarmModel>(_boxName);
    }
  }

  // 알람 목록에 대한 ValueListenable 제공
  ValueListenable<Box<AlarmModel>> get alarmsListenable => _box.listenable();

  // 모든 알람 가져오기
  List<AlarmModel> getAllAlarms() {
    return _box.values.toList();
  }

  // 알람 저장하기
  Future<void> saveAlarm(AlarmModel alarm) async {
    await _box.put(alarm.id, alarm);
  }

  // 알람 삭제하기
  Future<void> deleteAlarm(String id) async {
    await _box.delete(id);
  }

  // 알람 활성화/비활성화
  Future<void> toggleAlarm(String id, bool isActive) async {
    final alarm = _box.get(id);
    if (alarm != null) {
      alarm.isActive = isActive;
      await alarm.save();
    }
  }

  // 특정 알람 가져오기
  AlarmModel? getAlarm(String id) {
    return _box.get(id);
  }

  // 정렬된 알람 목록 가져오기
  List<AlarmModel> getSortedAlarms() {
    final alarms = getAllAlarms();
    alarms.sort((a, b) => a.time.compareTo(b.time));
    return alarms;
  }
}
