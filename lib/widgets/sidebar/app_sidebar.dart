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
  // All categories start expanded.
  final Set<String> _expandedCategories = {
    'Hardware',
    'Network',
    'Software',
    'Other',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final doc = provider.document;
    if (doc == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Group sections by category (all sections, including empty ones).
    final categorized = <String, List<SpxSection>>{};
    for (final section in doc.sections) {
      categorized.putIfAbsent(section.categoryName, () => []).add(section);
    }

    // Ordered category list.
    final categories = [...kCategoryOrder];
    for (final cat in categorized.keys) {
      if (!categories.contains(cat)) categories.add(cat);
    }

    return Container(
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FileHeader(fileName: doc.fileName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              children: [
                for (final cat in categories)
                  if (categorized.containsKey(cat))
                    _CategoryGroup(
                      category: cat,
                      allSections: categorized[cat]!,
                      isExpanded: _expandedCategories.contains(cat),
                      onToggleExpand: () => setState(() {
                        if (_expandedCategories.contains(cat)) {
                          _expandedCategories.remove(cat);
                        } else {
                          _expandedCategories.add(cat);
                        }
                      }),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FileHeader extends StatelessWidget {
  final String fileName;
  const _FileHeader({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, size: 15, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<SpxSection> allSections;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _CategoryGroup({
    required this.category,
    required this.allSections,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Overview sections are hidden from the sub-item list.
    final subItems = allSections
        .where((s) => !kOverviewDataTypes.contains(s.dataType))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    // Whether the overview for this category is currently active.
    final overviewActive = provider.selectedCategoryOverview == category;

    // The category has an overview if a matching overview section exists.
    final overviewType = kCategoryOverviewDataType[category];
    final hasOverview = overviewType != null &&
        allSections.any((s) => s.dataType == overviewType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Category header ──────────────────────────────────────────────
        Container(
          decoration: overviewActive
              ? BoxDecoration(
                  color: cs.primaryContainer.withAlpha(120),
                )
              : null,
          child: Row(
            children: [
              // Clicking the label area navigates to the overview.
              Expanded(
                child: InkWell(
                  onTap: hasOverview
                      ? () => provider.selectCategoryOverview(category)
                      : onToggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 4, 7),
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcon(category),
                          size: 13,
                          color: overviewActive
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: overviewActive
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Separate expand/collapse button.
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 15,
                    color: cs.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Sub-items ────────────────────────────────────────────────────
        if (isExpanded)
          for (final section in subItems)
            _SectionTile(section: section),
      ],
    );
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

// ─────────────────────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final SpxSection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Overview sections are never in the sub-items list, so no conflict.
    final isSelected = provider.selectedSection?.dataType == section.dataType;

    // Count search matches.
    int matchCount = 0;
    final q = provider.globalSearchQuery;
    if (q.isNotEmpty) {
      final qLower = q.toLowerCase();
      for (final item in section.items) {
        if (item.values.any((v) => v.toString().toLowerCase().contains(qLower))) {
          matchCount++;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: isSelected ? cs.primaryContainer : Colors.transparent,
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
                          ? cs.onPrimaryContainer
                          : section.isEmpty
                              ? cs.onSurface.withAlpha(70)
                              : cs.onSurface,
                    ),
                  ),
                ),
                if (matchCount > 0)
                  _MatchBadge(count: matchCount)
                else if (section.isEmpty)
                  Icon(
                    Icons.circle,
                    size: 5,
                    color: cs.onSurface.withAlpha(50),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MatchBadge extends StatelessWidget {
  final int count;
  const _MatchBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
