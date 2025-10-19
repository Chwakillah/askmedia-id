class CommentModel {
  final String id;
  final String userId;
  final String userNickname;
  final String content;
  final int timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userNickname,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userNickname': userNickname,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      userId: map['userId'] ?? '',
      userNickname: map['userNickname'] ?? 'Anonim',
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