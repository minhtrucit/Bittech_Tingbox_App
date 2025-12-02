class Statistic {
  final DateTime startDate;
  final DateTime endDate;
  final StatisticRevenue revenue;
  final Debt debt;
  final IncomeSources incomeSources;
  final ExpenseSources expenseSources;
  final List<StatisticTransaction> transactions;
  final Pagination? pagination;

  Statistic({
    required this.startDate,
    required this.endDate,
    required this.debt,
    required this.revenue,
    required this.incomeSources,
    required this.expenseSources,
    required this.transactions,
    this.pagination,
  });

  factory Statistic.fromJson(Map<String, dynamic> json) {
    // Handle transactions - can be either List or Object with data property
    List<StatisticTransaction> transactionsList = [];
    Pagination? paginationData;

    if (json['transactions'] != null) {
      if (json['transactions'] is List) {
        // Old format: direct array
        transactionsList =
            (json['transactions'] as List<dynamic>)
                .map(
                  (e) =>
                      StatisticTransaction.fromJson(e as Map<String, dynamic>),
                )
                .toList();
      } else if (json['transactions'] is Map) {
        // New format: object with data property
        final transactionsData = json['transactions'] as Map<String, dynamic>;
        if (transactionsData['data'] != null) {
          transactionsList =
              (transactionsData['data'] as List<dynamic>)
                  .map(
                    (e) => StatisticTransaction.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList();
        }
        // Parse pagination if exists
        if (transactionsData['pagination'] != null) {
          paginationData = Pagination.fromJson(
            transactionsData['pagination'] as Map<String, dynamic>,
          );
        }
      }
    }

    return Statistic(
      expenseSources: ExpenseSources.fromJson(
        json['expenseSources'] as Map<String, dynamic>,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      debt: Debt.fromJson(json['debt'] as Map<String, dynamic>),
      revenue: StatisticRevenue.fromJson(
        json['revenue'] as Map<String, dynamic>,
      ),
      incomeSources: IncomeSources.fromJson(
        json['incomeSources'] as Map<String, dynamic>,
      ),
      transactions: transactionsList,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'debt': debt.toJson(),
      'revenue': revenue.toJson(),
      'incomeSources': incomeSources.toJson(),
      'expenseSources': expenseSources.toJson(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }
}

class StatisticRevenue {
  final double total;
  final double totalIn;
  final double totalOut;
  final double previous;
  final double difference;
  final double balance;
  final double percentageChange;

  StatisticRevenue({
    required this.totalIn,
    required this.totalOut,
    required this.total,
    required this.previous,
    required this.difference,
    required this.balance,
    required this.percentageChange,
  });

  factory StatisticRevenue.fromJson(Map<String, dynamic> json) {
    return StatisticRevenue(
      totalIn: (json['totalIn'] as num?)?.toDouble() ?? 0.0,
      totalOut: (json['totalOut'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      previous: (json['previous'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIn': totalIn,
      'totalOut': totalOut,
      'total': total,
      'previous': previous,
      'difference': difference,
      'balance': balance,
      'percentageChange': percentageChange,
    };
  }
}

class Debt {
  final double current;
  final double previousMonth;
  final double difference;
  final double percentageChange;

  Debt({
    required this.current,
    required this.previousMonth,
    required this.difference,
    required this.percentageChange,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      previousMonth: (json['previous'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'previousMonth': previousMonth,
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

class ExpenseSources {
  final double total;
  final List<IncomeSource> sources;

  ExpenseSources({required this.total, required this.sources});

  factory ExpenseSources.fromJson(Map<String, dynamic> json) {
    return ExpenseSources(
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

class ExpenseSource {
  final String name;
  final String type;
  final double amount;
  final double percentage;

  ExpenseSource({
    required this.name,
    required this.type,
    required this.amount,
    required this.percentage,
  });

  factory ExpenseSource.fromJson(Map<String, dynamic> json) {
    return ExpenseSource(
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

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }
}
