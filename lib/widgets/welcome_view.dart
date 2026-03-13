import 'package:flutter/material.dart';
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
            Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error loading file',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: theme.colorScheme.onErrorContainer),
                    onPressed: provider.clearError,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
