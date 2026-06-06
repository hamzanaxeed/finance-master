import 'package:flutter/material.dart';

// Central spacing and sizing constants for consistent layout
class AppSpacing {
  // standard horizontal page padding
  static const double page = 16.0;

  // internal card padding
  static const double card = 12.0;

  // vertical gap between elements
  static const double gap = 12.0;

  // approximate FAB+margin height used to keep content above a floating button
  static const double fabHeight = 56.0;
  static const double fabMargin = 16.0;

  // total footer spacer height to avoid FAB overlap
  static double footerHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + fabHeight + fabMargin;
  }
}

