// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for guide data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.

@ProviderFor(guideRepository)
final guideRepositoryProvider = GuideRepositoryProvider._();

/// Repository for guide data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.

final class GuideRepositoryProvider
    extends
        $FunctionalProvider<GuideRepository, GuideRepository, GuideRepository>
    with $Provider<GuideRepository> {
  /// Repository for guide data sync between Firebase Firestore and local Drift DB.
  /// Implements offline-first pattern: write to Drift immediately, sync to Firestore.
  GuideRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideRepositoryHash();

  @$internal
  @override
  $ProviderElement<GuideRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GuideRepository create(Ref ref) {
    return guideRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideRepository>(value),
    );
  }
}

String _$guideRepositoryHash() => r'121b38a3452bd47181510b88d3cdf5b43e70525a';
