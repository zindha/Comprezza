import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app_dependencies.dart';

/// Provides immutable app dependencies to the widget tree.
class AppProviderScope extends StatelessWidget {
  /// Creates the app dependency scope.
  const AppProviderScope({
    required this.dependencies,
    required this.child,
    super.key,
  });

  /// Fully composed application dependencies.
  final AppDependencies dependencies;

  /// Root widget below the dependency scope.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AppDependencies>.value(value: dependencies),
      ],
      child: child,
    );
  }
}
