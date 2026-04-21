import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spx_section.dart';
import '../../providers/document_provider.dart';
import '../../providers/ui_scale_provider.dart';
import 'kv_table.dart';
import 'items_table.dart';
import 'usb_tree_view.dart';
import 'log_viewer.dart';
import 'grouped_kv_view.dart';
import 'nested_items_view.dart';
import 'bluetooth_view.dart';
import 'controller_view.dart';
import 'ethernet_view.dart';
import 'displays_view.dart';
import 'hardware_view.dart';
import 'apple_pay_view.dart';
import 'power_view.dart';
import 'storage_view.dart';
import 'thunderbolt_tree_view.dart';
import 'network_overview_view.dart';
import 'firewall_view.dart';
import 'locations_view.dart';
import 'wifi_view.dart';
import 'network_volumes_view.dart';
import 'software_view.dart';
import 'accessibility_view.dart';
import 'developer_tools_view.dart';
import 'detail_table_view.dart';
import 'printer_software_view.dart';
import 'rosetta_software_view.dart';
import 'smart_cards_view.dart';
import 'sync_services_view.dart';
import 'card_reader_view.dart';
import '../../utils/key_formatter.dart';
import '../../utils/section_descriptions.dart';

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
        child: Text('Select a section from the sidebar', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withAlpha(100))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        _SectionHeader(section: section),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(child: section.isEmpty ? _EmptySectionView(section: section) : _buildContent(section, provider.globalSearchQuery)),
      ],
    );
  }

  Widget _buildContent(SpxSection section, String searchQuery) {
    // Apple Pay (Secure Element) → two-section view matching macOS layout.
    if (section.dataType == 'SPSecureElementDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return ApplePayView(item: item, searchQuery: searchQuery);
    }

    // Accessibility → KV view with custom display/zoomMode value formatting.
    if (section.dataType == 'SPUniversalAccessDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return AccessibilityView(item: item, searchQuery: searchQuery);
    }

    // Developer Tools → hierarchical view (Version, Location, Apps, SDKs).
    if (section.dataType == 'SPDeveloperToolsDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return DeveloperToolsView(item: item, searchQuery: searchQuery);
    }

    // Applications → sortable table + click-to-detail panel.
    if (section.dataType == 'SPApplicationsDataType') {
      return DetailTableView.applications(section: section, searchQuery: searchQuery);
    }

    // Extensions → sortable table + click-to-detail panel.
    if (section.dataType == 'SPExtensionsDataType') {
      return DetailTableView.extensions(section: section, searchQuery: searchQuery);
    }

    // Fonts → sortable table + click-to-detail panel (with nested typefaces).
    if (section.dataType == 'SPFontsDataType') {
      return DetailTableView.fonts(section: section, searchQuery: searchQuery);
    }

    // Frameworks → sortable table + click-to-detail panel.
    if (section.dataType == 'SPFrameworksDataType') {
      return DetailTableView.frameworks(section: section, searchQuery: searchQuery);
    }

    // Install History → sortable table + click-to-detail panel.
    if (section.dataType == 'SPInstallHistoryDataType') {
      return DetailTableView.installations(section: section, searchQuery: searchQuery);
    }

    // Printer Software → collapsible category groups (PPDs, Printers, etc.).
    if (section.dataType == 'SPPrintersSoftwareDataType' ||
        section.dataType == 'SPPrinterSoftwareDataType') {
      return PrinterSoftwareView(items: section.items, searchQuery: searchQuery);
    }

    // Rosetta Software → two-pane Developer → App tree with detail panel.
    if (section.dataType == 'SPLegacySoftwareDataType') {
      return RosettaSoftwareView(items: section.items);
    }

    // SmartCards → labelled sections with numbered drivers and bullet lists.
    if (section.dataType == 'SPSmartCardsDataType') {
      return SmartCardsView(items: section.items, searchQuery: searchQuery);
    }

    // Sync Services → two-pane group → log tree with detail panel.
    if (section.dataType == 'SPSyncServicesDataType') {
      return SyncServicesView(items: section.items, searchQuery: searchQuery);
    }

    // Software Overview → ordered KV view with formatted uptime and labels.
    if (section.dataType == 'SPSoftwareDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return SoftwareView(item: item, searchQuery: searchQuery);
    }

    // Hardware Overview → ordered KV view with macOS-matching labels.
    if (section.dataType == 'SPHardwareDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return HardwareView(item: item, searchQuery: searchQuery);
    }

    // USB host data type → dedicated tree + detail view.
    if (section.dataType == 'SPUSBHostDataType') {
      return UsbTreeView(buses: section.items);
    }

    // Logs → dedicated two-pane log viewer.
    if (section.dataType == 'SPLogsDataType') {
      return LogViewer(items: section.items, searchQuery: searchQuery);
    }

    // Language & Region (and similar grouped-settings sections) →
    // named groups stacked vertically rather than a flat table.
    if (section.dataType == 'SPInternationalDataType') {
      return GroupedKvView(items: section.items, searchQuery: searchQuery);
    }

    // Bluetooth → dedicated grouped view matching L&R style.
    if (section.dataType == 'SPBluetoothDataType') {
      return BluetoothView(items: section.items, searchQuery: searchQuery);
    }

    // Ethernet → dedicated ordered view with clean labels.
    if (section.dataType == 'SPEthernetDataType') {
      return EthernetView(items: section.items, searchQuery: searchQuery);
    }

    // Graphics / Displays → GPU sections with nested per-display collapsibles.
    if (section.dataType == 'SPDisplaysDataType') {
      return DisplaysView(items: section.items, searchQuery: searchQuery);
    }

    // Thunderbolt / USB4 → two-pane tree + detail view.
    if (section.dataType == 'SPThunderboltDataType' || section.dataType == 'SPUSB4DataType') {
      return ThunderboltTreeView(items: section.items, searchQuery: searchQuery);
    }

    // Network Locations → hierarchical collapsible service tree.
    if (section.dataType == 'SPNetworkLocationDataType') {
      return LocationsView(items: section.items, searchQuery: searchQuery);
    }

    // Wi-Fi → hierarchical view with collapsible interfaces.
    if (section.dataType == 'SPAirPortDataType') {
      return WifiView(items: section.items, searchQuery: searchQuery);
    }

    // Network Volumes → table with detail panel on row selection.
    if (section.dataType == 'SPNetworkVolumeDataType') {
      return NetworkVolumesView(section: section, searchQuery: searchQuery);
    }

    // Firewall → hierarchical indented view matching macOS layout.
    if (section.dataType == 'SPFirewallDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return FirewallView(item: item, searchQuery: searchQuery);
    }

    // Network → table with scalar columns + row-selection recursive detail panel.
    if (section.dataType == 'SPNetworkDataType') {
      return NetworkOverviewView(section: section, searchQuery: searchQuery);
    }

    // Storage → table with byte-formatted columns + row-selection detail panel.
    if (section.dataType == 'SPStorageDataType') {
      return StorageView(section: section, searchQuery: searchQuery);
    }

    // Power → hierarchical section/sub-section view matching macOS layout.
    if (section.dataType == 'SPPowerDataType') {
      return PowerView(items: section.items, searchQuery: searchQuery);
    }

    if (section.dataType == 'SPCardReaderDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return CardReaderView(item: item, searchQuery: searchQuery);
    }

    // Controller (iBridge / T2 / Apple Silicon) → hierarchical indented tree.
    if (section.dataType == 'SPiBridgeDataType') {
      final item = section.items.isNotEmpty ? section.items.first : <String, dynamic>{};
      return ControllerView(item: item, searchQuery: searchQuery);
    }

    if (section.items.length == 1) {
      final only = section.items.first;

      // Wrapper pattern: single item whose own _items list holds the real data
      // (e.g. Audio "coreaudio_device" wrapping VZ249, Mix 3, …).
      final nested = only['_items'];
      if (nested is List && nested.isNotEmpty) {
        final nestedItems = nested.whereType<Map<String, dynamic>>().toList();
        if (nestedItems.isNotEmpty) {
          return NestedItemsView(
            items: nestedItems,
            searchQuery: searchQuery,
            keyFormatter: _keyFormatterFor(section.dataType),
            subtitleBuilder: _subtitleBuilderFor(section.dataType),
            leadingIconBuilder: _leadingIconBuilderFor(section.dataType),
            trailingIconBuilder: _trailingIconBuilderFor(section.dataType),
            detailIcon: _detailIconFor(section.dataType),
          );
        }
      }

      // Single item with no nested _items → plain key-value table.
      return KvTable(
        item:        only,
        searchQuery: searchQuery,
        sectionName: section.displayName,
      );
    }
    // Multiple items → sortable/filterable table
    return ItemsTable(
      section: section,
      searchQuery: searchQuery,
      keyFormatter: _keyFormatterFor(section.dataType),
    );
  }
}

// ─── Helpers for NestedItemsView configuration ──────────────────────────────

String Function(String) _keyFormatterFor(String dataType) {
  switch (dataType) {
    case 'SPAudioDataType':
      return formatAudioKey;
    case 'SPCameraDataType':
      return formatCameraKey;
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
        final parts = [if (mfr != null && mfr.isNotEmpty) mfr, if (transport != null) formatSpxValue(transport)];
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

IconData? Function(Map<String, dynamic>)? _leadingIconBuilderFor(String dataType) {
  switch (dataType) {
    case 'SPAudioDataType':
      return (item) {
        final hasOut = item.containsKey('coreaudio_output_source') || item.containsKey('coreaudio_device_output');
        final hasIn = item.containsKey('coreaudio_input_source') || item.containsKey('coreaudio_device_input');
        if (hasOut && hasIn) return Icons.headphones;
        if (hasOut) return Icons.volume_up;
        if (hasIn) return Icons.mic;
        return Icons.graphic_eq;
      };
    default:
      return null;
  }
}

IconData? Function(Map<String, dynamic>)? _trailingIconBuilderFor(String dataType) {
  switch (dataType) {
    case 'SPAudioDataType':
      return (item) {
        final raw = item['coreaudio_device_transport']?.toString();
        if (raw == null) return null;
        switch (formatSpxValue(raw)) {
          case 'HDMI':
            return Icons.monitor_outlined;
          case 'USB':
            return Icons.usb;
          case 'Virtual':
            return Icons.cloud_outlined;
          case 'Built-in':
            return Icons.laptop_mac;
          case 'Bluetooth':
            return Icons.bluetooth;
          case 'Thunderbolt':
            return Icons.bolt;
          case 'PCI':
            return Icons.extension;
          default:
            return null;
        }
      };
    default:
      return null;
  }
}

// ---------------------------------------------------------------------------

IconData iconForSection(String dataType) {
  switch (dataType) {
    // ── Hardware ─────────────────────────────────────────────────────────────
    case 'SPHardwareDataType':
      return Icons.computer_outlined;
    case 'SPSecureElementDataType':
      return Icons.contactless_outlined;
    case 'SPAudioDataType':
      return Icons.headset_outlined;
    case 'SPBluetoothDataType':
      return Icons.bluetooth;
    case 'SPCameraDataType':
      return Icons.camera_alt_outlined;
    case 'SPCardReaderDataType':
      return Icons.sd_card_outlined;
    case 'SPiBridgeDataType':
      return Icons.developer_board_outlined;
    case 'SPDiagnosticsDataType':
      return Icons.fact_check_outlined;
    case 'SPDiscBurningDataType':
      return Icons.album_outlined;
    case 'SPEthernetDataType':
      return Icons.settings_ethernet;
    case 'SPFibreChannelDataType':
      return Icons.cable_outlined;
    case 'SPDisplaysDataType':
      return Icons.monitor_outlined;
    case 'SPMemoryDataType':
      return Icons.memory_outlined;
    case 'SPNVMeDataType':
      return Icons.drive_eta_outlined;
    case 'SPPCIDataType':
      return Icons.extension_outlined;
    case 'SPParallelATADataType':
    case 'SPParallelSCSIDataType':
    case 'SPSASDataType':
    case 'SPSerialATADataType':
      return Icons.storage_outlined;
    case 'SPPowerDataType':
      return Icons.bolt_outlined;
    case 'SPPrintersDataType':
      return Icons.print_outlined;
    case 'SPSPIDataType':
      return Icons.developer_board_outlined;
    case 'SPStorageDataType':
      return Icons.storage_outlined;
    case 'SPThunderboltDataType':
      return Icons.bolt;
    case 'SPUSB4DataType':
    case 'SPUSBDataType':
    case 'SPUSBHostDataType':
      return Icons.usb_outlined;
    case 'SPFireWireDataType':
      return Icons.cable_outlined;
    // ── Network ───────────────────────────────────────────────────────────────
    case 'SPNetworkDataType':
      return Icons.router_outlined;
    case 'SPFirewallDataType':
      return Icons.security_outlined;
    case 'SPNetworkLocationDataType':
      return Icons.place_outlined;
    case 'SPNetworkVolumeDataType':
      return Icons.folder_shared_outlined;
    case 'SPAirPortDataType':
      return Icons.wifi;
    case 'SPWWANDataType':
      return Icons.signal_cellular_alt_outlined;
    case 'SPModemDataType':
      return Icons.router_outlined;
    // ── Software ──────────────────────────────────────────────────────────────
    case 'SPSoftwareDataType':
      return Icons.widgets_outlined;
    case 'SPUniversalAccessDataType':
      return Icons.accessibility_new_outlined;
    case 'SPApplicationsDataType':
      return Icons.apps_outlined;
    case 'SPDeveloperToolsDataType':
      return Icons.code_outlined;
    case 'SPDisabledSoftwareDataType':
    case 'SPLegacySoftwareDataType':
      return Icons.block_outlined;
    case 'SPExtensionsDataType':
      return Icons.extension_outlined;
    case 'SPFontsDataType':
      return Icons.font_download_outlined;
    case 'SPFrameworksDataType':
      return Icons.view_in_ar_outlined;
    case 'SPInstallHistoryDataType':
      return Icons.history_outlined;
    case 'SPInternationalDataType':
      return Icons.language_outlined;
    case 'SPLogsDataType':
      return Icons.description_outlined;
    case 'SPManagedClientDataType':
      return Icons.manage_accounts_outlined;
    case 'SPPrefPaneDataType':
      return Icons.tune_outlined;
    case 'SPPrinterSoftwareDataType':
    case 'SPPrintersSoftwareDataType':
      return Icons.print_outlined;
    case 'SPConfigurationProfileDataType':
      return Icons.assignment_outlined;
    case 'SPRawCameraDataType':
      return Icons.camera_outlined;
    case 'SPRosettaSoftwareDataType':
      return Icons.translate_outlined;
    case 'SPSmartCardsDataType':
      return Icons.credit_card_outlined;
    case 'SPStartupItemDataType':
      return Icons.play_circle_outline;
    case 'SPSyncServicesDataType':
      return Icons.sync_outlined;
    default:
      return Icons.info_outlined;
  }
}

// ---------------------------------------------------------------------------

enum _CopyFormat { json, text }

/// Serialises [section] to a pretty-printed JSON string.
String _sectionToJson(SpxSection section) {
  dynamic sanitize(dynamic v) {
    if (v is DateTime) return v.toIso8601String();
    if (v is Map) {
      return v.map((k, v2) => MapEntry(k.toString(), sanitize(v2)));
    }
    if (v is List) return v.map(sanitize).toList();
    return v;
  }

  return const JsonEncoder.withIndent('  ').convert(sanitize(section.toJson()));
}

/// Serialises [section] to a human-readable plain-text string.
String _sectionToText(SpxSection section) {
  final buf = StringBuffer();
  buf.writeln('${section.displayName}:');
  buf.writeln();

  void writeMap(Map<String, dynamic> m, int depth) {
    final indent = '  ' * depth;
    for (final e in m.entries) {
      if (isInternalKey(e.key)) continue;
      final key = formatKey(e.key);
      final v = e.value;
      if (v is Map) {
        buf.writeln('$indent$key:');
        writeMap(
          Map<String, dynamic>.fromEntries(
            v.entries.map((e2) => MapEntry(e2.key.toString(), e2.value)),
          ),
          depth + 1,
        );
      } else if (v is List) {
        buf.writeln('$indent$key:');
        for (final item in v) {
          if (item is Map) {
            writeMap(
              Map<String, dynamic>.fromEntries(
                item.entries.map((e2) => MapEntry(e2.key.toString(), e2.value)),
              ),
              depth + 1,
            );
          } else if (item != null) {
            buf.writeln('$indent  ${formatSpxValue(item.toString())}');
          }
        }
      } else if (v is bool) {
        buf.writeln('$indent$key: ${v ? 'Yes' : 'No'}');
      } else if (v != null) {
        buf.writeln('$indent$key: ${formatSpxValue(v.toString())}');
      }
    }
  }

  for (int i = 0; i < section.items.length; i++) {
    writeMap(section.items[i], 0);
    if (section.items.length > 1 && i < section.items.length - 1) buf.writeln();
  }

  return buf.toString().trim();
}

// ---------------------------------------------------------------------------

void showSectionInfo(BuildContext context, SpxSection section) {
  final theme = Theme.of(context);
  final cs    = theme.colorScheme;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(iconForSection(section.dataType), color: cs.primary, size: 32),
      title: Text(section.displayName),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Text(
          descriptionFor(section.dataType),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final SpxSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = iconForSection(section.dataType);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        spacing: 8,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (section.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Report: ${DateFormat('yyyy-MM-dd  HH:mm:ss').format(section.timestamp!.toLocal())}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),

          // Copy section data button
          PopupMenuButton<_CopyFormat>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.copy_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant.withAlpha(180),
            ),
            tooltip: 'Copy section data',
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _CopyFormat.json,
                child: Text('Copy as JSON'),
              ),
              PopupMenuItem(
                value: _CopyFormat.text,
                child: Text('Copy as plain text'),
              ),
            ],
            onSelected: (format) async {
              final text = format == _CopyFormat.json ? _sectionToJson(section) : _sectionToText(section);
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${section.displayName} copied as '
                      '${format == _CopyFormat.json ? 'JSON' : 'plain text'}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // Section info button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withAlpha(180),
            ),
            tooltip: 'About this section',
            onPressed: () => showSectionInfo(context, section),
          ),
          if (!section.isEmpty) _CountBadge(count: section.items.length, label: section.items.length == 1 ? 'item' : 'items', colorScheme: colorScheme, theme: theme),
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

  const _CountBadge({required this.count, required this.label, required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(14)),
      child: Text(
        '$count $label',
        style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w500),
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
    final cs = theme.colorScheme;
    final sp = context.watch<UiScaleProvider>();
    final description = descriptionFor(section.dataType);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: sp.sz(52), color: cs.onSurface.withAlpha(50)),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurface.withAlpha(100)),
              ),
              const SizedBox(height: 4),
              Text(
                section.dataType,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(60)),
              ),
              const SizedBox(height: 28),
              Divider(color: cs.outlineVariant.withAlpha(120)),
              const SizedBox(height: 20),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withAlpha(160),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
