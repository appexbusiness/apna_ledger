import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/category.dart';

/// The out-of-the-box categories every new user starts with. Categories only —
/// NO example sub-categories. Users add their own sub-categories as they go.
class DefaultCategories {
  DefaultCategories._();
  static const _uuid = Uuid();

  /// The category new transactions default to.
  static const othersName = 'Others';

  static List<Category> build() {
    Category cat(String name, IconData icon, int color) => Category(
          id: _uuid.v4(),
          name: name,
          iconCode: icon.codePoint,
          colorIndex: color,
          isDefault: true,
          subCategories: const [],
        );

    return [
      cat('Business', Icons.storefront_outlined, 0),
      cat('Family', Icons.family_restroom_outlined, 1),
      cat('Salary', Icons.payments_outlined, 5),
      cat('Loans & EMI', Icons.account_balance_outlined, 3),
      cat('Bills', Icons.receipt_long_outlined, 7),
      cat('Travel', Icons.flight_takeoff_outlined, 2),
      cat('Food', Icons.restaurant_outlined, 6),
      cat('Investment', Icons.trending_up_outlined, 4),
      cat('Shopping', Icons.shopping_bag_outlined, 8),
      cat(othersName, Icons.category_outlined, 9),
    ];
  }
}
