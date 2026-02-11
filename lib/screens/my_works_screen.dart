import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../constants/app_ui.dart';
import '../models/work_item.dart';
import '../models/suno_music_item.dart';
import '../services/prefs_service.dart';
import '../widgets/gradient_bubbles_background.dart';
import 'ai_chat_screen.dart';
import 'ai_image_screen.dart';
import 'image_detail_screen.dart';
import 'music_play_detail_screen.dart';
import 'text_to_music_screen.dart';

const String _recordInfoUrl = 'https://api.kie.ai/api/v1/generate/record-info';
const String _recordInfoToken = '4be3334cd55d4d81edc41c865e9ff192';

class MyWorksScreen extends StatefulWidget {
  const MyWorksScreen({super.key, this.onSwitchToTab, this.selectedTabNotifier});

  final void Function(int index)? onSwitchToTab;
  final ValueNotifier<int>? selectedTabNotifier;

  @override
  State<MyWorksScreen> createState() => _MyWorksScreenState();
}

class _MyWorksScreenState extends State<MyWorksScreen> {
  int _filterIndex = 0;
  List<WorkItem> _works = [];
  List<GeneratedImage> _generatedImages = [];
  List<WorkItem> _displayList = [];
  Timer? _pollTimer;
  String? _pollingTaskId;

  static const int _myWorksTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _load();
    PrefsService.worksUpdatedListeners.add(_onWorksUpdated);
    widget.selectedTabNotifier?.addListener(_onSelectedTabChanged);
  }

  @override
  void dispose() {
    _stopPolling();
    widget.selectedTabNotifier?.removeListener(_onSelectedTabChanged);
    PrefsService.worksUpdatedListeners.remove(_onWorksUpdated);
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingTaskId = null;
  }

  String? _getPendingMusicTaskId() {
    for (final w in _works) {
      if (w.type == 'music' &&
          w.taskId != null &&
          w.taskId!.isNotEmpty &&
          w.status != 'FAILED' &&
          (w.musicUrl == null || w.musicUrl!.isEmpty)) {
        return w.taskId;
      }
    }
    return null;
  }

  void _startPollingIfNeeded() {
    _stopPolling();
    final taskId = _getPendingMusicTaskId();
    if (taskId == null) return;
    _pollingTaskId = taskId;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPendingTask());
  }

  Future<void> _checkPendingTask() async {
    final taskId = _pollingTaskId;
    if (taskId == null || !mounted) return;
    final uri = Uri.parse(_recordInfoUrl).replace(queryParameters: {'taskId': taskId});
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_recordInfoToken'},
      );
      if (!mounted) return;
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
            if (r is Map<String, dynamic> && (r['taskId'] as String?) == taskId) {
              record = r as Map<String, dynamic>;
              break;
            }
          }
          record ??= records.first as Map<String, dynamic>?;
        } else if ((data['taskId'] as String?) == taskId) {
          record = data as Map<String, dynamic>;
        }
      }
      if (record == null) return;
      final status = record['status'] as String? ?? 'PENDING';
      if (status == 'SUCCESS') {
        String? audioUrl;
        String? coverUrl;
        final responseObj = record['response'] as Map<String, dynamic>?;
        if (responseObj != null) {
          final sunoData = responseObj['sunoData'] as List<dynamic>?;
          if (sunoData != null && sunoData.isNotEmpty) {
            final first = sunoData.first as Map<String, dynamic>;
            audioUrl = (first['audioUrl'] as String?) ?? (first['streamAudioUrl'] as String?);
            coverUrl = first['imageUrl'] as String?;
          }
        }
        if (audioUrl != null && audioUrl.isNotEmpty) {
          final all = await PrefsService.shared.getAllWorks();
          WorkItem? original;
          for (final w in all) {
            if (w.taskId == taskId) {
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
        }
        _stopPolling();
        if (mounted) _load();
      } else if (status == 'CREATE_TASK_FAILED' ||
          status == 'GENERATE_AUDIO_FAILED' ||
          status == 'CALLBACK_EXCEPTION' ||
          status == 'SENSITIVE_WORD_ERROR') {
        final all = await PrefsService.shared.getAllWorks();
        WorkItem? original;
        for (final w in all) {
          if (w.taskId == taskId) {
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
        if (mounted) _load();
      }
    } catch (_) {}
  }

  void _onSelectedTabChanged() {
    if (widget.selectedTabNotifier?.value == _myWorksTabIndex) {
      _load();
    }
  }

  void _onWorksUpdated() {
    _load();
  }

  Future<void> _load() async {
    final works = await PrefsService.shared.getAllWorks();
    final images = await PrefsService.shared.getAllGeneratedImages();
    if (!mounted) return;
    setState(() {
      _works = works;
      _generatedImages = images;
      _applyFilter();
    });
    _startPollingIfNeeded();
  }

  Future<void> _confirmDelete(BuildContext context, WorkItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this work?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await PrefsService.shared.deleteWorks([item.id]);
    if (item.type == 'image') {
      await PrefsService.shared.deleteGeneratedImage(item.id);
    }
    PrefsService.notifyWorksUpdated();
  }

  void _applyFilter() {
    final workIds = _works.map((w) => w.id).toSet();
    if (_filterIndex == 0) {
      final fromGen = _generatedImages
          .where((g) => !workIds.contains(g.id))
          .map((g) => WorkItem(
                id: g.id,
                title: g.prompt.length > 30 ? '${g.prompt.substring(0, 30)}...' : g.prompt,
                type: 'image',
                imageUrl: g.imagePath,
                createdAt: g.createdAt,
                description: g.prompt,
              ));
      _displayList = [..._works, ...fromGen];
      _displayList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_filterIndex == 1) {
      _displayList = _generatedImages.map((g) => WorkItem(
            id: g.id,
            title: g.prompt.length > 30 ? '${g.prompt.substring(0, 30)}...' : g.prompt,
            type: 'image',
            imageUrl: g.imagePath,
            createdAt: g.createdAt,
            description: g.prompt,
          )).toList();
      _displayList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _displayList = _works.where((w) => w.type == 'music').toList();
      _displayList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
          title: const SizedBox.shrink(),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _SegmentedTabBar(
                labels: const ['All', 'Images', 'Music'],
                selectedIndex: _filterIndex,
                onSelected: (index) {
                  setState(() {
                    _filterIndex = index;
                    _applyFilter();
                  });
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.expand(
                    child: _displayList.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _filterIndex == 0
                                  ? 'No works yet.\nStart creating!'
                                  : _filterIndex == 1
                                      ? 'No images yet.\nStart creating!'
                                      : 'No music yet.\nStart creating!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: () {
                                if (_filterIndex == 1) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AiImageScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TextToMusicScreen(),
                                    ),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF260FA9),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                _filterIndex == 1 ? 'Create Image' : 'Create Music',
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 16,
                          bottom: floatingTabBarBottomInset(context),
                        ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _displayList.length,
                      itemBuilder: (context, index) {
                        final item = _displayList[index];
                        final isImage = item.type == 'image';
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              if (isImage) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ImageDetailScreen(work: item),
                                  ),
                                );
                              } else {
                                final sunoItem = SunoMusicItem(
                                  id: item.id,
                                  title: item.title,
                                  imageUrl: item.imageUrl,
                                  audioUrl: item.musicUrl,
                                  prompt: item.description,
                                  tags: null,
                                  createTime: null,
                                  duration: null,
                                  taskId: item.taskId,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MusicPlayDetailScreen(item: sunoItem),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: isImage
                                    ? (item.imageUrl != null && item.imageUrl!.isNotEmpty
                                        ? _WorkImage(imageUrl: item.imageUrl!)
                                        : Container(
                                            color: Colors.white24,
                                            child: const Center(
                                              child: Icon(Icons.image, size: 48, color: Colors.white54),
                                            ),
                                          ))
                                    : _MusicCover(imageUrl: item.imageUrl),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.black.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (!isImage)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: _RotatingCdCover(),
                                ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () => _confirmDelete(context, item),
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          final isFirst = index == 0;
          final isLast = index == labels.length - 1;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(18) : Radius.zero,
                  right: isLast ? const Radius.circular(18) : Radius.zero,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst ? const Radius.circular(18) : Radius.zero,
                      right: isLast ? const Radius.circular(18) : Radius.zero,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF260FA9)
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RotatingCdCover extends StatefulWidget {
  const _RotatingCdCover();

  @override
  State<_RotatingCdCover> createState() => _RotatingCdCoverState();
}

class _RotatingCdCoverState extends State<_RotatingCdCover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        'assets/CDCover.png',
        width: 30,
        height: 30,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MusicCover extends StatelessWidget {
  const _MusicCover({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

    if (isNetwork) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _musicPlaceholder(),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return FutureBuilder<File>(
        future: _WorkImage._localFile(imageUrl!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.existsSync()) {
            return Image.file(snapshot.data!, fit: BoxFit.cover);
          }
          return _musicPlaceholder();
        },
      );
    }
    return _musicPlaceholder();
  }

  Widget _musicPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        size: 48,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

class _WorkImage extends StatelessWidget {
  const _WorkImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    if (isNetwork) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    return FutureBuilder<File>(
      future: _localFile(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          return Image.file(snapshot.data!, fit: BoxFit.cover);
        }
        return const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.white54),
        );
      },
    );
  }

  static Future<File> _localFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$relativePath');
  }
}

