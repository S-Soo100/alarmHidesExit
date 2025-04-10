import 'package:alarm_hides_exit/services/minute_alarm_service.dart';
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
  final MinuteAlarmService _minuteAlarmService = MinuteAlarmService(); // 추가
  bool _isMinuteAlarmActive = false; // 추가

  @override
  void initState() {
    super.initState();
    // 화면이 로드된 후 저장소 초기화
    _initRepository();
    // _initMinuteAlarmService(); // 추가
  }

  Future<void> _initMinuteAlarmService() async {
    await _minuteAlarmService.init();

    // 알람 이벤트 리스너 등록
    _minuteAlarmService.alarmStream.listen(_showAlarmDismissScreen);
  }

  void _showAlarmDismissScreen(AlarmModel alarm) {
    // 앱이 실행 중일 때 알람이 울리면 팝업 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(alarm.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alarm.description),
              const SizedBox(height: 10),
              Text('시간: ${DateFormat('HH:mm:ss').format(alarm.time)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('끄기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initRepository() async {
    await _repository.initialize();
  }

  @override
  void dispose() {
    _minuteAlarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 1분 알람 토글 버튼 추가
          Switch(
            value: _isMinuteAlarmActive,
            onChanged: (value) {
              setState(() {
                _isMinuteAlarmActive = value;
                if (_isMinuteAlarmActive) {
                  _minuteAlarmService.startMinuteAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('1분 알람이 시작되었습니다')),
                  );
                } else {
                  _minuteAlarmService.stopMinuteAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('1분 알람이 중지되었습니다')),
                  );
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: '1분 알람',
            onPressed: () {
              setState(() {
                _isMinuteAlarmActive = !_isMinuteAlarmActive;
                if (_isMinuteAlarmActive) {
                  _minuteAlarmService.startMinuteAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('1분 알람이 시작되었습니다')),
                  );
                } else {
                  _minuteAlarmService.stopMinuteAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('1분 알람이 중지되었습니다')),
                  );
                }
              });
            },
          ),
        ],
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
