import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/service_records/domain/models/service_action.dart';
import 'package:mentorride/features/service_records/domain/models/service_item.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';
import 'package:mentorride/features/service_records/providers/service_record_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';
import 'package:mentorride/shared/widgets/loading_button.dart';

class ServiceRecordFormScreen extends ConsumerWidget {
  const ServiceRecordFormScreen({this.recordId, super.key});

  final String? recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = recordId;
    if (id == null) return const _ServiceRecordEditor();

    final record = ref.watch(serviceRecordByIdProvider(id));
    return record.when(
      loading: () => const Scaffold(
        appBar: _FormAppBar(isEditing: true),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: const _FormAppBar(isEditing: true),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(serviceRecordsProvider),
        ),
      ),
      data: (value) {
        if (value == null) {
          return Scaffold(
            appBar: const _FormAppBar(isEditing: true),
            body: ErrorState(
              message: 'Catatan servis yang akan diedit tidak ditemukan.',
              onRetry: () => ref.invalidate(serviceRecordsProvider),
            ),
          );
        }
        return _ServiceRecordEditor(
          key: ValueKey(value.id),
          initialRecord: value,
        );
      },
    );
  }
}

class _ServiceRecordEditor extends ConsumerStatefulWidget {
  const _ServiceRecordEditor({this.initialRecord, super.key});

  final ServiceRecord? initialRecord;

  @override
  ConsumerState<_ServiceRecordEditor> createState() =>
      _ServiceRecordEditorState();
}

class _ServiceRecordEditorState extends ConsumerState<_ServiceRecordEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odometerController;
  late final TextEditingController _workshopController;
  late final TextEditingController _notesController;
  late DateTime _serviceDate;
  final List<_ServiceItemDraft> _items = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialRecord != null;

  int get _totalCost {
    return _items.fold(
      0,
      (total, item) => total + (int.tryParse(item.costController.text) ?? 0),
    );
  }

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _serviceDate = record?.serviceDate.toLocal() ?? DateTime.now();
    _odometerController = TextEditingController(
      text: record == null ? '' : record.odometer.toString(),
    );
    _workshopController = TextEditingController(text: record?.workshop ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');

    if (record == null || record.items.isEmpty) {
      _items.add(_ServiceItemDraft.empty());
    } else {
      _items.addAll(record.items.map(_ServiceItemDraft.fromItem));
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _workshopController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Catatan Servis' : 'Tambah Catatan Servis';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Informasi servis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _pickServiceDate,
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal servis',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(AppFormatters.date(_serviceDate)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _odometerController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Odometer',
                hintText: 'Contoh: 12500',
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed_rounded),
              ),
              validator: (value) =>
                  AppValidators.nonNegativeInteger(value, field: 'Odometer'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workshopController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Bengkel',
                hintText: 'Nama bengkel atau servis mandiri',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (value) =>
                  AppValidators.requiredText(value, field: 'Bengkel'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item perawatan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _addItem,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah item'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < _items.length; index++) ...[
              _ServiceItemFields(
                key: _items[index].key,
                index: index,
                draft: _items[index],
                enabled: !_isSubmitting,
                canRemove: _items.length > 1,
                onRemove: () => _removeItem(index),
                onCostChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total biaya',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      AppFormatters.rupiah(_totalCost),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              enabled: !_isSubmitting,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Tambahkan keterangan servis',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: LoadingButton(
                label: _isEditing ? 'Simpan perubahan' : 'Simpan servis',
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.save_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickServiceDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _serviceDate.isAfter(now) ? now : _serviceDate,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Pilih tanggal servis',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !mounted) return;
    setState(() => _serviceDate = selected);
  }

  void _addItem() {
    setState(() => _items.add(_ServiceItemDraft.empty()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    final removed = _items.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final scope = ref.read(activeServiceRecordScopeProvider);
    if (scope == null) {
      _showMessage('Sesi atau kendaraan aktif tidak tersedia.');
      return;
    }

    final items = _items
        .map(
          (draft) => ServiceItem(
            name: draft.nameController.text.trim(),
            action: draft.action,
            cost: int.parse(draft.costController.text),
          ),
        )
        .toList(growable: false);
    final original = widget.initialRecord;
    final record = ServiceRecord(
      id: original?.id ?? '',
      serviceDate: _serviceDate,
      odometer: int.parse(_odometerController.text),
      workshop: _workshopController.text.trim(),
      items: items,
      notes: _notesController.text.trim(),
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(serviceRecordRepositoryProvider);
      if (_isEditing) {
        await repository.updateServiceRecord(
          uid: scope.uid,
          vehicleId: scope.vehicleId,
          record: record,
        );
      } else {
        await repository.createServiceRecord(
          uid: scope.uid,
          vehicleId: scope.vehicleId,
          record: record,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isSubmitting = false);
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Catatan servis berhasil diperbarui.'
                : 'Catatan servis berhasil ditambahkan.',
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ServiceItemFields extends StatefulWidget {
  const _ServiceItemFields({
    required this.index,
    required this.draft,
    required this.enabled,
    required this.canRemove,
    required this.onRemove,
    required this.onCostChanged,
    super.key,
  });

  final int index;
  final _ServiceItemDraft draft;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onCostChanged;

  @override
  State<_ServiceItemFields> createState() => _ServiceItemFieldsState();
}

class _ServiceItemFieldsState extends State<_ServiceItemFields> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Hapus item',
                    onPressed: widget.enabled ? widget.onRemove : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: widget.draft.nameController,
              enabled: widget.enabled,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama item',
                hintText: 'Contoh: Oli mesin',
              ),
              validator: (value) =>
                  AppValidators.requiredText(value, field: 'Nama item'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ServiceAction>(
              initialValue: widget.draft.action,
              decoration: const InputDecoration(labelText: 'Tindakan'),
              items: ServiceAction.values
                  .map(
                    (action) => DropdownMenuItem(
                      value: action,
                      child: Text(action.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: widget.enabled
                  ? (action) {
                      if (action != null) widget.draft.action = action;
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.draft.costController,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Biaya',
                prefixText: 'Rp ',
                hintText: '0',
              ),
              validator: (value) =>
                  AppValidators.nonNegativeInteger(value, field: 'Biaya'),
              onChanged: (_) => widget.onCostChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FormAppBar({required this.isEditing});

  final bool isEditing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(isEditing ? 'Edit Catatan Servis' : 'Tambah Catatan Servis'),
    );
  }
}

class _ServiceItemDraft {
  _ServiceItemDraft({
    required this.nameController,
    required this.costController,
    required this.action,
  });

  factory _ServiceItemDraft.empty() {
    return _ServiceItemDraft(
      nameController: TextEditingController(),
      costController: TextEditingController(text: '0'),
      action: ServiceAction.periksa,
    );
  }

  factory _ServiceItemDraft.fromItem(ServiceItem item) {
    return _ServiceItemDraft(
      nameController: TextEditingController(text: item.name),
      costController: TextEditingController(text: item.cost.toString()),
      action: item.action,
    );
  }

  final Key key = UniqueKey();
  final TextEditingController nameController;
  final TextEditingController costController;
  ServiceAction action;

  void dispose() {
    nameController.dispose();
    costController.dispose();
  }
}
