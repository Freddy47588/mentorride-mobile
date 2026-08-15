import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (error, stackTrace) => ErrorState(
        message: 'Data belum dapat dimuat. Silakan coba lagi.',
        onRetry: onRetry,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
