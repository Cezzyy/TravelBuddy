// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_itinerary_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for guide itinerary items.

@ProviderFor(guideItineraryRepository)
final guideItineraryRepositoryProvider = GuideItineraryRepositoryProvider._();

/// Repository for guide itinerary items.

final class GuideItineraryRepositoryProvider
    extends
        $FunctionalProvider<
          GuideItineraryRepository,
          GuideItineraryRepository,
          GuideItineraryRepository
        >
    with $Provider<GuideItineraryRepository> {
  /// Repository for guide itinerary items.
  GuideItineraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideItineraryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideItineraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<GuideItineraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GuideItineraryRepository create(Ref ref) {
    return guideItineraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideItineraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideItineraryRepository>(value),
    );
  }
}

String _$guideItineraryRepositoryHash() =>
    r'5f9869093577d7d67908274cd085377412c4d990';
