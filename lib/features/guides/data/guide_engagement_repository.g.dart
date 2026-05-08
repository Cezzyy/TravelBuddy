// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_engagement_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for guide engagement (likes and comments).

@ProviderFor(guideEngagementRepository)
final guideEngagementRepositoryProvider = GuideEngagementRepositoryProvider._();

/// Repository for guide engagement (likes and comments).

final class GuideEngagementRepositoryProvider
    extends
        $FunctionalProvider<
          GuideEngagementRepository,
          GuideEngagementRepository,
          GuideEngagementRepository
        >
    with $Provider<GuideEngagementRepository> {
  /// Repository for guide engagement (likes and comments).
  GuideEngagementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideEngagementRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideEngagementRepositoryHash();

  @$internal
  @override
  $ProviderElement<GuideEngagementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GuideEngagementRepository create(Ref ref) {
    return guideEngagementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideEngagementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideEngagementRepository>(value),
    );
  }
}

String _$guideEngagementRepositoryHash() =>
    r'477bc961fd9e1f510fecfeb38b771f6d82029be0';
