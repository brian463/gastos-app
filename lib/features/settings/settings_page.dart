import 'package:flutter/material.dart';
import '../../data/sheets_api.dart';
import '../../data/sheets_config.dart';
import '../../shared/theme/theme_scope.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool loading = true;
  String? error;

  int year = DateTime.now().year;
  int month = DateTime.now().month;

  String mode = 'percent';
  final percentCtrl = TextEditingController(text: '60');
  final fixedCtrl = TextEditingController(text: '0');

  bool alertsEnabled = true;
  final alertPctCtrl = TextEditingController(text: '80');

  double _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    percentCtrl.dispose();
    fixedCtrl.dispose();
    alertPctCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = SheetsApi(baseUrl: kSheetsUrl, token: kSheetsToken, user: kSheetsUser);
      final res = await api.getMonthData(year: year, month: month);

      if (res['ok'] != true) throw Exception(res['error'] ?? 'Error desconocido');

      final b = Map<String, dynamic>.from(res['budget'] as Map);
      final s = Map<String, dynamic>.from(res['settings'] as Map);

      setState(() {
        mode = (b['mode'] ?? 'percent').toString();
        percentCtrl.text = ((b['percent'] ?? 60) as num).toString();
        fixedCtrl.text = ((b['fixedAmount'] ?? 0) as num).toString();

        alertsEnabled = s['alertsEnabled'] == true;
        alertPctCtrl.text = ((s['alertsThreshold'] ?? 80) as num).toString();

        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _themeToString(ThemeMode m) {
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.dark) return 'dark';
    return 'system';
  }

  Future<void> _save() async {
    final api = SheetsApi(baseUrl: kSheetsUrl, token: kSheetsToken, user: kSheetsUser);

    try {
      await api.setBudget(
        year: year,
        month: month,
        mode: mode,
        percent: _parse(percentCtrl.text),
        fixedAmount: _parse(fixedCtrl.text),
      );

      await api.setSettings(
        alertsEnabled: alertsEnabled,
        alertsThreshold: _parse(alertPctCtrl.text),
        themeMode: _themeToString(ThemeScope.of(context).mode),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Guardado en Sheets ($year-${month.toString().padLeft(2, '0')})')),
      );

      // opcional: recargar valores desde sheets
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustes')),
        body: Center(child: Text('Error: $error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: [
            const Text('Presupuesto mensual (Sheets)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            Row(
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

            const SizedBox(height: 14),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'percent', label: Text('Porcentaje')),
                ButtonSegment(value: 'fixed', label: Text('Fijo')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),

            const SizedBox(height: 14),

            if (mode == 'percent')
              TextField(
                controller: percentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Porcentaje de ingresos (%)',
                  helperText: 'Presupuesto = Ingresos del mes × porcentaje.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              )
            else
              TextField(
                controller: fixedCtrl,
                decoration: const InputDecoration(
                  labelText: 'Presupuesto fijo (S/)',
                  helperText: 'Monto fijo para el mes seleccionado.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Alertas', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activar alerta de límite'),
              value: alertsEnabled,
              onChanged: (v) => setState(() => alertsEnabled = v),
            ),

            TextField(
              controller: alertPctCtrl,
              enabled: alertsEnabled,
              decoration: const InputDecoration(
                labelText: 'Alerta al (%)',
                helperText: 'Ejemplo: 80 = alerta cuando gastes 80% del presupuesto.',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Apariencia', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            DropdownButtonFormField<ThemeMode>(
              value: ThemeScope.of(context).mode,
              decoration: const InputDecoration(labelText: 'Modo'),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Nocturno')),
              ],
              onChanged: (m) {
                if (m != null) ThemeScope.of(context).setMode(m);
              },
            ),

            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}