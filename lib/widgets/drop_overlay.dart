import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class DropOverlay extends StatefulWidget {
  final Widget child;

  const DropOverlay({super.key, required this.child});

  @override
  State<DropOverlay> createState() => _DropOverlayState();
}

class _DropOverlayState extends State<DropOverlay> {
  bool _isDragging = false;

  Future<void> _handleDrop(String path, BuildContext ctx) async {
    if (!path.toLowerCase().endsWith('.spx')) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Only .spx files are supported'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final provider = ctx.read<DocumentProvider>();

    if (!provider.hasDocument) {
      await provider.loadFile(path);
      return;
    }

    // File already open — ask the user
    if (!ctx.mounted) return;

    final result = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('File Already Open'),
        content: Text(
          'A report is already loaded (${provider.document!.fileName}).\n'
          'What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, 'replace'),
            child: const Text('Replace'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, 'new_window'),
            child: const Text('Open in New Window'),
          ),
        ],
      ),
    );

    if (result == 'replace' && ctx.mounted) {
      await provider.loadFile(path);
    } else if (result == 'new_window') {
      _openNewWindow(path);
    }
  }

  void _openNewWindow(String path) {
    Process.start(Platform.resolvedExecutable, [path]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          _handleDrop(details.files.first.path, context);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: colorScheme.primary.withAlpha(30),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(40),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            size: 52,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Drop .spx file to open',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
