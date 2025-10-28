import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple, brightness: Brightness.dark),
      home: const GalleryHomePage(),
    );
  }
}

class GalleryHomePage extends StatefulWidget {
  const GalleryHomePage({super.key});
  @override
  State<GalleryHomePage> createState() => _GalleryHomePageState();
}

class _GalleryHomePageState extends State<GalleryHomePage> {
  final ImagePicker _picker = ImagePicker();
  final String _prefsKey = 'gallery_paths_v1';
  List<String> _paths = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _paths = prefs.getStringList(_prefsKey) ?? [];
    _paths = _paths.where((p) => File(p).existsSync()).toList();
    setState(() => _loading = false);
  }

  Future<void> _savePaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _paths);
  }

  Future<void> _captureFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showSnack('Chưa cấp quyền camera');
      return;
    }
    final xfile = await _picker.pickImage(source: ImageSource.camera, maxWidth: 2000, maxHeight: 2000);
    if (xfile == null) return;
    await _persistAndAdd(xfile);
  }

  Future<void> _pickFromGallery() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 3000,
      maxHeight: 3000,
    );
    if (xfile == null) return;
    await _persistAndAdd(xfile);
  }

// Le Cam Binh

  Future<void> _persistAndAdd(XFile x) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = x.path.split('.').last;
    final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destPath = '${dir.path}/$fileName';
    await File(x.path).copy(destPath);

    setState(() => _paths.insert(0, destPath));
    await _savePaths();
  }

  Future<void> _deleteAt(int index) async {
    final path = _paths[index];
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    setState(() => _paths.removeAt(index));
    await _savePaths();
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullscreenViewer(paths: _paths, initialIndex: index)),
    );
  }
// Le Cam Binh
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            tooltip: 'Chọn từ thư viện',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _pickFromGallery,
          ),
          IconButton(
            tooltip: 'Chụp ảnh',
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: _captureFromCamera,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureFromCamera,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Chụp'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _paths.isEmpty
          ? const _EmptyView()
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: _paths.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, i) {
            final p = _paths[i];
            return GestureDetector(
              onTap: () => _openViewer(i),
              onLongPress: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xóa ảnh?'),
                    content: const Text('Ảnh sẽ bị xóa khỏi bộ nhớ ứng dụng.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
                    ],
                  ),
                );
                if (ok == true) _deleteAt(i);
              },
              child: Hero(
                tag: p,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(p),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            );
          },
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
            const Icon(Icons.photo_library_outlined, size: 64),
            const SizedBox(height: 12),
            Text('Chưa có ảnh nào', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class FullscreenViewer extends StatefulWidget {
  const FullscreenViewer({super.key, required this.paths, required this.initialIndex});
  final List<String> paths;
  final int initialIndex;

  @override
  State<FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<FullscreenViewer> {
  late final PageController _page = PageController(initialPage: widget.initialIndex);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.paths;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1}/${paths.length}'),
      ),
      body: PageView.builder(
        controller: _page,
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: paths.length,
        itemBuilder: (_, i) {
          final p = paths[i];
          return Center(
            child: Hero(
              tag: p,
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.file(
                  File(p),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}