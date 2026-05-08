// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for guide detail actions (like, comment, view tracking).

@ProviderFor(GuideDetailActions)
final guideDetailActionsProvider = GuideDetailActionsProvider._();

/// Notifier for guide detail actions (like, comment, view tracking).
final class GuideDetailActionsProvider
    extends $NotifierProvider<GuideDetailActions, AsyncValue<void>> {
  /// Notifier for guide detail actions (like, comment, view tracking).
  GuideDetailActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideDetailActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideDetailActionsHash();

  @$internal
  @override
  GuideDetailActions create() => GuideDetailActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$guideDetailActionsHash() =>
    r'3486f5fac5539317587fe54069faa24d08da3efb';

/// Notifier for guide detail actions (like, comment, view tracking).

abstract class _$GuideDetailActions extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
