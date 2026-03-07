import 'package:flutter/material.dart';
import '../../data/sheets_api.dart';
import '../../data/sheets_config.dart';
import '../../shared/utils/currency.dart';
import '../incomes/add_income_page.dart';

class IncomesPage extends StatefulWidget {
  const IncomesPage({super.key});

  @override
  State<IncomesPage> createState() => _IncomesPageState();
}

class _IncomesPageState extends State<IncomesPage> {
  bool loading = true;
  String? error;
  List<List<dynamic>> incomes = [];

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
        incomes = List<List<dynamic>>.from(res['ingresos'] as List);
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
        title: Text('Ingresos ($ym)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddIncomePage()));
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
              : incomes.isEmpty
                  ? const Center(child: Text('Aún no hay ingresos este mes.'))
                  : ListView.separated(
                      itemCount: incomes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        // ingresos row: [id,user,date,amount,note,created_at]
                        final row = incomes[i];
                        final date = row[2].toString();
                        final amount = (row[3] as num).toDouble();
                        final note = (row.length > 4 ? row[4].toString() : '');

                        return ListTile(
                          title: Text(Currency.format(amount)),
                          subtitle: Text(note.isEmpty ? date : '$date • $note'),
                        );
                      },
                    ),
    );
  }
}