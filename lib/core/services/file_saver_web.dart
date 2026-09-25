// Web implementation: trigger a direct browser download (no share sheet).
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveBytes(String fileName, Uint8List bytes, String mime) async {
  final blob = html.Blob(<Object>[bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Downloads';
}
