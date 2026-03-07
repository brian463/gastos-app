import 'package:flutter/material.dart';
import '../../data/sheets_api.dart';
import '../../data/sheets_config.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  DateTime _date = DateTime.now();
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
      appBar: AppBar(title: const Text('Agregar ingreso')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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

                        final amount =
                            double.parse(_amount.text.trim().replaceAll(',', '.'));

                        final api = SheetsApi(
                          baseUrl: kSheetsUrl,
                          token: kSheetsToken,
                          user: kSheetsUser,
                        );

                        try {
                          await api.addIncome(
                            date: _ymd(_date),
                            amount: amount,
                            note: _note.text,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Ingreso guardado'),
                              duration: Duration(seconds: 2),
                            ),
                          );

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
                label: Text(_saving ? 'Guardando...' : 'Guardar ingreso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}