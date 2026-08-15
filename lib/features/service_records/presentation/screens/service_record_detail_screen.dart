import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';

class ServiceRecordDetailScreen extends ConsumerStatefulWidget {
  const ServiceRecordDetailScreen({required this.recordId, super.key});

  final String recordId;

  @override
  ConsumerState<ServiceRecordDetailScreen> createState() =>
      _ServiceRecordDetailScreenState();
}

class _ServiceRecordDetailScreenState
    extends ConsumerState<ServiceRecordDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(serviceRecordByIdProvider(widget.recordId));

    return record.when(
      loading: () => const Scaffold(
        appBar: _DetailAppBar(),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: const _DetailAppBar(),
        body: ErrorState(
          message: userFacingErrorMessage(
            error,
            fallback: 'Catatan servis belum dapat dimuat.',
          ),
          onRetry: () => ref.invalidate(serviceRecordsProvider),
        ),
      ),
      data: (value) {
        if (value == null) {
          return Scaffold(
            appBar: const _DetailAppBar(),
            body: ErrorState(
              message: 'Catatan servis tidak ditemukan.',
              onRetry: () => ref.invalidate(serviceRecordsProvider),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail servis'),
            actions: [
              IconButton(
                tooltip: 'Edit catatan',
                onPressed: _isDeleting
                    ? null
                    : () => context.push('/history/${value.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Hapus catatan',
                onPressed: _isDeleting ? null : () => _confirmDelete(value),
                icon: _isDeleting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: _DetailBody(record: value),
        );
      },
    );
  }

  Future<void> _confirmDelete(ServiceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan servis?'),
        content: const Text(
          'Catatan dan seluruh item servis di dalamnya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isDeleting) return;

    final scope = ref.read(activeServiceRecordScopeProvider);
    if (scope == null) {
      _showMessage('Sesi atau kendaraan aktif tidak tersedia.');
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(serviceRecordRepositoryProvider)
          .deleteServiceRecord(
            uid: scope.uid,
            vehicleId: scope.vehicleId,
            recordId: record.id,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isDeleting = false);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Catatan servis berhasil dihapus.')),
      );
    } on Object catch (error) {
      if (mounted) {
        _showMessage(
          userFacingErrorMessage(
            error,
            fallback: 'Catatan servis belum dapat dihapus. Silakan coba lagi.',
          ),
        );
      }
    } finally {
      if (mounted && _isDeleting) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DetailAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Detail servis'));
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.record});

  final ServiceRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppFormatters.date(record.serviceDate),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.speed_rounded,
                  label: 'Odometer',
                  value: AppFormatters.kilometer(record.odometer),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  label: 'Bengkel',
                  value: record.workshop.isEmpty
                      ? 'Tidak dicatat'
                      : record.workshop,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Item perawatan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < record.items.length; index++) ...[
                ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(record.items[index].name),
                  subtitle: Text(record.items[index].action.label),
                  trailing: Text(
                    AppFormatters.rupiah(record.items[index].cost),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (index != record.items.length - 1)
                  const Divider(height: 1, indent: 72),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text('Total biaya', style: theme.textTheme.titleMedium),
                    Text(
                      AppFormatters.rupiah(record.totalCost),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Catatan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              record.notes.isEmpty ? 'Tidak ada catatan.' : record.notes,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        SizedBox(width: 76, child: Text(label)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
