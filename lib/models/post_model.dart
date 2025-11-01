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

  // Getter untuk format waktu yang mudah dibaca
  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      // Tampilkan tanggal lengkap jika lebih dari 7 hari
      return "${date.day}/${date.month}/${date.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} hari lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit lalu";
    } else {
      return "Baru saja";
    }
  }

  // Getter untuk format waktu lengkap (opsional)
  String get fullFormattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Oct', 'Nov', 'Des'
    ];
    
    return "${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}