// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the create/edit trip form.
/// Pass [tripId] to edit an existing trip; null to create a new one.

@ProviderFor(TripForm)
final tripFormProvider = TripFormFamily._();

/// Manages the create/edit trip form.
/// Pass [tripId] to edit an existing trip; null to create a new one.
final class TripFormProvider
    extends $NotifierProvider<TripForm, TripFormState> {
  /// Manages the create/edit trip form.
  /// Pass [tripId] to edit an existing trip; null to create a new one.
  TripFormProvider._({
    required TripFormFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'tripFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripFormHash();

  @override
  String toString() {
    return r'tripFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TripForm create() => TripForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripFormHash() => r'0a7fa1865d790f85548519d7695faf12fe79d229';

/// Manages the create/edit trip form.
/// Pass [tripId] to edit an existing trip; null to create a new one.

final class TripFormFamily extends $Family
    with
        $ClassFamilyOverride<
          TripForm,
          TripFormState,
          TripFormState,
          TripFormState,
          String?
        > {
  TripFormFamily._()
    : super(
        retry: null,
        name: r'tripFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the create/edit trip form.
  /// Pass [tripId] to edit an existing trip; null to create a new one.

  TripFormProvider call(String? tripId) =>
      TripFormProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripFormProvider';
}

/// Manages the create/edit trip form.
/// Pass [tripId] to edit an existing trip; null to create a new one.

abstract class _$TripForm extends $Notifier<TripFormState> {
  late final _$args = ref.$arg as String?;
  String? get tripId => _$args;

  TripFormState build(String? tripId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TripFormState, TripFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TripFormState, TripFormState>,
              TripFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Manages itinerary item creation/editing within a trip.

@ProviderFor(TripItineraryForm)
final tripItineraryFormProvider = TripItineraryFormProvider._();

/// Manages itinerary item creation/editing within a trip.
final class TripItineraryFormProvider
    extends $NotifierProvider<TripItineraryForm, AsyncValue<void>> {
  /// Manages itinerary item creation/editing within a trip.
  TripItineraryFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripItineraryFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripItineraryFormHash();

  @$internal
  @override
  TripItineraryForm create() => TripItineraryForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$tripItineraryFormHash() => r'ef784903600fc015f598b7c5e9255a9263829cf0';

/// Manages itinerary item creation/editing within a trip.

abstract class _$TripItineraryForm extends $Notifier<AsyncValue<void>> {
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
