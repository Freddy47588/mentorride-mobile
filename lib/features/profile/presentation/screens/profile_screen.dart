import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/errors/firebase_error_mapper.dart';
import 'package:mentorride/core/notifications/notification_providers.dart';
import 'package:mentorride/core/notifications/reminder_scheduler.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';
import 'package:mentorride/shared/widgets/app_logo.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  NotificationPermissionStatus? _permissionStatus;
  String? _permissionError;
  bool _isCheckingPermission = false;
  bool _isRequestingPermission = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(currentUserProfileProvider);
    final sessionValue = ref.watch(authSessionProvider);
    final authAction = ref.watch(authControllerProvider);
    final session = sessionValue.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profileValue.when(
        loading: () {
          if (session == null && sessionValue.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(
            profile: null,
            session: session,
            isProfileLoading: true,
            isAuthBusy: authAction.isSubmitting,
          );
        },
        error: (error, stackTrace) => _buildContent(
          profile: null,
          session: session,
          profileError: 'Informasi profil belum dapat dimuat.',
          isAuthBusy: authAction.isSubmitting,
        ),
        data: (profile) => _buildContent(
          profile: profile,
          session: session,
          isAuthBusy: authAction.isSubmitting,
        ),
      ),
    );
  }

  Widget _buildContent({
    required UserProfile? profile,
    required AuthSession? session,
    required bool isAuthBusy,
    bool isProfileLoading = false,
    String? profileError,
  }) {
    final displayName = _firstNonEmpty([
      profile?.displayName,
      session?.displayName,
      'Pengguna MentorRide',
    ]);
    final email = _firstNonEmpty([profile?.email, session?.email, '-']);

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _ProfileHeader(displayName: displayName, email: email),
          if (isProfileLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (profileError != null) ...[
            const SizedBox(height: 12),
            _InlineErrorCard(
              message: profileError,
              onRetry: () => ref.invalidate(currentUserProfileProvider),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Akun',
            children: [
              _InformationTile(
                icon: Icons.badge_outlined,
                label: 'Nama',
                value: displayName,
              ),
              const Divider(height: 1),
              _InformationTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: session == null || isAuthBusy
                      ? null
                      : () => _showEditNameDialog(
                          currentName: displayName,
                          session: session,
                        ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit nama'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NotificationCard(
            status: _permissionStatus,
            errorMessage: _permissionError,
            isChecking: _isCheckingPermission,
            isRequesting: _isRequestingPermission,
            onRequestPermission: _requestPermission,
            onRefresh: _refreshPermission,
          ),
          const SizedBox(height: 16),
          const _AboutCard(),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isLoggingOut || isAuthBusy ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(_isLoggingOut ? 'Sedang keluar...' : 'Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(currentUserProfileProvider);
    try {
      await Future.wait<void>([
        ref.read(currentUserProfileProvider.future).then((_) {}),
        _refreshPermission(),
      ]);
    } on Object {
      // Kartu profil atau notifikasi menampilkan error pada bagiannya sendiri.
    }
  }

  Future<void> _refreshPermission() async {
    if (_isCheckingPermission || _isRequestingPermission) return;

    if (mounted) {
      setState(() {
        _isCheckingPermission = true;
        _permissionError = null;
      });
    }

    try {
      final status = await ref
          .read(reminderSchedulerProvider)
          .permissionStatus();
      if (!mounted) return;
      setState(() {
        _permissionStatus = status;
        _isCheckingPermission = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _permissionError = 'Status izin notifikasi belum dapat diperiksa.';
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    if (_isRequestingPermission || _isCheckingPermission) return;

    setState(() {
      _isRequestingPermission = true;
      _permissionError = null;
    });

    try {
      final status = await ref
          .read(reminderSchedulerProvider)
          .requestPermission();
      if (!mounted) return;
      setState(() {
        _permissionStatus = status;
        _isRequestingPermission = false;
      });

      final message = switch (status) {
        NotificationPermissionStatus.granted =>
          'Izin notifikasi telah diberikan.',
        NotificationPermissionStatus.denied =>
          'Izin notifikasi belum diberikan. Anda dapat mengubahnya di setelan perangkat.',
        NotificationPermissionStatus.unavailable =>
          'Pengaturan izin notifikasi tidak tersedia di perangkat ini.',
      };
      _showSnackBar(message);
    } on Object {
      if (!mounted) return;
      setState(() {
        _permissionError = 'Permintaan izin notifikasi belum berhasil.';
        _isRequestingPermission = false;
      });
      _showSnackBar('Izin notifikasi belum dapat diminta. Silakan coba lagi.');
    }
  }

  Future<void> _showEditNameDialog({
    required String currentName,
    required AuthSession session,
  }) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EditNameDialog(
        initialName: currentName,
        onSave: (displayName) =>
            _updateDisplayName(uid: session.uid, displayName: displayName),
      ),
    );

    if (changed == true && mounted) {
      _showSnackBar('Nama berhasil diperbarui.');
    }
  }

  Future<String?> _updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final activeSession = ref.read(authSessionProvider).value;
    if (activeSession == null || activeSession.uid != uid) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .updateDisplayName(uid: uid, displayName: displayName);
      return null;
    } on Object catch (error) {
      return FirebaseErrorMapper.auth(error).message;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Semua pengingat lokal untuk sesi ini akan dibatalkan sebelum '
          'Anda keluar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await ref.read(reminderSchedulerProvider).cancelAll();
      final signedOut = await ref
          .read(authControllerProvider.notifier)
          .signOut();
      if (!signedOut && mounted) {
        final message = ref.read(authControllerProvider).errorMessage;
        _showSnackBar(message ?? 'Anda belum dapat keluar. Silakan coba lagi.');
      }
    } on Object {
      if (mounted) {
        _showSnackBar(
          'Pengingat lokal belum dapat dibatalkan. Anda belum keluar.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _firstNonEmpty(List<String?> values) {
    return values
        .map((value) => value?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().substring(0, 1).toUpperCase();

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InformationTile extends StatelessWidget {
  const _InformationTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.status,
    required this.errorMessage,
    required this.isChecking,
    required this.isRequesting,
    required this.onRequestPermission,
    required this.onRefresh,
  });

  final NotificationPermissionStatus? status;
  final String? errorMessage;
  final bool isChecking;
  final bool isRequesting;
  final VoidCallback onRequestPermission;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, description, icon, color) = switch (status) {
      NotificationPermissionStatus.granted => (
        'Izin diberikan',
        'Pengingat servis dapat ditampilkan sebagai notifikasi lokal.',
        Icons.notifications_active_rounded,
        colorScheme.secondary,
      ),
      NotificationPermissionStatus.denied => (
        'Izin belum diberikan',
        'Izinkan notifikasi agar pengingat servis dapat muncul tepat waktu.',
        Icons.notifications_off_outlined,
        colorScheme.error,
      ),
      NotificationPermissionStatus.unavailable => (
        'Izin tidak tersedia',
        'Perangkat ini tidak menyediakan pengaturan izin notifikasi.',
        Icons.notifications_none_rounded,
        colorScheme.outline,
      ),
      null => (
        'Memeriksa izin',
        'Status izin notifikasi sedang diperiksa.',
        Icons.notifications_none_rounded,
        colorScheme.outline,
      ),
    };

    return _SectionCard(
      title: 'Notifikasi',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: isChecking
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: color),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorMessage ?? description),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (status != NotificationPermissionStatus.granted &&
                status != NotificationPermissionStatus.unavailable)
              FilledButton.tonalIcon(
                onPressed: isChecking || isRequesting
                    ? null
                    : onRequestPermission,
                icon: isRequesting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                label: Text(isRequesting ? 'Meminta izin...' : 'Minta izin'),
              ),
            OutlinedButton.icon(
              onPressed: isChecking || isRequesting ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Perbarui status'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Tentang MentorRide',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: AppLogo(size: 48),
          title: Text('Perawatan motor lebih tertata'),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'MentorRide membantu mencatat kendaraan, riwayat dan biaya '
              'servis, serta jadwal perawatan dalam satu tempat.',
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            IconButton(
              tooltip: 'Coba lagi',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName, required this.onSave});

  final String initialName;
  final Future<String?> Function(String displayName) onSave;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: const Text('Edit nama'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _controller,
                  enabled: !_isSubmitting,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: AppValidators.displayName,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_submitError case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    final error = await widget.onSave(_controller.text.trim());
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitError = error;
    });
  }
}
