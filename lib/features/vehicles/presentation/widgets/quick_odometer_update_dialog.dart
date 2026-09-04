import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/core/utils/validators.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';
import 'package:mentorride/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:mentorride/features/vehicles/providers/vehicle_providers.dart';

Future<VehicleOdometerUpdateResult?> showQuickOdometerUpdateDialog({
  required BuildContext context,
  required Vehicle vehicle,
}) {
  return showDialog<VehicleOdometerUpdateResult>(
    context: context,
    builder: (_) => QuickOdometerUpdateDialog(vehicle: vehicle),
  );
}

class QuickOdometerUpdateDialog extends ConsumerStatefulWidget {
  const QuickOdometerUpdateDialog({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  ConsumerState<QuickOdometerUpdateDialog> createState() =>
      _QuickOdometerUpdateDialogState();
}

class _QuickOdometerUpdateDialogState
    extends ConsumerState<QuickOdometerUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odometerController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _odometerController = TextEditingController(
      text: widget.vehicle.currentOdometer.toString(),
    );
  }

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Perbarui kilometer'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kilometer saat ini: '
                '${AppFormatters.kilometer(widget.vehicle.currentOdometer)}',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odometerController,
                autofocus: true,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Kilometer baru',
                  suffixText: 'km',
                ),
                validator: (value) => AppValidators.updatedOdometer(
                  value,
                  currentOdometer: widget.vehicle.currentOdometer,
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_errorMessage case final message?) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final odometer = int.parse(_odometerController.text.trim());
    if (odometer == widget.vehicle.currentOdometer) {
      Navigator.pop(context, VehicleOdometerUpdateResult.unchanged);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(vehicleControllerProvider.notifier)
        .updateOdometer(vehicleId: widget.vehicle.id, odometer: odometer);
    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context, result);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = ref.read(vehicleControllerProvider).errorMessage;
    });
  }
}
