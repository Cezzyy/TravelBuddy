// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_itinerary_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for trip itinerary items.

@ProviderFor(tripItineraryRepository)
final tripItineraryRepositoryProvider = TripItineraryRepositoryProvider._();

/// Repository for trip itinerary items.

final class TripItineraryRepositoryProvider
    extends
        $FunctionalProvider<
          TripItineraryRepository,
          TripItineraryRepository,
          TripItineraryRepository
        >
    with $Provider<TripItineraryRepository> {
  /// Repository for trip itinerary items.
  TripItineraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripItineraryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripItineraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripItineraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripItineraryRepository create(Ref ref) {
    return tripItineraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripItineraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripItineraryRepository>(value),
    );
  }
}

String _$tripItineraryRepositoryHash() =>
    r'a3ec8238859135b093a1df88ce750a00992ac206';
