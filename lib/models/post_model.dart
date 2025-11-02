class PostModel {
  final String id;
  final String userId;
  final String authorEmail;
  final String authorName;
  final String title;
  final String content;
  final int timestamp;

  PostModel({
    required this.id,
    required this.userId,
    required this.authorEmail,
    required this.authorName,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'authorEmail': authorEmail,
      'authorName': authorName, 
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      authorEmail: map['authorEmail'] ?? '',
      authorName: map['authorName'] ?? map['authorEmail'] ?? 'Pengguna', 
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}