import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Fetch all events
  Future<List<EventModel>> fetchEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('eventDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Fetch events by category
  Future<List<EventModel>> fetchEventsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('category', isEqualTo: category)
          .orderBy('eventDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching events by category: $e');
      return [];
    }
  }

  // Fetch single event
  Future<EventModel?> fetchEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }

  // Create event
  Future<String?> createEvent({
    required String title,
    required String description,
    required String category,
    required String registrationLink,
    required String organizerName,
    required DateTime eventDate,
    required DateTime registrationDeadline,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user');
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final docRef = await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'category': category,
        'registrationLink': registrationLink,
        'organizerName': organizerName,
        'userId': user.uid,
        'eventDate': Timestamp.fromDate(eventDate),
        'registrationDeadline': Timestamp.fromDate(registrationDeadline),
        'createdAt': now,
        'updatedAt': now,
      });

      print('Event created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  // Update event
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String category,
    required String registrationLink,
    String? imageUrl,
    required String organizerName,
    required DateTime eventDate,
    required DateTime registrationDeadline,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'title': title,
        'description': description,
        'category': category,
        'registrationLink': registrationLink,
        'imageUrl': imageUrl,
        'organizerName': organizerName,
        'eventDate': Timestamp.fromDate(eventDate),
        'registrationDeadline': Timestamp.fromDate(registrationDeadline),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      print('Event updated: $eventId');
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      print('Event deleted: $eventId');
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Stream events
  Stream<List<EventModel>> streamEvents() {
    return _firestore
        .collection('events')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Get user's events
  Future<List<EventModel>> fetchUserEvents() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .orderBy('eventDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user events: $e');
      return [];
    }
  }
}