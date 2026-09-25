import '../../../core/design/fin_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/transaction.dart';

/// Presentation mappings for transaction types and recurrence, shared by
/// every screen that shows them.
extension TxnTypeUi on TransactionType {
  FinGlyph get glyph {
    switch (this) {
      case TransactionType.income:
        return FinGlyph.income;
      case TransactionType.expense:
        return FinGlyph.expense;
      case TransactionType.loanGiven:
        return FinGlyph.given;
      case TransactionType.loanTaken:
        return FinGlyph.taken;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case TransactionType.income:
        return l10n.income;
      case TransactionType.expense:
        return l10n.spending;
      case TransactionType.loanGiven:
        return l10n.loanGiven;
      case TransactionType.loanTaken:
        return l10n.loanTaken;
    }
  }

  String dateLabel(AppLocalizations l10n) {
    switch (this) {
      case TransactionType.income:
        return l10n.incomeDate;
      case TransactionType.expense:
        return l10n.spendingDate;
      case TransactionType.loanGiven:
        return l10n.moneyGivenDate;
      case TransactionType.loanTaken:
        return l10n.moneyTakenDate;
    }
  }
}

extension RecurrenceUi on Recurrence {
  String label(AppLocalizations l10n) {
    switch (this) {
      case Recurrence.once:
        return l10n.oneTime;
      case Recurrence.daily:
        return l10n.daily;
      case Recurrence.weekly:
        return l10n.weekly;
      case Recurrence.monthly:
        return l10n.monthly;
      case Recurrence.yearly:
        return l10n.yearly;
    }
  }
}
