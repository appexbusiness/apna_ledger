/// Build flavors. QA and UAT share the QA Firebase project (per requirement);
/// Production uses a separate Firebase project.
enum Flavor { qa, uat, prod }

extension FlavorX on Flavor {
  String get label => switch (this) {
        Flavor.qa => 'QA',
        Flavor.uat => 'UAT',
        Flavor.prod => 'PROD',
      };

  /// QA and UAT are backed by the same Firebase project (`apnaledgerqa`).
  /// Only PROD talks to the separate production project.
  bool get isProduction => this == Flavor.prod;

  /// Whether an in-app "flavor banner" should be shown (hidden in prod).
  bool get showBanner => this != Flavor.prod;
}
