// models/notification_model.dart

class NotificationModel {
  final String id;
  final String userId; // Penerima notifikasi
  final String type; // 'comment', 'bookmark_comment', dll
  final String postId;
  final String postTitle;
  final String actorId; // Yang melakukan aksi (komentator)
  final String actorName;
  final String message;
  final int timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.postId,
    required this.postTitle,
    required this.actorId,
    required this.actorName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'postId': postId,
      'postTitle': postTitle,
      'actorId': actorId,
      'actorName': actorName,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? 'Pengguna',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      isRead: map['isRead'] ?? false,
    );
  }

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} minggu lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? postId,
    String? postTitle,
    String? actorId,
    String? actorName,
    String? message,
    int? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}