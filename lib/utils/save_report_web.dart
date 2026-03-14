// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web: trigger download of [csvContent] as [filename].
Future<void> saveReportToDevice(String filename, String csvContent) async {
  final blob = html.Blob([csvContent], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
