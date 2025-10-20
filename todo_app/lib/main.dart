import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const TodoApp());

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      home: const TodoHomePage(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.done,
    required this.createdAt,
  });

  Task copyWith({String? id, String? title, bool? done, DateTime? createdAt}) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    done: done ?? this.done,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  static Task fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    title: j['title'] as String,
    done: j['done'] as bool,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});
  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final String _storageKey = 'todos_v1';
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _tasks = list.map(Task.fromJson).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_tasks.map((e) => e.toJson()).toList()));
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.add(Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        done: false,
        createdAt: DateTime.now(),
      ));
    });
    _saveToStorage();
  }

  void _toggleTask(Task t) {
    setState(() {
      final i = _tasks.indexWhere((e) => e.id == t.id);
      _tasks[i] = t.copyWith(done: !t.done);
    });
    _saveToStorage();
  }

  void _editTask(Task t, String newTitle) {
    if (newTitle.trim().isEmpty) return;
    setState(() {
      final i = _tasks.indexWhere((e) => e.id == t.id);
      _tasks[i] = t.copyWith(title: newTitle.trim());
    });
    _saveToStorage();
  }

  void _deleteTask(Task t) {
    setState(() => _tasks.removeWhere((e) => e.id == t.id));
    _saveToStorage();
  }

  void _showAddSheet() {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New Task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nhập task...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                _addTask(c.text);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _addTask(c.text);
                Navigator.pop(ctx);
              },
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Task t) {
    final c = TextEditingController(text: t.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit task'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'task...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                _editTask(t, c.text);
                Navigator.pop(ctx);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo app'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddSheet),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const _EmptyState()
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (ctx, i) {
          final t = _tasks[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Checkbox(
                value: t.done,
                onChanged: (_) => _toggleTask(t),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  decoration: t.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Text(
                'Tạo: ${t.createdAt.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Sửa',
                    onPressed: () => _showEditDialog(t),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => _deleteTask(t),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 60),
            const SizedBox(height: 12),
            Text('Chưa có task nào',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Nhấn nút + để thêm task mới'),
          ],
        ),
      ),
    );
  }
}
