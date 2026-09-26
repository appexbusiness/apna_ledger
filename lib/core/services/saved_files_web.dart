import 'saved_files.dart';

const bool canList = false;

Future<List<SavedFile>> listSavedFiles() async => const [];

Future<void> deleteSavedFile(SavedFile file) async {}

Future<String?> openSavedFile(SavedFile file) async =>
    'Open it from your browser’s Downloads folder.';

Future<String?> openSavedFolder(SavedFile file) async =>
    'Open your browser’s Downloads folder.';
