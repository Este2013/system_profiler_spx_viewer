/// One-paragraph descriptions for every known SPDataType.
///
/// Shown in three places:
///   • The "No data available" empty-state view
///   • An info dialog triggered from the section header button
///   • A context menu item when right-clicking a sidebar entry
const Map<String, String> kSectionDescriptions = {

  // ── Hardware ───────────────────────────────────────────────────────────────

  'SPHardwareDataType':
      'A top-level summary of this Mac\'s hardware identity: model name and '
      'identifier, chip family, total memory, serial number, hardware UUID, and '
      'provisioning UDID. This is the first section most diagnostic workflows '
      'check when identifying a specific machine.',

  'SPParallelATADataType':
      'Parallel ATA (also called IDE or ATAPI) was the primary internal storage '
      'bus on Macs made before 2008 — covering Power Mac G4 and G5 systems and '
      'some early Intel Macs whose optical drives used the ATAPI variant. All '
      'modern Macs use SATA or NVMe exclusively, so this section is empty on '
      'any Mac produced after roughly 2008.',

  'SPSecureElementDataType':
      'The Secure Element is a dedicated tamper-resistant chip that stores '
      'payment credentials and cryptographic keys for Apple Pay and contactless '
      'transactions. On Apple Silicon Macs it is integrated into the SoC; on '
      'qualifying Intel Macs it was a discrete chip. This section mirrors the '
      'layout shown under Apple Pay in macOS System Information.',

  'SPAudioDataType':
      'Lists every audio device currently recognised by Core Audio — built-in '
      'speakers, headphone jacks, HDMI/DisplayPort audio, USB audio interfaces, '
      'Bluetooth headphones, and virtual aggregates. Each entry shows transport '
      'type, manufacturer, input and output channels, and current sample rate.',

  'SPBluetoothDataType':
      'Reports the Bluetooth controller version and firmware, discoverable '
      'state, and all currently paired or connected devices — including their '
      'address, RSSI, services, battery level (where available), and firmware '
      'version. Useful for diagnosing pairing issues or auditing connected '
      'peripherals.',

  'SPCameraDataType':
      'Enumerates built-in and USB-attached cameras visible to the AVFoundation '
      'framework. For each camera the section shows model name, unique ID, '
      'supported formats, and whether it is currently in use. The built-in '
      'FaceTime HD or Center Stage camera appears here on all MacBook and iMac '
      'models.',

  'SPCardReaderDataType':
      'Covers the built-in SD / SDXC / SDHC card reader and any media currently '
      'inserted in it — including card manufacturer, capacity, BSD device name, '
      'partition map, and S.M.A.R.T. status. Present on MacBook Pro models with '
      'a built-in SD slot (most 2009–2020 models and all 2021+ M-series 14″/16″ '
      'models), some MacBook Air generations, and some iMac models. The Mac mini '
      'has no built-in card reader, so this section is empty unless an external '
      'USB card reader is attached.',

  'SPiBridgeDataType':
      'The T1 and T2 chips were dedicated Apple-designed security processors '
      'embedded in certain Intel Mac models (MacBook Pro and Air 2018–2020, '
      'iMac Pro 2017, Mac mini 2018, Mac Pro 2019). They handled Touch ID, '
      'secure boot, encrypted storage controller, and the System Management '
      'Controller. On Apple Silicon Macs these functions are integrated directly '
      'into the M-series SoC, so no separate bridge chip is present and this '
      'section does not appear.',

  'SPDiagnosticsDataType':
      'Stores the result of the last Power-On Self-Test (POST) run at boot, '
      'along with a timestamp and cumulative power-on count. More detailed '
      'results are logged here after running Apple Diagnostics — hold D during '
      'startup on Intel Macs, or press and hold the power button until "Loading '
      'startup options" appears on Apple Silicon, then hold D. A passing result '
      'shows "No issues found"; hardware faults surface specific reference '
      'codes.',

  'SPDiscBurningDataType':
      'Reports optical drives capable of burning discs — built-in SuperDrives '
      'and external USB optical drives — along with any disc currently inserted '
      '(type, blank/erasable status, available write speeds). Apple removed the '
      'built-in optical drive from MacBook Pro in 2012, MacBook Air in 2010, '
      'Mac mini in 2011, and iMac in 2012. Attaching an Apple USB SuperDrive '
      '(model MD564LL/A) or a compatible third-party USB drive will populate '
      'this section on any modern Mac.',

  'SPEthernetDataType':
      'Details each wired Ethernet adapter: BSD interface name, MAC address, '
      'link speed and duplex, IPv4/IPv6 addresses, MTU, media options, and '
      'whether the link is active. Covers both the built-in Ethernet port and '
      'any USB or Thunderbolt Ethernet adapters currently attached.',

  'SPFibreChannelDataType':
      'Fibre Channel is a high-speed networking technology used almost '
      'exclusively in professional video production and enterprise SAN '
      '(Storage Area Network) environments. This section lists Fibre Channel '
      'HBA (Host Bus Adapter) cards installed in PCIe slots, showing vendor, '
      'port speed (4/8/16 Gb/s), topology, link status, World Wide Name, and '
      'cable type. Because it requires PCIe expansion slots, it only appears on '
      'Mac Pro towers with an FC card installed — never on Mac mini, MacBook, or '
      'iMac.',

  'SPDisplaysDataType':
      'Shows each GPU (discrete and integrated) along with every display '
      'connected to it. GPU entries include VRAM, Metal support, and EFI '
      'driver version. Display entries show resolution, colour depth, colour '
      'space, refresh rate, connection type, and whether the panel is built-in '
      'or external.',

  'SPMemoryDataType':
      'Lists each physical memory slot and its installed module: capacity, '
      'speed (MT/s), type (DDR4, DDR5, LPDDR5…), part number, serial number, '
      'and manufacturer. On Apple Silicon Macs memory is unified and not '
      'upgradeable, so the section shows total capacity and bandwidth rather '
      'than individual slot data.',

  'SPNVMeDataType':
      'Reports all NVMe solid-state drives — the storage standard used by '
      'every Apple Silicon Mac and most Intel Macs from 2013 onward. Each '
      'entry includes model, capacity, firmware revision, serial number, '
      'S.M.A.R.T. status, and the BSD device name. On Apple Silicon this covers '
      'the internal SSD soldered to the logic board.',

  'SPPCIDataType':
      'Lists PCI Express controllers and expansion cards: slot position, device '
      'and vendor IDs, link width (×1 to ×16), and link speed. On Mac Pro '
      'towers this surfaces user-installed cards such as GPUs, capture cards, '
      'and RAID controllers. On Mac mini, MacBook, and iMac it shows only '
      'internal PCIe controllers (NVMe, Thunderbolt fabric, Wi-Fi) with no '
      'user-accessible slots.',

  'SPParallelSCSIDataType':
      'Parallel SCSI was a legacy high-performance bus used in the 1990s for '
      'hard drives, scanners, tape drives, and removable media (Jaz, Zip). '
      'Apple removed built-in SCSI from its desktop Macs in the late 1990s. '
      'This section can only be populated on Power Mac G4 or G5 systems with '
      'a PCI SCSI host adapter card installed. It is effectively extinct on '
      'all modern Macs.',

  'SPPowerDataType':
      'Covers everything related to power: battery capacity, cycle count, '
      'condition, and chemistry on laptops; AC adapter wattage and serial '
      'number; UPS status if a compatible uninterruptible power supply is '
      'attached. On a desktop Mac with no battery the battery subsection is '
      'absent, but AC adapter and UPS data still appear.',

  'SPPrintersDataType':
      'Enumerates every print queue configured in System Settings › Printers '
      '& Scanners — including the driver name, CUPS URI, default paper size, '
      'and whether the printer is currently online. Does not cover scanner '
      'functions or fax queues.',

  'SPSASDataType':
      'Serial Attached SCSI (SAS) is an enterprise storage interface common '
      'in servers, backward-compatible with SATA drives. This section appears '
      'on Macs with a SAS host bus adapter — primarily the Xserve (2006–2011), '
      'whose drive bays were SAS/SATA, and Mac Pro systems fitted with an Apple '
      'RAID Card or third-party SAS HBA. Each drive entry shows model, '
      'capacity, firmware revision, serial number, and whether it is a native '
      'SAS or SATA device. Empty on all consumer Mac models.',

  'SPSerialATADataType':
      'Lists SATA (Serial ATA) drives and their host controllers: HDD and SSD '
      'models, capacity, firmware revision, serial number, BSD name, socket '
      'type (internal/external), S.M.A.R.T. status, and medium type. This is '
      'the primary storage section on Intel Macs with spinning-disk or '
      'SATA-SSD storage. On Apple Silicon Macs all internal storage is NVMe '
      '(reported under NVMExpress), so this section is empty.',

  'SPSPIDataType':
      'Serial Peripheral Interface (SPI) is the low-level internal bus Apple '
      'uses to connect the keyboard, Force Touch trackpad, and Touch Bar '
      'controller on MacBook models from 2015 onwards and MacBook Pro from '
      '2016 onwards. Each attached device reports its vendor and product ID '
      'and firmware version. On desktop Macs (Mac mini, iMac, Mac Pro) there '
      'are no built-in SPI input devices, so this section is always empty.',

  'SPStorageDataType':
      'Shows every mounted volume on the system — internal and external, '
      'physical and virtual — with capacity, available space, file system '
      'type, BSD name, mount point, and volume UUID. This is the section most '
      'commonly used to audit disk usage at a glance.',

  'SPThunderboltDataType':
      'Maps the Thunderbolt bus topology: host controller, connected hubs and '
      'devices (docks, displays, storage, eGPUs), port speed, link status, '
      'and device serial numbers. Thunderbolt 3 and 4 appear here; USB4 '
      'devices on Apple Silicon are covered under USB4 (same view).',

  'SPUSB4DataType':
      'Maps the USB4 bus on Apple Silicon Macs — functionally equivalent to '
      'Thunderbolt 4 and displayed in the same tree view. Shows host '
      'controllers, hubs, and connected USB4, Thunderbolt, and USB 3.x '
      'devices with speed, power draw, and device identifiers.',

  'SPUSBDataType':
      'A flat list of USB devices (non-host-controller view). Supplements '
      'the USB tree with additional fields for individual devices.',

  'SPUSBHostDataType':
      'The full USB bus tree, starting from host controllers down through '
      'hubs to individual leaf devices. Each node shows speed, current draw, '
      'vendor and product ID, serial number, and any sub-devices. This is '
      'the most detailed USB view — equivalent to the USB section in macOS '
      'System Information.',

  'SPFireWireDataType':
      'FireWire (IEEE 1394) was a high-speed serial bus used for DV cameras, '
      'external hard drives, audio interfaces, and Target Disk Mode on Macs '
      'from the late 1990s until roughly 2013. Apple removed FireWire 400/800 '
      'ports from MacBook Pro with the 2013 Retina redesign, from MacBook Air '
      'in 2012, and from Mac mini in 2012. No modern Mac includes FireWire '
      'hardware, so this section will always be empty on current machines.',

  // ── Network ────────────────────────────────────────────────────────────────

  'SPNetworkDataType':
      'A comprehensive table of every network interface — physical and '
      'virtual — with IPv4/IPv6 addresses, subnet masks, DNS servers, default '
      'gateway, hardware address, MTU, and current status. Covers Ethernet, '
      'Wi-Fi, VPN tunnel adapters, Thunderbolt Bridge, and loopback.',

  'SPFirewallDataType':
      'Reports the state of the macOS application-level firewall: whether it '
      'is enabled, stealth mode setting, and the allow/block rule for each '
      'application. Note this covers only the user-space firewall managed in '
      'System Settings › Network › Firewall, not the lower-level packet '
      'filter (pf).',

  'SPNetworkLocationDataType':
      'Lists every Network Location configured in System Settings (formerly '
      '"Locations" in Network preferences), along with all the network '
      'services and their settings within each location. Useful for auditing '
      'multi-location network configurations on Macs used in different '
      'environments.',

  'SPNetworkVolumeDataType':
      'Shows network shares currently mounted on the desktop — AFP, SMB, '
      'NFS, and WebDAV volumes — with mount point, remote URL, file system '
      'type, and the username used to connect. Only volumes that are actively '
      'mounted at the time of the report appear here.',

  'SPAirPortDataType':
      'Detailed Wi-Fi diagnostics: interface name, hardware address, '
      'firmware version, supported PHY modes and channels, current network '
      'SSID, BSSID, channel, security type, transmit rate, RSSI, noise '
      'floor, and a list of recently seen networks. The name "AirPort" is '
      'Apple\'s legacy branding for Wi-Fi.',

  'SPWWANDataType':
      'WWAN (Wireless Wide Area Network) refers to built-in cellular modems '
      'for mobile data connectivity. Apple has never shipped a consumer Mac '
      'with a built-in cellular modem, so this section is empty on all '
      'standard Mac models. It is included in system_profiler\'s output for '
      'completeness and potential future hardware.',

  'SPModemDataType':
      'Legacy dial-up modem information. Apple removed built-in modems from '
      'MacBook Pro in 2008 and from all other Macs around the same time. This '
      'section is empty on all modern Macs.',

  // ── Software ───────────────────────────────────────────────────────────────

  'SPSoftwareDataType':
      'The macOS software overview: operating system version and build number, '
      'kernel version (Darwin), system uptime, boot volume name and mode, '
      'computer name, current user, and the status of Secure Virtual Memory '
      'and System Integrity Protection (SIP).',

  'SPUniversalAccessDataType':
      'Reports the current state of macOS Accessibility features: VoiceOver, '
      'Zoom mode, display adjustments (colour inversion, contrast, reduce '
      'motion), sticky keys, slow keys, mouse keys, and switch control. '
      'Reflects the settings in System Settings › Accessibility.',

  'SPApplicationsDataType':
      'A catalogue of every application bundle found in /Applications, '
      '~/Applications, and other standard locations — with version, bundle '
      'identifier, obtained-from source (App Store, identified developer, '
      'unknown), architecture (Universal, Apple Silicon, Intel-only), last '
      'modified date, and 64-bit status.',

  'SPDeveloperToolsDataType':
      'Reports the active Xcode installation selected by xcode-select: '
      'version, installation path, bundled application tools (Instruments, '
      'Simulator, etc.), and installed SDKs (macOS, iOS, watchOS, tvOS, '
      'visionOS). Empty if Xcode is not installed.',

  'SPDisabledSoftwareDataType':
      'Lists software that macOS has disabled due to incompatibility — most '
      'prominently 32-bit applications that were blocked when macOS Catalina '
      '(10.15) dropped 32-bit support in 2019. Also covers kernel extensions '
      'or plugins quarantined by Gatekeeper or System Integrity Protection. '
      'On a clean modern install this section is typically empty.',

  'SPExtensionsDataType':
      'Enumerates loaded kernel extensions (kexts) and system extensions — '
      'including Apple\'s own and any third-party extensions from security '
      'software, VPN clients, or hardware drivers. Shows bundle identifier, '
      'version, architecture, and runtime environment.',

  'SPFontsDataType':
      'A catalogue of all installed fonts across system, user, and network '
      'font directories, grouped by font family. Each entry shows the typefaces '
      'within the family along with kind (TrueType, OpenType, PostScript), '
      'validity, and enabled status.',

  'SPFrameworksDataType':
      'Lists installed frameworks in /Library/Frameworks and '
      '~/Library/Frameworks — primarily third-party frameworks from developer '
      'tools and media applications. Apple\'s own system frameworks in '
      '/System/Library/Frameworks are not included here.',

  'SPInstallHistoryDataType':
      'A chronological log of every software package installed through '
      'Software Update, the App Store, or an Apple installer package (.pkg). '
      'Each entry shows the package name, version, install date, and source. '
      'Useful for auditing what has been installed and when.',

  'SPInternationalDataType':
      'Reports the active localisation settings: preferred languages in order, '
      'region format, calendar system, number and currency formats, time zone, '
      'and text direction. Reflects the settings in System Settings › General '
      '› Language & Region.',

  'SPLogsDataType':
      'Provides access to key system log files — primarily system.log and the '
      'Sync Services diagnostic log. Log content can be lengthy; the Logs '
      'section in this viewer presents each file in a dedicated panel with '
      'syntax-aware display.',

  'SPManagedClientDataType':
      'Shows managed preference values pushed to this Mac by an MDM (Mobile '
      'Device Management) server or a directory-bound policy — for example, '
      'forced Finder settings, prohibited applications, or enforced security '
      'policies. Each entry names the preference domain and lists the key, '
      'enforced value, and whether it is always or once applied. Empty on '
      'unmanaged consumer Macs not enrolled in any MDM.',

  'SPPrefPaneDataType':
      'Lists all System Settings (formerly System Preferences) panes installed '
      'on this Mac — both Apple\'s built-in panes and third-party panes added '
      'by software such as antivirus tools, VPN clients, or developer utilities. '
      'Each entry shows the bundle identifier and file path. Note: querying '
      'this section can occasionally be slow if a pane\'s helper process is '
      'unresponsive.',

  'SPPrinterSoftwareDataType':
      'Lists the printer driver packages and PPD (PostScript Printer '
      'Description) files installed on this Mac, grouped by category. '
      'Printer software is installed automatically by macOS when a compatible '
      'printer is added, or can be downloaded manually from Apple\'s printer '
      'driver updates.',

  'SPPrintersSoftwareDataType':
      'Lists the printer driver packages and PPD (PostScript Printer '
      'Description) files installed on this Mac, grouped by category. '
      'Printer software is installed automatically by macOS when a compatible '
      'printer is added, or can be downloaded manually from Apple\'s printer '
      'driver updates.',

  'SPConfigurationProfileDataType':
      'Lists every configuration profile installed on this Mac — pushed by an '
      'MDM server, downloaded from a web portal, or manually installed. Each '
      'profile can carry payloads for Wi-Fi credentials, VPN settings, '
      'certificates, passcode policies, restrictions, and more. The full '
      'payload content is shown in the detail panel. Empty on unmanaged '
      'Macs with no profiles installed.',

  'SPRawCameraDataType':
      'Reports which digital camera models are supported for Raw image decoding '
      'by this version of macOS, along with the version of the Raw support '
      'bundle. This data is updated by macOS software updates when Apple adds '
      'support for new camera models. It does not reflect cameras physically '
      'connected to the Mac.',

  'SPLegacySoftwareDataType':
      'On Apple Silicon Macs, Rosetta 2 transparently translates Intel (x86-64) '
      'applications to run on the ARM-based M-series chip. This section lists '
      'each developer whose apps have been launched under Rosetta, with the '
      'specific application, how many times it was launched, the last-used '
      'date, and the reason Rosetta translation was needed (typically: no '
      'native ARM version available).',

  'SPSmartCardsDataType':
      'Reports the Smart Card subsystem: reader drivers, SmartCard drivers '
      '(CryptoTokenKit extensions), and the available token identifiers in '
      'both the keychain and token stores. Smart cards are used for PIV-based '
      'authentication in enterprise and government environments.',

  'SPStartupItemDataType':
      'Legacy startup items are bundles placed in /Library/StartupItems or '
      '/System/Library/StartupItems that were executed at boot before launchd '
      'was introduced in macOS 10.4 Tiger (2005). Apple deprecated this '
      'mechanism over two decades ago and modern software uses LaunchDaemons '
      'or LaunchAgents instead. This section is empty on virtually all '
      'current Macs.',

  'SPSyncServicesDataType':
      'Sync Services was a macOS framework (introduced in 10.4, removed after '
      '10.14 Mojave) that synchronised data between apps and devices — '
      'calendars, contacts, bookmarks, and more — before iCloud replaced it. '
      'This section surfaces the Sync Services diagnostic log and a summary '
      'of the last sync operation. On macOS Sequoia the data shown here is a '
      'historical artefact from an older macOS version.',
};

/// Returns the description for [dataType], or a generic fallback.
String descriptionFor(String dataType) =>
    kSectionDescriptions[dataType] ??
    'No description is available for this section ($dataType).';
