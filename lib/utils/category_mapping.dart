class SectionInfo {
  final String displayName;
  final String category;
  const SectionInfo(this.displayName, this.category);
}

// ── Main lookup table ─────────────────────────────────────────────────────────
// Names and categories are aligned with macOS System Information.app (Sonoma+).
const Map<String, SectionInfo> kDataTypeMap = {

  // ── Hardware ─────────────────────────────────────────────────────────────
  // Overview — accessed via the category header, not listed as a sub-item.
  'SPHardwareDataType':         SectionInfo('Hardware Overview',  'Hardware'),

  // Sub-items (alphabetical, matching macOS sidebar)
  'SPParallelATADataType':      SectionInfo('ATA',                'Hardware'),
  'SPSecureElementDataType':    SectionInfo('Apple Pay',          'Hardware'),
  'SPAudioDataType':            SectionInfo('Audio',              'Hardware'),
  'SPBluetoothDataType':        SectionInfo('Bluetooth',          'Hardware'),
  'SPCameraDataType':           SectionInfo('Camera',             'Hardware'),
  'SPCardReaderDataType':       SectionInfo('Card Reader',        'Hardware'),
  'SPiBridgeDataType':          SectionInfo('Controller',         'Hardware'),
  'SPDiagnosticsDataType':      SectionInfo('Diagnostics',        'Hardware'),
  'SPDiscBurningDataType':      SectionInfo('Disc Burning',       'Hardware'),
  'SPEthernetDataType':         SectionInfo('Ethernet',           'Hardware'),
  'SPFibreChannelDataType':     SectionInfo('Fibre Channel',      'Hardware'),
  'SPDisplaysDataType':         SectionInfo('Graphics/Displays',  'Hardware'),
  'SPMemoryDataType':           SectionInfo('Memory',             'Hardware'),
  'SPNVMeDataType':             SectionInfo('NVMExpress',         'Hardware'),
  'SPPCIDataType':              SectionInfo('PCI',                'Hardware'),
  'SPParallelSCSIDataType':     SectionInfo('Parallel SCSI',      'Hardware'),
  'SPPowerDataType':            SectionInfo('Power',              'Hardware'),
  'SPPrintersDataType':         SectionInfo('Printers',           'Hardware'),
  'SPSASDataType':              SectionInfo('SAS',                'Hardware'),
  'SPSerialATADataType':        SectionInfo('SATA',               'Hardware'),
  'SPSPIDataType':              SectionInfo('SPI',                'Hardware'),
  'SPStorageDataType':          SectionInfo('Storage',            'Hardware'),
  'SPThunderboltDataType':      SectionInfo('Thunderbolt/USB4',   'Hardware'),
  'SPUSB4DataType':             SectionInfo('USB4',               'Hardware'),
  'SPUSBDataType':              SectionInfo('USB',                'Hardware'),
  'SPUSBHostDataType':          SectionInfo('USB',                'Hardware'),
  'SPFireWireDataType':         SectionInfo('FireWire',           'Hardware'),

  // ── Network ───────────────────────────────────────────────────────────────
  // Overview — accessed via the category header.
  'SPNetworkDataType':          SectionInfo('Network Overview',   'Network'),

  // Sub-items
  'SPFirewallDataType':         SectionInfo('Firewall',           'Network'),
  'SPNetworkLocationDataType':  SectionInfo('Locations',          'Network'),
  'SPNetworkVolumeDataType':    SectionInfo('Volumes',            'Network'),
  'SPAirPortDataType':          SectionInfo('Wi-Fi',              'Network'),
  'SPWWANDataType':             SectionInfo('WWAN',               'Network'),
  'SPModemDataType':            SectionInfo('Modem',              'Network'),

  // ── Software ──────────────────────────────────────────────────────────────
  // Overview — accessed via the category header.
  'SPSoftwareDataType':             SectionInfo('Software Overview',  'Software'),

  // Sub-items
  'SPUniversalAccessDataType':      SectionInfo('Accessibility',      'Software'),
  'SPApplicationsDataType':         SectionInfo('Applications',       'Software'),
  'SPDeveloperToolsDataType':       SectionInfo('Developer',          'Software'),
  'SPDisabledSoftwareDataType':     SectionInfo('Disabled Software',  'Software'),
  'SPLegacySoftwareDataType':       SectionInfo('Disabled Software',  'Software'),
  'SPExtensionsDataType':           SectionInfo('Extensions',         'Software'),
  'SPFontsDataType':                SectionInfo('Fonts',              'Software'),
  'SPFrameworksDataType':           SectionInfo('Frameworks',         'Software'),
  'SPInstallHistoryDataType':       SectionInfo('Installations',      'Software'),
  'SPInternationalDataType':        SectionInfo('Language & Region',  'Software'),
  'SPLogsDataType':                 SectionInfo('Logs',               'Software'),
  'SPManagedClientDataType':        SectionInfo('Managed Client',     'Software'),
  'SPPrefPaneDataType':             SectionInfo('Preference Panes',   'Software'),
  'SPPrinterSoftwareDataType':      SectionInfo('Printer Software',   'Software'),
  'SPPrintersSoftwareDataType':     SectionInfo('Printer Software',   'Software'),
  'SPConfigurationProfileDataType': SectionInfo('Profiles',           'Software'),
  'SPRawCameraDataType':            SectionInfo('Raw Support',        'Software'),
  'SPRosettaSoftwareDataType':      SectionInfo('Rosetta Software',   'Software'),
  'SPSmartCardsDataType':           SectionInfo('SmartCards',         'Software'),
  'SPStartupItemDataType':          SectionInfo('Startup Items',      'Software'),
  'SPSyncServicesDataType':         SectionInfo('Sync Services',      'Software'),
};

// Ordered list of top-level category names.
const List<String> kCategoryOrder = ['Hardware', 'Network', 'Software', 'Other'];

// Which _dataType is the "overview" for each category (shown when the
// category header is clicked; NOT listed as a sidebar sub-item).
const Map<String, String> kCategoryOverviewDataType = {
  'Hardware': 'SPHardwareDataType',
  'Network':  'SPNetworkDataType',
  'Software': 'SPSoftwareDataType',
};

// The set of data types that are category overviews (used to filter them
// out of the sidebar sub-item list).
final Set<String> kOverviewDataTypes =
    Set.unmodifiable(kCategoryOverviewDataType.values.toSet());

// ── Helpers ───────────────────────────────────────────────────────────────────

SectionInfo getSectionInfo(String dataType) {
  if (kDataTypeMap.containsKey(dataType)) {
    return kDataTypeMap[dataType]!;
  }
  // Auto-derive a readable name from the raw data-type string.
  String name = dataType;
  if (name.startsWith('SP')) name = name.substring(2);
  if (name.endsWith('DataType')) name = name.substring(0, name.length - 8);
  // Insert spaces before uppercase runs (e.g. "NVMe" → "NV Me" → keep as-is below)
  final buf = StringBuffer();
  for (int i = 0; i < name.length; i++) {
    if (i > 0 &&
        name[i] == name[i].toUpperCase() &&
        name[i - 1] != name[i - 1].toUpperCase()) {
      buf.write(' ');
    }
    buf.write(name[i]);
  }
  return SectionInfo(buf.toString(), 'Other');
}
