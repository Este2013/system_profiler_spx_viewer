import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';
import 'providers/ui_scale_provider.dart';
import 'providers/split_pane_provider.dart';
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
        ChangeNotifierProvider(create: (_) => UiScaleProvider()),
        ChangeNotifierProvider(create: (_) => SplitPaneProvider()),
      ],
      child: Builder(
        builder: (ctx) {
          final themeMode = ctx.select<UiScaleProvider, ThemeMode>(
            (sp) => sp.themeMode,
          );
          return MaterialApp(
            title: 'SPX Viewer',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeMode,
            home: _AppRoot(initialFilePath: initialFilePath),
          );
        },
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
    HardwareKeyboard.instance.addHandler(_handleKey);
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
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (!ctrl) return false;

    final sp = context.read<UiScaleProvider>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      sp.increase();
      return true;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      sp.decrease();
      return true;
    }
    if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      sp.reset();
      return true;
    }
    if (key == LogicalKeyboardKey.keyO) {
      final dp = context.read<DocumentProvider>();
      if (HardwareKeyboard.instance.isShiftPressed) {
        dp.openFilePickerNewInstance();
      } else {
        dp.openFilePicker();
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<UiScaleProvider>().scale;
    return Stack(
      fit: StackFit.expand,
      children: [
        // All app content rendered with the selected text scale factor.
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: const DropOverlay(child: HomeScreen()),
        ),

        // Floating appearance controls — live outside the scaled MediaQuery.
        const Positioned(
          right: 16,
          bottom: 16,
          child: _AppearanceBar(),
        ),
      ],
    );
  }
}

// ── Floating zoom control pill ───────────────────────────────────────────────

class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final atMin = sp.scale <= UiScaleProvider.minScale;
    final atMax = sp.scale >= UiScaleProvider.maxScale;
    final isDefault = sp.scale == 1.0;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Decrease ────────────────────────────────────────────────────
            IconButton(
              onPressed: atMin ? null : sp.decrease,
              icon: const Icon(Icons.remove),
              iconSize: 16,
              tooltip: 'Zoom out  (Ctrl −)',
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            // ── Slider ──────────────────────────────────────────────────────
            SizedBox(
              width: 110,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: sp.scale,
                  min: UiScaleProvider.minScale,
                  max: UiScaleProvider.maxScale,
                  divisions: ((UiScaleProvider.maxScale -
                              UiScaleProvider.minScale) /
                          UiScaleProvider.step)
                      .round(),
                  onChanged: sp.setScale,
                ),
              ),
            ),

            // ── Scale label — tap to reset ───────────────────────────────────
            Tooltip(
              message: 'Reset zoom  (Ctrl 0)',
              child: InkWell(
                onTap: isDefault ? null : sp.reset,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    '${(sp.scale * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDefault ? cs.onSurfaceVariant : cs.primary,
                      fontWeight:
                          isDefault ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // ── Increase ────────────────────────────────────────────────────
            IconButton(
              onPressed: atMax ? null : sp.increase,
              icon: const Icon(Icons.add),
              iconSize: 16,
              tooltip: 'Zoom in  (Ctrl +)',
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appearance bar (zoom + theme) ────────────────────────────────────────────

class _AppearanceBar extends StatelessWidget {
  const _AppearanceBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        _ScaleSlider(),
        SizedBox(width: 8),
        _ThemeButton(),
      ],
    );
  }
}

// ── Theme toggle button ───────────────────────────────────────────────────────

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<UiScaleProvider>();
    final cs = Theme.of(context).colorScheme;

    final (IconData icon, String tooltip) = switch (sp.themeMode) {
      ThemeMode.system => (
          Icons.brightness_auto_outlined,
          'Appearance: System  (click → Light)',
        ),
      ThemeMode.light => (
          Icons.light_mode_outlined,
          'Appearance: Light  (click → Dark)',
        ),
      ThemeMode.dark => (
          Icons.dark_mode_outlined,
          'Appearance: Dark  (click → System)',
        ),
    };

    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 3,
        shape: const CircleBorder(),
        color: cs.surfaceContainerHighest,
        child: InkWell(
          onTap: sp.cycleTheme,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
