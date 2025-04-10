import 'dart:async';
import 'package:flutter/services.dart';
import 'package:alarm_hides_exit/utils/logger_mixin.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// 알람 소리를 재생하는 서비스
class AlarmSoundService with LoggerMixin {
  static final AlarmSoundService _instance = AlarmSoundService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;

  // 싱글톤 패턴
  factory AlarmSoundService() {
    return _instance;
  }

  AlarmSoundService._internal();

  /// 서비스 초기화
  Future<void> init() async {
    log("AlarmSoundService 초기화 시작");

    // 오디오 세션 설정 (알람 소리에 적합하게)
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.alarm,
          flags: AndroidAudioFlags.audibilityEnforced,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );

    _player = AudioPlayer();
    log("AlarmSoundService 초기화 완료");
  }

  /// 알람 소리를 무한 반복으로 재생
  Future<void> playAlarmSound() async {
    if (_isPlaying) {
      log("이미 알람 소리 재생 중, 중복 재생 방지");
      return;
    }

    if (_player == null) {
      log("플레이어가 초기화되지 않음, 초기화 시도");
      await init();
    }

    try {
      log("알람 소리 재생 시작");
      _isPlaying = true;

      // 앱 assets에서 알람 소리 파일 로드 및 무한 반복 설정
      await _player?.setAsset('assets/sound/test_alarm.mp3');
      await _player?.setLoopMode(LoopMode.one); // 단일 파일 무한 반복
      await _player?.setVolume(1.0); // 최대 볼륨

      // 재생 시작
      await _player?.play();

      log("알람 소리 무한 반복 재생 시작됨");
    } catch (e) {
      _isPlaying = false;
      log("알람 소리 재생 실패: $e");
    }
  }

  /// 알람 소리 중지
  Future<void> stopAlarmSound() async {
    log("알람 소리 중지 시작");

    try {
      if (!_isPlaying) {
        log("재생 중인 알람 소리 없음");
        return;
      }

      _isPlaying = false;

      // 플레이어가 초기화되어 있는지 확인
      if (_player == null) {
        log("플레이어가 null, 새로 생성 시도");
        _player = AudioPlayer();
      }

      // 플레이어가 재생 중인지 확인
      if (_player!.playing) {
        await _player!.stop();
        log("재생 중인 플레이어 정지 완료");
      }

      // 볼륨을 0으로 설정 (추가 안전장치)
      await _player!.setVolume(0);
      log("플레이어 볼륨 0으로 설정");

      // 모든 플레이어 상태 초기화
      await _player!.dispose();
      _player = AudioPlayer();
      log("플레이어 완전히 재생성");

      log("알람 소리 중지 완료");
    } catch (e) {
      log("알람 소리 중지 실패: $e");

      // 실패 시 새로운 플레이어로 교체 시도
      try {
        _player?.dispose();
        _player = AudioPlayer();
        _isPlaying = false;
        log("오류 후 플레이어 강제 재설정");
      } catch (e2) {
        log("플레이어 강제 재설정 실패: $e2");
      }
    }
  }

  /// 서비스 종료
  Future<void> dispose() async {
    log("AlarmSoundService 종료");
    await stopAlarmSound();
    await _player?.dispose();
    _player = null;
  }
}
