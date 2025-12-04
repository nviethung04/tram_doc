import 'package:flutter/material.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú Chủ động'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
            },
          ),
        ],
      ),
      body: _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add note screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList() {
    // TODO: Load notes from Firebase
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có ghi chú nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // TODO: Navigate to add note screen
            },
            child: const Text('Tạo ghi chú đầu tiên'),
          ),
        ],
      ),
    );
  }
}

