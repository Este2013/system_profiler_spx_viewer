import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../providers/update_provider.dart';
import '../widgets/sidebar/app_sidebar.dart';
import '../widgets/data_view/section_view.dart';
import '../widgets/welcome_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode  = FocusNode();
  int _lastFocusVersion   = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().addListener(_onProviderChanged);
    });
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final dp = context.read<DocumentProvider>();
    if (dp.searchFocusVersion != _lastFocusVersion) {
      _lastFocusVersion = dp.searchFocusVersion;
      // Wait for the search TextField to be in the tree, then focus + select all.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset:  0,
          extentOffset: _searchController.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    // Safe read — context is still valid during dispose.
    context.read<DocumentProvider>().removeListener(_onProviderChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: _buildAppBar(context, provider),
      body: _buildBody(context, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    DocumentProvider provider,
  ) {
    final theme = Theme.of(context);
    final updateProvider = context.watch<UpdateProvider>();

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: provider.hasDocument
          ? IconButton(
              icon: Icon(
                provider.isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
              ),
              tooltip: provider.isSidebarCollapsed ? 'Show sidebar' : 'Hide sidebar',
              onPressed: provider.toggleSidebar,
            )
          : null,
      title: provider.isSearchActive
          ? KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _searchController.clear();
                  provider.setGlobalSearch('');
                  provider.setSearchActive(false);
                }
              },
              child: TextField(
                controller: _searchController,
                focusNode:  _searchFocusNode,
                autofocus:  true,
                decoration: InputDecoration(
                  hintText: 'Search in report…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                style: theme.textTheme.titleMedium,
                onChanged: provider.setGlobalSearch,
              ),
            )
          : Text(
              provider.document?.fileName ?? 'SPX Viewer',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
      actions: [
        if (updateProvider.hasUpdate) ...[
          _UpdateChip(tag: updateProvider.latestTag!),
          const SizedBox(width: 4),
        ],
        if (provider.hasDocument) ...[
          // Search toggle
          IconButton(
            icon: Icon(
              provider.isSearchActive ? Icons.close : Icons.search_rounded,
            ),
            tooltip: provider.isSearchActive ? 'Close search' : 'Search',
            onPressed: () {
              if (provider.isSearchActive) {
                _searchController.clear();
                provider.setGlobalSearch('');
              }
              provider.setSearchActive(!provider.isSearchActive);
            },
          ),
          // Export JSON
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Export as JSON',
            onPressed: () => _exportJson(context, provider),
          ),
        ],
        // Open file
        IconButton(
          icon: const Icon(Icons.file_open),
          tooltip: 'Open SPX file',
          onPressed: () => provider.openFilePicker(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DocumentProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!provider.hasDocument) {
      return const WelcomeView();
    }

    return _MainLayout(provider: provider);
  }

  Future<void> _exportJson(
    BuildContext ctx,
    DocumentProvider provider,
  ) async {
    final success = await provider.exportJson();
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(success ? 'Exported successfully' : 'Export cancelled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _UpdateChip extends StatelessWidget {
  final String tag;
  const _UpdateChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'v$tag available — click to open releases page',
      child: ActionChip(
        avatar: Icon(
          Icons.new_releases_outlined,
          size: 15,
          color: cs.onSecondaryContainer,
        ),
        label: Text(
          'v$tag',
          style: TextStyle(
            color: cs.onSecondaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        backgroundColor: cs.secondaryContainer,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          try {
            if (Platform.isWindows) {
              await Process.run(
                'start', [UpdateProvider.releasesPageUrl],
                runInShell: true,
              );
            } else if (Platform.isMacOS) {
              await Process.run('open', [UpdateProvider.releasesPageUrl]);
            } else {
              await Process.run('xdg-open', [UpdateProvider.releasesPageUrl]);
            }
          } catch (_) {}
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MainLayout extends StatelessWidget {
  final DocumentProvider provider;

  const _MainLayout({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Sidebar ────────────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: SizedBox(
            width: provider.isSidebarCollapsed ? 0 : 248,
            child: provider.isSidebarCollapsed ? const SizedBox.shrink() : const AppSidebar(),
          ),
        ),

        if (!provider.isSidebarCollapsed)
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),

        // ── Main content ───────────────────────────────────────────────────
        const Expanded(child: SectionView()),
      ],
    );
  }
}
