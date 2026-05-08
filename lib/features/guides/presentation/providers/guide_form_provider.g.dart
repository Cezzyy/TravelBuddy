// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the create/edit guide form.
/// Pass [guideId] to edit an existing guide; null to create a new one.

@ProviderFor(GuideForm)
final guideFormProvider = GuideFormFamily._();

/// Manages the create/edit guide form.
/// Pass [guideId] to edit an existing guide; null to create a new one.
final class GuideFormProvider
    extends $NotifierProvider<GuideForm, GuideFormState> {
  /// Manages the create/edit guide form.
  /// Pass [guideId] to edit an existing guide; null to create a new one.
  GuideFormProvider._({
    required GuideFormFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'guideFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$guideFormHash();

  @override
  String toString() {
    return r'guideFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GuideForm create() => GuideForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GuideFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$guideFormHash() => r'880065faddae0ec9396efef47f3d410abf55ad2a';

/// Manages the create/edit guide form.
/// Pass [guideId] to edit an existing guide; null to create a new one.

final class GuideFormFamily extends $Family
    with
        $ClassFamilyOverride<
          GuideForm,
          GuideFormState,
          GuideFormState,
          GuideFormState,
          String?
        > {
  GuideFormFamily._()
    : super(
        retry: null,
        name: r'guideFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the create/edit guide form.
  /// Pass [guideId] to edit an existing guide; null to create a new one.

  GuideFormProvider call(String? guideId) =>
      GuideFormProvider._(argument: guideId, from: this);

  @override
  String toString() => r'guideFormProvider';
}

/// Manages the create/edit guide form.
/// Pass [guideId] to edit an existing guide; null to create a new one.

abstract class _$GuideForm extends $Notifier<GuideFormState> {
  late final _$args = ref.$arg as String?;
  String? get guideId => _$args;

  GuideFormState build(String? guideId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GuideFormState, GuideFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GuideFormState, GuideFormState>,
              GuideFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Manages itinerary item creation/editing within a guide.

@ProviderFor(GuideItineraryForm)
final guideItineraryFormProvider = GuideItineraryFormProvider._();

/// Manages itinerary item creation/editing within a guide.
final class GuideItineraryFormProvider
    extends $NotifierProvider<GuideItineraryForm, AsyncValue<void>> {
  /// Manages itinerary item creation/editing within a guide.
  GuideItineraryFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideItineraryFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideItineraryFormHash();

  @$internal
  @override
  GuideItineraryForm create() => GuideItineraryForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$guideItineraryFormHash() =>
    r'6596292d124d6193c0c72f3a432be1a2a6e2378f';

/// Manages itinerary item creation/editing within a guide.

abstract class _$GuideItineraryForm extends $Notifier<AsyncValue<void>> {
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
