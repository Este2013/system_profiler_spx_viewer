/// Converts a raw plist key into a human-readable label.
/// e.g. "_name" → "Name", "cpu_type" → "CPU Type",
///      "coreaudio_device_srate" → "Coreaudio Device Srate"
String formatKey(String key) {
  // Remove leading underscore
  String k = key.startsWith('_') ? key.substring(1) : key;

  // Replace underscores with spaces
  k = k.replaceAll('_', ' ');

  // Split on spaces, title-case each word
  return k
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

/// Returns true if the key is a metadata/internal key we generally hide.
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
