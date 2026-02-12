String dateIsoFrom(DateTime date) {
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? tryParseDateTime(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  try {
    return DateTime.parse(trimmed);
  } catch (_) {
    return null;
  }
}

DateTime parseDateTimeOrEpoch(String? value) {
  return tryParseDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
