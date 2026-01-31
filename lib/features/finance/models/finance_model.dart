class FinanceSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double pendingPayments;
  final double upcomingExpenses;
  final List<double> monthlyIncome;
  final List<double> monthlyExpenses;
  final Map<String, double> incomeBySource;
  final Map<String, double> expensesByCategory;

  FinanceSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.pendingPayments,
    required this.upcomingExpenses,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.incomeBySource,
    required this.expensesByCategory,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      pendingPayments: (json['pendingPayments'] ?? 0).toDouble(),
      upcomingExpenses: (json['upcomingExpenses'] ?? 0).toDouble(),
      monthlyIncome: List<double>.from(
        (json['monthlyIncome'] ?? []).map((e) => (e as num).toDouble()),
      ),
      monthlyExpenses: List<double>.from(
        (json['monthlyExpenses'] ?? []).map((e) => (e as num).toDouble()),
      ),
      incomeBySource: Map<String, double>.from(
        (json['incomeBySource'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      expensesByCategory: Map<String, double>.from(
        (json['expensesByCategory'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'pendingPayments': pendingPayments,
      'upcomingExpenses': upcomingExpenses,
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'incomeBySource': incomeBySource,
      'expensesByCategory': expensesByCategory,
    };
  }

  double get profitMargin => totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;
}

class Transaction {
  final String id;
  final String farmId;
  final TransactionType type;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final String? relatedCrop;
  final String? vendor;
  final String? invoiceNumber;
  final List<String>? attachments;
  final PaymentMode paymentMode;
  final String? notes;

  Transaction({
    required this.id,
    required this.farmId,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.relatedCrop,
    this.vendor,
    this.invoiceNumber,
    this.attachments,
    required this.paymentMode,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      relatedCrop: json['relatedCrop'],
      vendor: json['vendor'],
      invoiceNumber: json['invoiceNumber'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == json['paymentMode'],
        orElse: () => PaymentMode.cash,
      ),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'type': type.name,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'relatedCrop': relatedCrop,
      'vendor': vendor,
      'invoiceNumber': invoiceNumber,
      'attachments': attachments,
      'paymentMode': paymentMode.name,
      'notes': notes,
    };
  }
}

enum TransactionType {
  income,
  expense,
}

enum PaymentMode {
  cash,
  upi,
  bankTransfer,
  cheque,
  creditCard,
  debitCard,
}

class ExpenseCategory {
  static const String seeds = 'Seeds';
  static const String fertilizer = 'Fertilizer';
  static const String pesticides = 'Pesticides';
  static const String labor = 'Labor';
  static const String irrigation = 'Irrigation';
  static const String equipment = 'Equipment';
  static const String transport = 'Transport';
  static const String storage = 'Storage';
  static const String electricity = 'Electricity';
  static const String fuel = 'Fuel';
  static const String packaging = 'Packaging';
  static const String marketing = 'Marketing';
  static const String insurance = 'Insurance';
  static const String loan = 'Loan Repayment';
  static const String other = 'Other';

  static List<String> get all => [
    seeds, fertilizer, pesticides, labor, irrigation,
    equipment, transport, storage, electricity, fuel,
    packaging, marketing, insurance, loan, other,
  ];
}

class IncomeSource {
  static const String cropSales = 'Crop Sales';
  static const String dairyProducts = 'Dairy Products';
  static const String rental = 'Land/Equipment Rental';
  static const String subsidy = 'Government Subsidy';
  static const String insurance = 'Insurance Claim';
  static const String other = 'Other';

  static List<String> get all => [
    cropSales, dairyProducts, rental, subsidy, insurance, other,
  ];
}

class LoanInfo {
  final String id;
  final String bankName;
  final String loanType;
  final double principalAmount;
  final double interestRate;
  final int tenureMonths;
  final double emiAmount;
  final double totalPaid;
  final double remainingAmount;
  final DateTime startDate;
  final DateTime nextEmiDate;
  final String status;
  final String? loanAccountNumber;

  LoanInfo({
    required this.id,
    required this.bankName,
    required this.loanType,
    required this.principalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.emiAmount,
    required this.totalPaid,
    required this.remainingAmount,
    required this.startDate,
    required this.nextEmiDate,
    required this.status,
    this.loanAccountNumber,
  });

  double get completionPercent => (totalPaid / (principalAmount + (principalAmount * interestRate / 100))) * 100;
}

class InsuranceInfo {
  final String id;
  final String policyNumber;
  final String insuranceType;
  final String providerName;
  final double sumInsured;
  final double premiumAmount;
  final String premiumFrequency;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final List<String> coveredCrops;
  final List<String> coveredRisks;

  InsuranceInfo({
    required this.id,
    required this.policyNumber,
    required this.insuranceType,
    required this.providerName,
    required this.sumInsured,
    required this.premiumAmount,
    required this.premiumFrequency,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.coveredCrops,
    required this.coveredRisks,
  });

  bool get isActive => DateTime.now().isBefore(endDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}

class GovernmentScheme {
  final String id;
  final String name;
  final String description;
  final String ministry;
  final List<String> eligibilityCriteria;
  final List<String> benefits;
  final String applicationProcess;
  final String applicationUrl;
  final DateTime? deadline;
  final bool isApplied;
  final String? applicationStatus;

  GovernmentScheme({
    required this.id,
    required this.name,
    required this.description,
    required this.ministry,
    required this.eligibilityCriteria,
    required this.benefits,
    required this.applicationProcess,
    required this.applicationUrl,
    this.deadline,
    this.isApplied = false,
    this.applicationStatus,
  });
}
