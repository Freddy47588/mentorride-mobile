import 'package:flutter/material.dart';
import 'package:mentorride/core/utils/formatters.dart';
import 'package:mentorride/features/service_records/domain/models/service_record.dart';

class ServiceRecordTimelineTile extends StatelessWidget {
  const ServiceRecordTimelineTile({
    required this.record,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final ServiceRecord record;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final workshop = record.workshop.trim().isEmpty
        ? 'Bengkel tidak dicatat'
        : record.workshop.trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: _TimelineRail(isFirst: isFirst, isLast: isLast),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.date(record.serviceDate),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          workshop,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 12,
                          runSpacing: 5,
                          children: [
                            _RecordMetadata(
                              icon: Icons.build_outlined,
                              label: '${record.items.length} item',
                            ),
                            _RecordMetadata(
                              icon: Icons.speed_rounded,
                              label: AppFormatters.kilometer(record.odometer),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Total biaya',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              AppFormatters.rupiah(record.totalCost),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = colorScheme.outlineVariant;

    return Column(
      children: [
        Expanded(child: Container(width: 2, color: isFirst ? null : lineColor)),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.surface, width: 2),
          ),
        ),
        Expanded(child: Container(width: 2, color: isLast ? null : lineColor)),
      ],
    );
  }
}

class _RecordMetadata extends StatelessWidget {
  const _RecordMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
