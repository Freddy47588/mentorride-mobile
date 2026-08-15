import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mentorride/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/shared/widgets/loading_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForFeedback();
    final actionState = ref.watch(authControllerProvider);

    return AuthScaffold(
      showBackButton: true,
      title: 'Lupa kata sandi',
      subtitle:
          'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat kata sandi baru.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              enabled: !actionState.isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: AppValidators.email,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Kirim tautan',
              isLoading: actionState.isSubmitting,
              onPressed: _submit,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _listenForFeedback() {
    ref.listen<AuthActionState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.successMessage;
      final previousMessage =
          previous?.errorMessage ?? previous?.successMessage;
      if (message == null || message == previousMessage) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);
  }
}
