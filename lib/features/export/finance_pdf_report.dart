import 'dart:math';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/finance_store.dart';
import '../../shared/constants/categories.dart';

class FinancePdfReport {
  /// Si year/month son null => REPORTE GENERAL (acumulado)
  static Future<Uint8List> build(FinanceStore store, {int? year, int? month}) async {
    final pdf = pw.Document();

    final isMonthly = year != null && month != null;

    // ===== Datos =====
    final incomes = isMonthly ? store.listIncomesForMonth(year!, month!) : store.listIncomes();
    final expenses = isMonthly ? store.listExpensesForMonth(year!, month!) : store.listExpenses();

    final incomeTotal = incomes.fold<double>(0.0, (a, e) => a + ((e['amount'] ?? 0) as num).toDouble());
    final expenseTotal = expenses.fold<double>(0.0, (a, e) => a + ((e['amount'] ?? 0) as num).toDouble());

    // Presupuesto:
    // - mensual: presupuesto del mes seleccionado
    // - general: suma de presupuestos de los meses detectados
    final budget = isMonthly
        ? store.budgetAmountForMonth(year!, month!)
        : store.budgetTotalDetectedMonths();

    final available = budget - expenseTotal;

    // Por categoría
    final Map<String, double> byCat = {};
    for (final e in expenses) {
      final cat = (e['category'] ?? 'otros').toString();
      final amt = ((e['amount'] ?? 0) as num).toDouble();
      byCat[cat] = (byCat[cat] ?? 0) + amt;
    }
    final catRows = byCat.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ===== KPI extra: Promedio diario + Proyección (solo mensual) =====
    double avgDaily = 0.0;
    double projectedMonth = 0.0;
    String avgLabel = '-';
    String projLabel = '-';

    if (isMonthly) {
      final now = DateTime.now();
      final daysInMonth = DateTime(year!, month! + 1, 0).day;

      int daysElapsed;
      if (year == now.year && month == now.month) {
        daysElapsed = now.day;
      } else if (DateTime(year!, month!, 1).isBefore(DateTime(now.year, now.month, 1))) {
        daysElapsed = daysInMonth; // mes pasado completo
      } else {
        daysElapsed = 0; // mes futuro
      }

      if (daysElapsed > 0) {
        avgDaily = expenseTotal / daysElapsed;
        projectedMonth = avgDaily * daysInMonth;
        avgLabel = _money(avgDaily);
        projLabel = _money(projectedMonth);
      }
    }

    // ===== Estado =====
    final spentPct = budget <= 0 ? 0.0 : (expenseTotal / budget) * 100.0;
    String status;
    PdfColor statusColor;
    if (budget <= 0) {
      status = 'SIN PRESUPUESTO';
      statusColor = PdfColors.grey700;
    } else if (spentPct >= 100) {
      status = 'EXCEDIDO';
      statusColor = PdfColors.red700;
    } else if (spentPct >= 80) {
      status = 'ALERTA';
      statusColor = PdfColors.orange700;
    } else {
      status = 'OK';
      statusColor = PdfColors.green700;
    }

    final title = isMonthly ? 'Reporte Mensual' : 'Reporte General';
    final subtitle = isMonthly ? 'Periodo: ${year!}-${month!.toString().padLeft(2, '0')}' : _todayLabel();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          _header(title: title, subtitle: subtitle),
          pw.SizedBox(height: 14),

          pw.Row(
            children: [
              pw.Expanded(child: _kpiCard('Ingresos', incomeTotal, PdfColors.blueGrey800)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Presupuesto', budget, PdfColors.teal800)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: _kpiCard('Gastos', expenseTotal, PdfColors.deepOrange800)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Disponible', available, available < 0 ? PdfColors.red800 : PdfColors.green800)),
            ],
          ),

          if (isMonthly) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(child: _kpiTextCard('Promedio diario', avgLabel, PdfColors.indigo700)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _kpiTextCard('Proyección fin de mes', projLabel, PdfColors.purple700)),
              ],
            ),
          ],

          pw.SizedBox(height: 14),

          _statusBlock(
            spentPct: spentPct,
            budget: budget,
            status: status,
            statusColor: statusColor,
          ),

          pw.SizedBox(height: 18),
          pw.Text('Distribución por categoría', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(flex: 2, child: _barChart(catRows, maxBars: 8)),
              pw.SizedBox(width: 14),
              pw.Expanded(flex: 1, child: _pieLegend(catRows)),
            ],
          ),

          pw.SizedBox(height: 18),
          pw.Text('Detalle por categoría', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _categoryTable(catRows, expenseTotal),

          pw.SizedBox(height: 18),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text(
            isMonthly
                ? 'Nota: El presupuesto mensual se calcula según lo configurado para este mes.'
                : 'Nota: Presupuesto general = suma de presupuestos de los meses detectados (con ingresos o gastos).',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------- PDF widgets

  static pw.Widget _header({required String title, required String subtitle}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal600,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text('S/ SOLES', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiCard(String label, double value, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 10, height: 40, decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(6))),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(_money(value), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiTextCard(String label, String valueLabel, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 10, height: 40, decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(6))),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(valueLabel, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _statusBlock({
    required double spentPct,
    required double budget,
    required String status,
    required PdfColor statusColor,
  }) {
    final pct = spentPct.isFinite ? spentPct : 0.0;
    final barPct = (pct / 100.0).clamp(0.0, 1.0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Estado del presupuesto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(color: statusColor, borderRadius: pw.BorderRadius.circular(20)),
                child: pw.Text(status, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            budget <= 0 ? 'Presupuesto en 0: configura presupuesto para calcular %.' : 'Gastado: ${pct.toStringAsFixed(0)}%',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 10,
            decoration: pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.circular(20)),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: 420 * barPct,
                decoration: pw.BoxDecoration(color: statusColor, borderRadius: pw.BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _barChart(List<MapEntry<String, double>> catRows, {int maxBars = 8}) {
    if (catRows.isEmpty) {
      return pw.Container(
        height: 220,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(12)),
        child: pw.Text('Sin datos...', style: pw.TextStyle(color: PdfColors.grey700)),
      );
    }

    final top = catRows.take(maxBars).toList();
    final maxVal = top.map((e) => e.value).reduce(max);

    return pw.Container(
      height: 220,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Barras (top categorías)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...top.map((e) {
            final name = categoryLabel(e.key);
            final v = e.value;
            final ratio = (v / maxVal).clamp(0.0, 1.0);

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(width: 100, child: pw.Text(name, style: const pw.TextStyle(fontSize: 9))),
                  pw.Expanded(
                    child: pw.Container(
                      height: 10,
                      decoration: pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.circular(20)),
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: 230 * ratio,
                          decoration: pw.BoxDecoration(color: PdfColors.teal600, borderRadius: pw.BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(width: 70, child: pw.Text(_money(v), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _pieLegend(List<MapEntry<String, double>> catRows) {
    if (catRows.isEmpty) {
      return pw.Container(
        height: 220,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(12)),
        child: pw.Text('Sin datos', style: pw.TextStyle(color: PdfColors.grey700)),
      );
    }

    final total = catRows.fold<double>(0.0, (a, e) => a + e.value);
    final top = catRows.take(6).toList();

    final colors = [
      PdfColors.teal600,
      PdfColors.blue600,
      PdfColors.orange600,
      PdfColors.purple600,
      PdfColors.red600,
      PdfColors.indigo600,
    ];

    return pw.Container(
      height: 220,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Pie (leyenda top)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...List.generate(top.length, (i) {
            final e = top[i];
            final pct = (e.value / total) * 100.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                children: [
                  pw.Container(width: 10, height: 10, color: colors[i % colors.length]),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(categoryLabel(e.key), style: const pw.TextStyle(fontSize: 9))),
                  pw.Text('${pct.toStringAsFixed(0)}%', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _categoryTable(List<MapEntry<String, double>> catRows, double expenseTotal) {
    final headers = ['Categoría', 'Total (S/)', '% del gasto'];

    final data = catRows.map((e) {
      final pct = expenseTotal <= 0 ? 0.0 : (e.value / expenseTotal) * 100.0;
      return [categoryLabel(e.key), e.value.toStringAsFixed(2), '${pct.toStringAsFixed(0)}%'];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal600),
      cellStyle: const pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
    );
  }

  static String _money(double v) => 'S/ ${v.toStringAsFixed(2)}';

  static String _todayLabel() {
    final d = DateTime.now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return 'Fecha: ${d.year}-$mm-$dd';
  }
}