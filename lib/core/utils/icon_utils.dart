import 'package:flutter/material.dart';

/// The curated, CONST set of icons categories can use. Because every icon here
/// is a compile-time constant, Flutter can tree-shake the icon font normally —
/// no `--no-tree-shake-icons` flag required. Categories persist a Material
/// codePoint (int); [iconFromCode] maps it back to one of these const icons.
const List<IconData> kCategoryIcons = <IconData>[
  Icons.storefront_outlined,
  Icons.family_restroom_outlined,
  Icons.payments_outlined,
  Icons.account_balance_outlined,
  Icons.receipt_long_outlined,
  Icons.flight_takeoff_outlined,
  Icons.restaurant_outlined,
  Icons.trending_up_outlined,
  Icons.shopping_bag_outlined,
  Icons.directions_car_outlined,
  Icons.school_outlined,
  Icons.medical_services_outlined,
  Icons.sports_esports_outlined,
  Icons.pets_outlined,
  Icons.home_outlined,
  Icons.card_giftcard_outlined,
  Icons.category_outlined,
  Icons.savings_outlined,
  Icons.work_outline,
  Icons.fitness_center_outlined,
];

/// Resolves a stored codePoint to a CONST icon from [kCategoryIcons], so no
/// dynamic `IconData` is ever constructed. Falls back to a generic icon.
IconData iconFromCode(int codePoint) {
  for (final icon in kCategoryIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.category_outlined;
}
