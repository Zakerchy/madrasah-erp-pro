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

  DashboardSummary({required this.totalIn, required this.totalOut, required this.balance, required this.byFund});

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    final raw = (map['byFund'] ?? {}) as Map<String, dynamic>;
    final parsed = <String, FundSummary>{};
    raw.forEach((k, v) => parsed[k] = FundSummary.fromMap(v as Map<String, dynamic>));

    return DashboardSummary(
      totalIn: (map['totalIn'] ?? 0).toDouble(),
      totalOut: (map['totalOut'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      byFund: parsed,
    );
  }
}
