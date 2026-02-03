import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/suno_music_item.dart';
import '../models/work_item.dart';
import '../services/now_playing_service.dart';
import '../services/prefs_service.dart';
import '../widgets/gradient_bubbles_background.dart';

const double _containerRadius = 20;
const double _horizontalMargin = 20;
const double _innerPadding = 24;
const double _coverRadius = 12;
const double _playButtonSize = 56;

String _formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class MusicPlayDetailScreen extends StatefulWidget {
  const MusicPlayDetailScreen({super.key, required this.item});

  final SunoMusicItem item;

  @override
  State<MusicPlayDetailScreen> createState() => _MusicPlayDetailScreenState();
}

class _MusicPlayDetailScreenState extends State<MusicPlayDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isReady = false;
  String? _customCoverPath;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  Timer? _nowPlayingUpdateTimer;

  void _updateNowPlayingInfo({int? durationMs}) {
    final ms = durationMs ?? _duration.inMilliseconds;
    NowPlayingService.setNowPlaying(
      title: widget.item.title,
      artist: widget.item.prompt ?? widget.item.tags ?? '',
      artworkUrl: _customCoverPath != null ? null : widget.item.imageUrl,
      durationMs: ms,
    );
  }

  void _scheduleNowPlayingUpdates() {
    _nowPlayingUpdateTimer?.cancel();
    _nowPlayingUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || !_isPlaying) return;
      NowPlayingService.updatePlayback(
        positionMs: _position.inMilliseconds,
        isPlaying: true,
      );
    });
  }

  void _handleRemotePlayback(String action, [int? positionMs]) {
    if (!mounted) return;
    switch (action) {
      case 'play':
        _player.resume();
        break;
      case 'pause':
        _player.pause();
        break;
      case 'toggle':
        if (_isPlaying) {
          _player.pause();
        } else {
          if (_isReady) {
            _player.resume();
          } else {
            final url = widget.item.audioUrl;
            if (url != null && url.isNotEmpty) {
              _player.play(UrlSource(url));
              setState(() => _isReady = true);
            }
          }
        }
        break;
      case 'seek':
        if (positionMs != null) {
          _player.seek(Duration(milliseconds: positionMs));
        }
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCustomCover();
    NowPlayingService.setRemoteCallback(_handleRemotePlayback);
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _duration = d);
        if (_isPlaying) _updateNowPlayingInfo(durationMs: d.inMilliseconds);
      }
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        final playing = state == PlayerState.playing;
        setState(() => _isPlaying = playing);
        if (playing) {
          _scheduleNowPlayingUpdates();
        } else {
          _nowPlayingUpdateTimer?.cancel();
          NowPlayingService.updatePlayback(
            positionMs: _position.inMilliseconds,
            isPlaying: false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    NowPlayingService.setRemoteCallback(null);
    NowPlayingService.clearNowPlaying();
    _nowPlayingUpdateTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadCustomCover() async {
    final path = await PrefsService.shared.getMusicCustomCover(widget.item.id);
    if (mounted) setState(() => _customCoverPath = path);
  }

  Future<void> _pickAndSaveCover() async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (xFile == null || !mounted) return;
    final bytes = await xFile.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final musicCoversDir = Directory('${dir.path}/music_covers');
    if (!await musicCoversDir.exists()) {
      await musicCoversDir.create(recursive: true);
    }
    final id = widget.item.id;
    final ext = xFile.name.contains('.') ? '.${xFile.name.split('.').last}' : '.jpg';
    final safeName = id.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final file = File('${musicCoversDir.path}/$safeName$ext');
    await file.writeAsBytes(bytes);
    final relativePath = 'music_covers/$safeName$ext';
    await PrefsService.shared.setMusicCustomCover(widget.item.id, relativePath);
    final works = await PrefsService.shared.getAllWorks();
    final i = works.indexWhere((w) => w.id == id && w.type == 'music');
    if (i >= 0) {
      final w = works[i];
      await PrefsService.shared.updateWork(WorkItem(
        id: w.id,
        title: w.title,
        type: w.type,
        imageUrl: relativePath,
        createdAt: w.createdAt,
        description: w.description,
        taskId: w.taskId,
        musicUrl: w.musicUrl,
        status: w.status,
      ));
      PrefsService.notifyWorksUpdated();
    }
    if (mounted) {
      setState(() => _customCoverPath = relativePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover updated')),
      );
    }
  }

  Future<void> _playOrPause() async {
    final url = widget.item.audioUrl;
    if (url == null || url.isEmpty) return;

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (!_isReady) {
      final durationMs = ((widget.item.duration ?? 0.0) * 1000).round();
      _updateNowPlayingInfo(durationMs: durationMs);
      await _player.play(UrlSource(url));
      setState(() => _isReady = true);
    } else {
      await _player.resume();
    }
  }

  Future<File> _customCoverFile() async {
    if (_customCoverPath == null || _customCoverPath!.isEmpty) {
      return File('');
    }
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_customCoverPath');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasAudio = item.audioUrl != null && item.audioUrl!.isNotEmpty;
    final imageUrl = item.imageUrl;
    final isNetworkImage = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

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
            'Music',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: _pickAndSaveCover,
              color: Colors.white,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(_horizontalMargin),
            child: Container(
              padding: const EdgeInsets.all(_innerPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_containerRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_coverRadius),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _customCoverPath != null
                                ? FutureBuilder<File>(
                                    future: _customCoverFile(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data!.existsSync()) {
                                        return Image.file(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return _coverFallback(imageUrl, isNetworkImage);
                                    },
                                  )
                                : _coverFallback(imageUrl, isNetworkImage),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: hasAudio ? _playOrPause : null,
                                  customBorder: const CircleBorder(),
                                  child: SizedBox(
                                    width: _playButtonSize,
                                    height: _playButtonSize,
                                    child: Icon(
                                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      size: _playButtonSize,
                                      color: hasAudio ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a1a1a),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.prompt ?? item.tags ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                    value: _duration.inSeconds > 0
                        ? _position.inMilliseconds /
                            _duration.inMilliseconds
                        : 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF260FA9)),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDuration(_position)} / ${_duration.inSeconds > 0 ? _formatDuration(_duration) : '--:--'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback(String? imageUrl, bool isNetworkImage) {
    if (isNetworkImage && imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderCover(),
      );
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        size: 64,
        color: Colors.grey.shade600,
      ),
    );
  }
}
