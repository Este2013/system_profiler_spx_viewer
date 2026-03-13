import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/document_provider.dart';
import 'kv_table.dart';
import 'items_table.dart';
import 'usb_tree_view.dart';
import 'log_viewer.dart';
import 'grouped_kv_view.dart';
import 'nested_items_view.dart';
import '../../utils/key_formatter.dart';

/// Routes a selected [SpxSection] to the appropriate view widget.
class SectionView extends StatelessWidget {
  const SectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final section = provider.selectedSection;
    final theme = Theme.of(context);

    if (section == null) {
      return Center(
        child: Text(
          'Select a section from the sidebar',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(100),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        _SectionHeader(section: section),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: section.isEmpty
              ? _EmptySectionView(section: section)
              : _buildContent(section, provider.globalSearchQuery),
        ),
      ],
    );
  }

  Widget _buildContent(SpxSection section, String searchQuery) {
    // USB host data type → dedicated tree + detail view.
    if (section.dataType == 'SPUSBHostDataType') {
      return UsbTreeView(buses: section.items);
    }

    // Logs → dedicated two-pane log viewer.
    if (section.dataType == 'SPLogsDataType') {
      return LogViewer(items: section.items);
    }

    // Language & Region (and similar grouped-settings sections) →
    // named groups stacked vertically rather than a flat table.
    if (section.dataType == 'SPInternationalDataType') {
      return GroupedKvView(
        items: section.items,
        searchQuery: searchQuery,
      );
    }

    if (section.items.length == 1) {
      final only = section.items.first;

      // Wrapper pattern: single item whose own _items list holds the real data
      // (e.g. Audio "coreaudio_device" wrapping VZ249, Mix 3, …).
      final nested = only['_items'];
      if (nested is List && nested.isNotEmpty) {
        final nestedItems =
            nested.whereType<Map<String, dynamic>>().toList();
        if (nestedItems.isNotEmpty) {
          return NestedItemsView(
            items: nestedItems,
            searchQuery: searchQuery,
            keyFormatter: _keyFormatterFor(section.dataType),
            subtitleBuilder: _subtitleBuilderFor(section.dataType),
            detailIcon: _detailIconFor(section.dataType),
          );
        }
      }

      // Single item with no nested _items → plain key-value table.
      return KvTable(
        item: only,
        searchQuery: searchQuery,
      );
    }
    // Multiple items → sortable/filterable table
    return ItemsTable(
      section: section,
      searchQuery: searchQuery,
    );
  }
}

// ─── Helpers for NestedItemsView configuration ──────────────────────────────

String Function(String) _keyFormatterFor(String dataType) {
  switch (dataType) {
    case 'SPAudioDataType':
      return formatAudioKey;
    default:
      return formatKey;
  }
}

String? Function(Map<String, dynamic>)? _subtitleBuilderFor(String dataType) {
  switch (dataType) {
    case 'SPAudioDataType':
      return (item) {
        final mfr = item['coreaudio_device_manufacturer']?.toString();
        final transport = item['coreaudio_device_transport']?.toString();
        final parts = [
          if (mfr != null && mfr.isNotEmpty) mfr,
          if (transport != null) formatSpxValue(transport),
        ];
        return parts.isEmpty ? null : parts.join(' · ');
      };
    default:
      return null;
  }
}

IconData _detailIconFor(String dataType) {
  switch (dataType) {
    case 'SPAudioDataType':
      return Icons.graphic_eq;
    default:
      return Icons.tune;
  }
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final SpxSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (section.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Report: ${DateFormat('yyyy-MM-dd  HH:mm:ss').format(section.timestamp!.toLocal())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!section.isEmpty)
            _CountBadge(
              count: section.items.length,
              label: section.items.length == 1 ? 'item' : 'items',
              colorScheme: colorScheme,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _CountBadge({
    required this.count,
    required this.label,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count $label',
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptySectionView extends StatelessWidget {
  final SpxSection section;

  const _EmptySectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 52,
            color: colorScheme.onSurface.withAlpha(50),
          ),
          const SizedBox(height: 14),
          Text(
            'No data available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withAlpha(100),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            section.dataType,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withAlpha(60),
            ),
          ),
        ],
      ),
    );
  }
}
