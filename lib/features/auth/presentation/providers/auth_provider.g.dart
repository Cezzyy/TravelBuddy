// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current Firebase auth state (User or null).

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Provides the current Firebase auth state (User or null).

final class AuthStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<auth.User?>,
          auth.User?,
          Stream<auth.User?>
        >
    with $FutureModifier<auth.User?>, $StreamProvider<auth.User?> {
  /// Provides the current Firebase auth state (User or null).
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<auth.User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<auth.User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'1e51db4c750b03c60b5545719e64bd41f42daa4d';

/// Controller for email authentication actions.

@ProviderFor(EmailAuthController)
final emailAuthControllerProvider = EmailAuthControllerProvider._();

/// Controller for email authentication actions.
final class EmailAuthControllerProvider
    extends $AsyncNotifierProvider<EmailAuthController, void> {
  /// Controller for email authentication actions.
  EmailAuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emailAuthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emailAuthControllerHash();

  @$internal
  @override
  EmailAuthController create() => EmailAuthController();
}

String _$emailAuthControllerHash() =>
    r'db7dfa75f77591b67fffab2288aabe8274507cf8';

/// Controller for email authentication actions.

abstract class _$EmailAuthController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
