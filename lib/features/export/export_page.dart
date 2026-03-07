import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/finance_store.dart';
import 'finance_pdf_report.dart';
import 'pdf_download.dart';
import 'xlsx_report_service.dart';
import 'web_download.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore();

    return Scaffold(
      appBar: AppBar(title: const Text('Exportar')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // PDF PRO
            FilledButton.icon(
              onPressed: () async {
                if (!kIsWeb) return;
                final bytes = await FinancePdfReport.build(store);
                PdfDownload.download(bytes, filename: 'reporte_financiero.pdf');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF descargado: reporte_financiero.pdf')),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Descargar PDF (Informe con gráficas)'),
            ),

            const SizedBox(height: 10),

            // XLSX PRO
            OutlinedButton.icon(
              onPressed: () {
                if (!kIsWeb) return;

                final bytes = XlsxReportService.buildXlsx(store);
                WebDownload.downloadBytes(
                  bytes,
                  'reporte_financiero.xlsx',
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('XLSX descargado: reporte_financiero.xlsx')),
                );
              },
              icon: const Icon(Icons.grid_on_outlined),
              label: const Text('Descargar XLSX (Excel pro)'),
            ),
          ],
        ),
      ),
    );
  }
}