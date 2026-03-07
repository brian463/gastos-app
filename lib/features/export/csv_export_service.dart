import 'dart:convert';
import 'package:universal_html/html.dart' as html;

import '../../data/finance_store.dart';

class CsvExportService {
  static String _escape(dynamic v) {
    final s = (v ?? '').toString();
    if (s.contains(',') || s.contains('\n') || s.contains('"')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String buildCsv(FinanceStore store) {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;

    // MES ACTUAL
    final incomeMonth = store.incomesTotalForMonth(y, m);
    final expenseMonth = store.expensesTotalForMonth(y, m);
    final budgetMonth = store.budgetAmountForMonth(y, m);
    final availableMonth = budgetMonth - expenseMonth;

    // GENERAL (acumulado)
    final incomeTotal = store.incomesTotal();
    final expenseTotal = store.expensesTotal();
    final budgetTotal = store.budgetTotalDetectedMonths();
    final availableTotal = budgetTotal - expenseTotal;

    final sb = StringBuffer();

    sb.writeln('RESUMEN MES ACTUAL ($y-${m.toString().padLeft(2, '0')})');
    sb.writeln('Ingresos Mes,${incomeMonth.toStringAsFixed(2)}');
    sb.writeln('Presupuesto Mes,${budgetMonth.toStringAsFixed(2)}');
    sb.writeln('Gastos Mes,${expenseMonth.toStringAsFixed(2)}');
    sb.writeln('Disponible Mes,${availableMonth.toStringAsFixed(2)}');
    sb.writeln();

    sb.writeln('RESUMEN GENERAL (ACUMULADO)');
    sb.writeln('Ingresos Total,${incomeTotal.toStringAsFixed(2)}');
    sb.writeln('Presupuesto Total (meses detectados),${budgetTotal.toStringAsFixed(2)}');
    sb.writeln('Gastos Total,${expenseTotal.toStringAsFixed(2)}');
    sb.writeln('Disponible Total,${availableTotal.toStringAsFixed(2)}');
    sb.writeln();

    // Gastos por categoría (mes actual)
    sb.writeln('GASTOS POR CATEGORIA (MES ACTUAL)');
    sb.writeln('Categoria,Total');
    final byCatMonth = store.expensesByCategoryForMonth(y, m);
    for (final e in byCatMonth.entries) {
      sb.writeln('${_escape(e.key)},${e.value.toStringAsFixed(2)}');
    }
    sb.writeln();

    // Gastos (global)
    sb.writeln('GASTOS (GLOBAL)');
    sb.writeln('Fecha,Categoria,Monto,Nota');
    final expenses = store.listExpenses().reversed;
    for (final e in expenses) {
      sb.writeln([
        _escape(e['date']),
        _escape(e['category']),
        _escape((e['amount'] ?? 0).toString()),
        _escape(e['note']),
      ].join(','));
    }
    sb.writeln();

    // Ingresos (global)
    sb.writeln('INGRESOS (GLOBAL)');
    sb.writeln('Fecha,Monto,Nota');
    final incomes = store.listIncomes().reversed;
    for (final i in incomes) {
      sb.writeln([
        _escape(i['date']),
        _escape((i['amount'] ?? 0).toString()),
        _escape(i['note']),
      ].join(','));
    }

    return sb.toString();
  }

  static void downloadCsv(FinanceStore store) {
    final csv = buildCsv(store);
    final bytes = utf8.encode(csv);

    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final a = html.AnchorElement(href: url)
      ..download = 'gastos.csv'
      ..style.display = 'none';

    html.document.body!.children.add(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
  }
}