import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
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

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: provider.hasDocument
          ? IconButton(
              icon: Icon(
                provider.isSidebarCollapsed
                    ? Icons.menu_rounded
                    : Icons.menu_open_rounded,
              ),
              tooltip: provider.isSidebarCollapsed
                  ? 'Show sidebar'
                  : 'Hide sidebar',
              onPressed: provider.toggleSidebar,
            )
          : null,
      title: provider.isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search in report…',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
              ),
              style: theme.textTheme.titleMedium,
              onChanged: provider.setGlobalSearch,
            )
          : Text(
              provider.document?.fileName ?? 'SPX Viewer',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
      actions: [
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
              }
              provider.setSearchActive(!provider.isSearchActive);
            },
          ),
          // Export JSON
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export as JSON',
            onPressed: () => _exportJson(context, provider),
          ),
        ],
        // Open file
        IconButton(
          icon: const Icon(Icons.folder_open_outlined),
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
            child: provider.isSidebarCollapsed
                ? const SizedBox.shrink()
                : const AppSidebar(),
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
