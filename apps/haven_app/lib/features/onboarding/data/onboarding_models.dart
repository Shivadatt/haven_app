/// Progressive multi-step onboarding wizard steps.
enum OnboardingStep {
  explain('explain'),
  setup('setup'),
  child('child'),
  device('device');

  const OnboardingStep(this.wire);
  final String wire;

  static OnboardingStep? fromWire(String? value) => switch (value) {
    'explain' || 'ethics' || '1' => OnboardingStep.explain,
    'setup' || 'family' || '2' => OnboardingStep.setup,
    'child' || '3' => OnboardingStep.child,
    'device' || '4' => OnboardingStep.device,
    _ => null,
  };
}

/// Age groups available when setting up a child profile during onboarding.
enum ChildAgeGroup {
  toddler('toddler', 'Toddler (2–5)', 'Ages 2 to 5'),
  child('child', 'Child (6–12)', 'Ages 6 to 12'),
  teen('teen', 'Teen (13–17)', 'Ages 13 to 17');

  const ChildAgeGroup(this.key, this.label, this.description);
  final String key;
  final String label;
  final String description;

  static ChildAgeGroup fromKey(String? key) => switch (key) {
    'toddler' => ChildAgeGroup.toddler,
    'teen' => ChildAgeGroup.teen,
    _ => ChildAgeGroup.child,
  };
}

/// Animal avatar options for children, represented as friendly emojis.
enum ChildAvatar {
  bear('bear', '🐻', 'Bear'),
  fox('fox', '🦊', 'Fox'),
  owl('owl', '🦉', 'Owl'),
  rabbit('rabbit', '🐰', 'Rabbit'),
  panda('panda', '🐼', 'Panda'),
  lion('lion', '🦁', 'Lion');

  const ChildAvatar(this.key, this.emoji, this.label);
  final String key;
  final String emoji;
  final String label;

  static ChildAvatar fromKey(String? key) => switch (key) {
    'fox' => ChildAvatar.fox,
    'owl' => ChildAvatar.owl,
    'rabbit' => ChildAvatar.rabbit,
    'panda' => ChildAvatar.panda,
    'lion' => ChildAvatar.lion,
    _ => ChildAvatar.bear,
  };
}
