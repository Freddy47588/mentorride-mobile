import 'package:flutter/material.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/vehicles/domain/models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    required this.vehicle,
    required this.isActive,
    required this.onTap,
    required this.onSelect,
    this.isSelecting = false,
    super.key,
  });

  final Vehicle vehicle;
  final bool isActive;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.two_wheeler_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _VehicleMetadata(
                          icon: Icons.pin_rounded,
                          label: vehicle.plateNumber,
                        ),
                        _VehicleMetadata(
                          icon: Icons.speed_rounded,
                          label: AppFormatters.kilometer(
                            vehicle.currentOdometer,
                          ),
                        ),
                        if (isActive)
                          const _VehicleMetadata(
                            icon: Icons.check_circle_rounded,
                            label: 'Aktif',
                            isHighlighted: true,
                          ),
                      ],
                    ),
                    if (!isActive) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: isSelecting ? null : onSelect,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: isSelecting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Jadikan aktif'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleMetadata extends StatelessWidget {
  const _VehicleMetadata({
    required this.icon,
    required this.label,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isHighlighted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: foreground),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: isHighlighted ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
