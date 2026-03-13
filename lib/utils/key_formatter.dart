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

/// Like [formatKey] but strips Core Audio field prefixes so that
/// e.g. `coreaudio_device_manufacturer` → "Manufacturer".
String formatAudioKey(String key) {
  const _kOverrides = {
    'coreaudio_device_srate': 'Sample Rate',
    'coreaudio_device_input': 'Input Channels',
    'coreaudio_device_output': 'Output Channels',
  };
  if (_kOverrides.containsKey(key)) return _kOverrides[key]!;
  for (final prefix in ['coreaudio_device_', 'coreaudio_', 'spaudio_']) {
    if (key.startsWith(prefix)) return formatKey(key.substring(prefix.length));
  }
  return formatKey(key);
}

/// Translates macOS system-profiler value codes to human-readable strings.
///
/// Examples:
///   `value_yes`          → "Yes"
///   `voice_gender_female`→ "Female"
///   `text_direction_ltr` → "Left-To-Right"
///   `gregorian`          → "Gregorian"
String formatSpxValue(String v) {
  switch (v) {
    case 'value_yes':
    case 'value_true':
      return 'Yes';
    case 'value_no':
    case 'value_false':
      return 'No';
    case 'text_direction_ltr':
      return 'Left-To-Right';
    case 'text_direction_rtl':
      return 'Right-To-Left';
    case 'gregorian':
      return 'Gregorian';
    case 'buddhist':
      return 'Buddhist';
    case 'chinese':
      return 'Chinese';
    case 'hebrew':
      return 'Hebrew';
    case 'islamic':
      return 'Islamic';
    case 'japanese':
      return 'Japanese';
    case 'persian':
      return 'Persian';
    case 'spaudio_default':
      return 'Default';
    default:
      // coreaudio_device_type_xxx → "HDMI", "USB", "Virtual", etc.
      if (v.startsWith('coreaudio_device_type_')) {
        final type = v.substring('coreaudio_device_type_'.length);
        switch (type) {
          case 'hdmi':
            return 'HDMI';
          case 'builtin':
            return 'Built-in';
          case 'usb':
            return 'USB';
          case 'bluetooth':
            return 'Bluetooth';
          case 'thunderbolt':
            return 'Thunderbolt';
          case 'virtual':
            return 'Virtual';
          case 'pci':
            return 'PCI';
          default:
            return formatKey(type);
        }
      }
      // spaudio_xxx values → strip prefix, title-case
      if (v.startsWith('spaudio_')) {
        return formatKey(v.substring('spaudio_'.length));
      }
      // voice_gender_xxx → strip prefix, title-case remainder
      if (v.startsWith('voice_gender_')) {
        return formatKey(v.substring('voice_gender_'.length));
      }
      return v;
  }
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
