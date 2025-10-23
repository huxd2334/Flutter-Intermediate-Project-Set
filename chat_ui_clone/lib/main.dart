import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const ChatApp());

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat UI Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark),
      home: const ChatPage(),
    );
  }
}

class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.createdAt,
  });
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final List<Message> _messages = [];
  bool _botTyping = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _messages.insertAll(0, [
      Message(id: 'm1', text: 'Chào Bình', isMe: false, createdAt: now.subtract(const Duration(minutes: 28))),
    ]);
  }

  void _send() {
    final txt = _input.text.trim();
    if (txt.isEmpty) return;
    final msg = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: txt,
      isMe: true,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, msg);
      _input.clear();
    });
    _scrollToBottom();

    _simulateBotReply();
  }

  void _simulateBotReply() async {
    setState(() => _botTyping = true);
    await Future.delayed(const Duration(milliseconds: 900));
    final reply = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: 'Đã nhận "${_messages.first.text}"!',
      isMe: false,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, reply);
      _botTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            const CircleAvatar(radius: 18, child: Text('B')),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BOT',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                Text(_botTyping ? 'Bot đang nhập...' : 'Đang hoạt động',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: _messages.length + _headerCount(),
              itemBuilder: (context, visualIndex) {
                final mapped = _mapIndex(visualIndex);
                if (mapped.isHeader) {
                  return _DateHeader(text: mapped.headerText!);
                }
                final i = mapped.msgIndex!;
                final msg = _messages[i];

                final prevMsg = (i + 1 < _messages.length) ? _messages[i + 1] : null;
                final nextMsg = (i - 1 >= 0) ? _messages[i - 1] : null;

                final isFirstOfGroup = prevMsg == null ||
                    prevMsg.isMe != msg.isMe ||
                    !_isSameDay(prevMsg.createdAt, msg.createdAt) ||
                    prevMsg.createdAt.difference(msg.createdAt).inMinutes.abs() > 10;

                final isLastOfGroup = nextMsg == null ||
                    nextMsg.isMe != msg.isMe ||
                    !_isSameDay(nextMsg.createdAt, msg.createdAt) ||
                    nextMsg.createdAt.difference(msg.createdAt).inMinutes.abs() > 10;

                return _MessageRow(
                  message: msg,
                  isFirstOfGroup: isFirstOfGroup,
                  isLastOfGroup: isLastOfGroup,
                );
              },
            ),
          ),
          _InputBar(
            controller: _input,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  List<_HeaderInfo> get _headers {
    final result = <_HeaderInfo>[];
    DateTime? lastDay;
    for (var i = 0; i < _messages.length; i++) {
      final d = _messages[i].createdAt;
      if (lastDay == null || !_isSameDay(d, lastDay)) {
        result.add(_HeaderInfo(i, _formatDay(d)));
        lastDay = d;
      }
    }
    return result;
  }

  int _headerCount() => _headers.length;

  _MappedIndex _mapIndex(int visualIndex) {
    var msgIndex = visualIndex;
    for (final h in _headers) {
      if (visualIndex == h.visualInsertIndex) {
        return _MappedIndex.header(h.text);
      }
      if (visualIndex > h.visualInsertIndex) msgIndex--;
    }
    return _MappedIndex.message(msgIndex);
  }

  String _formatDay(DateTime d) {
    final today = DateTime.now();
    if (_isSameDay(d, today)) return 'Hôm nay';
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(d, yesterday)) return 'Hôm qua';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _HeaderInfo {
  final int firstMsgIndexOfDay;
  final String text;
  _HeaderInfo(this.firstMsgIndexOfDay, this.text);

  int get visualInsertIndex => firstMsgIndexOfDay;
}

class _MappedIndex {
  final bool isHeader;
  final int? msgIndex;
  final String? headerText;
  _MappedIndex.message(this.msgIndex)
      : isHeader = false,
        headerText = null;
  _MappedIndex.header(this.headerText)
      : isHeader = true,
        msgIndex = null;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

// Le Cam Binh

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isFirstOfGroup,
    required this.isLastOfGroup,
  });

  final Message message;
  final bool isFirstOfGroup;
  final bool isLastOfGroup;

  String _fmtTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstOfGroup ? 10 : 2,
        bottom: 2,
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
      ),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _Bubble(
            text: message.text,
            isMe: isMe,
          ),
          if (isLastOfGroup)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _fmtTime(message.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isMe,
  });

  final String text;
  final bool isMe;

  BorderRadius _radius() {
    return BorderRadius.circular(18);
  }

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceVariant;
    final fg = isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onLongPress: () => _showMessageActions(context, text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: _radius()),
        constraints: const BoxConstraints(maxWidth: 320),
        child: SelectableText(
          text,
          style: TextStyle(color: fg, fontSize: 15),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('Sao chép'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('Trả lời'),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// Le Cam Binh

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}