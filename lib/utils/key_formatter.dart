/// Converts a raw plist key into a human-readable label.
///
/// Handles:
///   - Leading underscore removal   "_name"   → "Name"
///   - Underscore → space           "cpu_type" → "CPU Type"
///   - camelCase splitting          "serialNumber" → "Serial Number"
///   - ALLCAPS+camel                "USBDeviceKeyLinkSpeed" → "USB Device Key Link Speed"
String formatKey(String key) {
  // 1. Remove leading underscore.
  String k = key.startsWith('_') ? key.substring(1) : key;

  // 2. Replace underscores with spaces.
  k = k.replaceAll('_', ' ');

  // 3. camelCase split — insert space between lowercase→uppercase transitions.
  //    e.g. "serialNumber" → "serial Number"
  k = k.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );

  // 4. camelCase split — insert space before an uppercase letter that follows
  //    a run of uppercase letters and is itself followed by a lowercase letter.
  //    e.g. "USBDevice" → "USB Device",  "PCIVendorID" → "PCI Vendor ID"
  k = k.replaceAllMapped(
    RegExp(r'([A-Z]+)([A-Z][a-z])'),
    (m) => '${m[1]} ${m[2]}',
  );

  // 5. Title-case each word (preserves existing uppercase, e.g. "USB" stays "USB").
  return k
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

/// Like [formatKey] but additionally strips Apple's USB field prefixes so that
/// e.g. `USBDeviceKeyLinkSpeed` → "Link Speed" instead of "USB Device Key Link Speed".
String formatUsbKey(String key) {
  const prefixes = ['USBDeviceKey', 'USBControllerKey', 'USBKey'];
  for (final prefix in prefixes) {
    if (key.startsWith(prefix)) {
      return formatKey(key.substring(prefix.length));
    }
  }
  return formatKey(key);
}

/// Returns true if [key] is an internal/metadata key that should not be
/// shown directly in the UI.
bool isInternalKey(String key) {
  const internal = {
    '_SPCommandLineArguments',
    '_SPCompletionInterval',
    '_SPResponseTime',
    '_detailLevel',
    '_parentDataType',
    '_properties',
    '_timeStamp',
    '_versionInfo',
    '_dataType',
    '_items',
  };
  return internal.contains(key);
}
