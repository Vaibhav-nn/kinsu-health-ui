/// Conditional re-export for the `health` package.
///
/// On mobile (Android / iOS): exports the real `package:health/health.dart`.
/// On web (dart.library.html is defined): exports the no-op stub so Chrome
/// compilation succeeds without needing `dart:io` or platform channels.
library health_shim;

export 'package:health/health.dart'
    if (dart.library.html) 'health_shim_web.dart';
