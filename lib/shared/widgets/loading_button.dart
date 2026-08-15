import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Text(label),
            ],
          );
    return FilledButton(onPressed: isLoading ? null : onPressed, child: child);
  }
}
