import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mentorride/core/maintenance/maintenance_preset.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/service_schedules/domain/models/service_schedule.dart';
import 'package:mentorride/features/service_schedules/presentation/navigation/service_schedule_prefill.dart';
import 'package:mentorride/features/service_schedules/providers/service_schedule_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';
import 'package:mentorride/shared/widgets/loading_button.dart';

class ServiceScheduleFormScreen extends ConsumerWidget {
  const ServiceScheduleFormScreen({
    this.scheduleId,
    this.initialSchedule,
    this.prefill,
    super.key,
  });

  final String? scheduleId;
  final ServiceSchedule? initialSchedule;
  final ServiceSchedulePrefill? prefill;

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
      return _ServiceScheduleForm(prefill: prefill);
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
  const _ServiceScheduleForm({this.initialSchedule, this.prefill, super.key});

  final ServiceSchedule? initialSchedule;
  final ServiceSchedulePrefill? prefill;

  @override
  ConsumerState<_ServiceScheduleForm> createState() =>
      _ServiceScheduleFormState();
}

class _ServiceScheduleFormState extends ConsumerState<_ServiceScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _serviceTypeController;
  late final TextEditingController _dueOdometerController;
  DateTime? _dueDate;
  DateTime? _reminderAt;
  late bool _reminderEnabled;
  late bool _reminderTimeSelected;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialSchedule != null;
  bool get _isFollowUp => !_isEditing && widget.prefill != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSchedule;
    final prefill = widget.prefill;
    final now = DateTime.now();
    final defaultDueDate = DateTime(now.year, now.month, now.day + 30);
    final defaultReminder = DateTime(
      defaultDueDate.year,
      defaultDueDate.month,
      defaultDueDate.day - 1,
      9,
    );

    _titleController = TextEditingController(
      text: initial?.title ?? prefill?.title ?? '',
    );
    _serviceTypeController = TextEditingController(
      text: initial?.serviceType ?? prefill?.serviceType ?? '',
    );
    _dueOdometerController = TextEditingController(
      text: initial?.dueOdometer?.toString() ?? '',
    );
    _dueDate = _isFollowUp ? null : initial?.dueDate ?? defaultDueDate;
    _reminderAt = _isFollowUp ? null : initial?.reminderAt ?? defaultReminder;
    _reminderEnabled = _isFollowUp ? false : initial?.reminderEnabled ?? true;
    _reminderTimeSelected = !_isFollowUp;
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (_isFollowUp) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.replay_rounded),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Judul dan jenis servis telah disalin. Pilih '
                            'sendiri tanggal jatuh tempo serta pengingat untuk '
                            'jadwal berikutnya.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('schedule_title_field'),
                controller: _titleController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul jadwal',
                  hintText: 'Contoh: Servis rutin bulanan',
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Judul jadwal'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('schedule_service_type_field'),
                controller: _serviceTypeController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Jenis servis',
                  hintText: 'Contoh: Ganti oli mesin',
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Jenis servis'),
              ),
              const SizedBox(height: 10),
              Text(
                'Saran jenis servis',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MaintenancePresets.serviceTypeSuggestions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion =
                        MaintenancePresets.serviceTypeSuggestions[index];
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: _isSubmitting
                          ? null
                          : () => _selectServiceType(suggestion),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih saran atau ketik jenis servis sendiri.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _PickerField(
                icon: Icons.calendar_month_outlined,
                label: 'Tanggal jatuh tempo *',
                value: _dueDate == null
                    ? 'Pilih tanggal'
                    : AppFormatters.date(_dueDate!),
                enabled: !_isSubmitting,
                onTap: _pickDueDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('schedule_due_odometer_field'),
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
                      subtitle: Text(
                        _isFollowUp
                            ? 'Pengingat awalnya nonaktif. Aktifkan jika Anda '
                                  'ingin memilih waktu pengingat.'
                            : 'MentorRide akan mengingatkan pada waktu yang '
                                  'dipilih.',
                      ),
                    ),
                    AnimatedSize(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _reminderEnabled
                          ? Column(
                              children: [
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _PickerField(
                                        icon: Icons.event_outlined,
                                        label: 'Tanggal pengingat *',
                                        value: _reminderAt == null
                                            ? 'Pilih tanggal'
                                            : AppFormatters.date(_reminderAt!),
                                        enabled: !_isSubmitting,
                                        onTap: _pickReminderDate,
                                      ),
                                      const SizedBox(height: 12),
                                      _PickerField(
                                        icon: Icons.schedule_outlined,
                                        label: 'Waktu pengingat *',
                                        value:
                                            _reminderAt == null ||
                                                !_reminderTimeSelected
                                            ? 'Pilih waktu'
                                            : _formatTime(_reminderAt!),
                                        enabled: !_isSubmitting,
                                        onTap: _pickReminderTime,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
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
    final currentDueDate = _dueDate;
    final selected = await showDatePicker(
      context: context,
      initialDate:
          currentDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal jatuh tempo',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !mounted) return;

    setState(() {
      _dueDate = selected;
      final reminderAt = _reminderAt;
      if (reminderAt != null && reminderAt.isAfter(_endOfDay(selected))) {
        _reminderAt = DateTime(
          selected.year,
          selected.month,
          selected.day - 1,
          reminderAt.hour,
          reminderAt.minute,
        );
      }
    });
  }

  void _selectServiceType(String serviceType) {
    _serviceTypeController.value = TextEditingValue(
      text: serviceType,
      selection: TextSelection.collapsed(offset: serviceType.length),
    );
  }

  Future<void> _pickReminderDate() async {
    final currentReminder = _reminderAt;
    final selected = await showDatePicker(
      context: context,
      initialDate: currentReminder ?? DateTime.now(),
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
        currentReminder?.hour ?? 9,
        currentReminder?.minute ?? 0,
      );
    });
  }

  Future<void> _pickReminderTime() async {
    final currentReminder = _reminderAt;
    if (currentReminder == null) {
      _showMessage('Pilih tanggal pengingat terlebih dahulu.');
      return;
    }
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTimeSelected
          ? TimeOfDay.fromDateTime(currentReminder)
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Pilih waktu pengingat',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _reminderAt = DateTime(
        currentReminder.year,
        currentReminder.month,
        currentReminder.day,
        selected.hour,
        selected.minute,
      );
      _reminderTimeSelected = true;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final dueDate = _dueDate;
    if (dueDate == null) {
      _showMessage('Tanggal jatuh tempo wajib dipilih.');
      return;
    }

    final reminderAt = _reminderAt;
    if (_reminderEnabled && reminderAt == null) {
      _showMessage('Tanggal pengingat wajib dipilih.');
      return;
    }
    if (_reminderEnabled && !_reminderTimeSelected) {
      _showMessage('Waktu pengingat wajib dipilih.');
      return;
    }
    if (_reminderEnabled && !reminderAt!.isAfter(DateTime.now())) {
      _showMessage('Waktu pengingat harus berada di masa mendatang.');
      return;
    }
    if (_reminderEnabled && reminderAt!.isAfter(_endOfDay(dueDate))) {
      _showMessage('Waktu pengingat tidak boleh setelah tanggal jatuh tempo.');
      return;
    }

    final original = widget.initialSchedule;
    final odometerText = _dueOdometerController.text.trim();
    final schedule = ServiceSchedule(
      id: original?.id ?? '',
      title: _titleController.text.trim(),
      serviceType: _serviceTypeController.text.trim(),
      dueDate: dueDate,
      dueOdometer: odometerText.isEmpty ? null : int.parse(odometerText),
      reminderAt:
          reminderAt ?? DateTime(dueDate.year, dueDate.month, dueDate.day),
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
      title: Text(isEditing ? 'Edit jadwal servis' : 'Tambah jadwal servis'),
    );
  }
}
