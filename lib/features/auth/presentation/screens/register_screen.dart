import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/app/router/app_routes.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mentorride/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/shared/widgets/loading_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForFeedback();
    final actionState = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: 'Buat akun MentorRide',
      subtitle:
          'Mulai catat perawatan motor agar setiap servis lebih terencana.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !actionState.isSubmitting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: AppValidators.displayName,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap atau panggilan',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: !actionState.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                validator: AppValidators.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'nama@email.com',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                enabled: !actionState.isSubmitting,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AppValidators.password,
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  helperText: 'Minimal 6 karakter',
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    onPressed: actionState.isSubmitting
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmationController,
                enabled: !actionState.isSubmitting,
                obscureText: _obscureConfirmation,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    AppValidators.confirmation(value, _passwordController.text),
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Konfirmasi kata sandi',
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmation
                        ? 'Tampilkan konfirmasi kata sandi'
                        : 'Sembunyikan konfirmasi kata sandi',
                    onPressed: actionState.isSubmitting
                        ? null
                        : () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Daftar',
                isLoading: actionState.isSubmitting,
                onPressed: _submit,
                icon: Icons.person_add_alt_1_rounded,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(child: Text('Sudah memiliki akun?')),
                  TextButton(
                    onPressed: actionState.isSubmitting
                        ? null
                        : () => context.go(AppRoutes.login),
                    child: const Text('Masuk'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _listenForFeedback() {
    ref.listen<AuthActionState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .register(
          displayName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}
