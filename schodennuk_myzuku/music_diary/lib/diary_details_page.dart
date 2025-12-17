import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Для іконок CupertinoIcons
import 'diary_entry_model.dart'; // Імпорт твоєї моделі

class DiaryDetailsPage extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailsPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Entry Details', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Обкладинка альбому
            Center(
              child: Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), 
                      blurRadius: 15, 
                      offset: const Offset(0, 8)
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    entry.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Заголовок та Виконавець
            Text(
              entry.title, 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              "${entry.artist} • ${entry.album}", 
              style: TextStyle(fontSize: 16, color: Colors.grey[700])
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            
            // Деталі: Дата та Настрій
            _buildDetailRow("Date", entry.date),
            const SizedBox(height: 12),
            _buildDetailRow("Mood", entry.mood, isHighlight: true),
            
            const SizedBox(height: 12),
            
            // Рейтинг
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Rating", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                _DetailsRatingHearts(rating: entry.rating),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Нотатки
            const Text("Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.notes.isNotEmpty ? entry.notes : "No notes added.",
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        isHighlight 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// Локальний віджет для відображення сердечок саме на цій сторінці
class _DetailsRatingHearts extends StatelessWidget {
  final int rating;
  const _DetailsRatingHearts({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) => Icon(
        index < rating ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
        color: Colors.red,
        size: 20,
      )),
    );
  }
}