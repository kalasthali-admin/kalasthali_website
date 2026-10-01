import 'package:flutter/widgets.dart';

bool useCompactLayout(
  BuildContext context, {
  required double breakpoint,
  double minScaledLogicalWidth = 650,
}) {
  final mediaQuery = MediaQuery.of(context);
  final size = mediaQuery.size;
  final physicalWidth = size.width * mediaQuery.devicePixelRatio;
  final highDpiWideViewport =
      size.width >= minScaledLogicalWidth &&
      physicalWidth >= 1100 &&
      size.height >= 500;
  return !highDpiWideViewport && size.width < breakpoint;
}
