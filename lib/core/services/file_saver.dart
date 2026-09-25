import 'dart:typed_data';

import 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart'
    as impl;

/// Saves [bytes] as a file the user can keep. On web this triggers a normal
/// browser download; on desktop it writes to the Downloads folder; on mobile it
/// writes to the app's documents. Returns a short human-readable location.
Future<String> saveBytes(String fileName, Uint8List bytes, String mime) =>
    impl.saveBytes(fileName, bytes, mime);
