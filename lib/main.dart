import 'package:flutter/material.dart';
import 'package:alarm_hides_exit/models/alarm_model.dart';
import 'package:alarm_hides_exit/screens/dismiss/alarm_dismiss_base.dart';
import 'package:alarm_hides_exit/screens/home_screen.dart';
import 'package:alarm_hides_exit/services/alarm_service.dart';
import 'package:alarm_hides_exit/utils/app_initializer.dart';

void main() async {
  // 앱 초기화
  await AppInitializer.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AlarmService _alarmService = AlarmService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // 알람 스트림 리스너 설정
    _alarmService.alarmStream.listen(_showAlarmDismissScreen);
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }

  // 알람 종료 화면 표시
  void _showAlarmDismissScreen(AlarmModel alarm) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (context) => AlarmDismissScreen.create(
              alarm: alarm,
              onDismiss: () {
                // 알람 종료
                _alarmService.dismissAlarm(alarm.id);

                // 종료 화면 닫기
                _navigatorKey.currentState?.pop();
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '알람 앱',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          widget.title,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      body: Center(
        // child: ValueListenableBuilder(
        //   valueListenable: T value,
        //   builder: (BuildContext context, T value, Widget widget) {},
        // ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
