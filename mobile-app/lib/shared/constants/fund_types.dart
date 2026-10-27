/// Central fund-type registry.
/// Internal keys (used in API / Sheets) are the NEW keys.
/// [legacyKey] = what the sheet currently stores before migration.
/// Display names are in Bangla + English.
class FundType {
  final String key;
  final String? legacyKey;
  final String labelBn;
  final String labelEn;
  final String descBn;
  final bool donorVisible; // shown on donor portal
  final bool seasonal;    // seasonal fund (e.g. Ramadan)

  const FundType({
    required this.key,
    this.legacyKey,
    required this.labelBn,
    required this.labelEn,
    this.descBn = '',
    this.donorVisible = true,
    this.seasonal = false,
  });
}

class FundTypes {
  FundTypes._();

  static const sadaqah = FundType(
    key: 'SADAQAH',
    legacyKey: 'CONSTRUCTION',
    labelBn: 'সাদাকাহ/দান (যাকাত নয়)',
    labelEn: 'Sadaqah / General Donation',
    descBn: 'মাদ্রাসার নির্মাণ ও সাধারণ কল্যাণ কাজে ব্যয়',
  );

  static const zakat = FundType(
    key: 'ZAKAT',
    legacyKey: 'JAKAT',
    labelBn: 'যাকাত ফান্ড',
    labelEn: 'Zakat Fund',
    descBn: 'ফরজ যাকাতের অর্থ সঠিক খাতে বিতরণ',
  );

  static const talebeElm = FundType(
    key: 'TALEBE_ELM',
    legacyKey: 'SCHOLARSHIP',
    labelBn: 'তালেবে ইলমদের খেদমত ফান্ড',
    labelEn: "Talebe Elm Service Fund",
    descBn: 'অসহায় ছাত্রদের পড়াশোনার খরচ ও বৃত্তি',
  );

  static const yatim = FundType(
    key: 'YATIM',
    labelBn: 'ইয়াতিম সহায়তা ফান্ড',
    labelEn: 'Orphan Support Fund',
    descBn: 'ইয়াতিম শিশুদের ভরণপোষণ ও শিক্ষায় সহায়তা',
  );

  static const bia = FundType(
    key: 'BIA',
    labelBn: 'বিয়ে ফান্ড',
    labelEn: 'Marriage Support Fund',
    descBn: 'অসহায় পরিবারের বিয়ের আয়োজনে সহায়তা',
  );

  static const eid = FundType(
    key: 'EID',
    labelBn: 'ঈদ উপহার ফান্ড',
    labelEn: 'Eid Gift Fund',
    descBn: 'ঈদে অসহায় শিশু ও পরিবারকে উপহার প্রদান',
    seasonal: true,
  );

  static const iftar = FundType(
    key: 'IFTAR',
    labelBn: 'ইফতার ও সেহরি ফান্ড',
    labelEn: 'Iftar & Suhoor Fund',
    descBn: 'রমজানে রোজাদারদের ইফতার ও সেহরির ব্যবস্থা',
    seasonal: true,
  );

  static const fitra = FundType(
    key: 'FITRA',
    labelBn: 'ফিতরা ফান্ড',
    labelEn: 'Fitrah Fund',
    descBn: 'ঈদুল ফিতরে ফিতরা সংগ্রহ ও বিতরণ',
    seasonal: true,
  );

  static const library = FundType(
    key: 'LIBRARY',
    labelBn: 'পাঠাগার/কিতাবখানা',
    labelEn: 'Library Fund',
    descBn: 'মাদ্রাসার পাঠাগার ও ইসলামি কিতাব সংগ্রহ',
  );

  static const water = FundType(
    key: 'WATER',
    labelBn: 'পানি ও পয়ঃনিষ্কাশন',
    labelEn: 'Water & Sanitation',
    descBn: 'টিউবওয়েল, ওয়াশরুম ও পানি সরবরাহ ব্যবস্থা\n(সুদমুক্ত নিয়তে দেওয়া যাবে)',
  );

  /// সকল fund-এর ordered list (admin-visible)
  static const all = <FundType>[
    sadaqah,
    zakat,
    talebeElm,
    yatim,
    bia,
    eid,
    iftar,
    fitra,
    library,
    water,
  ];

  /// Donor portal-এ দেখানো fund list
  static List<FundType> get donorVisible =>
      all.where((f) => f.donorVisible).toList();

  /// key বা legacyKey থেকে FundType খোঁজে
  static FundType? byKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final upper = key.toUpperCase();
    for (final f in all) {
      if (f.key == upper || f.legacyKey == upper) return f;
    }
    return null;
  }

  /// Display label (key বা legacyKey উভয়ের জন্য কাজ করে)
  static String labelBn(String? key) => byKey(key)?.labelBn ?? key ?? '';
  static String labelEn(String? key) => byKey(key)?.labelEn ?? key ?? '';

  /// Normalise করা canonical key (legacyKey → নতুন key)
  static String canonical(String key) => byKey(key)?.key ?? key.toUpperCase();
}
