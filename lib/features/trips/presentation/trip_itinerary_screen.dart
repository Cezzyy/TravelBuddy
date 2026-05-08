import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/data/app_db.dart';
import '../../auth/presentation/providers/current_user_provider.dart';
import 'providers/trip_detail_provider.dart';
import 'providers/trip_form_provider.dart';
import 'providers/trip_itinerary_provider.dart';

/// Itinerary builder screen — manage day-by-day items for a trip.
class TripItineraryScreen extends ConsumerWidget {
  const TripItineraryScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    final itemsAsync = ref.watch(tripItineraryProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Itinerary'),
        centerTitle: false,
        actions: [
          tripAsync.when(
            data: (trip) => trip != null
                ? TextButton.icon(
                    onPressed: () => _showAddItemSheet(
                      context,
                      ref,
                      trip: trip,
                      scheduledDate: trip.startDate,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          return tripAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (trip) {
              if (trip == null) {
                return const Center(child: Text('Trip not found'));
              }

              if (items.isEmpty) {
                return _EmptyItinerary(
                  onAdd: () => _showAddItemSheet(
                    context,
                    ref,
                    trip: trip,
                    scheduledDate: trip.startDate,
                  ),
                );
              }

              // Group by date
              final byDate = <DateTime, List<ItineraryItem>>{};
              for (final item in items) {
                final dateKey = DateTime(
                  item.scheduledDate.year,
                  item.scheduledDate.month,
                  item.scheduledDate.day,
                );
                byDate.putIfAbsent(dateKey, () => []).add(item);
              }
              final dates = byDate.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: dates.length + 1, // +1 for "Add Day" button
                itemBuilder: (context, index) {
                  if (index == dates.length) {
                    // Add new day button
                    final nextDate = dates.isEmpty
                        ? trip.startDate
                        : dates.last.add(const Duration(days: 1));
                    
                    // Only show if within trip dates
                    if (nextDate.isAfter(trip.endDate)) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddItemSheet(
                          context,
                          ref,
                          trip: trip,
                          scheduledDate: nextDate,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'Add ${DateFormat('MMM d').format(nextDate)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }

                  final date = dates[index];
                  final dateItems = byDate[date]!;
                  final dayNumber = date.difference(trip.startDate).inDays + 1;

                  return _DateSection(
                    date: date,
                    dayNumber: dayNumber,
                    items: dateItems,
                    trip: trip,
                    onAddItem: () => _showAddItemSheet(
                      context,
                      ref,
                      trip: trip,
                      scheduledDate: date,
                    ),
                    onEditItem: (item) => _showEditItemSheet(
                      context,
                      ref,
                      trip: trip,
                      item: item,
                    ),
                    onDeleteItem: (item) => _confirmDeleteItem(
                      context,
                      ref,
                      item,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddItemSheet(
    BuildContext context,
    WidgetRef ref, {
    required Trip trip,
    required DateTime scheduledDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        tripId: tripId,
        trip: trip,
        scheduledDate: scheduledDate,
        onSave: (data) async {
          final currentUserAsync = ref.read(currentUserProvider);
          final currentUser = currentUserAsync.value;
          if (currentUser == null) {
            throw Exception('Not authenticated');
          }

          await ref.read(tripItineraryFormProvider.notifier).addItem(
                tripId: tripId,
                createdBy: currentUser.id,
                title: data['title'] as String,
                description: data['description'] as String?,
                locationName: data['locationName'] as String?,
                scheduledDate: scheduledDate,
                startTime: data['startTime'] as DateTime?,
                endTime: data['endTime'] as DateTime?,
                category: data['category'] as String? ?? 'other',
              );
          
          // Check if the operation failed
          final state = ref.read(tripItineraryFormProvider);
          if (state.hasError) {
            throw state.error!;
          }
        },
      ),
    );
  }

  void _showEditItemSheet(
    BuildContext context,
    WidgetRef ref, {
    required Trip trip,
    required ItineraryItem item,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        tripId: tripId,
        trip: trip,
        scheduledDate: item.scheduledDate,
        existingItem: item,
        onSave: (data) async {
          await ref.read(tripItineraryFormProvider.notifier).updateItem(
                itemId: item.id,
                title: data['title'] as String?,
                description: data['description'] as String?,
                locationName: data['locationName'] as String?,
                startTime: data['startTime'] as DateTime?,
                endTime: data['endTime'] as DateTime?,
                category: data['category'] as String?,
              );
          
          // Check if the operation failed
          final state = ref.read(tripItineraryFormProvider);
          if (state.hasError) {
            throw state.error!;
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    WidgetRef ref,
    ItineraryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Item'),
        content: Text('Remove "${item.title}" from the itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(tripItineraryFormProvider.notifier).deleteItem(item.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Item removed successfully'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Failed to remove item. Please try again.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}

// ─── Date Section ─────────────────────────────────────────────────────────────

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.date,
    required this.dayNumber,
    required this.items,
    required this.trip,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final DateTime date;
  final int dayNumber;
  final List<ItineraryItem> items;
  final Trip trip;
  final VoidCallback onAddItem;
  final void Function(ItineraryItem) onEditItem;
  final void Function(ItineraryItem) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Day $dayNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(date),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items
        ...items.map(
          (item) => _EditableItemTile(
            item: item,
            onEdit: () => onEditItem(item),
            onDelete: () => onDeleteItem(item),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EditableItemTile extends StatelessWidget {
  const _EditableItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ItineraryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _categoryColor(item.category).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _categoryIcon(item.category),
            size: 18,
            color: _categoryColor(item.category),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (item.startTime != null)
              Text(
                timeFormat.format(item.startTime!),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        subtitle: item.locationName != null
            ? Text(
                item.locationName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 18),
              color: AppColors.textSecondary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: Colors.redAccent,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
        'transport' => Icons.directions_rounded,
        'food' => Icons.restaurant_rounded,
        'activity' => Icons.local_activity_rounded,
        'accommodation' => Icons.hotel_rounded,
        _ => Icons.place_rounded,
      };

  Color _categoryColor(String category) => switch (category) {
        'transport' => Colors.blueAccent,
        'food' => Colors.orangeAccent,
        'activity' => AppColors.accent,
        'accommodation' => AppColors.primary,
        _ => AppColors.textSecondary,
      };
}

// ─── Item Form Sheet ──────────────────────────────────────────────────────────

class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({
    required this.tripId,
    required this.trip,
    required this.scheduledDate,
    required this.onSave,
    this.existingItem,
  });

  final String tripId;
  final Trip trip;
  final DateTime scheduledDate;
  final ItineraryItem? existingItem;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = 'other';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;

  static const _categories = [
    ('other', 'General', Icons.place_rounded),
    ('activity', 'Activity', Icons.local_activity_rounded),
    ('food', 'Food', Icons.restaurant_rounded),
    ('transport', 'Transport', Icons.directions_rounded),
    ('accommodation', 'Stay', Icons.hotel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _titleController.text = item.title;
      _descController.text = item.description ?? '';
      _locationController.text = item.locationName ?? '';
      _category = item.category;
      if (item.startTime != null) {
        _startTime = TimeOfDay.fromDateTime(item.startTime!);
      }
      if (item.endTime != null) {
        _endTime = TimeOfDay.fromDateTime(item.endTime!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormat = DateFormat('EEEE, MMM d');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isEditing
                  ? 'Edit Item'
                  : 'Add Item — ${dateFormat.format(widget.scheduledDate)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Category selector
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) {
                  final isSelected = _category == cat.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.$3, size: 14),
                          const SizedBox(width: 4),
                          Text(cat.$2),
                        ],
                      ),
                      onSelected: (_) => setState(() => _category = cat.$1),
                      selectedColor:
                          AppColors.primaryLight.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: _inputDec('Title *'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              decoration: _inputDec('Description (optional)'),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Location
            TextField(
              controller: _locationController,
              decoration: _inputDec('Location name (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Start Time',
                    time: _startTime,
                    onChanged: (time) => setState(() => _startTime = time),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimePickerField(
                    label: 'End Time',
                    time: _endTime,
                    onChanged: (time) => setState(() => _endTime = time),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Update Item' : 'Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please enter a title'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Convert TimeOfDay to DateTime
      DateTime? startDateTime;
      DateTime? endDateTime;

      if (_startTime != null) {
        startDateTime = DateTime(
          widget.scheduledDate.year,
          widget.scheduledDate.month,
          widget.scheduledDate.day,
          _startTime!.hour,
          _startTime!.minute,
        );
      }

      if (_endTime != null) {
        endDateTime = DateTime(
          widget.scheduledDate.year,
          widget.scheduledDate.month,
          widget.scheduledDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      await widget.onSave({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'locationName': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'category': _category,
        'startTime': startDateTime,
        'endTime': endDateTime,
      });

      if (mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  widget.existingItem != null
                      ? 'Item updated successfully'
                      : 'Item added successfully',
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.existingItem != null
                        ? 'Failed to update item. Please try again.'
                        : 'Failed to add item. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

// ─── Time Picker Field ────────────────────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color: time != null
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time != null ? time!.format(context) : label,
                style: TextStyle(
                  fontSize: 14,
                  color: time != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
            if (time != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyItinerary extends StatelessWidget {
  const _EmptyItinerary({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No itinerary yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add day-by-day activities to plan your perfect trip.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Item'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
