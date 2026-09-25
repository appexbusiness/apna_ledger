import 'dart:io';

import 'package:open_filex/open_filex.dart';

import 'file_saver_io.dart';
import 'saved_files.dart';

const bool canList = true;

Future<List<SavedFile>> listSavedFiles() async {
  final dir = await exportDirectory();
  if (!await dir.exists()) return const [];
  final files = <SavedFile>[];
  await for (final e in dir.list()) {
    if (e is! File) continue;
    final name = e.uri.pathSegments.last;
    final lower = name.toLowerCase();
    if (!lower.startsWith('apna-ledger')) continue;
    if (!lower.endsWith('.pdf') && !lower.endsWith('.csv')) continue;
    final stat = await e.stat();
    files.add(
      SavedFile(
        path: e.path,
        name: name,
        sizeBytes: stat.size,
        modified: stat.modified,
      ),
    );
  }
  files.sort((a, b) => b.modified.compareTo(a.modified));
  return files;
}

Future<void> deleteSavedFile(SavedFile file) async {
  final f = File(file.path);
  if (await f.exists()) await f.delete();
}

Future<String?> openSavedFile(SavedFile file) async {
  final result = await OpenFilex.open(
    file.path,
    type: file.isPdf ? 'application/pdf' : 'text/csv',
  );
  return result.type == ResultType.done ? null : result.message;
}
