import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';

void main() => runApp(const NewsApp());

const String _apiKey = 'f79313a09aaf40e08e7ba83c4f2e52ee';

Map<String, dynamic> _parseJson(String body) => jsonDecode(body) as Map<String, dynamic>;
const String _baseUrl = 'https://newsapi.org/v2/top-headlines';

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Reader App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const NewsHomePage(),
    );
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  String _category = 'general';
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchArticles();
  }

  Future<List<Article>> _fetchArticles() async {
    final uri = Uri.parse('$_baseUrl?country=us&category=$_category&apiKey=$_apiKey');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }

    final Map<String, dynamic> data = await compute(_parseJson, res.body);

    if (data['status'] != 'ok') {
      final code = data['code'] ?? 'unknown_error';
      final msg = data['message'] ?? 'Unknown error';
      throw Exception('API error [$code]: $msg');
    }

    final List list = data['articles'] ?? [];
    return list.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _reload() async {
    final f = _fetchArticles();
    setState(() {
      _future = f;
    });
    await f;
  }


  void _changeCategory(String c) {
    if (c == _category) return;
    final f = _fetchArticles();
    setState(() {
      _category = c;
      _future = f;
    });
  }


  @override
  Widget build(BuildContext context) {
    final categories = ['general', 'technology', 'health', 'sports', 'entertainment'];

    return Scaffold(
      appBar: AppBar(title: const Text('News Reader App')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => _changeCategory(c),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: FutureBuilder<List<Article>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorView(error: snapshot.error.toString(), onRetry: _reload);
                  }
                  final articles = snapshot.data ?? [];
                  if (articles.isEmpty) return const _EmptyView();
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, i) => ArticleTile(article: articles[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text('Lỗi tải dữ liệu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.article_outlined, size: 56),
        const SizedBox(height: 8),
        Text('Không có bài viết', style: Theme.of(context).textTheme.titleMedium),
      ]),
    );
  }
}

class ArticleTile extends StatelessWidget {
  const ArticleTile({super.key, required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final imageUrl = article.urlToImage;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: article.url != null
            ? () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailPage(article: article),
          ),
        )
            : null,
        child: SizedBox(
          height: 130,
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: (imageUrl != null)
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _errorImage(),
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                )
                    : _errorImage(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title ?? '(Không có tiêu đề)',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          article.description ?? article.content ?? '',
                          style: textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (article.sourceName != null)
                            Flexible(
                              child: Text(
                                article.sourceName!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const Spacer(),
                          if (article.publishedAt != null)
                            Text(_timeAgo(article.publishedAt!), style: textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorImage() => Container(
    color: Colors.black12,
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported_outlined, size: 40),
  );
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

class Article {
  final String? title;
  final String? description;
  final String? content;
  final String? url;
  final String? urlToImage;
  final String? sourceName;
  final DateTime? publishedAt;

  Article({
    this.title,
    this.description,
    this.content,
    this.url,
    this.urlToImage,
    this.sourceName,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
    title: j['title'] as String?,
    description: j['description'] as String?,
    content: j['content'] as String?,
    url: j['url'] as String?,
    urlToImage: j['urlToImage'] as String?,
    sourceName: (j['source']?['name']) as String?,
    publishedAt: j['publishedAt'] != null
        ? DateTime.tryParse(j['publishedAt'])
        : null,
  );
}

class ArticleDetailPage extends StatefulWidget {
  final Article article;
  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late final WebViewController _controller;
  int _loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loadingPercentage = 0),
          onProgress: (progress) => setState(() => _loadingPercentage = progress),
          onPageFinished: (_) => setState(() => _loadingPercentage = 100),
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url!));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.article.url!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double progressHeight = 3.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.sourceName ?? 'Chi tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: 'Mở trong trình duyệt',
          ),
        ],
        bottom: _loadingPercentage < 100
            ? PreferredSize(
          preferredSize: const Size.fromHeight(progressHeight),
          child: LinearProgressIndicator(
            value: _loadingPercentage / 100.0,
            minHeight: progressHeight,
          ),
        )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
