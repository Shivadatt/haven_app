import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart' show BackendStatus, BackendReadiness;
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/constants/haven_config.dart';

/// What Haven does, what it refuses to do, and what this particular build is
/// actually connected to — so a parent is never told "you're protected" when the
/// data backend has not been approved yet.
final class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.config});

  /// Injectable for tests; read from the app's own bindings otherwise.
  final HavenConfig? config;

  static const _promises = [
    'Haven does not hide itself on your child’s phone. It is visible there, '
        'with what it watches explained on this app’s setup screen.',
    'A restriction is only reported as applied once the device confirms it. '
        'Until then Haven says it is waiting.',
    'Location comes from your child’s device while its Haven app is running. '
        'This build makes no promise about background updates.',
    'No number on any Haven screen is an example, an estimate or a guess. If '
        'Haven cannot read something, it says so instead of filling the space.',
  ];

  @override
  Widget build(BuildContext context) {
    final HavenConfig? cfg = Get.isRegistered<HavenConfig>()
        ? Get.find<HavenConfig>()
        : config;
    return HavenScaffold(
      title: 'About Haven',
      body: HavenPageBody(
        // Eager, like the account page: this is four fixed sections, and a
        // lazily built list is a section that does not exist until it is seen.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'What Haven is',
                child: Text(
                  'Haven is a parental-control app for one family. A parent sets '
                  'time limits and app blocks, sees which apps a child used, and '
                  'gets told when the child arrives at or leaves a place you '
                  'marked as safe.',
                  style: HavenText.body,
                ),
              ),
              const SizedBox(height: HavenSpacing.md),
              SectionCard(
                title: 'What Haven promises',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final String promise in _promises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(
                              child: Text(promise, style: HavenText.body),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: HavenSpacing.md),
              _Connectivity(cfg),
            ],
          ),
        ),
      ),
    );
  }
}

/// The connection state, in the app's own words. Values are non-secret
/// identifiers; nothing here prints a key, even a publishable one.
class _Connectivity extends StatelessWidget {
  const _Connectivity(this.config);

  final HavenConfig? config;

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return const SectionCard(
        title: 'This build',
        child: Text('Haven has not been given any build configuration.'),
      );
    }
    final BackendStatus status = config!.status;
    final List<String> missing = config!.missingDefines();
    return SectionCard(
      title: 'This build',
      subtitle: '${config!.channel} channel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: switch (status.readiness) {
              BackendReadiness.notConfigured => 'Not connected',
              BackendReadiness.supabaseOnly => 'Data only',
              BackendReadiness.firebaseOnly => 'Messaging only',
              BackendReadiness.configured => 'Connected to staging',
            },
            tone: status.readiness == BackendReadiness.configured
                ? StatusTone.good
                : StatusTone.blocked,
          ),
          const SizedBox(height: HavenSpacing.md),
          Text(status.message, style: HavenText.body),
          if (status.projectRef != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Staging project: ${status.projectRef}',
              style: HavenText.caption,
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Build values still missing: ${missing.join(', ')}',
              style: HavenText.caption,
            ),
          ],
          const SizedBox(height: HavenSpacing.md),
          Text(
            'Haven is built against the staging contract captured in the '
            'source repository. Production is never contacted by this app.',
            style: HavenText.caption,
          ),
        ],
      ),
    );
  }
}
