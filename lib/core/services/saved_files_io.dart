import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import 'file_saver_io.dart';
import 'saved_files.dart';

const bool canList = true;

String? _androidFolder;

Future<String> _folderLabel(Directory dir) async {
  if (Platform.isAndroid) {
    try {
      return _androidFolder ??=
          await downloadsChannel.invokeMethod<String>('folderLabel') ??
              dir.path;
    } catch (_) {
      return dir.path;
    }
  }
  if (Platform.isIOS) return 'Files › On My iPhone › Apna Ledger';
  return dir.path;
}

Future<List<SavedFile>> listSavedFiles() async {
  final dir = await exportDirectory();
  if (!await dir.exists()) return const [];
  final folder = await _folderLabel(dir);
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
        location: Platform.isAndroid || Platform.isIOS
            ? '$folder/$name'
            : e.path,
      ),
    );
  }
  files.sort((a, b) => b.modified.compareTo(a.modified));
  return files;
}

Future<void> deleteSavedFile(SavedFile file) async {
  final f = File(file.path);
  if (await f.exists()) await f.delete();
  if (Platform.isAndroid) {
    try {
      await downloadsChannel.invokeMethod<void>('delete', {'name': file.name});
    } catch (_) {}
  }
}

Future<String?> openSavedFile(SavedFile file) async {
  final result = await OpenFilex.open(
    file.path,
    type: file.isPdf ? 'application/pdf' : 'text/csv',
  );
  return result.type == ResultType.done ? null : result.message;
}

Future<String?> openSavedFolder(SavedFile file) async {
  try {
    if (Platform.isAndroid) {
      final ok = await downloadsChannel.invokeMethod<bool>('openFolder');
      return ok == true ? null : 'No file manager found';
    }
    if (Platform.isIOS) {
      final dir = File(file.path).parent.path;
      final ok = await launchUrl(Uri.parse('shareddocuments://$dir'));
      return ok ? null : 'Open the Files app › On My iPhone › Apna Ledger';
    }
    if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', file.path]);
      return null;
    }
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.path]);
      return null;
    }
    await Process.run('xdg-open', [File(file.path).parent.path]);
    return null;
  } catch (e) {
    return '$e';
  }
}
