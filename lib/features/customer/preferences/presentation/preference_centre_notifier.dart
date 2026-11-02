import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/data/preferences_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/domain/preference_centre.dart';

/// The preference centre screen's state.
class PreferenceCentreState {
  const PreferenceCentreState({
    this.centre,
    this.loading = true,
    this.error,
    this.context = 'self',
    this.saving = const {},
    this.saveError,
  });

  final PreferenceCentre? centre;
  final bool loading;
  final String? error;

  /// The shopper context being edited (self, gift, kids …).
  final String context;

  /// Keys with a write in flight.
  final Set<String> saving;
  final String? saveError;

  PreferenceCentreState copyWith({
    PreferenceCentre? centre,
    bool? loading,
    String? error,
    bool clearError = false,
    String? context,
    Set<String>? saving,
    String? saveError,
    bool clearSaveError = false,
  }) => PreferenceCentreState(
    centre: centre ?? this.centre,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    context: context ?? this.context,
    saving: saving ?? this.saving,
    saveError: clearSaveError ? null : (saveError ?? this.saveError),
  );
}

/// Loads the registry-driven preference centre and writes the shopper's
/// choices. Every write sets the full value set for the key in the current
/// context, for all departments (`*`).
class PreferenceCentreNotifier extends StateNotifier<PreferenceCentreState> {
  PreferenceCentreNotifier(this._repository)
    : super(const PreferenceCentreState());

  final PreferencesRepository _repository;

  static const String allDepartments = '*';

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final centre = await _repository.load();
      if (!mounted) return;
      state = state.copyWith(centre: centre, loading: false);
    } on Object catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: 'Your preferences could not be loaded.',
      );
    }
  }

  void selectContext(String context) =>
      state = state.copyWith(context: context, clearSaveError: true);

  /// Taps [value] on [dimension]: toggles it for a multi-valued key, picks
  /// (or un-picks) it for a single-valued one.
  Future<void> toggle(DeclarableDimension dimension, String value) {
    final selected = dimension.selectedIn(state.context);
    final Set<String> next;
    if (dimension.isMulti) {
      next = {...selected};
      if (!next.remove(value)) next.add(value);
    } else {
      next = selected.contains(value) ? <String>{} : {value};
    }
    return _write(dimension, next.toList());
  }

  Future<void> clear(DeclarableDimension dimension) =>
      _write(dimension, const [], viaDelete: true);

  Future<void> _write(
    DeclarableDimension dimension,
    List<String> values, {
    bool viaDelete = false,
  }) async {
    final centre = state.centre;
    if (centre == null || state.saving.contains(dimension.key)) return;
    final ctx = state.context;
    final keep = [
      for (final v in dimension.current)
        if (!(v.context == ctx && v.department == allDepartments)) v,
    ];
    final optimistic = dimension.withCurrent([
      ...keep,
      for (final v in values)
        DeclaredValue(department: allDepartments, context: ctx, value: v),
    ]);
    state = state.copyWith(
      centre: centre.replacing(optimistic),
      saving: {...state.saving, dimension.key},
      clearSaveError: true,
    );
    try {
      DeclarableDimension? confirmed;
      if (viaDelete || values.isEmpty) {
        await _repository.clear(
          key: dimension.key,
          department: allDepartments,
          context: ctx,
        );
      } else {
        confirmed = await _repository.put(
          key: dimension.key,
          department: allDepartments,
          context: ctx,
          values: values,
        );
      }
      if (!mounted) return;
      state = state.copyWith(
        centre: confirmed == null
            ? state.centre
            : state.centre!.replacing(confirmed),
        saving: {...state.saving}..remove(dimension.key),
      );
    } on Object catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        centre: state.centre!.replacing(dimension),
        saving: {...state.saving}..remove(dimension.key),
        saveError: 'That change could not be saved. Please try again.',
      );
    }
  }
}
