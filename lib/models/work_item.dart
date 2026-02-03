class WorkItem {
  final String id;
  final String title;
  final String type;
  final String? imageUrl;
  final DateTime createdAt;
  final String description;
  final String? taskId;
  final String? musicUrl;
  final String? status;

  const WorkItem({
    required this.id,
    required this.title,
    required this.type,
    this.imageUrl,
    required this.createdAt,
    required this.description,
    this.taskId,
    this.musicUrl,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'imageUrl': imageUrl,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'description': description,
        'taskId': taskId,
        'musicUrl': musicUrl,
        'status': status,
      };

  static WorkItem fromJson(Map<String, dynamic> json) => WorkItem(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        description: json['description'] as String,
        taskId: json['taskId'] as String?,
        musicUrl: json['musicUrl'] as String?,
        status: json['status'] as String?,
      );
}

class GeneratedImage {
  final String id;
  final String? taskId;
  final String prompt;
  final String? imagePath;
  final DateTime createdAt;

  const GeneratedImage({
    required this.id,
    this.taskId,
    required this.prompt,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'prompt': prompt,
        'imagePath': imagePath,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static GeneratedImage fromJson(Map<String, dynamic> json) => GeneratedImage(
        id: json['id'] as String,
        taskId: json['taskId'] as String?,
        prompt: json['prompt'] as String,
        imagePath: json['imagePath'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      );
}
