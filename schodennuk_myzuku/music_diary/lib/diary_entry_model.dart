import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String? id;
  final String title;
  final String artist;
  final String album;
  final String mood;
  final String notes;
  final String date;
  final int rating;
  final String imagePath;
  final String? userId;

  const DiaryEntry({
    this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.mood,
    required this.notes,
    required this.date,
    required this.rating,
    required this.imagePath,
    this.userId,
  });

  // Перетворення з Firebase у Dart об'єкт
  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'] ?? '',
      mood: data['mood'] ?? '',
      notes: data['notes'] ?? '',
      date: data['date'] ?? '',
      rating: (data['rating'] ?? 0).toInt(),
      imagePath: data['imagePath'] ?? 'assets/albums/default.jpg',
      userId: data['userId'],
    );
  }

  // Перетворення Dart об'єкта у Map для запису в Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'mood': mood,
      'notes': notes,
      'date': date,
      'rating': rating,
      'imagePath': imagePath,
      'userId': userId,
    };
  }
}