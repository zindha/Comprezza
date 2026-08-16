import 'package:flutter/widgets.dart';

import 'app.dart';
import 'app/app_bootstrap.dart';

/// Bootstraps infrastructure before the Flutter widget tree is rendered.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppBootstrap.initialize();
  runApp(PhotoCompressorApp(dependencies: dependencies));
}
