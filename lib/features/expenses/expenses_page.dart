import 'package:flutter/material.dart';
import '../../data/sheets_api.dart';
import '../../data/sheets_config.dart';
import '../../shared/utils/currency.dart';
import '../../shared/constants/categories.dart';
import '../expenses/add_expense_page.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  bool loading = true;
  String? error;
  List<List<dynamic>> expenses = [];

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
      final res = await api.getMonthData(year: now.year, month: now.month);

      if (res['ok'] != true) throw Exception(res['error'] ?? 'Error desconocido');

      setState(() {
        expenses = List<List<dynamic>>.from(res['gastos'] as List);
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
        title: Text('Gastos ($ym)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpensePage()));
              _load();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : expenses.isEmpty
                  ? const Center(child: Text('Aún no hay gastos este mes.'))
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        // gastos row: [id,user,date,category,amount,note,created_at]
                        final row = expenses[i];
                        final date = row[2].toString();
                        final cat = row[3].toString();
                        final amount = (row[4] as num).toDouble();
                        final note = (row.length > 5 ? row[5].toString() : '');

                        return ListTile(
                          title: Text('${categoryLabel(cat)} • ${Currency.format(amount)}'),
                          subtitle: Text(note.isEmpty ? date : '$date • $note'),
                        );
                      },
                    ),
    );
  }
}