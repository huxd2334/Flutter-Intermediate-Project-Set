import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() => runApp(const NotesApp());

class Note {
  final String id;
  String title;
  String body;
  DateTime createdAt;
  DateTime updatedAt;
  bool pinned;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });
}

class NotesProvider extends ChangeNotifier {
  final List<Note> _items = [];

  List<Note> get items {
    final list = [..._items];
    list.sort((a, b) {
      if (a.pinned != b.pinned) return b.pinned ? 1 : -1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Note? byId(String id) => _items.firstWhere((n) => n.id == id,
      orElse: () => Note(
          id: '',
          title: '',
          body: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now()));

  String create({String title = '', String body = ''}) {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_${Random().nextInt(999)}';
    _items.add(Note(
      id: id,
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    ));
    notifyListeners();
    return id;
  }

  void update(String id, {String? title, String? body, bool? pinned}) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final n = _items[idx];
    _items[idx] = Note(
      id: n.id,
      title: title ?? n.title,
      body: body ?? n.body,
      createdAt: n.createdAt,
      updatedAt: DateTime.now(),
      pinned: pinned ?? n.pinned,
    );
    notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void togglePin(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final n = _items[idx];
    _items[idx] = Note(
      id: n.id,
      title: n.title,
      body: n.body,
      createdAt: n.createdAt,
      updatedAt: DateTime.now(),
      pinned: !n.pinned,
    );
    notifyListeners();
  }

  List<Note> search(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return items;
    return items
        .where((n) =>
    n.title.toLowerCase().contains(s) ||
        n.body.toLowerCase().contains(s))
        .toList();
  }
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesProvider(),
      child: MaterialApp(
        title: 'Notes App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark),
        home: const NotesHomePage(),
      ),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});
  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  String _query = '';

  void _openEditor(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: id)),
    );
  }

  void _createNew(BuildContext context) {
    final id = context.read<NotesProvider>().create(title: '', body: '');
    _openEditor(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final data = _query.isEmpty ? provider.items : provider.search(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes App'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNew(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm ghi chú',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                border: InputBorder.none,
                enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                focusedBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: data.isEmpty
                ? const _EmptyView()
                : GridView.builder(
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final n = data[i];
                return _NoteGridItem(
                  note: n,
                  onTap: () => _openEditor(context, n.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteGridItem extends StatelessWidget {
  const _NoteGridItem({required this.note, required this.onTap});
  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotesProvider>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? '(Không có tiêu đề)' : note.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.body.isEmpty ? 'Ghi chú trống' : note.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 6,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: note.pinned ? 'Bỏ ghim' : 'Ghim',
                    icon: Icon(
                        note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                    onPressed: () => provider.togglePin(note.id),
                  ),
                  IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Xoá',
                    icon:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => provider.delete(note.id),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('Chưa có ghi chú nào cả',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, required this.noteId});
  final String noteId;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

// Le Cam Binh

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleC;
  late TextEditingController _bodyC;

  @override
  void initState() {
    super.initState();
    final p = context.read<NotesProvider>();
    final note = p.byId(widget.noteId);
    _titleC = TextEditingController(text: note?.title ?? '');
    _bodyC = TextEditingController(text: note?.body ?? '');

    _titleC.addListener(() {
      p.update(widget.noteId, title: _titleC.text);
    });
    _bodyC.addListener(() {
      p.update(widget.noteId, body: _bodyC.text);
    });
  }

  @override
  void dispose() {
    _titleC.dispose();
    _bodyC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = context.watch<NotesProvider>().byId(widget.noteId);

    if (note?.id.isEmpty ?? true) {
      Future.microtask(() => Navigator.pop(context));
    }

    return Scaffold(
      appBar: AppBar(
        title: null,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Ghim/Bỏ ghim',
            icon: Icon(note?.pinned == true
                ? Icons.push_pin
                : Icons.push_pin_outlined),
            onPressed: () => context.read<NotesProvider>().togglePin(widget.noteId),
          ),
          IconButton(
            tooltip: 'Xoá',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              context.read<NotesProvider>().delete(widget.noteId);
              Navigator.pop(context);
            },
          ),
          IconButton(
            tooltip: 'Xong',
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              TextField(
                controller: _titleC,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề',
                  border: InputBorder.none,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _bodyC,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Nội dung ghi chú…',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}