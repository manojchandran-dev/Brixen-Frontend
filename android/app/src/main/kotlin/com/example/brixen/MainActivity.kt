package com.example.brixen

import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity (not FlutterActivity): local_auth's fingerprint prompt
// needs it on Android — with FlutterActivity authenticate() just fails.
class MainActivity : FlutterFragmentActivity()
