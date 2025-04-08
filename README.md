# 알람 앱 (alarm_hides_exit)

## 프로젝트 개요

- 알람 기능을 제공하는 Flutter 모바일 앱
- 로컬 데이터베이스(Hive)를 활용한 알람 저장 및 관리
- 백그라운드 알람 실행 기능 제공
- 다양한 알람 종료 방식 지원 (일반, 수학 문제, 텍스트 입력, 영어 단어 퀴즈)

## 아키텍처 구조

### 데이터 계층

1. **모델**

   - `models/alarm_model.dart`: Hive와 연동되는 알람 데이터 모델

   ```dart
   class AlarmModel {
     String id;
     String title;
     String description;
     DateTime time;
     bool isActive;
     List<bool> repeatDays;  // [월, 화, 수, 목, 금, 토, 일]
     String soundPath;
     bool vibrate;
     AlarmDismissType dismissType;  // 알람 종료 방식
   }

   // 알람 종료 방식 enum
   enum AlarmDismissType {
     none,         // 버튼 클릭
     mathProblem,  // 수학 문제 풀기
     typingText,   // 텍스트 따라 치기
     englishWord   // 영어 단어 뜻 맞추기
   }
   ```

2. **저장소**

   - `repositories/alarm_repository.dart`: Hive DB 연동 및 CRUD 연산 처리

   ```dart
   class AlarmRepository {
     // Hive Box 인스턴스
     late Box<AlarmModel> _box;

     // 초기화 메서드
     Future<void> initialize() async {...}

     // Box에 대한 ValueListenable 제공
     ValueListenable<Box<AlarmModel>> get alarmsListenable => _box.listenable();

     // 알람 저장, 조회, 수정, 삭제 기능 제공
     List<AlarmModel> getAllAlarms();
     Future<void> saveAlarm(AlarmModel alarm);
     Future<void> deleteAlarm(String id);
     Future<void> toggleAlarm(String id, bool isActive);
     AlarmModel? getAlarm(String id);
     List<AlarmModel> getSortedAlarms();
   }
   ```

### 비즈니스 로직 계층

1. **서비스**

   - `services/alarm_service.dart`: 알람 기능 관련 핵심 로직 처리

   ```dart
   class AlarmService {
     final AlarmRepository _repository = AlarmRepository();

     // 알람 스트림 컨트롤러 (알람 실행 시 사용)
     final StreamController<AlarmModel> _alarmStreamController;
     Stream<AlarmModel> get alarmStream => _alarmStreamController.stream;

     // 알람 서비스 초기화
     Future<void> init() async {
       // 저장소 초기화
       await _repository.initialize();
       // 안드로이드 알람 매니저 초기화
       // 로컬 알림 초기화
     }

     // 알람 관리 기능
     Future<void> scheduleAllAlarms();
     Future<void> scheduleAlarm(AlarmModel alarm);
     Future<void> cancelAlarm(String id);
     Future<void> addAlarm(AlarmModel alarm);
     Future<void> updateAlarm(AlarmModel alarm);
     Future<void> deleteAlarm(String id);
     Future<void> toggleAlarm(String id, bool isActive);
     void dismissAlarm(String id);

     // 알람 실행 및 알림 표시
     static Future<void> _showAlarmNotification(int id, Map<String, dynamic> data);
   }
   ```

### 프레젠테이션 계층

1. **화면**

   - `screens/home_screen.dart`: 알람 목록 표시 및 관리

   ```dart
   class HomeScreen extends StatefulWidget {
     @override
     State<HomeScreen> createState() => _HomeScreenState();
   }

   class _HomeScreenState extends State<HomeScreen> {
     final AlarmRepository _repository = AlarmRepository();
     final AlarmService _alarmService = AlarmService();

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         // ... 생략 ...
         body: ValueListenableBuilder<Box<AlarmModel>>(
           valueListenable: _repository.alarmsListenable,
           builder: (context, box, child) {
             final alarms = box.values.toList()..sort((a, b) => a.time.compareTo(b.time));
             // UI 구성 로직
           },
         ),
       );
     }
   }
   ```

   - `screens/alarm_editor_screen.dart`: 알람 추가 및 편집 화면

   ```dart
   class AlarmEditorScreen extends StatefulWidget {
     final AlarmModel? alarm;

     @override
     State<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
   }

   class _AlarmEditorScreenState extends State<AlarmEditorScreen> {
     final AlarmService _alarmService = AlarmService();
     // ... 생략 ...
     AlarmDismissType _dismissType = AlarmDismissType.none;

     void _saveAlarm() {
       // ... 생략 ...
     }
   }
   ```

   - **알람 종료 화면**

     - `screens/dismiss/alarm_dismiss_base.dart`: 알람 종료 화면 기본 인터페이스 및 팩토리

     ```dart
     abstract class AlarmDismissScreen extends StatelessWidget {
       // 팩토리 메서드로 알람 종료 유형에 맞는 화면 생성
       static Widget create({required AlarmModel alarm, required VoidCallback onDismiss}) {
         switch (alarm.dismissType) {
           case AlarmDismissType.mathProblem:
             return MathProblemDismissScreen(alarm: alarm, onDismiss: onDismiss);
           case AlarmDismissType.typingText:
             return TypingTextDismissScreen(alarm: alarm, onDismiss: onDismiss);
           case AlarmDismissType.englishWord:
             return EnglishWordDismissScreen(alarm: alarm, onDismiss: onDismiss);
           case AlarmDismissType.none:
           default:
             return SimpleDismissScreen(alarm: alarm, onDismiss: onDismiss);
         }
       }
     }
     ```

     - `screens/dismiss/simple_dismiss_screen.dart`: 버튼 클릭으로 종료하는 화면
     - `screens/dismiss/math_problem_dismiss_screen.dart`: 수학 문제를 풀어 종료하는 화면
     - `screens/dismiss/typing_text_dismiss_screen.dart`: 텍스트를 입력하여 종료하는 화면
     - `screens/dismiss/english_word_dismiss_screen.dart`: 영어 단어 의미를 맞춰 종료하는 화면

2. **위젯**
   - `widgets/alarm_list_item.dart`: 알람 항목 UI 컴포넌트

### 유틸리티 및 초기화

- `utils/app_initializer.dart`: 앱 초기화 로직 처리

```dart
class AppInitializer {
  static Future<void> initialize() async {
    // Hive 데이터베이스 초기화
    await Hive.initFlutter();

    // Hive 어댑터 등록
    Hive.registerAdapter(AlarmDismissTypeAdapter());
    Hive.registerAdapter(AlarmModelAdapter());

    // 알람 서비스 초기화
    final alarmService = AlarmService();
    await alarmService.init();

    // 저장된 모든 알람 일정 설정
    await alarmService.scheduleAllAlarms();
  }
}
```

## 주요 기능 구현

### 1. 로컬 데이터 관리 (Hive)

- 알람 데이터를 로컬에 저장하고 관리
- Hive 어댑터를 통한 객체-데이터 매핑
- Hive Box 변경 감지를 통한 실시간 UI 업데이트

### 2. 알람 기능

- 정확한 시간에 알람 실행
- 반복 알람 설정 (요일별)
- 일회성 알람 자동 비활성화
- 다양한 종료 방식 지원

### 3. 알람 종료 상호작용

- **버튼 클릭**: 간단히 버튼을 눌러 알람 종료
- **수학 문제**: 수학 문제를 풀어야 알람 종료 가능
- **텍스트 입력**: 제시된 텍스트를 정확히 입력해야 종료 가능
- **영어 단어 퀴즈**: 영어 단어의 의미를 맞춰야 종료 가능
- 확장 가능한 설계로 새로운 종료 방식 추가 용이

### 4. 알림 처리

- `flutter_local_notifications` 패키지를 활용한 알림 표시
- `android_alarm_manager_plus`를 활용한 백그라운드 알람 관리
- 앱이 실행 중이 아닐 때도 알람 기능 동작

### 5. 상태 관리

- 별도의 상태 관리 라이브러리 없이 Hive의 `ValueListenable` 활용
- `ValueListenableBuilder`를 통한 UI와 데이터 연동
- 데이터 변경 시 자동으로 UI 업데이트

## 의존성 패키지

- `hive` & `hive_flutter`: 로컬 데이터베이스 및 상태 관리
- `flutter_local_notifications`: 알림 표시
- `android_alarm_manager_plus`: 백그라운드 알람 관리
- `uuid`: 고유 ID 생성
- `intl`: 날짜/시간 포맷팅

## 플랫폼 설정

- Android: 백그라운드 실행 및 알람 관련 권한 설정
- iOS: 백그라운드 모드 및 알림 권한 설정

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
