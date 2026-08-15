import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';
import 'package:mentorride/shared/widgets/error_state.dart';
import 'package:mentorride/shared/widgets/loading_button.dart';

class VehicleFormScreen extends ConsumerWidget {
  const VehicleFormScreen({this.vehicleId, this.initialVehicle, super.key});

  final String? vehicleId;
  final Vehicle? initialVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = initialVehicle;
    if (initial != null) {
      return _VehicleEditor(key: ValueKey(initial.id), initialVehicle: initial);
    }

    final id = vehicleId;
    if (id == null || id.isEmpty) {
      return const _VehicleEditor();
    }

    final vehicleValue = ref.watch(vehicleDetailProvider(id));
    return vehicleValue.when(
      loading: () => const Scaffold(
        appBar: _VehicleFormAppBar(title: 'Edit kendaraan'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: const _VehicleFormAppBar(title: 'Edit kendaraan'),
        body: ErrorState(
          message: 'Data kendaraan belum dapat dimuat.',
          onRetry: () => ref.invalidate(vehicleDetailProvider(id)),
        ),
      ),
      data: (vehicle) {
        if (vehicle == null) {
          return const Scaffold(
            appBar: _VehicleFormAppBar(title: 'Edit kendaraan'),
            body: ErrorState(message: 'Data kendaraan tidak ditemukan.'),
          );
        }
        return _VehicleEditor(
          key: ValueKey(vehicle.id),
          initialVehicle: vehicle,
        );
      },
    );
  }
}

class _VehicleEditor extends ConsumerStatefulWidget {
  const _VehicleEditor({this.initialVehicle, super.key});

  final Vehicle? initialVehicle;

  @override
  ConsumerState<_VehicleEditor> createState() => _VehicleEditorState();
}

class _VehicleEditorState extends ConsumerState<_VehicleEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _odometerController;

  bool get _isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.initialVehicle;
    _nameController = TextEditingController(text: vehicle?.name ?? '');
    _brandController = TextEditingController(text: vehicle?.brand ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _yearController = TextEditingController(
      text: vehicle == null ? '' : vehicle.year.toString(),
    );
    _plateController = TextEditingController(text: vehicle?.plateNumber ?? '');
    _odometerController = TextEditingController(
      text: vehicle == null ? '' : vehicle.currentOdometer.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(vehicleControllerProvider);

    return Scaffold(
      appBar: _VehicleFormAppBar(
        title: _isEditing ? 'Edit kendaraan' : 'Tambah kendaraan',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                _isEditing
                    ? 'Perbarui informasi sepeda motor Anda.'
                    : 'Masukkan informasi sepeda motor yang akan dirawat.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama kendaraan',
                  hintText: 'Contoh: Motor harian',
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Nama kendaraan'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Merek',
                  hintText: 'Contoh: Honda',
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Merek'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'Contoh: Vario 160',
                ),
                validator: (value) =>
                    AppValidators.requiredText(value, field: 'Model'),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 340) {
                    return Column(
                      children: [
                        _buildYearField(),
                        const SizedBox(height: 16),
                        _buildPlateField(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildYearField()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPlateField()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Kilometer saat ini',
                  hintText: '0',
                  suffixText: 'km',
                ),
                validator: (value) {
                  final initial = widget.initialVehicle;
                  if (initial != null) {
                    return AppValidators.updatedOdometer(
                      value,
                      currentOdometer: initial.currentOdometer,
                    );
                  }
                  return AppValidators.nonNegativeInteger(
                    value,
                    field: 'Kilometer',
                  );
                },
                onFieldSubmitted: (_) {
                  if (!actionState.isSubmitting) _submit();
                },
              ),
              if (actionState.errorMessage case final message?) ...[
                const SizedBox(height: 16),
                _FormError(message: message),
              ],
              const SizedBox(height: 28),
              LoadingButton(
                label: _isEditing ? 'Simpan perubahan' : 'Tambah kendaraan',
                icon: _isEditing ? Icons.save_outlined : Icons.add_rounded,
                isLoading: actionState.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(labelText: 'Tahun', hintText: '2024'),
      validator: AppValidators.year,
    );
  }

  Widget _buildPlateField() {
    return TextFormField(
      controller: _plateController,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        LengthLimitingTextInputFormatter(12),
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
      ],
      decoration: const InputDecoration(
        labelText: 'Nomor polisi',
        hintText: 'B 1234 XYZ',
      ),
      validator: AppValidators.plateNumber,
    );
  }

  Future<void> _submit() async {
    final controller = ref.read(vehicleControllerProvider.notifier);
    if (ref.read(vehicleControllerProvider).isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final initial = widget.initialVehicle;
    final vehicle = Vehicle(
      id: initial?.id ?? '',
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text),
      plateNumber: _plateController.text.trim().toUpperCase(),
      currentOdometer: int.parse(_odometerController.text),
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
    );

    final success = initial == null
        ? await controller.createVehicle(vehicle) != null
        : await controller.updateVehicle(vehicle);
    if (!mounted || !success) return;
    Navigator.of(context).pop(true);
  }
}

class _VehicleFormAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _VehicleFormAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
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
        ],
      ),
    );
  }
}
