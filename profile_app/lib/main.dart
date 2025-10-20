import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatefulWidget {
  const ProfileApp({super.key});
  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Profile',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomePage(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onToggleTheme, required this.isDark});
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Toggle Dark Mode',
            onPressed: onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final content = isWide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 420, child: const _LeftPane()),
              const SizedBox(width: 16),
              const Expanded(child: _RightPane()),
            ],
          )
              : const _NarrowLayout();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeftPane extends StatelessWidget {
  const _LeftPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 56,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lê Cẩm Bình',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '2004 - Final Year Student at VKU',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Developer • AI Enthusiast',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _ContactCard(),
        const SizedBox(height: 12),
        const _SkillsCard(),
      ],
    );
  }
}

class _RightPane extends StatelessWidget {
  const _RightPane();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _AboutCard(),
        SizedBox(height: 12),
        _HighlightsCard(),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _HeaderCard(),
        SizedBox(height: 12),
        _AboutCard(),
        SizedBox(height: 12),
        _LanguagesCard(),
        SizedBox(height: 12),
        _SkillsCard(),
        SizedBox(height: 12),
        _ContactCard(),
        SizedBox(height: 12),
        _HighlightsCard(),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lê Cẩm Bình',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('2004 - Final Year Student at VKU',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text('Developer • AI Enthusiast',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context, 'About Me'),
            const SizedBox(height: 8),
            const Text(
              'Mình có niềm đam mê với lập trình và phát triển phần mềm. Mình thích AI nên đang tim hiểu. Ngoài ra mình cũng bắt đầu tìm hiểu Flutter.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard();

  @override
  Widget build(BuildContext context) {
    final skills = [
      'Python',
      'ReactJS',
      'REST APIs',
      'Java',
      'Flutter',
      'MySQL',
      'PostgreSQL',
      'Git',
      'Figma',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context, 'Skills'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 8,
              children: skills.map((s) => Chip(label: Text(s))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagesCard extends StatelessWidget {
  const _LanguagesCard();

  @override
  Widget build(BuildContext context) {
    final languages = [
      'English: TOEIC 730',
      'Korean: Intermediate',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context, 'Languages'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((s) => Chip(label: Text(s))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: const Text('binhlexd04@gmail.com'),
            onTap: () => _open('mailto:binhlexd04@gmail.com'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('GitHub'),
            subtitle: const Text('https://github.com/huxd2334'),
            onTap: () => _open('https://github.com/huxd2334'),
          ),
        ],
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Crop Yield Prediction', 'A website for predicting crop yield using geospatial indices, satellite imagery, and weather data.'),
      ('LAN Monitor', 'A system to monitor devices connected to a LAN, built with C#.'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              title: _title(context, 'Highlights'),
            ),
            const Divider(height: 1),
            ...items.map((e) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(e.$1),
                  subtitle: Text(e.$2),
                ),
                if (e != items.last) const Divider(height: 1),
              ],
            ))
          ],
        ),
      ),
    );
  }
}

Widget _title(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}
