class SunoMusicItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? audioUrl;
  final String? prompt;
  final String? tags;
  final String? createTime;
  final double? duration;
  final String? taskId;

  const SunoMusicItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.audioUrl,
    this.prompt,
    this.tags,
    this.createTime,
    this.duration,
    this.taskId,
  });
}
