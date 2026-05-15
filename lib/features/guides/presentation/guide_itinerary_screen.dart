import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/errors/error_state_widget.dart';
import '../../../shared/data/app_db.dart';
import 'providers/guide_detail_provider.dart';
import 'providers/guide_form_provider.dart';

/// Itinerary builder screen — manage day-by-day items for a guide.
class GuideItineraryScreen extends ConsumerWidget {
  const GuideItineraryScreen({super.key, required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(guideItineraryProvider(guideId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Itinerary'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => _showAddItemSheet(context, ref, dayNumber: 1),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget.fromException(
          e,
          onRetry: () => ref.invalidate(guideItineraryProvider(guideId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyItinerary(
              onAdd: () => _showAddItemSheet(context, ref, dayNumber: 1),
            );
          }

          // Group by day
          final byDay = <int, List<GuideItineraryItem>>{};
          for (final item in items) {
            byDay.putIfAbsent(item.dayNumber, () => []).add(item);
          }
          final days = byDay.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: days.length + 1, // +1 for "Add Day" button
            itemBuilder: (context, index) {
              if (index == days.length) {
                // Add new day button
                final nextDay = days.isEmpty ? 1 : days.last + 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddItemSheet(context, ref, dayNumber: nextDay),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add Day $nextDay'),
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

              final day = days[index];
              final dayItems = byDay[day]!;
              return _DaySection(
                day: day,
                items: dayItems,
                onAddItem: () =>
                    _showAddItemSheet(context, ref, dayNumber: day),
                onEditItem: (item) => _showEditItemSheet(context, ref, item),
                onDeleteItem: (item) => _confirmDeleteItem(context, ref, item),
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
    required int dayNumber,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        guideId: guideId,
        dayNumber: dayNumber,
        onSave: (data) async {
          await ref
              .read(guideItineraryFormProvider.notifier)
              .addItem(
                guideId: guideId,
                title: data['title'] as String,
                description: data['description'] as String?,
                locationName: data['locationName'] as String?,
                dayNumber: dayNumber,
                category: data['category'] as String? ?? 'other',
                estimatedCost: data['estimatedCost'] as double?,
                costCurrency: data['costCurrency'] as String?,
              );
        },
      ),
    );
  }

  void _showEditItemSheet(
    BuildContext context,
    WidgetRef ref,
    GuideItineraryItem item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        guideId: guideId,
        dayNumber: item.dayNumber,
        existingItem: item,
        onSave: (data) async {
          await ref
              .read(guideItineraryFormProvider.notifier)
              .updateItem(
                itemId: item.id,
                title: data['title'] as String?,
                description: data['description'] as String?,
                locationName: data['locationName'] as String?,
                category: data['category'] as String?,
                estimatedCost: data['estimatedCost'] as double?,
                costCurrency: data['costCurrency'] as String?,
              );
        },
      ),
    );
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    WidgetRef ref,
    GuideItineraryItem item,
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
        await ref.read(guideItineraryFormProvider.notifier).deleteItem(item.id);

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

// ─── Day Section ──────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final int day;
  final List<GuideItineraryItem> items;
  final VoidCallback onAddItem;
  final void Function(GuideItineraryItem) onEditItem;
  final void Function(GuideItineraryItem) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
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
                  'Day $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
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

  final GuideItineraryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        title: Text(
          item.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
            if (item.estimatedCost != null)
              Text(
                '${item.costCurrency ?? 'USD'} ${item.estimatedCost!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    required this.guideId,
    required this.dayNumber,
    required this.onSave,
    this.existingItem,
  });

  final String guideId;
  final int dayNumber;
  final GuideItineraryItem? existingItem;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _costController = TextEditingController();
  String _category = 'other';
  String _currency = 'USD';
  bool _isSaving = false;

  static const _categories = [
    ('other', 'General', Icons.place_rounded),
    ('activity', 'Activity', Icons.local_activity_rounded),
    ('food', 'Food', Icons.restaurant_rounded),
    ('transport', 'Transport', Icons.directions_rounded),
    ('accommodation', 'Stay', Icons.hotel_rounded),
  ];

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _titleController.text = item.title;
      _descController.text = item.description ?? '';
      _locationController.text = item.locationName ?? '';
      _costController.text = item.estimatedCost?.toStringAsFixed(0) ?? '';
      _category = item.category;
      _currency = item.costCurrency ?? 'USD';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              isEditing ? 'Edit Item' : 'Add Item — Day ${widget.dayNumber}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                      selectedColor: AppColors.primaryLight.withValues(
                        alpha: 0.2,
                      ),
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

            // Cost
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costController,
                    decoration: _inputDec('Estimated cost'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currency,
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                    borderRadius: BorderRadius.circular(10),
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
      final cost = double.tryParse(_costController.text.trim());

      await widget.onSave({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'locationName': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'category': _category,
        'estimatedCost': cost,
        'costCurrency': cost != null ? _currency : null,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              'Add day-by-day activities to help travelers plan their trip.',
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
