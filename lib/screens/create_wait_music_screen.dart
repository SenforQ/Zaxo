import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/work_item.dart';
import '../services/prefs_service.dart';
import '../widgets/gradient_bubbles_background.dart';

const String _zeenoToken = '4be3334cd55d4d81edc41c865e9ff192';
const String _recordInfoUrl = 'https://api.kie.ai/api/v1/generate/record-info';
const double _zeenoCDSize = 160;
const double _zeenoCDInnerSize = 48;
const double _zeenoCDCenterOffset = -40;
const double _zeenoTitleToCDGap = 24;
const double _zeenoCDToStatusGap = 28;
const double _zeenoStatusHorizontalInset = 40;

class CreateWaitMusicScreen extends StatefulWidget {
  const CreateWaitMusicScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<CreateWaitMusicScreen> createState() => _CreateWaitMusicScreenState();
}

class _CreateWaitMusicScreenState extends State<CreateWaitMusicScreen>
    with SingleTickerProviderStateMixin {
  String _statusText = 'Generating music... Please wait.';
  Timer? _pollTimer;
  Timer? _dotsTimer;
  bool _isPolling = true;
  int _dotsCount = 0;
  late AnimationController _rotationController;

  String get _animatedDots => '.' * (_dotsCount % 4);

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dotsCount++);
    });
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _dotsTimer?.cancel();
    _dotsTimer = null;
    _rotationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _checkStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  void _stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkStatus() async {
    if (!_isPolling) return;
    final uri = Uri.parse(_recordInfoUrl).replace(
      queryParameters: {'taskId': widget.taskId},
    );
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_zeenoToken'},
      );
      if (!_isPolling || !mounted) return;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return;
      final code = body['code'] as int?;
      if (code != 200) return;
      final data = body['data'];
      if (data == null) return;
      Map<String, dynamic>? record;
      if (data is Map<String, dynamic>) {
        final records = data['records'] as List<dynamic>?;
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            if (r is Map<String, dynamic> &&
                (r['taskId'] as String?) == widget.taskId) {
              record = r;
              break;
            }
          }
          record ??= records.first as Map<String, dynamic>?;
        } else if ((data['taskId'] as String?) == widget.taskId) {
          record = data as Map<String, dynamic>;
        }
      }
      if (record == null) return;
      final status = record['status'] as String? ?? 'PENDING';
      if (!mounted) return;
      setState(() {
        switch (status) {
          case 'PENDING':
            _statusText = 'Waiting for processing...';
            break;
          case 'TEXT_SUCCESS':
            _statusText = 'Text generation successful, generating audio...';
            break;
          case 'FIRST_SUCCESS':
            _statusText = 'First track completed, generating more...';
            break;
          case 'SUCCESS':
            _statusText = 'Generation Complete!';
            break;
          default:
            if (status.contains('FAILED') ||
                status.contains('ERROR') ||
                status.contains('EXCEPTION')) {
              _statusText = 'Generation Failed: $status';
            } else {
              _statusText = 'Generating music... Please wait.';
            }
        }
      });
      if (status == 'SUCCESS') {
        String? audioUrl;
        String? coverUrl;
        String? returnedTitle;
        final responseObj = record['response'] as Map<String, dynamic>?;
        if (responseObj != null) {
          final sunoData = responseObj['sunoData'] as List<dynamic>?;
          if (sunoData != null && sunoData.isNotEmpty) {
            final first = sunoData.first as Map<String, dynamic>;
            audioUrl = (first['audioUrl'] as String?) ??
                (first['streamAudioUrl'] as String?);
            coverUrl = first['imageUrl'] as String?;
            returnedTitle = first['title'] as String?;
          }
        }
        if (audioUrl != null && audioUrl.isNotEmpty) {
          final all = await PrefsService.shared.getAllWorks();
          WorkItem? original;
          for (final w in all) {
            if (w.taskId == widget.taskId) {
              original = w;
              break;
            }
          }
          if (original != null) {
            final updated = WorkItem(
              id: original.id,
              title: original.title,
              type: original.type,
              imageUrl: coverUrl ?? original.imageUrl,
              createdAt: original.createdAt,
              description: original.description,
              taskId: original.taskId,
              musicUrl: audioUrl,
              status: 'COMPLETED',
            );
            await PrefsService.shared.updateWork(updated);
          }
          _stopPolling();
          if (mounted) Navigator.of(context).pop();
        }
      } else if (status == 'CREATE_TASK_FAILED' ||
          status == 'GENERATE_AUDIO_FAILED' ||
          status == 'CALLBACK_EXCEPTION' ||
          status == 'SENSITIVE_WORD_ERROR') {
        final all = await PrefsService.shared.getAllWorks();
        WorkItem? original;
        for (final w in all) {
          if (w.taskId == widget.taskId) {
            original = w;
            break;
          }
        }
        if (original != null) {
          final updated = WorkItem(
            id: original.id,
            title: original.title,
            type: original.type,
            imageUrl: original.imageUrl,
            createdAt: original.createdAt,
            description: original.description,
            taskId: original.taskId,
            musicUrl: original.musicUrl,
            status: 'FAILED',
          );
          await PrefsService.shared.updateWork(updated);
        }
        _stopPolling();
      }
    } catch (e) {
      if (_isPolling && mounted) {
        setState(() => _statusText = 'Error checking status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBubblesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Generating Music',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: -_zeenoCDCenterOffset),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Creating your song$_animatedDots',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _zeenoTitleToCDGap),
                  SizedBox(
                    width: _zeenoCDSize,
                    height: _zeenoCDSize,
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * 3.14159265359,
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF595959).withValues(alpha: 0.8),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: _zeenoCDInnerSize,
                          height: _zeenoCDInnerSize,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _zeenoCDToStatusGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _zeenoStatusHorizontalInset,
                    ),
                    child: Text(
                      _statusText.endsWith('...')
                          ? _statusText.replaceFirst(RegExp(r'\.{3}$'), _animatedDots)
                          : _statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
