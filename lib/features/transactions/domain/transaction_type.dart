/// The four kinds of money movement Apna Ledger tracks.
///
/// Colours (applied via the theme's semantic colours, not here):
///   income    → dark green
///   expense   → red
///   loanGiven → amber  (#F0A81C)  — money you lent out
///   loanTaken → purple           — money you borrowed
enum TransactionType { income, expense, loanGiven, loanTaken }

extension TransactionTypeX on TransactionType {
  String get key => name;

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
  bool get isLoanGiven => this == TransactionType.loanGiven;
  bool get isLoanTaken => this == TransactionType.loanTaken;
  bool get isLoan => isLoanGiven || isLoanTaken;

  /// Effect on cash-in-hand (the "net balance"):
  ///   income & loanTaken  →  +1 (cash comes in)
  ///   expense & loanGiven →  -1 (cash goes out)
  int get sign {
    switch (this) {
      case TransactionType.income:
      case TransactionType.loanTaken:
        return 1;
      case TransactionType.expense:
      case TransactionType.loanGiven:
        return -1;
    }
  }

  static TransactionType fromKey(String key) => TransactionType.values
      .firstWhere((e) => e.name == key, orElse: () => TransactionType.expense);
}
