class FundSummary {
  final double incoming;
  final double outgoing;
  final double balance;

  FundSummary({required this.incoming, required this.outgoing, required this.balance});

  factory FundSummary.fromMap(Map<String, dynamic> map) {
    return FundSummary(
      incoming: (map['in'] ?? 0).toDouble(),
      outgoing: (map['out'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }
}

class DashboardSummary {
  final double totalIn;
  final double totalOut;
  final double balance;
  final Map<String, FundSummary> byFund;

  // Separation calculations (Excel dashboard rows)
  final double totalFound;         // = sum of all IN (same as totalIn)
  final double balanceExclZakat;   // totalIn − zakatIn
  final double balanceExclZakatScholarship; // balanceExclZakat − scholarshipIn

  DashboardSummary({
    required this.totalIn,
    required this.totalOut,
    required this.balance,
    required this.byFund,
    required this.totalFound,
    required this.balanceExclZakat,
    required this.balanceExclZakatScholarship,
  });

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    final raw = (map['byFund'] ?? {}) as Map<String, dynamic>;
    final parsed = <String, FundSummary>{};
    raw.forEach((k, v) {
      if (v is Map) parsed[k] = FundSummary.fromMap(Map<String, dynamic>.from(v));
    });

    final totalIn = (map['totalIn'] ?? 0).toDouble();
    final zakatIn = parsed['JAKAT']?.incoming ?? 0;
    final scholarshipIn = parsed['SCHOLARSHIP']?.incoming ?? 0;

    // If server provides pre-calculated values use them, else compute client-side
    final totalFound = (map['totalFound'] as num?)?.toDouble() ?? totalIn;
    final balanceExclZakat = (map['balanceExclZakat'] as num?)?.toDouble()
        ?? (totalFound - zakatIn);
    final balanceExclZakatScholarship = (map['balanceExclZakatScholarship'] as num?)?.toDouble()
        ?? (balanceExclZakat - scholarshipIn);

    return DashboardSummary(
      totalIn: totalIn,
      totalOut: (map['totalOut'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      byFund: parsed,
      totalFound: totalFound,
      balanceExclZakat: balanceExclZakat,
      balanceExclZakatScholarship: balanceExclZakatScholarship,
    );
  }

  FundSummary fund(String key) =>
      byFund[key] ?? FundSummary(incoming: 0, outgoing: 0, balance: 0);
}
