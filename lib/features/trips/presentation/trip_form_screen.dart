import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import 'providers/trip_form_provider.dart';

/// Create or edit a trip.
/// Pass [tripId] to edit an existing trip; null to create a new one.
class TripFormScreen extends ConsumerWidget {
  const TripFormScreen({super.key, this.tripId});

  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = tripId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Trip' : 'Create Trip',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: _TripFormBody(tripId: tripId),
      bottomNavigationBar: _SaveBar(tripId: tripId),
    );
  }
}

// ─── Form Body ────────────────────────────────────────────────────────────────

class _TripFormBody extends ConsumerStatefulWidget {
  const _TripFormBody({this.tripId});

  final String? tripId;

  @override
  ConsumerState<_TripFormBody> createState() => _TripFormBodyState();
}

class _TripFormBodyState extends ConsumerState<_TripFormBody> {
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _destinationController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(tripFormProvider(widget.tripId));
    final theme = Theme.of(context);

    // Update controllers when state changes (for editing mode)
    if (_titleController.text != formState.title) {
      _titleController.text = formState.title;
    }
    if (_destinationController.text != formState.destination) {
      _destinationController.text = formState.destination;
    }
    if (_descriptionController.text != formState.description) {
      _descriptionController.text = formState.description;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.luggage_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan Your Adventure',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create your perfect travel itinerary',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Basic Information Section
          _SectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Basic Information',
          ),
          const SizedBox(height: 16),

          // Title
          _FormField(
            label: 'Trip Title *',
            child: TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g. Summer in Europe'),
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15),
              onChanged: (v) => ref
                  .read(tripFormProvider(widget.tripId).notifier)
                  .updateTitle(v),
            ),
          ),
          const SizedBox(height: 18),

          // Destination
          _FormField(
            label: 'Destination *',
            child: TextFormField(
              controller: _destinationController,
              decoration: _inputDecoration('e.g. Paris, France'),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 15),
              onChanged: (v) => ref
                  .read(tripFormProvider(widget.tripId).notifier)
                  .updateDestination(v),
            ),
          ),
          const SizedBox(height: 18),

          // Description
          _FormField(
            label: 'Description *',
            hint: 'A brief summary of your trip',
            child: TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('What are you planning?'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15, height: 1.5),
              onChanged: (v) => ref
                  .read(tripFormProvider(widget.tripId).notifier)
                  .updateDescription(v),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 28),

          // Dates Section
          _SectionHeader(icon: Icons.calendar_today_rounded, title: 'Dates'),
          const SizedBox(height: 16),

          // Start Date
          _FormField(
            label: 'Start Date *',
            child: _DatePickerField(
              value: formState.startDate,
              hint: 'Select start date',
              onChanged: (date) => ref
                  .read(tripFormProvider(widget.tripId).notifier)
                  .updateStartDate(date),
            ),
          ),
          const SizedBox(height: 18),

          // End Date
          _FormField(
            label: 'End Date *',
            child: _DatePickerField(
              value: formState.endDate,
              hint: 'Select end date',
              firstDate: formState.startDate,
              onChanged: (date) => ref
                  .read(tripFormProvider(widget.tripId).notifier)
                  .updateEndDate(date),
            ),
          ),

          // Duration display
          if (formState.startDate != null && formState.endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Duration: ${_calculateDuration(formState.startDate!, formState.endDate!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 28),

          // Status Section
          _SectionHeader(icon: Icons.flag_outlined, title: 'Status'),
          const SizedBox(height: 16),
          _StatusSelector(tripId: widget.tripId),

          // Error message
          Consumer(
            builder: (context, ref, _) {
              final error = ref
                  .watch(tripFormProvider(widget.tripId))
                  .errorMessage;
              if (error == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        fontSize: 15,
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.surfaceVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.surfaceVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Form Field Wrapper ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child, this.hint});

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─── Date Picker Field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.firstDate,
  });

  final DateTime? value;
  final String hint;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: value != null
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null ? dateFormat.format(value!) : hint,
                style: TextStyle(
                  fontSize: 15,
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: value ?? firstDate ?? now,
      firstDate: firstDate ?? now,
      lastDate: DateTime(now.year + 5),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}

// ─── Status Selector ──────────────────────────────────────────────────────────

class _StatusSelector extends ConsumerWidget {
  const _StatusSelector({this.tripId});

  final String? tripId;

  static const _statuses = [
    {'value': 'upcoming', 'label': 'Upcoming', 'icon': Icons.schedule_rounded},
    {
      'value': 'ongoing',
      'label': 'Ongoing',
      'icon': Icons.flight_takeoff_rounded,
    },
    {
      'value': 'completed',
      'label': 'Completed',
      'icon': Icons.check_circle_rounded,
    },
    {'value': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_rounded},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(
      tripFormProvider(tripId).select((s) => s.status),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _statuses.map((status) {
        final isSelected = selectedStatus == status['value'];
        return _StatusChip(
          label: status['label'] as String,
          icon: status['icon'] as IconData,
          isSelected: isSelected,
          onTap: () => ref
              .read(tripFormProvider(tripId).notifier)
              .updateStatus(status['value'] as String),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save Bar ─────────────────────────────────────────────────────────────────

class _SaveBar extends ConsumerWidget {
  const _SaveBar({this.tripId});

  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(tripFormProvider(tripId));

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Validation status
            if (!formState.isValid) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fill in all required fields to save',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: formState.isSaving || !formState.isValid
                    ? null
                    : () => _save(context, ref),
                icon: formState.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  formState.isSaving
                      ? 'Saving...'
                      : tripId != null
                      ? 'Save Changes'
                      : 'Create Trip',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textSecondary.withValues(
                    alpha: 0.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final savedId = await ref.read(tripFormProvider(tripId).notifier).save();
    if (!context.mounted) return;

    if (savedId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tripId != null
                    ? 'Trip updated successfully'
                    : 'Trip created successfully',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to trip detail
      context.pushReplacement(
        RoutePaths.tripDetail.replaceFirst(':tripId', savedId),
      );
    }
  }
}
