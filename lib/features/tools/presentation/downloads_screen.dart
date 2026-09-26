import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/design.dart';
import '../../../core/services/saved_files.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// Every ledger export (PDF / CSV) saved on this device: open it, share it,
/// or swipe it away.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<SavedFile>> _files = listSavedFiles();

  Future<void> _reload() async {
    setState(() => _files = listSavedFiles());
    await _files;
  }

  Future<void> _open(SavedFile f) async {
    final toast = Toaster.of(context);
    final err = await openSavedFile(f);
    if (err != null) toast.error(err);
  }

  Future<void> _openFolder(SavedFile f) async {
    final toast = Toaster.of(context);
    final err = await openSavedFolder(f);
    if (err != null) toast.info(err);
  }

  Future<void> _share(SavedFile f) async {
    await Share.shareXFiles(
      [XFile(f.path, mimeType: f.isPdf ? 'application/pdf' : 'text/csv')],
      subject: f.name,
    );
  }

  Future<bool> _delete(SavedFile f) async {
    final l10n = AppLocalizations.of(context);
    final toast = Toaster.of(context);
    final ok = await showAppConfirm(
      context,
      icon: Icons.delete_rounded,
      title: l10n.delete,
      message: f.name,
      confirmLabel: l10n.delete,
      danger: true,
    );
    if (!ok) return false;
    await deleteSavedFile(f);
    toast.success(l10n.deletedToast);
    await _reload();
    return false; // the list reloads itself
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<List<SavedFile>>(
                  future: _files,
                  builder: (context, snap) {
                    final files = snap.data ?? const <SavedFile>[];
                    final loading =
                        snap.connectionState != ConnectionState.done;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        ScreenHeader(
                          title: l10n.myDownloads,
                          subtitle: loading ? null : '${files.length}',
                          onBack: () => context.pop(),
                        ),
                        if (!canListSavedFiles)
                          EmptyState(
                            glyph: FinGlyph.download,
                            title: l10n.myDownloads,
                            message: l10n.browserDownloadsHint,
                          )
                        else if (loading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: LedgerSkeleton(rows: 4),
                          )
                        else if (snap.hasError)
                          ErrorState(onRetry: _reload)
                        else if (files.isEmpty)
                          EmptyState(
                            glyph: FinGlyph.download,
                            title: l10n.noDownloads,
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Entrance(child: _Summary(files: files)),
                          ),
                          for (var i = 0; i < files.length; i++)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                              child: Entrance(
                                index: i + 1,
                                child: Dismissible(
                                  key: ValueKey(files[i].path),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _delete(files[i]),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    child: Icon3D(
                                      icon: Icons.delete_rounded,
                                      color: context.semantic.expense,
                                      size: 38,
                                    ),
                                  ),
                                  child: _FileCard(
                                    file: files[i],
                                    onOpen: () => _open(files[i]),
                                    onShare: () => _share(files[i]),
                                    onFolder: () => _openFolder(files[i]),
                                    onDelete: () => _delete(files[i]),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.files});
  final List<SavedFile> files;

  @override
  Widget build(BuildContext context) {
    final pdfs = files.where((f) => f.isPdf).length;
    final csvs = files.length - pdfs;
    final total = files.fold<int>(0, (s, f) => s + f.sizeBytes);
    Widget stat(String label, String value, Color c) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: c,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    return HeroPanel(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          stat('PDF', '$pdfs', AppColors.onDarkOut),
          stat('CSV', '$csvs', AppColors.onDarkIn),
          stat('Size', _size(total), AppColors.accentSoft),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
    required this.onFolder,
  });

  final SavedFile file;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = file.isPdf ? AppColors.expense : AppColors.income;
    return Surface3D(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon3D(
                icon: file.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.table_chart_rounded,
                color: color,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Formatters.dateDayTime(file.modified)} · ${_size(file.sizeBytes)}',
                      style: TextStyle(
                        color: context.semantic.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: context.semantic.muted,),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Where it lives on the device — tap to open that folder.
          Pressable(
            onTap: onFolder,
            pressedScale: 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: context.surfaces.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.folder_rounded,
                      size: 18, color: AppColors.accent,),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.location,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded,
                      size: 16, color: context.semantic.muted,),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Action(
                icon: Icons.open_in_new_rounded,
                label: l10n.openFile,
                color: color,
                onTap: onOpen,
              ),
              const SizedBox(width: 8),
              _Action(
                icon: Icons.ios_share_rounded,
                label: l10n.shareFile,
                color: AppColors.info,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _size(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
