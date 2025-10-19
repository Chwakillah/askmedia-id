class PostModel {
  final String id;
  final String title;
  final String content;
  final String authorEmail;
  final String userId; 
  final int timestamp;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorEmail,
    required this.userId,
    required this.timestamp,
  });

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorEmail: map['authorEmail'] ?? '',
      userId: map['userId'] ?? '', 
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorEmail': authorEmail,
      'userId': userId, 
      'timestamp': timestamp,
    };
  }
}
