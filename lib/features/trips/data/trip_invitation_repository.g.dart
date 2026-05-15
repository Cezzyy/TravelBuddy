// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_invitation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripInvitationRepository)
final tripInvitationRepositoryProvider = TripInvitationRepositoryProvider._();

final class TripInvitationRepositoryProvider
    extends
        $FunctionalProvider<
          TripInvitationRepository,
          TripInvitationRepository,
          TripInvitationRepository
        >
    with $Provider<TripInvitationRepository> {
  TripInvitationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripInvitationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripInvitationRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripInvitationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripInvitationRepository create(Ref ref) {
    return tripInvitationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripInvitationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripInvitationRepository>(value),
    );
  }
}

String _$tripInvitationRepositoryHash() =>
    r'673c91569bf097bc289140a42c25911bb691b843';
