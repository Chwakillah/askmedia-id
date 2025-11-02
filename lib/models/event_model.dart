import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category; 
  final String registrationLink;
  final String organizerName;
  final String userId; 
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int createdAt;
  final int updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.registrationLink,
    required this.organizerName,
    required this.userId,
    required this.eventDate,
    required this.registrationDeadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'webinar',
      registrationLink: data['registrationLink'] ?? '',
      organizerName: data['organizerName'] ?? '',
      userId: data['userId'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp).toDate(),
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'registrationLink': registrationLink,
      'organizerName': organizerName,
      'userId': userId,
      'eventDate': Timestamp.fromDate(eventDate),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isRegistrationOpen {
    return DateTime.now().isBefore(registrationDeadline);
  }

  String get categoryLabel {
    switch (category) {
      case 'webinar':
        return 'Webinar';
      case 'lomba':
        return 'Lomba';
      case 'beasiswa':
        return 'Beasiswa';
      case 'kuisioner':
        return 'Kuisioner';
      case 'magang':
        return 'Magang';
      default:
        return 'Event';
    }
  }
}