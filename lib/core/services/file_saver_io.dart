// Mobile/desktop implementation: write straight to a file.
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveBytes(String fileName, Uint8List bytes, String mime) async {
  Directory? dir;
  try {
    dir = await getDownloadsDirectory(); // desktop
  } catch (_) {
    dir = null;
  }
  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
