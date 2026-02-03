import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _autoHangUpTimer;
  Timer? _countdownTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startRinging();
    _autoHangUpTimer = Timer(const Duration(seconds: 30), _hangUp);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_elapsedSeconds >= 30) return;
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _startRinging() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('zaxoling.mp3'));
  }

  void _hangUp() {
    if (!mounted) return;
    _autoHangUpTimer?.cancel();
    _countdownTimer?.cancel();
    _player.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _autoHangUpTimer?.cancel();
    _countdownTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/applogo.png',
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'Voice Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _hangUp,
                    child: Image.asset(
                      'assets/btn_video_call_hang_up.webp',
                      width: 155,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 155,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '00:${_elapsedSeconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
