import 'package:flutter/material.dart';

import '../theme/inkquery_theme.dart';

class InkPanel extends StatelessWidget {
  const InkPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: InkqueryTheme.panelDecoration(context),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
