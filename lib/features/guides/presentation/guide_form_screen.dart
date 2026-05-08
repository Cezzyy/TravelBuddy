import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import 'providers/guide_form_provider.dart';

/// Create or edit a guide.
/// Pass [guideId] to edit an existing guide; null to create a new one.
class GuideFormScreen extends ConsumerWidget {
  const GuideFormScreen({super.key, this.guideId});

  final String? guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = guideId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Guide' : 'Write a Guide',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          // Save draft button
          _SaveDraftButton(guideId: guideId),
          const SizedBox(width: 8),
        ],
      ),
      body: _GuideFormBody(guideId: guideId),
      bottomNavigationBar: _PublishBar(guideId: guideId),
    );
  }
}

// ─── Form Body ────────────────────────────────────────────────────────────────

class _GuideFormBody extends ConsumerStatefulWidget {
  const _GuideFormBody({this.guideId});

  final String? guideId;

  @override
  ConsumerState<_GuideFormBody> createState() => _GuideFormBodyState();
}

class _GuideFormBodyState extends ConsumerState<_GuideFormBody> {
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _destinationController = TextEditingController();
    _descriptionController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(guideFormProvider(widget.guideId));
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
    if (_contentController.text != formState.content) {
      _contentController.text = formState.content;
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
                    Icons.menu_book_rounded,
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
                        'Share Your Journey',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Help travelers discover amazing places',
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
            label: 'Title *',
            child: TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g. 3 Days in Kyoto'),
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15),
              onChanged: (v) => ref
                  .read(guideFormProvider(widget.guideId).notifier)
                  .updateTitle(v),
            ),
          ),
          const SizedBox(height: 18),

          // Destination
          _FormField(
            label: 'Destination *',
            child: TextFormField(
              controller: _destinationController,
              decoration: _inputDecoration('e.g. Kyoto, Japan'),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 15),
              onChanged: (v) => ref
                  .read(guideFormProvider(widget.guideId).notifier)
                  .updateDestination(v),
            ),
          ),
          const SizedBox(height: 18),

          // Description
          _FormField(
            label: 'Short Description *',
            hint: 'A brief summary shown in the guide card (max 300 chars)',
            child: TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(
                'What makes this guide special?',
              ),
              maxLength: 300,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 15, height: 1.5),
              onChanged: (v) => ref
                  .read(guideFormProvider(widget.guideId).notifier)
                  .updateDescription(v),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 28),

          // Tags Section
          _SectionHeader(
            icon: Icons.label_outline_rounded,
            title: 'Tags',
          ),
          const SizedBox(height: 12),
          _TagInput(guideId: widget.guideId),

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 28),

          // Content Section
          _SectionHeader(
            icon: Icons.article_outlined,
            title: 'Guide Content',
          ),
          const SizedBox(height: 12),
          Text(
            'Share your full story, tips, and recommendations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            decoration: _inputDecoration(
              'Write your guide here...\n\nShare your experiences, tips, must-visit places, and insider knowledge.',
            ),
            maxLines: 14,
            minLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 15, height: 1.6),
            onChanged: (v) => ref
                .read(guideFormProvider(widget.guideId).notifier)
                .updateContent(v),
          ),

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 28),

          // Itinerary Section
          _SectionHeader(
            icon: Icons.map_outlined,
            title: 'Itinerary',
          ),
          const SizedBox(height: 12),
          if (widget.guideId != null) ...[
            Text(
              'Add a day-by-day plan for travelers',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _ItineraryShortcut(guideId: widget.guideId!),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Save your guide as a draft first to add an itinerary.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error message
          Consumer(
            builder: (context, ref, _) {
              final error =
                  ref.watch(guideFormProvider(widget.guideId)).errorMessage;
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
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
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

// ─── Tag Input ────────────────────────────────────────────────────────────────

class _TagInput extends ConsumerStatefulWidget {
  const _TagInput({this.guideId});

  final String? guideId;

  @override
  ConsumerState<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends ConsumerState<_TagInput> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'beach', 'adventure', 'budget', 'luxury', 'family',
    'solo', 'food', 'culture', 'nature', 'city',
    'hiking', 'backpacking', 'weekend', 'road-trip', 'photography',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    ref.read(guideFormProvider(widget.guideId).notifier).addTag(tag);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(
      guideFormProvider(widget.guideId).select((s) => s.tags),
    );
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Helper text
        Text(
          'Add up to 10 tags to help travelers find your guide',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Current tags
        if (tags.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text('#$tag'),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.15),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      deleteIconColor: AppColors.primary,
                      onDeleted: () => ref
                          .read(guideFormProvider(widget.guideId).notifier)
                          .removeTag(tag),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (tags.length < 10) ...[
          // Tag input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) _addTag(v.trim());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      _addTag(_controller.text.trim());
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  color: Colors.white,
                  tooltip: 'Add tag',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Suggestions
          Text(
            'Suggestions:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .where((s) => !tags.contains(s))
                .take(10)
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _addTag(s),
                    backgroundColor: AppColors.surfaceVariant,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Maximum of 10 tags reached',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Itinerary Shortcut ───────────────────────────────────────────────────────

class _ItineraryShortcut extends StatelessWidget {
  const _ItineraryShortcut({required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            RoutePaths.guideItinerary.replaceFirst(':guideId', guideId),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Itinerary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add day-by-day activities',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form Field Wrapper ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.child,
    this.hint,
  });

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

// ─── Save Draft Button ────────────────────────────────────────────────────────

class _SaveDraftButton extends ConsumerWidget {
  const _SaveDraftButton({this.guideId});

  final String? guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(
      guideFormProvider(guideId).select((s) => s.isSaving),
    );

    return TextButton.icon(
      onPressed: isSaving ? null : () => _save(context, ref),
      icon: isSaving
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined, size: 18),
      label: const Text(
        'Save Draft',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final formState = ref.read(guideFormProvider(guideId));
    final savedId =
        await ref.read(guideFormProvider(guideId).notifier).saveDraft();
    if (!context.mounted) return;

    if (savedId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                formState.isEditingPublished
                    ? 'Draft saved successfully'
                    : 'Draft saved successfully',
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      // If this was a new guide, replace route with edit route
      // Use the saved ID (which is the draft ID)
      if (guideId == null) {
        context.pushReplacement(
          RoutePaths.guideEdit.replaceFirst(':guideId', savedId),
        );
      }
      // If editing published guide, we're already on the right route
      // The guideId in the URL should be the draft ID
    }
  }
}

// ─── Publish Bar ──────────────────────────────────────────────────────────────

class _PublishBar extends ConsumerWidget {
  const _PublishBar({this.guideId});

  final String? guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(guideFormProvider(guideId));

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
            // Draft editing info banner
            if (formState.isEditingPublished) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Editing draft version. Changes won\'t affect the published guide until applied.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                        'Fill in all required fields to publish',
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

            // Action buttons
            Row(
              children: [
                // Discard draft button (only for editing published)
                if (formState.isEditingPublished) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: formState.isPublishing
                          ? null
                          : () => _discardDraft(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Discard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Publish/Apply button
                Expanded(
                  flex: formState.isEditingPublished ? 2 : 1,
                  child: FilledButton.icon(
                    onPressed: formState.isPublishing || !formState.isValid
                        ? null
                        : () => _publish(context, ref),
                    icon: formState.isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            formState.isEditingPublished
                                ? Icons.check_circle_rounded
                                : Icons.publish_rounded,
                            size: 20,
                          ),
                    label: Text(
                      formState.isPublishing
                          ? 'Publishing...'
                          : formState.isEditingPublished
                              ? 'Apply Changes'
                              : 'Publish Guide',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: formState.isEditingPublished
                          ? AppColors.success
                          : AppColors.accent,
                      disabledBackgroundColor:
                          AppColors.textSecondary.withValues(alpha: 0.2),
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
          ],
        ),
      ),
    );
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    final formState = ref.read(guideFormProvider(guideId));
    final publishedId =
        await ref.read(guideFormProvider(guideId).notifier).publish();
    if (!context.mounted) return;

    if (publishedId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                formState.isEditingPublished
                    ? 'Changes applied successfully!'
                    : 'Guide published successfully!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      // Navigate to the published guide
      context.pushReplacement(
        RoutePaths.guideDetail.replaceFirst(':guideId', publishedId),
      );
    }
  }

  Future<void> _discardDraft(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Draft?'),
        content: const Text(
          'All changes will be lost and the published version will remain unchanged. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success =
        await ref.read(guideFormProvider(guideId).notifier).discardDraft();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft discarded'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Go back to the published guide
      final formState = ref.read(guideFormProvider(guideId));
      if (formState.publishedVersionId != null) {
        context.pushReplacement(
          RoutePaths.guideDetail
              .replaceFirst(':guideId', formState.publishedVersionId!),
        );
      } else {
        context.pop();
      }
    }
  }
}
