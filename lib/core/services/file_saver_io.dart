// Mobile/desktop implementation: write straight to a file.
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Where exports are written (and where "My downloads" lists them from):
/// the Downloads folder on desktop, the app's documents folder on mobile.
Future<Directory> exportDirectory() async {
  Directory? dir;
  try {
    dir = await getDownloadsDirectory(); // desktop
  } catch (_) {
    dir = null;
  }
  return dir ?? await getApplicationDocumentsDirectory();
}

Future<String> saveBytes(String fileName, Uint8List bytes, String mime) async {
  final dir = await exportDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
