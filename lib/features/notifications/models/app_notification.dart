enum AppNotificationType {
  photoSaved,
  permission,
  storage,
  project,
  general,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.relatedPhotoId,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final AppNotificationType type;
  final bool isRead;
  final String? relatedPhotoId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        type: type,
        isRead: isRead ?? this.isRead,
        relatedPhotoId: relatedPhotoId,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'isRead': isRead,
        'relatedPhotoId': relatedPhotoId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Notification',
      message: (json['message'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      type: AppNotificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AppNotificationType.general,
      ),
      isRead: json['isRead'] as bool? ?? false,
      relatedPhotoId: json['relatedPhotoId'] as String?,
    );
  }
}
