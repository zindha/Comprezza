import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

class AppFade extends StatelessWidget {
  const AppFade({required this.child, this.visible = true, super.key});
  final Widget child;
  final bool visible;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: _reduceMotion(context) ? Duration.zero : AppAnimations.standard,
    child: child,
  );
}
