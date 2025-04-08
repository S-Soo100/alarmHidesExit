import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/repositories/alarm_repository.dart';
import 'package:alarm_hides_exit/services/alarm_service.dart';
import 'package:alarm_hides_exit/screens/alarm_editor_screen.dart';
import 'package:alarm_hides_exit/widgets/alarm_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmRepository _repository = AlarmRepository();
  final AlarmService _alarmService = AlarmService();

  @override
  void initState() {
    super.initState();
    // 화면이 로드된 후 저장소 초기화
    _initRepository();
  }

  Future<void> _initRepository() async {
    await _repository.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ValueListenableBuilder<Box<AlarmModel>>(
        valueListenable: _repository.alarmsListenable,
        builder: (context, box, child) {
          final alarms =
              box.values.toList()..sort((a, b) => a.time.compareTo(b.time));

          if (alarms.isEmpty) {
            return const Center(
              child: Text(
                '알람이 없습니다\n오른쪽 하단 버튼을 눌러 추가하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return AlarmListItem(
                alarm: alarm,
                onToggle: () {
                  _alarmService.toggleAlarm(alarm.id, !alarm.isActive);
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlarmEditorScreen(alarm: alarm),
                    ),
                  );
                },
                onDelete: () {
                  _alarmService.deleteAlarm(alarm.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlarmEditorScreen()),
          );
        },
        tooltip: '알람 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}
