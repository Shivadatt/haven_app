import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/permissions/area_reading.dart';
import 'package:haven_app/core/permissions/device_state_decoding.dart';
import 'package:haven_app/core/permissions/permission_and_monitoring_states.dart';

/// These tests are the record of what a garbled or withheld answer becomes.
///
/// The channel delivers `Map<Object?, Object?>` and any value in it may be missing,
/// so the rule under test everywhere below is the one the card depends on: a value
/// that is not there is read as "the phone did not say", never coerced into `false`
/// or `0`, which would put a confident refusal on screen that no OS ever gave.
void main() {
  test(
    'a permission answer of the wrong shape is not turned into a refusal',
    () {
      final PermissionStates states = decodePermissionStates(<String, Object?>{
        'granted': <Object?, Object?>{
          'notifications': 'yes',
          'microphone': 1,
          'camera': false,
        },
        'undeclared': <Object?>['locationInUse'],
        'declaredPermissions': <Object?>['INTERNET'],
      });

      expect(
        states.answerFor('notifications'),
        PermissionAnswer.noSuchQuestion,
      );
      expect(states.answerFor('microphone'), PermissionAnswer.noSuchQuestion);
      expect(states.answerFor('camera'), PermissionAnswer.notAllowed);
      expect(
        states.answerFor('locationInUse'),
        PermissionAnswer.notDeclaredInThisBuild,
      );
      expect(states.declaredPermissions, <String>['INTERNET']);
      expect(
        states.askableKeys,
        unorderedEquals(<String>['notifications', 'microphone', 'camera']),
      );
    },
  );

  test('monitoring keeps the app-ops mode next to the yes-or-no', () {
    final MonitoringStates ignored = decodeMonitoringStates(<String, Object?>{
      'usageAccess': false,
      'usageAccessMode': 'ignored',
      'runningServices': <String, Object?>{'count': 4, 'withForegroundType': 1},
    });
    expect(ignored.usageAccessKnown, isTrue);
    expect(
      ignored.usageLine,
      'Usage access: not allowed (the phone answers: ignored).',
    );
    expect(ignored.backgroundLine, contains('4 services are declared'));
    expect(
      ignored.backgroundLine,
      contains('1 of them with a foreground type'),
    );

    // No mode at all means the app-ops service would not answer, which is a
    // different fact from it answering "not allowed".
    final MonitoringStates refused = decodeMonitoringStates(
      <String, Object?>{},
    );
    expect(refused.usageAccessMode, 'refused');
    expect(refused.usageAccessKnown, isFalse);
    expect(refused.backgroundLine, isNull);
    expect(refused.notificationImportance, isNull);
    expect(refused.exactAlarmsAllowed, isNull);
    expect(refused.batteryOptimizationIgnored, isNull);
  });

  test('media names hardware and grants apart, without implying capture', () {
    expect(
      decodeCommunicationStates(<String, Object?>{
        'inputDevices': 2,
        'camerasPresent': 1,
        'microphoneAllowed': false,
        'cameraAllowed': null,
      }).mediaLine,
      'Microphone is not allowed, camera cannot be asked in this build; '
      '2 audio input(s) and 1 camera(s) are present.',
    );
    expect(
      decodeCommunicationStates(<String, Object?>{}).mediaLine,
      contains('the phone would not say what audio inputs or cameras it has'),
    );
    expect(
      decodeCommunicationStates(<String, Object?>{
        'audioMode': 'in-call',
        'speakerphoneOn': true,
      }).audioMode,
      'in-call',
    );
  });

  group("one area is either an answer or the phone's reason", () {
    const Map<String, Object?> sections = <String, Object?>{
      'permissions': <String, Object?>{'granted': <String, Object?>{}},
    };
    const Map<String, Object?> errors = <String, Object?>{
      'monitoring': 'section-failed',
    };

    test('a section reported as failed keeps the phone\'s reason', () {
      final AreaReading<MonitoringStates> area = areaReading<MonitoringStates>(
        'monitoring',
        sections,
        errors,
        decodeMonitoringStates,
      );

      expect(area, isA<RefusedArea<MonitoringStates>>());
      expect((area as RefusedArea<MonitoringStates>).reason, 'section-failed');
      expect(area.valueOrNull, isNull);
    });

    test('a section that arrived empty is refused, not shown as dashes', () {
      final AreaReading<PermissionStates> area = areaReading<PermissionStates>(
        'permissions',
        <String, Object?>{},
        <String, Object?>{},
        decodePermissionStates,
      );

      expect((area as RefusedArea<PermissionStates>).reason, 'no-answer');
    });

    test('a section that arrived is decoded', () {
      final AreaReading<PermissionStates> area = areaReading<PermissionStates>(
        'permissions',
        sections,
        errors,
        decodePermissionStates,
      );

      expect(area, isA<AnsweredArea<PermissionStates>>());
      expect(area.valueOrNull, isA<PermissionStates>());
    });

    test('the envelope is read the way the channel delivers it', () {
      final (Map<String, Object?> s, Map<String, Object?> e) = sectionMaps(
        <Object?, Object?>{
          'sections': <Object?, Object?>{
            'location': <Object?, Object?>{'gpsOn': true},
          },
          'sectionErrors': <Object?, Object?>{'media': 'section-failed'},
        },
      );

      expect(s['location'], isNotNull);
      expect(e['media'], 'section-failed');
      expect(sectionMaps(null).$1, isEmpty);
      expect(sectionMaps('a string is not an envelope').$2, isEmpty);
    });
  });
}
