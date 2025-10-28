import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CategoryAdapter());
  await Hive.openBox<Expense>('expensesBox');
  runApp(const ExpenseApp());
}

@HiveType(typeId: 1)
enum Category {
  @HiveField(0) food,
  @HiveField(1) transport,
  @HiveField(2) shopping,
  @HiveField(3) bills,
  @HiveField(4) entertainment,
  @HiveField(5) health,
  @HiveField(6) other,
}

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  double amount;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  Category category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      category: fields[4] as Category,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category);
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Category.food;
      case 1:
        return Category.transport;
      case 2:
        return Category.shopping;
      case 3:
        return Category.bills;
      case 4:
        return Category.entertainment;
      case 5:
        return Category.health;
      default:
        return Category.other;
    }
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    switch (obj) {
      case Category.food:
        writer.writeByte(0);
        break;
      case Category.transport:
        writer.writeByte(1);
        break;
      case Category.shopping:
        writer.writeByte(2);
        break;
      case Category.bills:
        writer.writeByte(3);
        break;
      case Category.entertainment:
        writer.writeByte(4);
        break;
      case Category.health:
        writer.writeByte(5);
        break;
      case Category.other:
        writer.writeByte(6);
        break;
    }
  }
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker (Hive)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        cardTheme: CardThemeData(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ),
      ),
      home: const ExpenseHomePage(),
    );
  }
}

// Le Cam Binh

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  int _tabIndex = 0;
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = _range ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'Chọn khoảng thời gian',
      saveText: 'Áp dụng',
    );
    if (picked != null) setState(() => _range = picked);
  }

  // Le Cam Binh

  void _clearRange() => setState(() => _range = null);

  void _openEditor(BuildContext context, {Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ExpenseEditorSheet(expense: expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expensesBox');
    final titles = ['Expense Tracker', 'Expense Tracker'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: [
          IconButton(onPressed: _pickRange, tooltip: 'Lọc ngày', icon: const Icon(Icons.filter_alt_outlined)),
          if (_range != null)
            IconButton(onPressed: _clearRange, tooltip: 'Xóa lọc', icon: const Icon(Icons.filter_alt_off_outlined)),
        ],

        bottom: _range == null
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight - 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text('${_fmtDate(_range!.start)} - ${_fmtDate(_range!.end)}'),
              onDeleted: _clearRange,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              deleteIconColor: Theme.of(context).colorScheme.onSecondaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Chi tiêu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Thống kê'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Expense> b, _) {
          final expenses = b.values.toList()..sort((a, b) => b.date.compareTo(a.date));
          final filtered = _applyRangeFilter(expenses, _range);
          final total = filtered.fold(0.0, (s, e) => s + e.amount);

          return IndexedStack(
            index: _tabIndex,
            children: [
              _ExpenseListView(
                items: filtered,
                total: total,
                onEdit: (e) => _openEditor(context, expense: e),
              ),
              _StatsView(all: filtered),
            ],
          );
        },
      ),
    );
  }

  List<Expense> _applyRangeFilter(List<Expense> items, DateTimeRange? range) {
    if (range == null) return items;
    return items.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final s = DateTime(range.start.year, range.start.month, range.start.day);
      final t = DateTime(range.end.year, range.end.month, range.end.day);
      return !d.isBefore(s) && !d.isAfter(t);
    }).toList();
  }
}
class _ExpenseListView extends StatelessWidget {
  const _ExpenseListView({required this.items, required this.total, required this.onEdit});
  final List<Expense> items;
  final double total;
  final void Function(Expense e) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryHeader(total: total),
        if (items.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Chưa có chi tiêu.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 90),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final e = items[i];
                return Slidable(
                  key: ValueKey(e.id),
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => onEdit(e),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Sửa',
                        borderRadius: BorderRadius.circular(12),
                      ),
                      SlidableAction(
                        onPressed: (_) async {
                          await e.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa')),
                          );
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Xóa',
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0.2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _catColor(e.category).withOpacity(0.15),
                        foregroundColor: _catColor(e.category),
                        child: Icon(_catIconData(e.category), size: 20), // <-- Dùng Icon()
                      ),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${_fmtDate(e.date)} • ${_catLabel(e.category)}'),

                      trailing: Text(
                        _money(e.amount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng chi tiêu',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      _money(total),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
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
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.all});
  final List<Expense> all;

  @override
  Widget build(BuildContext context) {
    final byDay = _sumLast7Days(all);
    final byCat = _sumByCategoryThisMonth(all);

    final categoriesWithSpending = byCat.entries.where((e) => e.value > 0).toList();
    categoriesWithSpending.sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7 ngày gần đây', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(_shortMoney(value), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= byDay.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(byDay[i].label, style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < byDay.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: byDay[i].amount,
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                color: Theme.of(context).colorScheme.primary,
                              )
                            ],
                          ),
                      ],
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theo danh mục (tháng này)', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        for (final e in categoriesWithSpending)
                          PieChartSectionData(
                            color: _catColor(e.key),
                            value: e.value,
                            title: e.value == 0 ? '' : _shortMoney(e.value),
                            radius: 70,
                            titleStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    children: [
                      for (final entry in categoriesWithSpending)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _catColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_catLabel(entry.key))),
                              Text(_money(entry.value), style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_DaySum> _sumLast7Days(List<Expense> items) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final map = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      map[_key(d)] = 0;
    }
    for (final e in items) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d.isBefore(start) || d.isAfter(DateTime(now.year, now.month, now.day))) continue;
      map[_key(d)] = (map[_key(d)] ?? 0) + e.amount;
    }
    final arr = <_DaySum>[];
    map.forEach((k, v) {
      final d = _parseKey(k);
      arr.add(_DaySum(label: '${d.day}/${d.month}', amount: v));
    });
    arr.sort((a, b) {
      final aParts = a.label.split('/');
      final bParts = b.label.split('/');
      final ad = DateTime(now.year, int.parse(aParts[1]), int.parse(aParts[0]));
      final bd = DateTime(now.year, int.parse(bParts[1]), int.parse(bParts[0]));
      return ad.compareTo(bd);
    });
    return arr;
  }

  Map<Category, double> _sumByCategoryThisMonth(List<Expense> items) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final nextMonth = (now.month == 12) ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final map = {for (final c in Category.values) c: 0.0};
    for (final e in items) {
      if (e.date.isAfter(nextMonth) || e.date.isAtSameMomentAs(nextMonth)) continue;
      if (e.date.isBefore(first)) continue;
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
  DateTime _parseKey(String k) {
    final p = k.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
}

class _DaySum {
  final String label;
  final double amount;
  _DaySum({required this.label, required this.amount});
}

class ExpenseEditorSheet extends StatefulWidget {
  const ExpenseEditorSheet({super.key, this.expense});
  final Expense? expense;

  @override
  State<ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<ExpenseEditorSheet> {
  late TextEditingController _title;
  late TextEditingController _amount;
  late DateTime _date;
  Category _cat = Category.other;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(text: e != null ? e.amount.toStringAsFixed(0) : '');
    _date = e?.date ?? DateTime.now();
    _cat = e?.category ?? Category.other;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // [MỚI] Hàm chọn Category bằng bottom sheet
  Future<void> _pickCategory() async {
    final cat = await showModalBottomSheet<Category>(
      context: context,
      builder: (ctx) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Chọn danh mục', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            ...Category.values.map((c) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _catColor(c).withOpacity(0.15),
                foregroundColor: _catColor(c),
                child: Icon(_catIconData(c), size: 20),
              ),
              title: Text(_catLabel(c)),
              onTap: () => Navigator.pop(ctx, c),
            ))
          ],
        );
      },
    );
    if (cat != null) setState(() => _cat = cat);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final amt = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (title.isEmpty || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tiêu đề và số tiền > 0')));
      return;
    }
    final box = Hive.box<Expense>('expensesBox');

    if (widget.expense == null) {
      final id = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999)}';
      await box.add(Expense(id: id, title: title, amount: amt, date: _date, category: _cat));
    } else {
      final e = widget.expense!;
      e.title = title;
      e.amount = amt;
      e.date = _date;
      e.category = _cat;
      await e.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              isEditing ? 'Sửa chi tiêu' : 'Thêm chi tiêu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề (ví dụ: Ăn trưa)',
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Số tiền',
              prefixText: '₫ ',
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Danh mục'),
                  trailing: Text(_catLabel(_cat)),
                  onTap: _pickCategory,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Ngày'),
                  trailing: Text(_fmtDate(_date)),
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            onPressed: _save,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(isEditing ? 'Cập nhật' : 'Lưu'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

String _money(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final left = s.length - i - 1;
    if (left % 3 == 0 && i != s.length - 1) buf.write(',');
  }
  return '${buf.toString()} ₫';
}

String _shortMoney(double v) {
  if (v == 0) return '0';
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _catLabel(Category c) {
  switch (c) {
    case Category.food: return 'Ăn uống';
    case Category.transport: return 'Di chuyển';
    case Category.shopping: return 'Mua sắm';
    case Category.bills: return 'Hóa đơn';
    case Category.entertainment: return 'Giải trí';
    case Category.health: return 'Sức khỏe';
    case Category.other: return 'Khác';
  }
}

IconData _catIconData(Category c) {
  switch (c) {
    case Category.food:
      return Icons.restaurant_menu;
    case Category.transport:
      return Icons.directions_bus;
    case Category.shopping:
      return Icons.shopping_bag;
    case Category.bills:
      return Icons.receipt_long;
    case Category.entertainment:
      return Icons.movie;
    case Category.health:
      return Icons.medical_services;
    case Category.other:
      return Icons.category;
  }
}

Color _catColor(Category c) {
  switch (c) {
    case Category.food: return Colors.orange;
    case Category.transport: return Colors.blue;
    case Category.shopping: return Colors.purple;
    case Category.bills: return Colors.red;
    case Category.entertainment: return Colors.teal;
    case Category.health: return Colors.green;
    case Category.other: return Colors.grey;
  }
}