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
  Map<String, dynamic>? res;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = SheetsApi(baseUrl: kSheetsUrl, token: kSheetsToken, user: kSheetsUser);
      final now = DateTime.now();

      final r = await api.getMonthSummary(year: now.year, month: now.month);
      if (r['ok'] != true) throw Exception(r['error'] ?? 'Error desconocido');

      setState(() {
        res = r;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ($ym)'),
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
      floatingActionButton: FloatingActionButton(
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
              : _content(),
    );
  }

  Widget _content() {
    final totalGastos = (res!['totalGastos'] as num?)?.toDouble() ?? 0.0;
    final totalIngresos = (res!['totalIngresos'] as num?)?.toDouble() ?? 0.0;

    final budget = Map<String, dynamic>.from(res!['budget'] as Map);
    final settings = Map<String, dynamic>.from(res!['settings'] as Map);

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

    final byCatRaw = Map<String, dynamic>.from(res!['byCat'] as Map);
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

    return ListView(
      padding: const EdgeInsets.all(12),
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
                const Text('Gastos por categoría'),
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