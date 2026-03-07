import 'dart:math';
import 'package:hive/hive.dart';
import '../shared/utils/dates.dart';
import 'hive_boxes.dart';

class FinanceStore {
  Box<Map> get _incomes => Hive.box<Map>(HiveBoxes.incomes);
  Box<Map> get _expenses => Hive.box<Map>(HiveBoxes.expenses);
  Box<Map> get _settings => Hive.box<Map>(HiveBoxes.settings);

  // ---------- Utils
  DateTime _parseDate(String s) => DateTime.parse(s); // yyyy-MM-dd
  String _genId() {
    final r = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${r.nextInt(1 << 20)}';
  }

  String _monthKey(int year, int month) => 'budget_${year}_${month.toString().padLeft(2, '0')}';

  // ---------- Incomes
  List<Map<String, dynamic>> listIncomes() {
    return _incomes.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }

  Future<void> addIncome({
    required double amount,
    DateTime? date,
    String? note,
  }) async {
    final d = date ?? DateTime.now();
    await _incomes.add({
      'id': _genId(),
      'amount': amount,
      'date': Dates.ymd(d),
      'note': note?.trim() ?? '',
    });
  }

  Future<void> deleteIncome(String id) async {
    for (final key in _incomes.keys) {
      final m = _incomes.get(key);
      if (m != null && m['id'] == id) {
        await _incomes.delete(key);
        return;
      }
    }
  }

  // ---------- Expenses
  List<Map<String, dynamic>> listExpenses() {
    return _expenses.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    DateTime? date,
    String? note,
  }) async {
    final d = date ?? DateTime.now();
    await _expenses.add({
      'id': _genId(),
      'category': category,
      'amount': amount,
      'date': Dates.ymd(d),
      'note': note?.trim() ?? '',
    });
  }

  Future<void> deleteExpense(String id) async {
    for (final key in _expenses.keys) {
      final m = _expenses.get(key);
      if (m != null && m['id'] == id) {
        await _expenses.delete(key);
        return;
      }
    }
  }

  // ---------- Monthly filters
  List<Map<String, dynamic>> listExpensesForMonth(int year, int month) {
    return listExpenses().where((e) {
      final d = _parseDate((e['date'] ?? '1970-01-01').toString());
      return d.year == year && d.month == month;
    }).toList();
  }

  List<Map<String, dynamic>> listIncomesForMonth(int year, int month) {
    return listIncomes().where((e) {
      final d = _parseDate((e['date'] ?? '1970-01-01').toString());
      return d.year == year && d.month == month;
    }).toList();
  }

  double expensesTotalForMonth(int year, int month) {
    final items = listExpensesForMonth(year, month);
    return items.fold<double>(0.0, (a, e) => a + ((e['amount'] ?? 0) as num).toDouble());
  }

  double incomesTotalForMonth(int year, int month) {
    final items = listIncomesForMonth(year, month);
    return items.fold<double>(0.0, (a, e) => a + ((e['amount'] ?? 0) as num).toDouble());
  }

  Map<String, double> expensesByCategoryForMonth(int year, int month) {
    final items = listExpensesForMonth(year, month);
    final Map<String, double> map = {};
    for (final m in items) {
      final cat = (m['category'] ?? 'otros') as String;
      final amt = (m['amount'] as num).toDouble();
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return map;
  }

  // ---------- Monthly budget (settings_box)
  Map<String, dynamic> getBudgetFor(int year, int month) {
    final key = _monthKey(year, month);
    final raw = _settings.get(key);

    if (raw == null) {
      return {
        'mode': 'percent',
        'percent': 60.0,
        'fixedAmount': 0.0,
      };
    }
    final map = Map<String, dynamic>.from(raw);
    map.putIfAbsent('mode', () => 'percent');
    map.putIfAbsent('percent', () => 60.0);
    map.putIfAbsent('fixedAmount', () => 0.0);
    return map;
  }

  Future<void> setBudgetFor({
    required int year,
    required int month,
    required String mode, // 'percent' | 'fixed'
    required double percent,
    required double fixedAmount,
  }) async {
    final key = _monthKey(year, month);
    await _settings.put(key, {
      'mode': mode,
      'percent': percent,
      'fixedAmount': fixedAmount,
    });
  }

  /// Presupuesto del mes:
  /// - percent: ingresos del mes * percent
  /// - fixed: fixedAmount
  double budgetAmountForMonth(int year, int month) {
    final b = getBudgetFor(year, month);
    final mode = (b['mode'] ?? 'percent') as String;
    final percent = ((b['percent'] ?? 0.0) as num).toDouble();
    final fixed = ((b['fixedAmount'] ?? 0.0) as num).toDouble();

    if (mode == 'fixed') return fixed;

    final inc = incomesTotalForMonth(year, month);
    return inc * (percent / 100.0);
  }

  /// Presupuesto "general": suma de presupuestos mensuales detectados (meses con ingresos o gastos)
  double budgetTotalDetectedMonths() {
    final months = detectedMonths();
    double sum = 0.0;
    for (final ym in months) {
      sum += budgetAmountForMonth(ym.$1, ym.$2);
    }
    return sum;
  }

  /// Meses detectados según ingresos/gastos
  Set<(int, int)> detectedMonths() {
    final Set<(int, int)> out = {};

    for (final m in _incomes.values) {
      final d = _parseDate((m['date'] ?? '1970-01-01').toString());
      out.add((d.year, d.month));
    }
    for (final m in _expenses.values) {
      final d = _parseDate((m['date'] ?? '1970-01-01').toString());
      out.add((d.year, d.month));
    }
    return out;
  }

  // ---------- Totals (global)
  double incomesTotal() {
    return _incomes.values.fold<double>(0.0, (a, m) => a + (m['amount'] as num).toDouble());
  }

  double expensesTotal() {
    return _expenses.values.fold<double>(0.0, (a, m) => a + (m['amount'] as num).toDouble());
  }

  Map<String, double> expensesByCategory() {
    final Map<String, double> map = {};
    for (final m in _expenses.values) {
      final cat = (m['category'] ?? 'otros') as String;
      final amt = (m['amount'] as num).toDouble();
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return map;
  }

  // ---------- Alert Settings (global)
  Map<String, dynamic> getAlertSettings() {
    final raw = _settings.get('alerts') ?? {};
    final map = Map<String, dynamic>.from(raw);
    map.putIfAbsent('enabled', () => true);
    map.putIfAbsent('threshold', () => 80.0);
    return map;
  }

  Future<void> setAlertSettings({
    required bool enabled,
    required double threshold, // 0-100
  }) async {
    await _settings.put('alerts', {
      'enabled': enabled,
      'threshold': threshold.clamp(1.0, 100.0),
    });
  }
}