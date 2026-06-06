import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'app_theme.dart';

extension ContextSnackBar on BuildContext {
  void showSuccess(String message, {Duration duration = const Duration(seconds: 3), String? actionLabel, VoidCallback? onAction}) {
    final action = (actionLabel != null && onAction != null)
        ? SnackBarAction(label: actionLabel, onPressed: onAction, textColor: Colors.white)
        : null;
    ScaffoldMessenger.of(this).showSnackBar(AppTheme.successSnackBar(this, message, duration: duration, action: action));
  }

  void showError(String message, {Duration duration = const Duration(seconds: 4), String? actionLabel, VoidCallback? onAction}) {
    final action = (actionLabel != null && onAction != null)
        ? SnackBarAction(label: actionLabel, onPressed: onAction, textColor: Colors.white)
        : null;
    ScaffoldMessenger.of(this).showSnackBar(AppTheme.errorSnackBar(this, message, duration: duration, action: action));
  }
}

