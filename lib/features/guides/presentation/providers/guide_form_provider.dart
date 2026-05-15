import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../data/guide_itinerary_repository.dart';
import '../../data/guide_repository.dart';

part 'guide_form_provider.g.dart';

// ─── Form State ───────────────────────────────────────────────────────────────

/// Holds all editable fields for a guide create/edit form.
@immutable
class GuideFormState {
  const GuideFormState({
    this.title = '',
    this.description = '',
    this.destination = '',
    this.content = '',
    this.coverImageUrl,
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.isSaving = false,
    this.isPublishing = false,
    this.errorMessage,
    this.isEditingPublished = false,
    this.publishedVersionId,
    this.hasDraftVersion = false,
  });

  final String title;
  final String description;
  final String destination;
  final String content;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final bool isSaving;
  final bool isPublishing;
  final String? errorMessage;

  /// True if editing a published guide (working on a draft version)
  final bool isEditingPublished;

  /// The ID of the published version (if this is a draft)
  final String? publishedVersionId;

  /// True if the published guide has a draft version
  final bool hasDraftVersion;

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      destination.trim().isNotEmpty;

  GuideFormState copyWith({
    String? title,
    String? description,
    String? destination,
    String? content,
    String? coverImageUrl,
    double? latitude,
    double? longitude,
    List<String>? tags,
    bool? isSaving,
    bool? isPublishing,
    String? errorMessage,
    bool? isEditingPublished,
    String? publishedVersionId,
    bool? hasDraftVersion,
    bool clearError = false,
    bool clearCoverImage = false,
  }) {
    return GuideFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      content: content ?? this.content,
      coverImageUrl: clearCoverImage
          ? null
          : (coverImageUrl ?? this.coverImageUrl),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      isSaving: isSaving ?? this.isSaving,
      isPublishing: isPublishing ?? this.isPublishing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isEditingPublished: isEditingPublished ?? this.isEditingPublished,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      hasDraftVersion: hasDraftVersion ?? this.hasDraftVersion,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Manages the create/edit guide form.
/// Pass [guideId] to edit an existing guide; null to create a new one.
@riverpod
class GuideForm extends _$GuideForm {
  @override
  GuideFormState build(String? guideId) {
    // If editing, load existing guide data asynchronously
    if (guideId != null) {
      // Schedule the load to happen after build
      Future.microtask(() => _loadExistingGuide(guideId));
    }
    return const GuideFormState();
  }

  Future<void> _loadExistingGuide(String guideId) async {
    final repo = ref.read(guideRepositoryProvider);
    final guide = await repo.getGuide(guideId);
    if (guide == null) return;

    // Parse tags from JSON string
    List<String> parsedTags = [];
    if (guide.tags != null && guide.tags!.isNotEmpty) {
      try {
        if (guide.tags!.startsWith('[')) {
          parsedTags = guide.tags!
              .substring(1, guide.tags!.length - 1)
              .split(',')
              .map((t) => t.trim().replaceAll('"', ''))
              .where((t) => t.isNotEmpty)
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing tags: $e');
      }
    }

    // Check if this guide is a draft of a published guide
    final isDraft = guide.publishedVersionId != null;

    state = GuideFormState(
      title: guide.title,
      description: guide.description,
      destination: guide.destination,
      content: guide.content,
      coverImageUrl: guide.coverImageUrl,
      latitude: guide.latitude,
      longitude: guide.longitude,
      tags: parsedTags,
      isEditingPublished: isDraft,
      publishedVersionId: guide.publishedVersionId,
      hasDraftVersion: guide.draftVersionId != null,
    );
  }

  void updateTitle(String value) =>
      state = state.copyWith(title: value, clearError: true);

  void updateDescription(String value) =>
      state = state.copyWith(description: value, clearError: true);

  void updateDestination(String value) =>
      state = state.copyWith(destination: value, clearError: true);

  void updateContent(String value) => state = state.copyWith(content: value);

  void updateCoverImageUrl(String? url) => state = url == null
      ? state.copyWith(clearCoverImage: true)
      : state.copyWith(coverImageUrl: url);

  void updateLocation(double lat, double lng) =>
      state = state.copyWith(latitude: lat, longitude: lng);

  void addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty || state.tags.contains(trimmed)) return;
    if (state.tags.length >= 10) return; // max 10 tags
    state = state.copyWith(tags: [...state.tags, trimmed]);
  }

  void removeTag(String tag) {
    state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());
  }

  /// Save as draft (create or update).
  Future<String?> saveDraft() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Please fill in all required fields',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      if (currentUser == null) {
        throw AuthException(
          errorType: AuthErrorType.unknown,
          userMessage: 'Not authenticated',
        );
      }

      final repo = ref.read(guideRepositoryProvider);

      if (guideId != null) {
        // Update existing guide (whether it's a draft or regular guide)
        await repo.updateGuide(
          guideId: guideId!,
          title: state.title.trim(),
          description: state.description.trim(),
          destination: state.destination.trim(),
          content: state.content,
          coverImageUrl: state.coverImageUrl,
          latitude: state.latitude,
          longitude: state.longitude,
          tags: state.tags,
        );
        state = state.copyWith(isSaving: false);
        return guideId;
      } else {
        // Create new guide as draft
        final guide = await repo.createGuide(
          authorId: currentUser.id,
          title: state.title.trim(),
          description: state.description.trim(),
          destination: state.destination.trim(),
          content: state.content,
          coverImageUrl: state.coverImageUrl,
          latitude: state.latitude,
          longitude: state.longitude,
          tags: state.tags,
        );
        state = state.copyWith(isSaving: false);
        return guide.id;
      }
    } catch (e) {
      final appError = e is AppException ? e : convertException(e);
      state = state.copyWith(
        isSaving: false,
        errorMessage: appError.userMessage,
      );
      return null;
    }
  }

  /// Save and publish the guide (or apply draft to published).
  Future<String?> publish() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Please fill in all required fields',
      );
      return null;
    }

    state = state.copyWith(isPublishing: true, clearError: true);

    try {
      final repo = ref.read(guideRepositoryProvider);

      // If editing a published guide (working on draft), apply draft to published
      if (state.isEditingPublished && state.publishedVersionId != null) {
        // First save current changes to draft
        if (guideId != null) {
          await repo.updateGuide(
            guideId: guideId!,
            title: state.title.trim(),
            description: state.description.trim(),
            destination: state.destination.trim(),
            content: state.content,
            coverImageUrl: state.coverImageUrl,
            latitude: state.latitude,
            longitude: state.longitude,
            tags: state.tags,
          );
        }

        // Apply draft to published
        await repo.applyDraftToPublished(guideId!);
        state = state.copyWith(isPublishing: false);
        return state.publishedVersionId;
      }

      // Regular publish flow for new guides or unpublished drafts
      String targetId;

      if (guideId != null) {
        // Update then publish
        await repo.updateGuide(
          guideId: guideId!,
          title: state.title.trim(),
          description: state.description.trim(),
          destination: state.destination.trim(),
          content: state.content,
          coverImageUrl: state.coverImageUrl,
          latitude: state.latitude,
          longitude: state.longitude,
          tags: state.tags,
        );
        targetId = guideId!;
      } else {
        // Create then publish
        final currentUserAsync = ref.read(currentUserProvider);
        final currentUser = currentUserAsync.value;
        if (currentUser == null) {
          throw AuthException(
            errorType: AuthErrorType.unknown,
            userMessage: 'Not authenticated',
          );
        }

        final guide = await repo.createGuide(
          authorId: currentUser.id,
          title: state.title.trim(),
          description: state.description.trim(),
          destination: state.destination.trim(),
          content: state.content,
          coverImageUrl: state.coverImageUrl,
          latitude: state.latitude,
          longitude: state.longitude,
          tags: state.tags,
        );
        targetId = guide.id;
      }

      await repo.publishGuide(targetId);
      state = state.copyWith(isPublishing: false);
      return targetId;
    } catch (e) {
      final appError = e is AppException ? e : convertException(e);
      state = state.copyWith(
        isPublishing: false,
        errorMessage: appError.userMessage,
      );
      return null;
    }
  }

  /// Discard draft changes and return to published version.
  Future<bool> discardDraft() async {
    if (!state.isEditingPublished || guideId == null) {
      return false;
    }

    try {
      final repo = ref.read(guideRepositoryProvider);
      await repo.discardDraft(guideId!);
      return true;
    } catch (e) {
      final appError = e is AppException ? e : convertException(e);
      state = state.copyWith(errorMessage: appError.userMessage);
      return false;
    }
  }
}

// ─── Itinerary Form ───────────────────────────────────────────────────────────

/// Manages itinerary item creation/editing within a guide.
@riverpod
class GuideItineraryForm extends _$GuideItineraryForm {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addItem({
    required String guideId,
    required String title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    required int dayNumber,
    DateTime? suggestedStartTime,
    DateTime? suggestedEndTime,
    String category = 'other',
    int sortOrder = 0,
    double? estimatedCost,
    String? costCurrency,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(guideItineraryRepositoryProvider);
      await repo.addItineraryItem(
        guideId: guideId,
        title: title,
        description: description,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        dayNumber: dayNumber,
        suggestedStartTime: suggestedStartTime,
        suggestedEndTime: suggestedEndTime,
        category: category,
        sortOrder: sortOrder,
        estimatedCost: estimatedCost,
        costCurrency: costCurrency,
      );
    });
  }

  Future<void> updateItem({
    required String itemId,
    String? title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    int? dayNumber,
    DateTime? suggestedStartTime,
    DateTime? suggestedEndTime,
    String? category,
    int? sortOrder,
    double? estimatedCost,
    String? costCurrency,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(guideItineraryRepositoryProvider);
      await repo.updateItineraryItem(
        itemId: itemId,
        title: title,
        description: description,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        dayNumber: dayNumber,
        suggestedStartTime: suggestedStartTime,
        suggestedEndTime: suggestedEndTime,
        category: category,
        sortOrder: sortOrder,
        estimatedCost: estimatedCost,
        costCurrency: costCurrency,
      );
    });
  }

  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(guideItineraryRepositoryProvider);
      await repo.deleteItineraryItem(itemId);
    });
  }

  Future<void> reorderItems(
    String guideId,
    int dayNumber,
    List<String> itemIds,
  ) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(guideItineraryRepositoryProvider);
      await repo.reorderItems(guideId, dayNumber, itemIds);
    });
  }
}
