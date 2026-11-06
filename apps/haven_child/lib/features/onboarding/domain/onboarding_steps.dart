/// The five onboarding steps, in order (brief §4 C). The enum index IS the
/// persisted draft's `step_index`, so resume is one integer.
enum OnboardingStep {
  welcome('Welcome'),
  childProfile('About you'),
  deviceReview('This device'),
  permissionsIntro('Permissions'),
  finish('All set');

  const OnboardingStep(this.title);

  final String title;

  static const int count = 5;

  /// Out-of-range indices clamp instead of crashing: a draft from a future
  /// build must still land on a real step.
  static OnboardingStep fromIndex(int index) =>
      values[index.clamp(0, values.length - 1)];

  String get progressLabel => 'Step ${index + 1} of $count';

  bool get isLast => this == finish;
}
