/// Domain-level failure. Repositories throw/return these instead of leaking
/// Firebase or platform exceptions into the UI layer.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppFailure($message)';
}
