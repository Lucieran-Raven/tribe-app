class CustomInterestUtils {
  /// Converts "scuba diving" / "SCUBA DIVING" / "sCuBa" -> "Scuba Diving"
  static String toTitleCase(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// "Scuba Diving!" -> "custom_scuba_diving"
  static String toCustomId(String name) {
    final sanitized = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final truncated = sanitized.length > 40 ? sanitized.substring(0, 40) : sanitized;
    return 'custom_$truncated';
  }

  static String? validateName(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'Enter an interest';
    if (t.length < 2) return 'At least 2 characters';
    if (t.length > 40) return 'Max 40 characters';
    if (t.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '').isEmpty) {
      return 'Use letters and numbers';
    }
    return null;
  }
}
