import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

class PdfDownload {
  static void download(Uint8List bytes, {String filename = 'reporte_financiero.pdf'}) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final a = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';

    html.document.body!.children.add(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
  }
}