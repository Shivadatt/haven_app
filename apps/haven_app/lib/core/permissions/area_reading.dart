/// One area of the device lane, and whether the phone answered for it.
///
/// `refused` is not `answered(null)`. The operating system staying silent about,
/// say, its encryption state is a fact a parent is entitled to see, and folding it
/// into "no answer" would let a screen render a blank row where the truth is that
/// the phone will not tell an app that is not a device admin.
sealed class AreaReading<T extends Object> {
  const AreaReading();

  const factory AreaReading.answered(T value) = AnsweredArea<T>;

  const factory AreaReading.refused(String reason) = RefusedArea<T>;

  /// The answer, when there is one — for callers that only read what came back.
  T? get valueOrNull => switch (this) {
    AnsweredArea<T>(:final value) => value,
    RefusedArea<T>() => null,
  };
}

final class AnsweredArea<T extends Object> extends AreaReading<T> {
  const AnsweredArea(this.value);

  final T value;
}

final class RefusedArea<T extends Object> extends AreaReading<T> {
  const RefusedArea(this.reason);

  /// Why the phone would not say, in the phone's own terms.
  final String reason;
}
