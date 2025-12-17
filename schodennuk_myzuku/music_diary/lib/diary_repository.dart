import 'package:cloud_firestore/cloud_firestore.dart';
import 'diary_entry_model.dart';

class DiaryRepository {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('diary_entries');

  // Отримання списку (сортуємо за датою)
  Future<List<DiaryEntry>> getEntries() async {
    try {
      QuerySnapshot snapshot = await _collection.orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => DiaryEntry.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Помилка завантаження даних: $e');
    }
  }

  // Додавання нового запису
  Future<void> addEntry(DiaryEntry entry) async {
    await _collection.add(entry.toMap());
  }

  // Оновлення існуючого запису
  Future<void> updateEntry(DiaryEntry entry) async {
    if (entry.id == null) return;
    await _collection.doc(entry.id).update(entry.toMap());
  }

  // Видалення запису
  Future<void> deleteEntry(String id) async {
    await _collection.doc(id).delete();
  }
}