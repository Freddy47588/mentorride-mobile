import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';
import 'package:mentorride/shared/widgets/loading_button.dart';

class ServiceScheduleFormScreen extends ConsumerWidget {
  const ServiceScheduleFormScreen({
    this.scheduleId,
    this.initialSchedule,
    super.key,
  });

  final String? scheduleId;
  final ServiceSchedule? initialSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provided = initialSchedule;
    if (provided != null) {
      return _ServiceScheduleForm(
        key: ValueKey(provided.id),
        initialSchedule: provided,
      );
    }

    final id = scheduleId;
    if (id == null || id.isEmpty) {
      return const _ServiceScheduleForm();
    }

    return ref
        .watch(serviceScheduleByIdProvider(id))
        .when(
          loading: () => const Scaffold(
            appBar: _FormAppBar(isEditing: true),
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Scaffold(
            appBar: const _FormAppBar(isEditing: true),
            body: ErrorState(
              message: 'Jadwal servis belum dapat dimuat.',
              onRetry: () => ref.invalidate(serviceSchedulesProvider),
            ),
          ),
          data: (schedule) {
            if (schedule == null) {
              return Scaffold(
                appBar: const _FormAppBar(isEditing: true),
                body: ErrorState(
                  message: 'Jadwal servis tidak ditemukan.',
                  onRetry: () => ref.invalidate(serviceSchedulesProvider),
                ),
              );
            }
            return _ServiceScheduleForm(
              key: ValueKey(schedule.id),
              initialSchedule: schedule,
            );
          },
        );
  }
}

class _ServiceScheduleForm extends ConsumerStatefulWidget {
  const _ServiceScheduleForm({this.initialSchedule, super.key});

  final ServiceSchedule? initialSchedule;

  @override
  ConsumerState<_ServiceScheduleForm> createState() =>
      _ServiceScheduleFormState();
}

class _ServiceScheduleFormState extends ConsumerState<_ServiceScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _serviceTypeController;
  late final TextEditingController _dueOdometerController;
  late DateTime _dueDate;
  late DateTime _reminderAt;
  late bool _reminderEnabled;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialSchedule != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSchedule;
    final now = DateTime.now();
    final defaultDueDate = DateTime(now.year, now.month, now.day + 30);
    final defaultReminder = DateTime(
      defaultDueDate.year,
      defaultDueDate.month,
      defaultDueDate.day - 1,
      9,
    );

    _titleController = TextEditingController(text: initial?.title ?? '');
    _serviceTypeController = TextEditingController(
      text: initial?.serviceType ?? '',
    );
    _dueOdometerController = TextEditingController(
      text: initial?.dueOdometer?.toString() ?? '',
    );
    _dueDate = initial?.dueDate ?? defaultDueDate;
    _reminderAt = initial?.reminderAt ?? defaultReminder;
    _reminderEnabled = initial?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _serviceTypeController.dispose();
    _dueOdometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _FormAppBar(isEditing: _isEditing),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              TextFormField(
                controller: _titleController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul jadwal',
                  hintText: 'Contoh: Servis rutin bulanan',
                  prefixIcon: Icon(Icons.event_note_outlined),
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Judul jadwal'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceTypeController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Jenis servis',
                  hintText: 'Contoh: Ganti oli mesin',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Jenis servis'),
              ),
              const SizedBox(height: 16),
              _PickerField(
                icon: Icons.calendar_month_outlined,
                label: 'Tanggal jatuh tempo',
                value: AppFormatters.date(_dueDate),
                enabled: !_isSubmitting,
                onTap: _pickDueDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueOdometerController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Kilometer jatuh tempo (opsional)',
                  hintText: 'Contoh: 15000',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed_rounded),
                ),
                validator: (value) => AppValidators.optionalNonNegativeInteger(
                  value,
                  field: 'Kilometer jatuh tempo',
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _reminderEnabled,
                      onChanged: _isSubmitting
                          ? null
                          : (enabled) {
                              setState(() => _reminderEnabled = enabled);
                            },
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Aktifkan pengingat'),
                      subtitle: const Text(
                        'MentorRide akan mengingatkan pada waktu yang dipilih.',
                      ),
                    ),
                    if (_reminderEnabled) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _PickerField(
                              icon: Icons.event_outlined,
                              label: 'Tanggal pengingat',
                              value: AppFormatters.date(_reminderAt),
                              enabled: !_isSubmitting,
                              onTap: _pickReminderDate,
                            ),
                            const SizedBox(height: 12),
                            _PickerField(
                              icon: Icons.schedule_outlined,
                              label: 'Waktu pengingat',
                              value: _formatTime(_reminderAt),
                              enabled: !_isSubmitting,
                              onTap: _pickReminderTime,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: _isEditing ? 'Simpan perubahan' : 'Simpan jadwal',
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal jatuh tempo',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !mounted) return;

    setState(() {
      _dueDate = selected;
      if (_reminderAt.isAfter(_endOfDay(selected))) {
        _reminderAt = DateTime(
          selected.year,
          selected.month,
          selected.day - 1,
          _reminderAt.hour,
          _reminderAt.minute,
        );
      }
    });
  }

  Future<void> _pickReminderDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _reminderAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal pengingat',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _reminderAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _reminderAt.hour,
        _reminderAt.minute,
      );
    });
  }

  Future<void> _pickReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt),
      helpText: 'Pilih waktu pengingat',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _reminderAt = DateTime(
        _reminderAt.year,
        _reminderAt.month,
        _reminderAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_reminderEnabled && !_reminderAt.isAfter(DateTime.now())) {
      _showMessage('Waktu pengingat harus berada di masa mendatang.');
      return;
    }
    if (_reminderEnabled && _reminderAt.isAfter(_endOfDay(_dueDate))) {
      _showMessage('Waktu pengingat tidak boleh setelah tanggal jatuh tempo.');
      return;
    }

    final original = widget.initialSchedule;
    final odometerText = _dueOdometerController.text.trim();
    final schedule = ServiceSchedule(
      id: original?.id ?? '',
      title: _titleController.text.trim(),
      serviceType: _serviceTypeController.text.trim(),
      dueDate: _dueDate,
      dueOdometer: odometerText.isEmpty ? null : int.parse(odometerText),
      reminderAt: _reminderAt,
      reminderEnabled: _reminderEnabled,
      localNotificationId: original?.localNotificationId ?? 0,
      status: original?.status ?? ServiceScheduleStatus.pending,
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );

    setState(() => _isSubmitting = true);
    final controller = ref.read(serviceScheduleControllerProvider.notifier);
    final success = _isEditing
        ? await controller.update(schedule)
        : await controller.create(schedule) != null;
    if (!mounted) return;

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isSubmitting = false);
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Jadwal servis berhasil diperbarui.'
                : 'Jadwal servis berhasil ditambahkan.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = false);
    final message = ref.read(serviceScheduleControllerProvider).errorMessage;
    _showMessage(message ?? 'Jadwal servis belum dapat disimpan.');
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}.'
        '${value.minute.toString().padLeft(2, '0')} WIB';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          enabled: enabled,
        ),
        child: Text(value),
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
      title: Text(isEditing ? 'Edit Jadwal Servis' : 'Tambah Jadwal Servis'),
    );
  }
}
