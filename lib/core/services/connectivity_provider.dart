import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isOnline(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

/// Streams whether the device currently has a network connection.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    yield _isOnline(await connectivity.checkConnectivity());
  } catch (_) {
    yield true; // assume online if the check fails
  }
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});
