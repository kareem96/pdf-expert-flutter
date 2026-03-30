import 'package:flutter/material.dart';

class AdaptiveLayoutWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final double breakpoint;

  const AdaptiveLayoutWrapper({
    super.key,
    required this.mobile,
    required this.tablet,
    this.breakpoint = 600,
  });

  static bool isTablet(BuildContext context, {double breakpoint = 600}) {
    return MediaQuery.of(context).size.width >= breakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return tablet;
        }
        return mobile;
      },
    );
  }
}
