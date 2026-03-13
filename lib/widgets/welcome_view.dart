import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<DocumentProvider>();
    final error = context.select<DocumentProvider, String?>((p) => p.errorMessage);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.computer_outlined,
            size: 80,
            color: theme.colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 24),
          Text(
            'SPX Viewer',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drop a .spx file here, or click Open below',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: provider.openFilePicker,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open SPX File'),
          ),
          if (error != null) ...[
            const SizedBox(height: 24),
            _ErrorPanel(error: error, onDismiss: provider.clearError),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ErrorPanel extends StatefulWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorPanel({required this.error, required this.onDismiss});

  @override
  State<_ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<_ErrorPanel> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.error));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading file',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Copy button
                Tooltip(
                  message: _copied ? 'Copied!' : 'Copy error to clipboard',
                  child: IconButton(
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_outlined,
                      size: 16,
                      color: cs.onErrorContainer,
                    ),
                    onPressed: _copy,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 2),
                // Dismiss button
                Tooltip(
                  message: 'Dismiss',
                  child: IconButton(
                    icon: Icon(Icons.close, size: 16, color: cs.onErrorContainer),
                    onPressed: widget.onDismiss,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable error text
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                widget.error,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: cs.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
