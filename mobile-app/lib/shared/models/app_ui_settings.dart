class AppUiSettings {
  final DateTime defaultFromDate;
  final DateTime defaultToDate;
  final String defaultToSource;
  final int maxRangeDays;
  final String updatedAt;

  const AppUiSettings({
    required this.defaultFromDate,
    required this.defaultToDate,
    required this.defaultToSource,
    required this.maxRangeDays,
    required this.updatedAt,
  });

  factory AppUiSettings.defaults() {
    final now = DateTime.now();
    return AppUiSettings(
      defaultFromDate: DateTime(2022, 1, 26),
      defaultToDate: DateTime(now.year, now.month, now.day),
      defaultToSource: 'TODAY',
      maxRangeDays: 3653,
      updatedAt: '',
    );
  }

  factory AppUiSettings.fromApi(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      final raw = (value ?? '').toString().trim();
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return fallback;
      return DateTime.tryParse(raw) ?? fallback;
    }

    final defaults = AppUiSettings.defaults();
    final maxDays = int.tryParse((map['max_range_days'] ?? '').toString()) ??
        defaults.maxRangeDays;
    return AppUiSettings(
      defaultFromDate:
          parseDate(map['default_from_date'], defaults.defaultFromDate),
      defaultToDate: parseDate(map['default_to_date'], defaults.defaultToDate),
      defaultToSource:
          (map['default_to_source'] ?? 'TODAY').toString().toUpperCase(),
      maxRangeDays: maxDays < 1 ? defaults.maxRangeDays : maxDays,
      updatedAt: (map['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toPayload() {
    String fmt(DateTime dt) {
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    return {
      'default_from_date': fmt(defaultFromDate),
      'default_to_date': fmt(defaultToDate),
      'default_to_mode': defaultToSource,
    };
  }

  AppUiSettings copyWith({
    DateTime? defaultFromDate,
    DateTime? defaultToDate,
    String? defaultToSource,
    int? maxRangeDays,
    String? updatedAt,
  }) {
    return AppUiSettings(
      defaultFromDate: defaultFromDate ?? this.defaultFromDate,
      defaultToDate: defaultToDate ?? this.defaultToDate,
      defaultToSource: defaultToSource ?? this.defaultToSource,
      maxRangeDays: maxRangeDays ?? this.maxRangeDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
