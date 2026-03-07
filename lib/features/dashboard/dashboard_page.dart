import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/sheets_api.dart';
import '../../data/sheets_config.dart';
import '../../shared/widgets/money_card.dart';
import '../../shared/constants/categories.dart';
import '../../shared/constants/category_colors.dart';
import '../../shared/theme/theme_scope.dart';
import '../export/export_page.dart';
import '../expenses/add_expense_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  String? error;

  // modo
  bool generalMode = false;

  // selector mes/año
  int year = DateTime.now().year;
  int month = DateTime.now().month;

  // data
  Map<String, dynamic>? monthSummary; // getMonthSummary
  Map<String, dynamic>? allData;      // getAllData

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _daysInMonth(int y, int m) {
    final first = DateTime(y, m, 1);
    final next = DateTime(y, m + 1, 1);
    return next.difference(first).inDays;
  }

  double _sumGastosRows(List<List<dynamic>> rows) {
    double s = 0;
    for (final r in rows) {
      // [id,user,date,category,amount,note,created_at]
      s += (r[4] as num).toDouble();
    }
    return s;
  }

  double _sumIngresosRows(List<List<dynamic>> rows) {
    double s = 0;
    for (final r in rows) {
      // [id,user,date,amount,note,created_at]
      s += (r[3] as num).toDouble();
    }
    return s;
  }

  Map<String, double> _byCatFromGastos(List<List<dynamic>> gastos) {
    final map = <String, double>{};
    for (final c in kCategories) map[c] = 0.0;
    for (final r in gastos) {
      final cat = r[3].toString();
      final amt = (r[4] as num).toDouble();
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return map;
  }

  /// devuelve cantidad de días distintos con gasto en el mes
  int _distinctExpenseDays(List<List<dynamic>> gastos) {
    final set = <String>{};
    for (final r in gastos) {
      // date en r[2] formato YYYY-MM-DD
      set.add(r[2].toString());
    }
    return set.length;
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = SheetsApi(baseUrl: kSheetsUrl, token: kSheetsToken, user: kSheetsUser);

      if (generalMode) {
        final r = await api.getAllData();
        if (r['ok'] != true) throw Exception(r['error'] ?? 'Error desconocido');
        setState(() {
          allData = r;
          monthSummary = null;
          loading = false;
        });
      } else {
        final r = await api.getMonthSummary(year: year, month: month);
        if (r['ok'] != true) throw Exception(r['error'] ?? 'Error desconocido');
        setState(() {
          monthSummary = r;
          allData = null;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = generalMode
        ? 'Dashboard (General)'
        : 'Dashboard (${year}-${month.toString().padLeft(2, '0')})';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Modo claro',
            onPressed: () => ThemeScope.of(context).setMode(ThemeMode.light),
            icon: Icon(
              Icons.wb_sunny_outlined,
              color: ThemeScope.of(context).mode == ThemeMode.light ? Colors.amber : null,
            ),
          ),
          IconButton(
            tooltip: 'Modo nocturno',
            onPressed: () => ThemeScope.of(context).setMode(ThemeMode.dark),
            icon: Icon(
              Icons.nightlight_round,
              color: ThemeScope.of(context).mode == ThemeMode.dark ? Colors.lightBlueAccent : null,
            ),
          ),
          IconButton(
            tooltip: 'Exportar',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExportPage())),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      floatingActionButton: generalMode
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpensePage()));
                _load();
              },
              child: const Icon(Icons.add),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _modeSelector(),
                    const SizedBox(height: 12),
                    if (!generalMode) _monthSelector(),
                    const SizedBox(height: 12),
                    if (generalMode) _buildGeneral() else _buildMonth(),
                  ],
                ),
    );
  }

  Widget _modeSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text('Vista:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Mes'),
              selected: !generalMode,
              onSelected: (v) {
                if (!v) return;
                setState(() => generalMode = false);
                _load();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('General'),
              selected: generalMode,
              onSelected: (v) {
                if (!v) return;
                setState(() => generalMode = true);
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: month,
                decoration: const InputDecoration(labelText: 'Mes'),
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))))
                    .toList(),
                onChanged: (v) {
                  setState(() => month = v ?? month);
                  _load();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: year,
                decoration: const InputDecoration(labelText: 'Año'),
                items: List.generate(7, (i) => DateTime.now().year - 3 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (v) {
                  setState(() => year = v ?? year);
                  _load();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonth() {
    final r = monthSummary!;
    final totalGastos = (r['totalGastos'] as num?)?.toDouble() ?? 0.0;
    final totalIngresos = (r['totalIngresos'] as num?)?.toDouble() ?? 0.0;

    final budget = Map<String, dynamic>.from(r['budget'] as Map);
    final settings = Map<String, dynamic>.from(r['settings'] as Map);

    final mode = (budget['mode'] ?? 'percent').toString();
    final percent = (budget['percent'] as num?)?.toDouble() ?? 60.0;
    final fixedAmount = (budget['fixedAmount'] as num?)?.toDouble() ?? 0.0;

    final budgetAmount = (mode == 'fixed') ? fixedAmount : (totalIngresos * (percent / 100.0));
    final avail = budgetAmount - totalGastos;

    final alertsEnabled = settings['alertsEnabled'] == true;
    final threshold = (settings['alertsThreshold'] as num?)?.toDouble() ?? 80.0;

    final ratioPct = budgetAmount <= 0 ? 0.0 : (totalGastos / budgetAmount) * 100.0;
    final reached = budgetAmount > 0 && ratioPct >= threshold;
    final disponibleColor = (alertsEnabled && reached) ? Colors.red : null;

    // Promedio diario + proyección
    // Para el promedio diario real, necesitamos #días con gasto. Como summary no trae filas,
    // hacemos una llamada ligera a getMonthData SOLO para esto.
    return FutureBuilder<Map<String, dynamic>>(
      future: SheetsApi(baseUrl: kSheetsUrl, token: kSheetsToken, user: kSheetsUser)
          .getMonthData(year: year, month: month),
      builder: (context, snap) {
        int daysWithExpense = 0;
        double avgDaily = 0;
        double projected = 0;

        if (snap.hasData && snap.data!['ok'] == true) {
          final gastosRows = List<List<dynamic>>.from(snap.data!['gastos'] as List);
          daysWithExpense = _distinctExpenseDays(gastosRows);
          avgDaily = daysWithExpense == 0 ? 0 : (totalGastos / daysWithExpense);
          projected = avgDaily * _daysInMonth(year, month);
        }

        final byCatRaw = Map<String, dynamic>.from(r['byCat'] as Map);
        final byCat = <String, double>{};
        for (final c in kCategories) {
          byCat[c] = (byCatRaw[c] as num?)?.toDouble() ?? 0.0;
        }

        final sections = byCat.entries.map((e) {
          if (e.value <= 0) return null;
          final total = totalGastos <= 0 ? 1 : totalGastos;
          final pct = (e.value / total) * 100.0;
          return PieChartSectionData(
            value: e.value,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 60,
            color: colorForCategory(e.key),
          );
        }).whereType<PieChartSectionData>().toList();

        return Column(
          children: [
            MoneyCard(title: 'Ingresos del mes', value: totalIngresos, icon: Icons.trending_up),
            MoneyCard(title: 'Presupuesto del mes', value: budgetAmount, icon: Icons.pie_chart_outline),
            MoneyCard(title: 'Gastos del mes', value: totalGastos, icon: Icons.payments_outlined),
            MoneyCard(
              title: 'Disponible',
              value: avail,
              icon: Icons.account_balance_wallet_outlined,
              valueColor: disponibleColor,
            ),

            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promedios y proyección', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Días con gasto registrado'),
                      trailing: Text(daysWithExpense.toString()),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gasto promedio diario'),
                      trailing: Text('S/ ${avgDaily.toStringAsFixed(2)}'),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Proyección fin de mes'),
                      subtitle: const Text('Promedio diario × días del mes'),
                      trailing: Text('S/ ${projected.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gastos por categoría', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    if (sections.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(child: Text('Aún no hay gastos para graficar.')),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 35)),
                      ),
                    const SizedBox(height: 10),
                    ...kCategories.map((c) {
                      final v = byCat[c] ?? 0.0;
                      if (v <= 0) return const SizedBox.shrink();
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: colorForCategory(c), shape: BoxShape.circle),
                        ),
                        title: Text(categoryLabel(c)),
                        trailing: Text('S/ ${v.toStringAsFixed(2)}'),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeneral() {
    final r = allData!;
    final gastosRows = List<List<dynamic>>.from(r['gastos'] as List);
    final ingresosRows = List<List<dynamic>>.from(r['ingresos'] as List);

    final totalGastos = _sumGastosRows(gastosRows);
    final totalIngresos = _sumIngresosRows(ingresosRows);

    final byCat = _byCatFromGastos(gastosRows);

    // Promedio diario general (días distintos con gasto)
    final daysWithExpense = _distinctExpenseDays(gastosRows);
    final avgDaily = daysWithExpense == 0 ? 0 : (totalGastos / daysWithExpense);

    final sections = byCat.entries.map((e) {
      if (e.value <= 0) return null;
      final total = totalGastos <= 0 ? 1 : totalGastos;
      final pct = (e.value / total) * 100.0;
      return PieChartSectionData(
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        color: colorForCategory(e.key),
      );
    }).whereType<PieChartSectionData>().toList();

    return Column(
      children: [
        MoneyCard(title: 'Ingresos (total)', value: totalIngresos, icon: Icons.trending_up),
        MoneyCard(title: 'Gastos (total)', value: totalGastos, icon: Icons.payments_outlined),
        MoneyCard(
          title: 'Saldo (total)',
          value: totalIngresos - totalGastos,
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Promedios (General)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Días con gasto registrado'),
                  trailing: Text(daysWithExpense.toString()),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gasto promedio diario (general)'),
                  trailing: Text('S/ ${avgDaily.toStringAsFixed(2)}'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gastos por categoría (General)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (sections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Center(child: Text('Aún no hay gastos para graficar.')),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 35)),
                  ),
                const SizedBox(height: 10),
                ...kCategories.map((c) {
                  final v = byCat[c] ?? 0.0;
                  if (v <= 0) return const SizedBox.shrink();
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: colorForCategory(c), shape: BoxShape.circle),
                    ),
                    title: Text(categoryLabel(c)),
                    trailing: Text('S/ ${v.toStringAsFixed(2)}'),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}