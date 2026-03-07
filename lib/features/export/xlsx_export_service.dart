import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../../data/finance_store.dart';
import '../../shared/constants/categories.dart';

class XlsxReportService {
  static Uint8List buildXlsx(FinanceStore store) {
    final excel = Excel.createExcel();

    final shResumen = excel['RESUMEN'];
    final shMes = excel['MES_ACTUAL'];
    final shGastos = excel['GASTOS'];
    final shIngresos = excel['INGRESOS'];

    // borrar hoja default
    if (excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    final now = DateTime.now();
    final y = now.year;
    final m = now.month;
    final ym = '$y-${m.toString().padLeft(2, '0')}';

    // ====== Datos MES ACTUAL
    final incM = store.incomesTotalForMonth(y, m);
    final expM = store.expensesTotalForMonth(y, m);
    final budM = store.budgetAmountForMonth(y, m);
    final availM = budM - expM;
    final byCatM = store.expensesByCategoryForMonth(y, m);

    // ====== Datos GENERAL
    final incT = store.incomesTotal();
    final expT = store.expensesTotal();
    final budT = store.budgetTotalDetectedMonths();
    final availT = budT - expT;
    final byCatT = store.expensesByCategory();

    // ====== Styles
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#0F766E'),
      fontColorHex: ExcelColor.white,
    );

    final moneyStyle = CellStyle(numberFormat: NumFormat.standard_2);
    final boldStyle = CellStyle(bold: true);

    final negativeMoneyStyle = CellStyle(
      numberFormat: NumFormat.standard_2,
      fontColorHex: ExcelColor.fromHexString('#B91C1C'),
      bold: true,
    );

    // Helpers (excel 4.x)
    void t(Sheet s, String addr, String v, {CellStyle? st}) {
      final c = s.cell(CellIndex.indexByString(addr));
      c.value = TextCellValue(v);
      if (st != null) c.cellStyle = st;
    }

    void n(Sheet s, String addr, double v, {CellStyle? st}) {
      final c = s.cell(CellIndex.indexByString(addr));
      c.value = DoubleCellValue(v);
      if (st != null) c.cellStyle = st;
    }

    // =========================
    // RESUMEN (GENERAL + MES)
    // =========================
    shResumen.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
    t(shResumen, 'A1', 'REPORTE FINANCIERO - EXCEL', st: titleStyle);

    t(shResumen, 'A3', 'Sección', st: headerStyle);
    t(shResumen, 'B3', 'Ingresos (S/)', st: headerStyle);
    t(shResumen, 'C3', 'Presupuesto (S/)', st: headerStyle);
    t(shResumen, 'D3', 'Gastos (S/)', st: headerStyle);
    t(shResumen, 'E3', 'Disponible (S/)', st: headerStyle);

    // Fila MES
    t(shResumen, 'A4', 'MES ACTUAL ($ym)', st: boldStyle);
    n(shResumen, 'B4', incM, st: moneyStyle);
    n(shResumen, 'C4', budM, st: moneyStyle);
    n(shResumen, 'D4', expM, st: moneyStyle);
    n(shResumen, 'E4', availM, st: availM < 0 ? negativeMoneyStyle : moneyStyle);

    // Fila GENERAL
    t(shResumen, 'A5', 'GENERAL (ACUMULADO)', st: boldStyle);
    n(shResumen, 'B5', incT, st: moneyStyle);
    n(shResumen, 'C5', budT, st: moneyStyle);
    n(shResumen, 'D5', expT, st: moneyStyle);
    n(shResumen, 'E5', availT, st: availT < 0 ? negativeMoneyStyle : moneyStyle);

    // Anchos (Sheet.setColumnWidth en tu versión)
    shResumen.setColumnWidth(0, 24);
    shResumen.setColumnWidth(1, 16);
    shResumen.setColumnWidth(2, 16);
    shResumen.setColumnWidth(3, 14);
    shResumen.setColumnWidth(4, 16);

    // =========================
    // MES_ACTUAL (detalle)
    // =========================
    shMes.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
    t(shMes, 'A1', 'DETALLE MES ACTUAL ($ym)', st: titleStyle);

    t(shMes, 'A3', 'Indicador', st: headerStyle);
    t(shMes, 'B3', 'Monto (S/)', st: headerStyle);
    t(shMes, 'C3', '%', st: headerStyle);
    t(shMes, 'D3', 'Estado', st: headerStyle);

    final pctM = budM <= 0 ? 0.0 : (expM / budM) * 100.0;
    String estadoM = budM <= 0 ? 'Sin presupuesto' : (pctM >= 100 ? 'Excedido' : (pctM >= 80 ? 'Alerta' : 'OK'));

    void addRowMes(int row, String name, double val, String pct, String st) {
      t(shMes, 'A$row', name, st: boldStyle);
      n(shMes, 'B$row', val, st: val < 0 ? negativeMoneyStyle : moneyStyle);
      t(shMes, 'C$row', pct);
      t(shMes, 'D$row', st);
    }

    addRowMes(4, 'Ingresos del mes', incM, '-', 'OK');
    addRowMes(5, 'Presupuesto del mes', budM, '-', budM <= 0 ? 'Sin presupuesto' : 'OK');
    addRowMes(6, 'Gastos del mes', expM, budM <= 0 ? '-' : '${pctM.toStringAsFixed(0)}%', estadoM);
    addRowMes(7, 'Disponible', availM, budM <= 0 ? '-' : '${(100 - pctM).clamp(0, 100).toStringAsFixed(0)}%', availM < 0 ? 'Negativo' : 'OK');

    t(shMes, 'A9', 'GASTOS POR CATEGORÍA (MES)', st: boldStyle);
    t(shMes, 'A10', 'Categoría', st: headerStyle);
    t(shMes, 'B10', 'Total (S/)', st: headerStyle);
    t(shMes, 'C10', '% del gasto', st: headerStyle);

    int r = 10;
    for (final c in kCategories) {
      final v = byCatM[c] ?? 0.0;
      if (v <= 0) continue;
      r++;
      t(shMes, 'A$r', categoryLabel(c));
      n(shMes, 'B$r', v, st: moneyStyle);
      final p = expM <= 0 ? 0.0 : (v / expM) * 100.0;
      t(shMes, 'C$r', '${p.toStringAsFixed(0)}%');
    }

    shMes.setColumnWidth(0, 26);
    shMes.setColumnWidth(1, 16);
    shMes.setColumnWidth(2, 12);
    shMes.setColumnWidth(3, 14);

    // =========================
    // GASTOS (global tabla)
    // =========================
    t(shGastos, 'A1', 'Fecha', st: headerStyle);
    t(shGastos, 'B1', 'Categoría', st: headerStyle);
    t(shGastos, 'C1', 'Monto (S/)', st: headerStyle);
    t(shGastos, 'D1', 'Nota', st: headerStyle);

    shGastos.setColumnWidth(0, 14);
    shGastos.setColumnWidth(1, 18);
    shGastos.setColumnWidth(2, 14);
    shGastos.setColumnWidth(3, 32);

    final expenses = store.listExpenses().reversed.toList();
    for (int i = 0; i < expenses.length; i++) {
      final row = i + 2;
      final e = expenses[i];
      t(shGastos, 'A$row', (e['date'] ?? '').toString());
      t(shGastos, 'B$row', categoryLabel((e['category'] ?? '').toString()));
      n(shGastos, 'C$row', ((e['amount'] ?? 0) as num).toDouble(), st: moneyStyle);
      t(shGastos, 'D$row', (e['note'] ?? '').toString());
    }

    // =========================
    // INGRESOS (global tabla)
    // =========================
    t(shIngresos, 'A1', 'Fecha', st: headerStyle);
    t(shIngresos, 'B1', 'Monto (S/)', st: headerStyle);
    t(shIngresos, 'C1', 'Nota', st: headerStyle);

    shIngresos.setColumnWidth(0, 14);
    shIngresos.setColumnWidth(1, 14);
    shIngresos.setColumnWidth(2, 32);

    final incomes = store.listIncomes().reversed.toList();
    for (int i = 0; i < incomes.length; i++) {
      final row = i + 2;
      final it = incomes[i];
      t(shIngresos, 'A$row', (it['date'] ?? '').toString());
      n(shIngresos, 'B$row', ((it['amount'] ?? 0) as num).toDouble(), st: moneyStyle);
      t(shIngresos, 'C$row', (it['note'] ?? '').toString());
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}