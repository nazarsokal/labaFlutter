import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'diary_entry_model.dart';
import 'diary_repository.dart';
import 'diary_details_page.dart';

// ------------------ Provider (State & Logic) ------------------

enum LoadingStatus { initial, loading, loaded, error }

class EntryProvider extends ChangeNotifier {
  final DiaryRepository _repository = DiaryRepository();

  LoadingStatus _status = LoadingStatus.initial;
  List<DiaryEntry> _allEntries = [];     
  List<DiaryEntry> _filteredEntries = []; 
  String _errorMessage = '';
  String _searchQuery = '';

  LoadingStatus get status => _status;
  List<DiaryEntry> get entries => _filteredEntries;
  String get errorMessage => _errorMessage;

  EntryProvider() {
    loadEntries();
  }


  Future<void> loadEntries({bool simulateError = false}) async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (simulateError) throw Exception("Test Error Triggered");
      final rawEntries = await _repository.getEntries();
      
      _allEntries = List.from(rawEntries);
      _applyFilter();
      _status = LoadingStatus.loaded;
    } catch (e) {
      _status = LoadingStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> addEntry(DiaryEntry entry) async {
    try {
      await _repository.addEntry(entry);
      loadEntries();
    } catch (e) {
      print("Error adding: $e");
    }
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      await _repository.updateEntry(entry);
      loadEntries();
    } catch (e) {
      print("Error updating: $e");
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _repository.deleteEntry(id);
      loadEntries();
    } catch (e) {
      print("Error deleting: $e");
    }
  }

  // --- Search Logic ---

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredEntries = List.from(_allEntries);
    } else {
      _filteredEntries = _allEntries.where((entry) {
        final q = _searchQuery.toLowerCase();
        return entry.title.toLowerCase().contains(q) ||
               entry.artist.toLowerCase().contains(q) ||
               entry.album.toLowerCase().contains(q);
      }).toList();
    }
  }

  // --- Statistics Logic (Getters) ---

  int get totalEntries => _allEntries.length;

  String get averageRating {
    if (_allEntries.isEmpty) return "0.0";
    final sum = _allEntries.fold(0, (prev, element) => prev + element.rating);
    return (sum / _allEntries.length).toStringAsFixed(1);
  }

  int get uniqueArtistsCount {
    final artists = _allEntries.map((e) => e.artist.trim().toLowerCase()).toSet();
    return artists.length;
  }

  String get topMood {
    if (_allEntries.isEmpty) return "None";
    final moodCount = <String, int>{};
    for (var entry in _allEntries) {
      moodCount[entry.mood] = (moodCount[entry.mood] ?? 0) + 1;
    }
    if (moodCount.isEmpty) return "None";
    
    final sortedMoods = moodCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedMoods.first.key;
  }
}

// ------------------ Main Page Scaffold ------------------

class MainDiaryPage extends StatelessWidget {
  const MainDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EntryProvider(),
      child: const _MainDiaryPageContent(),
    );
  }
}

class _MainDiaryPageContent extends StatefulWidget {
  const _MainDiaryPageContent();

  @override
  State<_MainDiaryPageContent> createState() => _MainDiaryPageState();
}

class _MainDiaryPageState extends State<_MainDiaryPageContent> {
  bool _isStatsView = false; // Стан перемикача: Список або Статистика

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logScreenView(screenName: 'MainDiaryPage');
  }

  // Універсальний діалог для створення та редагування
  void _showEntryDialog(BuildContext context, {DiaryEntry? entryToEdit}) async {
    final result = await showDialog<DiaryEntry>(
      context: context,
      builder: (context) => _EntryDialog(entryToEdit: entryToEdit),
    );

    if (result != null && mounted) {
      if (entryToEdit == null) {
        context.read<EntryProvider>().addEntry(result);
        FirebaseAnalytics.instance.logEvent(name: 'entry_added');
      } else {
        context.read<EntryProvider>().updateEntry(result);
        FirebaseAnalytics.instance.logEvent(name: 'entry_updated');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _HeaderWidget(),
          
          // Пошук показуємо тільки якщо ми в режимі списку
          if (!_isStatsView) const _SearchField(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _AddEntryButton(onPressed: () => _showEntryDialog(context)),
          ),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 8),
          
          // Вкладки перемикання
          _TabsRow(
            isStatsSelected: _isStatsView,
            onTabChanged: (isStats) {
              setState(() => _isStatsView = isStats);
              FirebaseAnalytics.instance.logEvent(
                name: isStats ? 'view_stats' : 'view_list'
              );
            },
          ),
          
          // Основна область контенту
          Expanded(
            child: Consumer<EntryProvider>(
              builder: (context, provider, child) {
                switch (provider.status) {
                  case LoadingStatus.initial:
                  case LoadingStatus.loading:
                    return const Center(child: CircularProgressIndicator(color: Colors.black));
                  
                  case LoadingStatus.error:
                    return Center(
                      child: _ErrorView(
                        message: provider.errorMessage,
                        onRetry: () => provider.loadEntries(simulateError: false),
                        onSimulateError: () => provider.loadEntries(simulateError: true),
                      ),
                    );

                  case LoadingStatus.loaded:
                    // ✅ ЛОГІКА ПЕРЕМИКАННЯ ЕКРАНІВ
                    if (_isStatsView) {
                      return const StatisticsView();
                    } else {
                      if (provider.entries.isEmpty) {
                        return const Center(child: Text("No entries found."));
                      }
                      return _EntriesList(
                        entries: provider.entries,
                        onEdit: (entry) => _showEntryDialog(context, entryToEdit: entry),
                      );
                    }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ Statistics View ------------------

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EntryProvider>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            label: const Text("View Advanced Statistics", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        _StatCard(
          icon: CupertinoIcons.music_note_2,
          iconColor: Colors.blueAccent,
          bgIconColor: Colors.blue.withOpacity(0.1),
          label: "Total Entries",
          value: "${provider.totalEntries}",
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: CupertinoIcons.heart_fill,
          iconColor: Colors.redAccent,
          bgIconColor: Colors.red.withOpacity(0.1),
          label: "Average Rating",
          value: provider.averageRating,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: CupertinoIcons.graph_square_fill,
          iconColor: Colors.green,
          bgIconColor: Colors.green.withOpacity(0.1),
          label: "Unique Artists",
          value: "${provider.uniqueArtistsCount}",
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: CupertinoIcons.calendar,
          iconColor: Colors.purpleAccent,
          bgIconColor: Colors.purple.withOpacity(0.1),
          label: "Top Mood",
          value: provider.topMood,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgIconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgIconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------ UI Components ------------------

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.music_note, size: 30, color: Colors.black),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Music Diary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Track your musical journey', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () {}, 
              icon: Icon(FirebaseAuth.instance.currentUser != null ? Icons.person : Icons.login, size: 28)
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) => context.read<EntryProvider>().search(value),
        decoration: InputDecoration(
          hintText: 'Search songs...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
        ),
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  final bool isStatsSelected;
  final Function(bool) onTabChanged;

  const _TabsRow({required this.isStatsSelected, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final activeStyle = TextButton.styleFrom(
      backgroundColor: Colors.black, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
    final inactiveStyle = TextButton.styleFrom(
      backgroundColor: Colors.transparent, foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => onTabChanged(false),
            icon: const Icon(Icons.list_alt, size: 20),
            label: const Text('Diary Entries'), 
            style: !isStatsSelected ? activeStyle : inactiveStyle,
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => onTabChanged(true),
            icon: const Icon(CupertinoIcons.chart_bar_square, size: 20),
            label: const Text('Statistics'), 
            style: isStatsSelected ? activeStyle : inactiveStyle,
          ),
        ],
      ),
    );
  }
}

class _EntriesList extends StatelessWidget {
  final List<DiaryEntry> entries;
  final Function(DiaryEntry) onEdit;
  
  const _EntriesList({required this.entries, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _DiaryEntryCard(
          entry: entries[index],
          onEdit: () => onEdit(entries[index]),
        );
      },
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onEdit;

  const _DiaryEntryCard({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && entry.userId == user.uid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DiaryDetailsPage(entry: entry)),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  entry.imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.music_note, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit();
                              } else if (value == 'delete') {
                                _confirmDelete(context, entry.id!);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(entry.artist, style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                    Text(entry.album, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMoodTag(entry.mood),
                        const SizedBox(width: 8),
                        _RatingHeartsDisplay(rating: entry.rating, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(entry.notes, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(entry.date, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Entry"),
        content: const Text("Are you sure you want to delete this song?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.black))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EntryProvider>().deleteEntry(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTag(String mood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(4)),
      child: Text(mood, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }
}

// ------------------ Dialogs (Add/Edit) ------------------

class _EntryDialog extends StatefulWidget {
  final DiaryEntry? entryToEdit;
  const _EntryDialog({this.entryToEdit});

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _notesController;
  String? _selectedMood;
  int _selectedRating = 0;
  final List<String> _moods = ['Peaceful', 'Energetic', 'Nostalgic', 'Happy', 'Sad', 'Angry'];

  @override
  void initState() {
    super.initState();
    final e = widget.entryToEdit;
    _titleController = TextEditingController(text: e?.title ?? '');
    _artistController = TextEditingController(text: e?.artist ?? '');
    _albumController = TextEditingController(text: e?.album ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _selectedMood = e?.mood;
    _selectedRating = e?.rating ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.isEmpty || _artistController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final isEditing = widget.entryToEdit != null;

    final entry = DiaryEntry(
      id: widget.entryToEdit?.id,
      title: _titleController.text,
      artist: _artistController.text,
      album: _albumController.text.isEmpty ? "Unknown" : _albumController.text,
      mood: _selectedMood ?? 'Neutral',
      notes: _notesController.text,
      date: isEditing ? widget.entryToEdit!.date : DateTime.now().toString().split(' ')[0],
      rating: _selectedRating,
      imagePath: 'assets/albums/default.jpg',
      userId: isEditing ? widget.entryToEdit!.userId : user?.uid,
    );
    Navigator.pop(context, entry);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.entryToEdit == null ? "Add New Song" : "Edit Song", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey))
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _titleController, decoration: _inputDecoration("Title")),
              const SizedBox(height: 12),
              TextField(controller: _artistController, decoration: _inputDecoration("Artist")),
              const SizedBox(height: 12),
              TextField(controller: _albumController, decoration: _inputDecoration("Album")),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMood,
                decoration: _inputDecoration("Mood"),
                items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedMood = v),
              ),
              const SizedBox(height: 12),
              const Text("Rating", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(children: List.generate(5, (index) => IconButton(
                icon: Icon(index < _selectedRating ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: Colors.red),
                onPressed: () => setState(() => _selectedRating = index + 1),
              ))),
              TextField(controller: _notesController, decoration: _inputDecoration("Notes"), maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: Text(widget.entryToEdit == null ? "Add Entry" : "Save Changes")
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ Misc Helpers ------------------

class _RatingHeartsDisplay extends StatelessWidget {
  final int rating;
  final double size;
  const _RatingHeartsDisplay({required this.rating, this.size = 20});
  @override
  Widget build(BuildContext context) => Row(children: List.generate(5, (i) => Icon(i < rating ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: Colors.red, size: size)));
}

class _AddEntryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddEntryButton({required this.onPressed});
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(onPressed: onPressed, icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add Entry', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSimulateError;
  const _ErrorView({required this.message, required this.onRetry, required this.onSimulateError});
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error, color: Colors.red, size: 50), Text(message), Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton(onPressed: onRetry, child: const Text("Retry")), TextButton(onPressed: onSimulateError, child: const Text("Test Error", style: TextStyle(color: Colors.red)))])]);
}