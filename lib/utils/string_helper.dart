class StringHelper {
  static String capitalizeWords(String? value) {
    if (value == null) return '';
    final normalized = value.trim();
    if (normalized.isEmpty) return '';

    return normalized
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          final first = word[0].toUpperCase();
          final rest = word.length > 1 ? word.substring(1).toLowerCase() : '';
          return '$first$rest';
        })
        .join(' ');
  }

  static String upper(String? value) {
    return (value ?? '').toUpperCase();
  }
}
