import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> downloadBytesOnWeb(List<int> bytes, String fileName) async {
  final jsBytes = bytes.map((b) => b.toJS).toList().toJS;
  final blob = web.Blob([jsBytes].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..setAttribute('download', fileName)
    ..click();
  web.URL.revokeObjectURL(url);
  anchor.remove();
}
