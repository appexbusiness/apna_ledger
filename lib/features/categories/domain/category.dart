import 'package:equatable/equatable.dart';

/// A sub-category, e.g. "Xerox Business" under "Business",
/// or "Vivek Parmar" under "Family".
class SubCategory extends Equatable {
  const SubCategory({required this.id, required this.name});
  final String id;
  final String name;

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory SubCategory.fromMap(Map<String, dynamic> m) =>
      SubCategory(id: m['id'] as String, name: m['name'] as String);

  @override
  List<Object?> get props => [id, name];
}

/// A top-level category. `isDefault` marks the seeded ones (can't be deleted,
/// only hidden); user-created categories are fully editable.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorIndex,
    this.subCategories = const [],
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int iconCode; // stored codePoint; resolved to IconData in the UI
  final int colorIndex; // index into AppColors.chart
  final List<SubCategory> subCategories;
  final bool isDefault;

  Category copyWith({
    String? name,
    int? iconCode,
    int? colorIndex,
    List<SubCategory>? subCategories,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
        colorIndex: colorIndex ?? this.colorIndex,
        subCategories: subCategories ?? this.subCategories,
        isDefault: isDefault,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'colorIndex': colorIndex,
        'isDefault': isDefault,
        'subCategories': subCategories.map((e) => e.toMap()).toList(),
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        iconCode: m['iconCode'] as int,
        colorIndex: m['colorIndex'] as int,
        isDefault: (m['isDefault'] as bool?) ?? false,
        subCategories: ((m['subCategories'] as List?) ?? [])
            .map((e) => SubCategory.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  List<Object?> get props =>
      [id, name, iconCode, colorIndex, subCategories, isDefault];
}
