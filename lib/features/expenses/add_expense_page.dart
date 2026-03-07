import 'package:flutter/material.dart';
import '../../shared/constants/categories.dart';
import '../../data/sheets_api.dart';
import '../../data/sheets_config.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  DateTime _date = DateTime.now();
  String _category = kCategories.first;

  bool _saving = false; // ✅ evita doble click

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar gasto')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                items: kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(categoryLabel(c))))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _category = v ?? kCategories.first),
                decoration: const InputDecoration(labelText: 'Tipo de gasto'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amount,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Monto (S/)',
                  prefixText: 'S/ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final s = (v ?? '').trim().replaceAll(',', '.');
                  final n = double.tryParse(s);
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _note,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                subtitle: Text(_ymd(_date)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(DateTime.now().year - 2),
                          lastDate: DateTime(DateTime.now().year + 2),
                          initialDate: _date,
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
              ),

              const SizedBox(height: 18),

              FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => _saving = true);

                        final amount = double.parse(_amount.text.trim().replaceAll(',', '.'));
                        final api = SheetsApi(baseUrl: kSheetsUrl, token: kSheetsToken, user: kSheetsUser);

                        try {
                          await api.addExpense(
                            date: _ymd(_date),
                            category: _category,
                            amount: amount,
                            note: _note.text,
                          );

                          if (!context.mounted) return;

                          // ✅ Mensaje claro
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Gasto guardado'),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // ✅ Cerrar pantalla para evitar duplicar
                          Navigator.of(context).pop();
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _saving = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Error al guardar: $e')),
                          );
                        }
                      },
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}