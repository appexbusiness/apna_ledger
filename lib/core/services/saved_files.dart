import 'saved_files_io.dart' if (dart.library.html) 'saved_files_web.dart'
    as impl;

/// A ledger export (PDF / CSV) previously saved by [saveBytes].
class SavedFile {
  const SavedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modified,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modified;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

/// Whether this platform keeps files the app can list (false on web, where
/// downloads go to the browser's own Downloads folder).
bool get canListSavedFiles => impl.canList;

/// Every export in the app's save folder, newest first.
Future<List<SavedFile>> listSavedFiles() => impl.listSavedFiles();

Future<void> deleteSavedFile(SavedFile file) => impl.deleteSavedFile(file);

/// Opens the file in the device's default viewer. Returns an error message,
/// or null on success.
Future<String?> openSavedFile(SavedFile file) => impl.openSavedFile(file);
