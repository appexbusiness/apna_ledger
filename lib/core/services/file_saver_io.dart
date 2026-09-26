// Mobile/desktop implementation: write straight to a file.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Native bridge (Android) for the public Download/ApnaLedger folder.
const downloadsChannel = MethodChannel('apna_ledger/downloads');

/// Where the app keeps its own copy of every export (and what "My downloads"
/// lists): the Downloads folder on desktop, the app's documents folder on
/// mobile (visible in the iOS Files app).
Future<Directory> exportDirectory() async {
  Directory? dir;
  try {
    dir = await getDownloadsDirectory(); // desktop
  } catch (_) {
    dir = null;
  }
  return dir ?? await getApplicationDocumentsDirectory();
}

/// Saves the app copy and, on Android, a public copy in
/// Download/ApnaLedger. Returns the path the user can find the file at.
Future<String> saveBytes(String fileName, Uint8List bytes, String mime) async {
  final dir = await exportDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  if (Platform.isAndroid) {
    try {
      final public = await downloadsChannel.invokeMethod<String>('save', {
        'name': fileName,
        'mime': mime,
        'bytes': bytes,
      });
      if (public != null) return public;
    } catch (_) {
      // Public copy is best-effort; the app copy is always kept.
    }
  }
  return file.path;
}
