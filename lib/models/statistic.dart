class Statistic {
  final DateTime startDate;
  final DateTime endDate;
  final StatisticRevenue revenue;
  final IncomeSources incomeSources;
  final List<StatisticTransaction> transactions;

  Statistic({
    required this.startDate,
    required this.endDate,
    required this.revenue,
    required this.incomeSources,
    required this.transactions,
  });

  factory Statistic.fromJson(Map<String, dynamic> json) {
    return Statistic(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      revenue: StatisticRevenue.fromJson(
        json['revenue'] as Map<String, dynamic>,
      ),
      incomeSources: IncomeSources.fromJson(
        json['incomeSources'] as Map<String, dynamic>,
      ),
      transactions:
          (json['transactions'] as List<dynamic>)
              .map(
                (e) => StatisticTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'revenue': revenue.toJson(),
      'incomeSources': incomeSources.toJson(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }
}

class StatisticRevenue {
  final double total;
  final double previous;
  final double difference;
  final double percentageChange;

  StatisticRevenue({
    required this.total,
    required this.previous,
    required this.difference,
    required this.percentageChange,
  });

  factory StatisticRevenue.fromJson(Map<String, dynamic> json) {
    return StatisticRevenue(
      total: (json['total'] as num).toDouble(),
      previous: (json['previous'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'previous': previous,
      'difference': difference,
      'percentageChange': percentageChange,
    };
  }
}

class IncomeSources {
  final double total;
  final List<IncomeSource> sources;

  IncomeSources({required this.total, required this.sources});

  factory IncomeSources.fromJson(Map<String, dynamic> json) {
    return IncomeSources(
      total: (json['total'] as num).toDouble(),
      sources:
          (json['sources'] as List<dynamic>)
              .map((e) => IncomeSource.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'sources': sources.map((e) => e.toJson()).toList()};
  }
}

class IncomeSource {
  final String name;
  final String type;
  final double amount;
  final double percentage;

  IncomeSource({
    required this.name,
    required this.type,
    required this.amount,
    required this.percentage,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      name: json['name'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'amount': amount,
      'percentage': percentage,
    };
  }
}

class StatisticTransaction {
  final int? id;
  final String? type;
  final String? subject;
  final double? amount;
  final DateTime? date;
  final String? time;
  final String? cashbook;
  final int? cashbookType;
  final String? note;

  StatisticTransaction({
    this.id,
    this.type,
    this.subject,
    this.amount,
    this.date,
    this.time,
    this.cashbook,
    this.cashbookType,
    this.note,
  });

  factory StatisticTransaction.fromJson(Map<String, dynamic> json) {
    return StatisticTransaction(
      id: json['id'] as int?,
      type: json['type'] as String?,
      subject: json['subject'] as String?,
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      time: json['time'] as String?,
      cashbook: json['cashbook'] as String?,
      cashbookType: json['cashbookType'] as int?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'subject': subject,
      'amount': amount,
      'date': date?.toIso8601String(),
      'time': time,
      'cashbook': cashbook,
      'cashbookType': cashbookType,
      'note': note,
    };
  }
}
