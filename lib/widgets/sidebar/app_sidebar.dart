import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/document_provider.dart';
import '../../utils/category_mapping.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final Set<String> _expandedCategories = {
    'Hardware',
    'Network',
    'Software',
    'Other',
  };
  bool _showEmptySections = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final doc = provider.document;
    if (doc == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group sections by category, preserving display order
    final categorized = <String, List<SpxSection>>{};
    for (final section in doc.sections) {
      categorized.putIfAbsent(section.categoryName, () => []).add(section);
    }

    // Build ordered category list
    final categories = [...kCategoryOrder];
    for (final cat in categorized.keys) {
      if (!categories.contains(cat)) categories.add(cat);
    }

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: filename
          _buildHeader(context, doc.fileName, colorScheme, theme),

          // Section list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              children: [
                for (final cat in categories)
                  if (categorized.containsKey(cat))
                    _buildCategoryGroup(
                      context,
                      cat,
                      categorized[cat]!,
                      provider,
                      theme,
                      colorScheme,
                    ),

                const Divider(height: 8, thickness: 0.5),

                // Toggle empty sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _showEmptySections = !_showEmptySections);
                    },
                    icon: Icon(
                      _showEmptySections
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 14,
                    ),
                    label: Text(
                      _showEmptySections
                          ? 'Hide empty sections'
                          : 'Show empty sections',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      textStyle: theme.textTheme.bodySmall,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String fileName,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, size: 15, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context,
    String category,
    List<SpxSection> sections,
    DocumentProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isExpanded = _expandedCategories.contains(category);
    final visible = _showEmptySections
        ? sections
        : sections.where((s) => !s.isEmpty).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category header (clickable to expand/collapse)
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedCategories.remove(category);
            } else {
              _expandedCategories.add(category);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
            child: Row(
              children: [
                Icon(
                  _categoryIcon(category),
                  size: 13,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 15,
                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                ),
              ],
            ),
          ),
        ),

        // Section items
        if (isExpanded)
          for (final section in visible)
            _buildSectionTile(context, section, provider, theme, colorScheme),
      ],
    );
  }

  Widget _buildSectionTile(
    BuildContext context,
    SpxSection section,
    DocumentProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected =
        provider.selectedSection?.dataType == section.dataType;

    // Count search matches
    int matchCount = 0;
    final q = provider.globalSearchQuery;
    if (q.isNotEmpty) {
      final qLower = q.toLowerCase();
      for (final item in section.items) {
        if (_itemContainsQuery(item, qLower)) matchCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: () => provider.selectSection(section),
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 6, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : section.isEmpty
                              ? colorScheme.onSurface.withAlpha(80)
                              : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (matchCount > 0)
                  _MatchBadge(count: matchCount, colorScheme: colorScheme, theme: theme)
                else if (section.isEmpty)
                  Icon(
                    Icons.circle,
                    size: 5,
                    color: colorScheme.onSurface.withAlpha(50),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _itemContainsQuery(Map<String, dynamic> item, String queryLower) {
    for (final value in item.values) {
      if (value.toString().toLowerCase().contains(queryLower)) return true;
    }
    return false;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Hardware':
        return Icons.memory_outlined;
      case 'Network':
        return Icons.wifi_outlined;
      case 'Software':
        return Icons.apps_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

class _MatchBadge extends StatelessWidget {
  final int count;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _MatchBadge({
    required this.count,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
