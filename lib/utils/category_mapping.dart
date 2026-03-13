class SectionInfo {
  final String displayName;
  final String category;
  const SectionInfo(this.displayName, this.category);
}

const Map<String, SectionInfo> kDataTypeMap = {
  // Hardware
  'SPHardwareDataType': SectionInfo('Hardware Overview', 'Hardware'),
  'SPMemoryDataType': SectionInfo('Memory', 'Hardware'),
  'SPDisplaysDataType': SectionInfo('Displays', 'Hardware'),
  'SPAudioDataType': SectionInfo('Audio', 'Hardware'),
  'SPBluetoothDataType': SectionInfo('Bluetooth', 'Hardware'),
  'SPCameraDataType': SectionInfo('Camera', 'Hardware'),
  'SPUSBDataType': SectionInfo('USB', 'Hardware'),
  'SPThunderboltDataType': SectionInfo('Thunderbolt', 'Hardware'),
  'SPPCIDataType': SectionInfo('PCI', 'Hardware'),
  'SPNVMeDataType': SectionInfo('NVMe', 'Hardware'),
  'SPSerialATADataType': SectionInfo('Serial-ATA', 'Hardware'),
  'SPParallelATADataType': SectionInfo('Parallel ATA', 'Hardware'),
  'SPSASDataType': SectionInfo('SAS', 'Hardware'),
  'SPFibreChannelDataType': SectionInfo('Fibre Channel', 'Hardware'),
  'SPPowerDataType': SectionInfo('Power', 'Hardware'),
  'SPSecureElementDataType': SectionInfo('Secure Element', 'Hardware'),
  'SPCardReaderDataType': SectionInfo('Card Reader', 'Hardware'),
  'SPDiscBurningDataType': SectionInfo('Disc Burning', 'Hardware'),
  'SPiBridgeDataType': SectionInfo('iBridge', 'Hardware'),
  'SPDeveloperToolsDataType': SectionInfo('Developer Tools', 'Hardware'),
  'SPUSB4DataType': SectionInfo('USB4', 'Hardware'),

  // Network
  'SPAirPortDataType': SectionInfo('Wi-Fi', 'Network'),
  'SPNetworkDataType': SectionInfo('Network', 'Network'),
  'SPFirewallDataType': SectionInfo('Firewall', 'Network'),
  'SPNetworkLocationDataType': SectionInfo('Locations', 'Network'),
  'SPNetworkVolumeDataType': SectionInfo('Network Volumes', 'Network'),
  'SPEthernetDataType': SectionInfo('Ethernet', 'Network'),
  'SPFireWireDataType': SectionInfo('FireWire', 'Network'),
  'SPWWANDataType': SectionInfo('WWAN', 'Network'),
  'SPModemDataType': SectionInfo('Modem', 'Network'),

  // Software
  'SPSoftwareDataType': SectionInfo('Software Overview', 'Software'),
  'SPApplicationsDataType': SectionInfo('Applications', 'Software'),
  'SPExtensionsDataType': SectionInfo('Extensions', 'Software'),
  'SPFontsDataType': SectionInfo('Fonts', 'Software'),
  'SPFrameworksDataType': SectionInfo('Frameworks', 'Software'),
  'SPLogsDataType': SectionInfo('Logs', 'Software'),
  'SPStartupItemDataType': SectionInfo('Startup Items', 'Software'),
  'SPPrefPaneDataType': SectionInfo('Preference Panes', 'Software'),
  'SPPrintersDataType': SectionInfo('Printers', 'Software'),
  'SPInstallHistoryDataType': SectionInfo('Install History', 'Software'),
  'SPManagedClientDataType': SectionInfo('Managed Client', 'Software'),
  'SPLegacySoftwareDataType': SectionInfo('Legacy Software', 'Software'),
  'SPConfigurationProfileDataType': SectionInfo('Profiles', 'Software'),
  'SPSmartCardsDataType': SectionInfo('Smart Cards', 'Software'),
  'SPUniversalAccessDataType': SectionInfo('Accessibility', 'Software'),
};

const List<String> kCategoryOrder = ['Hardware', 'Network', 'Software', 'Other'];

SectionInfo getSectionInfo(String dataType) {
  if (kDataTypeMap.containsKey(dataType)) {
    return kDataTypeMap[dataType]!;
  }
  // Auto-generate a display name from the dataType string
  String name = dataType;
  if (name.startsWith('SP')) name = name.substring(2);
  if (name.endsWith('DataType')) name = name.substring(0, name.length - 8);
  // Insert spaces before capital letters
  final buffer = StringBuffer();
  for (int i = 0; i < name.length; i++) {
    if (i > 0 && name[i].toUpperCase() == name[i] && name[i - 1].toUpperCase() != name[i - 1]) {
      buffer.write(' ');
    }
    buffer.write(name[i]);
  }
  return SectionInfo(buffer.toString(), 'Other');
}
