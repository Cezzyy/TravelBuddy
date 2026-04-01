// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for user data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

/// Repository for user data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  /// Repository for user data sync between Firebase Firestore and local Drift DB.
  /// Implements offline-first pattern: write to Drift immediately, sync to Firestore.
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'edb9a78e7aa185e932571316d5e790033e345b36';
