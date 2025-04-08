import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/models/alarm_dismiss_type.dart';
import 'package:alarm_hides_exit/services/alarm_service.dart';
import 'package:uuid/uuid.dart';

class AlarmEditorScreen extends StatefulWidget {
  final AlarmModel? alarm;

  const AlarmEditorScreen({super.key, this.alarm});

  @override
  State<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends State<AlarmEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AlarmService _alarmService = AlarmService();

  late TimeOfDay _selectedTime;
  List<bool> _repeatDays = List.filled(7, false); // [월, 화, 수, 목, 금, 토, 일]
  bool _isActive = true;
  String _soundPath = 'default';
  bool _vibrate = true;
  AlarmDismissType _dismissType = AlarmDismissType.none;

  @override
  void initState() {
    super.initState();

    if (widget.alarm != null) {
      // 기존 알람 정보로 초기화
      _titleController.text = widget.alarm!.title;
      _descriptionController.text = widget.alarm!.description;
      _selectedTime = TimeOfDay.fromDateTime(widget.alarm!.time);
      _repeatDays = [...widget.alarm!.repeatDays];
      _isActive = widget.alarm!.isActive;
      _soundPath = widget.alarm!.soundPath;
      _vibrate = widget.alarm!.vibrate;
      _dismissType = widget.alarm!.dismissType;
    } else {
      // 새 알람의 기본값
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? '알람 추가' : '알람 편집'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.alarm != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _alarmService.deleteAlarm(widget.alarm!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '알람 제목',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '알람 제목을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '메모 (선택사항)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '시간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '반복',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildWeekdayToggles(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '종료 방식',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AlarmDismissType>(
                      value: _dismissType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AlarmDismissType.none,
                          child: Text('버튼 클릭'),
                        ),
                        DropdownMenuItem(
                          value: AlarmDismissType.mathProblem,
                          child: Text('수학 문제 풀기'),
                        ),
                        DropdownMenuItem(
                          value: AlarmDismissType.typingText,
                          child: Text('텍스트 입력하기'),
                        ),
                        DropdownMenuItem(
                          value: AlarmDismissType.englishWord,
                          child: Text('영어 단어 뜻 맞추기'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _dismissType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('알람 활성화'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              secondary: const Icon(Icons.alarm),
            ),

            SwitchListTile(
              title: const Text('진동'),
              value: _vibrate,
              onChanged: (value) {
                setState(() {
                  _vibrate = value;
                });
              },
              secondary: const Icon(Icons.vibration),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAlarm,
        label: const Text('저장'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  List<Widget> _buildWeekdayToggles() {
    const List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (index) {
      return InkWell(
        onTap: () {
          setState(() {
            _repeatDays[index] = !_repeatDays[index];
          });
        },
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _repeatDays[index]
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Text(
            days[index],
            style: TextStyle(
              color:
                  _repeatDays[index]
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _saveAlarm() {
    if (!_formKey.currentState!.validate()) return;

    // 현재 시간 기준으로 DateTime 객체 생성
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.alarm == null) {
      // 새 알람 생성
      final alarm = AlarmModel(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        time: alarmTime,
        isActive: _isActive,
        repeatDays: _repeatDays,
        soundPath: _soundPath,
        vibrate: _vibrate,
        dismissType: _dismissType,
      );

      _alarmService.addAlarm(alarm);
    } else {
      // 기존 알람 업데이트
      final updatedAlarm = AlarmModel(
        id: widget.alarm!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        time: alarmTime,
        isActive: _isActive,
        repeatDays: _repeatDays,
        soundPath: _soundPath,
        vibrate: _vibrate,
        dismissType: _dismissType,
      );

      _alarmService.updateAlarm(updatedAlarm);
    }

    Navigator.pop(context);
  }
}
