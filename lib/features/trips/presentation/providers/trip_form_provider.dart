import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../data/trip_itinerary_repository.dart';
import '../../data/trip_repository.dart';

part 'trip_form_provider.g.dart';

// ─── Form State ───────────────────────────────────────────────────────────────

/// Holds all editable fields for a trip create/edit form.
@immutable
class TripFormState {
  const TripFormState({
    this.title = '',
    this.description = '',
    this.destination = '',
    this.coverImageUrl,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.status = 'upcoming',
    this.isSaving = false,
    this.errorMessage,
  });

  final String title;
  final String description;
  final String destination;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final bool isSaving;
  final String? errorMessage;

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      destination.trim().isNotEmpty &&
      startDate != null &&
      endDate != null &&
      endDate!.isAfter(startDate!);

  TripFormState copyWith({
    String? title,
    String? description,
    String? destination,
    String? coverImageUrl,
    double? latitude,
    double? longitude,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool clearCoverImage = false,
  }) {
    return TripFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      coverImageUrl: clearCoverImage
          ? null
          : (coverImageUrl ?? this.coverImageUrl),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Manages the create/edit trip form.
/// Pass [tripId] to edit an existing trip; null to create a new one.
@riverpod
class TripForm extends _$TripForm {
  @override
  TripFormState build(String? tripId) {
    // If editing, load existing trip data asynchronously
    if (tripId != null) {
      // Schedule the load to happen after build
      Future.microtask(() => _loadExistingTrip(tripId));
    }
    return const TripFormState();
  }

  Future<void> _loadExistingTrip(String tripId) async {
    final repo = ref.read(tripRepositoryProvider);
    final trip = await repo.getTrip(tripId);
    if (trip == null) return;

    state = TripFormState(
      title: trip.title,
      description: trip.description ?? '',
      destination: trip.destination,
      coverImageUrl: trip.coverImageUrl,
      latitude: trip.latitude,
      longitude: trip.longitude,
      startDate: trip.startDate,
      endDate: trip.endDate,
      status: trip.status,
    );
  }

  void updateTitle(String value) =>
      state = state.copyWith(title: value, clearError: true);

  void updateDescription(String value) =>
      state = state.copyWith(description: value, clearError: true);

  void updateDestination(String value) =>
      state = state.copyWith(destination: value, clearError: true);

  void updateCoverImageUrl(String? url) => state = url == null
      ? state.copyWith(clearCoverImage: true)
      : state.copyWith(coverImageUrl: url);

  void updateLocation(double lat, double lng) =>
      state = state.copyWith(latitude: lat, longitude: lng);

  void updateStartDate(DateTime date) =>
      state = state.copyWith(startDate: date, clearError: true);

  void updateEndDate(DateTime date) =>
      state = state.copyWith(endDate: date, clearError: true);

  void updateStatus(String status) => state = state.copyWith(status: status);

  /// Save trip (create or update).
  Future<String?> save() async {
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
      if (currentUser == null)
        throw AuthException(
          errorType: AuthErrorType.unknown,
          userMessage: 'Not authenticated',
        );

      final repo = ref.read(tripRepositoryProvider);

      if (tripId != null) {
        // Update existing trip
        await repo.updateTrip(
          tripId: tripId!,
          title: state.title.trim(),
          description: state.description.trim(),
          destination: state.destination.trim(),
          startDate: state.startDate,
          endDate: state.endDate,
          coverImageUrl: state.coverImageUrl,
          latitude: state.latitude,
          longitude: state.longitude,
          status: state.status,
        );
        state = state.copyWith(isSaving: false);
        return tripId;
      } else {
        // Create new trip
        final trip = await repo.createTrip(
          ownerId: currentUser.id,
          title: state.title.trim(),
          description: state.description.trim(),
          destination: state.destination.trim(),
          startDate: state.startDate!,
          endDate: state.endDate!,
          coverImageUrl: state.coverImageUrl,
          latitude: state.latitude,
          longitude: state.longitude,
          status: state.status,
        );
        state = state.copyWith(isSaving: false);
        return trip.id;
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

  /// Delete the trip.
  Future<bool> delete() async {
    if (tripId == null) return false;

    try {
      final repo = ref.read(tripRepositoryProvider);
      await repo.deleteTrip(tripId!);
      return true;
    } catch (e) {
      final appError = e is AppException ? e : convertException(e);
      state = state.copyWith(errorMessage: appError.userMessage);
      return false;
    }
  }
}

// ─── Itinerary Form ───────────────────────────────────────────────────────────

/// Manages itinerary item creation/editing within a trip.
@riverpod
class TripItineraryForm extends _$TripItineraryForm {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addItem({
    required String tripId,
    required String createdBy,
    required String title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    String category = 'other',
    int sortOrder = 0,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripItineraryRepositoryProvider);
      await repo.addItineraryItem(
        tripId: tripId,
        createdBy: createdBy,
        title: title,
        description: description,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        scheduledDate: scheduledDate,
        startTime: startTime,
        endTime: endTime,
        category: category,
        sortOrder: sortOrder,
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
    DateTime? scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripItineraryRepositoryProvider);
      await repo.updateItineraryItem(
        itemId: itemId,
        title: title,
        description: description,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        scheduledDate: scheduledDate,
        startTime: startTime,
        endTime: endTime,
        category: category,
        sortOrder: sortOrder,
      );
    });
  }

  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripItineraryRepositoryProvider);
      await repo.deleteItineraryItem(itemId);
    });
  }

  Future<void> reorderItems(
    String tripId,
    DateTime date,
    List<String> itemIds,
  ) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tripItineraryRepositoryProvider);
      await repo.reorderItems(tripId, date, itemIds);
    });
  }
}
