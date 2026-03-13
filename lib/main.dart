import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/drop_overlay.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SpxViewerApp(initialFilePath: args.isNotEmpty ? args.first : null));
}

class SpxViewerApp extends StatelessWidget {
  final String? initialFilePath;

  const SpxViewerApp({super.key, this.initialFilePath});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ],
      child: MaterialApp(
        title: 'SPX Viewer',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: _AppRoot(initialFilePath: initialFilePath),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5C7A9F),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  final String? initialFilePath;

  const _AppRoot({this.initialFilePath});

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      // Load after the first frame so the Provider tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DocumentProvider>().loadFile(widget.initialFilePath!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const DropOverlay(child: HomeScreen());
  }
}
