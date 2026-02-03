import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/app_ui.dart';
import '../models/suno_music_item.dart';
import '../models/work_item.dart';
import '../services/prefs_service.dart';
import '../widgets/gradient_bubbles_background.dart';
import 'music_play_detail_screen.dart';

const String _apiToken = '4be3334cd55d4d81edc41c865e9ff192';
const String _recordInfoUrl = 'https://api.kie.ai/api/v1/generate/record-info';

const double _coverSize = 64;
const double _listItemPadding = 16;

class MusicHistoryScreen extends StatefulWidget {
  const MusicHistoryScreen({super.key});

  @override
  State<MusicHistoryScreen> createState() => _MusicHistoryScreenState();
}

class _MusicHistoryScreenState extends State<MusicHistoryScreen> {
  List<SunoMusicItem> _musicList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final List<SunoMusicItem> all = [];
    final localWorks = await PrefsService.shared.getAllWorks();
    final musicWorks = localWorks.where((w) => w.type == 'music').toList();

    for (final work in musicWorks) {
      final taskId = work.taskId;
      if (taskId == null || taskId.isEmpty) {
        all.add(SunoMusicItem(
          id: work.id,
          title: work.title,
          imageUrl: work.imageUrl,
          audioUrl: work.musicUrl,
          prompt: work.description,
          taskId: null,
        ));
        continue;
      }
      try {
        final uri = Uri.parse(_recordInfoUrl).replace(
          queryParameters: {'taskId': taskId},
        );
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $_apiToken'},
        );
        if (!mounted) return;
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) continue;
        final code = body['code'] as int?;
        if (code != 200) continue;
        final data = body['data'];
        if (data == null) continue;
        Map<String, dynamic>? record;
        if (data is Map<String, dynamic>) {
          final records = data['records'] as List<dynamic>?;
          if (records != null && records.isNotEmpty) {
            for (final r in records) {
              if (r is Map<String, dynamic> &&
                  (r['taskId'] as String?) == taskId) {
                record = r as Map<String, dynamic>;
                break;
              }
            }
            record ??= records.first as Map<String, dynamic>;
          } else if ((data['taskId'] as String?) == taskId) {
            record = data as Map<String, dynamic>;
          }
        }
        if (record == null) {
          all.add(SunoMusicItem(
            id: work.id,
            title: work.title,
            imageUrl: work.imageUrl,
            audioUrl: work.musicUrl,
            prompt: work.description,
            taskId: taskId,
          ));
          continue;
        }
        final responseObj = record['response'] as Map<String, dynamic>?;
        final sunoData = responseObj?['sunoData'] as List<dynamic>?;
        if (sunoData != null && sunoData.isNotEmpty) {
          for (final item in sunoData) {
            if (item is! Map<String, dynamic>) continue;
            all.add(SunoMusicItem(
              id: item['id'] as String? ?? work.id,
              title: item['title'] as String? ?? work.title,
              imageUrl: item['imageUrl'] as String?,
              audioUrl: (item['audioUrl'] as String?) ??
                  (item['streamAudioUrl'] as String?),
              prompt: item['prompt'] as String?,
              tags: item['tags'] as String?,
              createTime: item['createTime'] as String?,
              duration: (item['duration'] as num?)?.toDouble(),
              taskId: taskId,
            ));
          }
        } else {
          all.add(SunoMusicItem(
            id: work.id,
            title: work.title,
            imageUrl: work.imageUrl,
            audioUrl: work.musicUrl,
            prompt: work.description,
            taskId: taskId,
          ));
        }
      } catch (_) {
        all.add(SunoMusicItem(
          id: work.id,
          title: work.title,
          imageUrl: work.imageUrl,
          audioUrl: work.musicUrl,
          prompt: work.description,
          taskId: taskId,
        ));
      }
    }

    all.sort((a, b) {
      final at = a.createTime ?? '';
      final bt = b.createTime ?? '';
      return bt.compareTo(at);
    });

    if (mounted) {
      setState(() {
        _musicList = all;
        _loading = false;
      });
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
            'Music Works',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _musicList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No music works yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Create New Songs'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: Colors.white,
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 8,
                        bottom: floatingTabBarBottomInset(context),
                      ),
                      itemCount: _musicList.length,
                      itemBuilder: (context, index) {
                        final item = _musicList[index];
                        return _MusicListItem(item: item);
                      },
                    ),
                  ),
      ),
    );
  }
}

class _MusicListItem extends StatelessWidget {
  const _MusicListItem({required this.item});

  final SunoMusicItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final isNetwork = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MusicPlayDetailScreen(item: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(_listItemPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: _coverSize,
                    height: _coverSize,
                    child: isNetwork
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderCover(),
                          )
                        : _placeholderCover(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.prompt != null && item.prompt!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.prompt!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (item.tags != null && item.tags!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.tags!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (item.createTime != null && item.createTime!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.createTime!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        size: 28,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}
