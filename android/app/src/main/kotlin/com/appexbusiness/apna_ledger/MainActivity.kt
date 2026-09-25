package com.appexbusiness.apna_ledger

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (App Lock / biometrics) shows the system BiometricPrompt, which
// needs a FragmentActivity. With a plain FlutterActivity every authenticate()
// call fails with "no_fragment_activity".
class MainActivity : FlutterFragmentActivity()
