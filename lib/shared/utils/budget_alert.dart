import 'package:flutter/material.dart';
import '../../data/finance_store.dart';

class BudgetAlert {
  static DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);

  static void checkAndNotify(BuildContext context, FinanceStore store) {
    final a = store.getAlertSettings();
    final enabled = (a['enabled'] ?? true) as bool;
    final thresholdPct = ((a['threshold'] ?? 80.0) as num).toDouble();

    if (!enabled) return;

    final now = DateTime.now();
    final y = now.year;
    final m = now.month;

    final budget = store.budgetAmountForMonth(y, m);
    if (budget <= 0) return;

    final spent = store.expensesTotalForMonth(y, m);
    final ratioPct = (spent / budget) * 100.0;

    if (ratioPct < thresholdPct) return;

    // Anti-spam
    final t = DateTime.now();
    if (t.difference(_lastShown).inSeconds < 3) return;
    _lastShown = t;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Alerta: vas en ${ratioPct.toStringAsFixed(0)}% del presupuesto del mes'),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}