import 'package:flutter_test/flutter_test.dart';
import 'package:sense_guard/core/adapt.dart';

void main() {
  group('adapt — profile needs', () {
    test('low vision increases text scale and contrast', () {
      final a = adapt(const Profile({Need.lowVision: 1.0}), Conditions.neutral);
      expect(a.textScale, greaterThan(1.3));
      expect(a.contrast, greaterThan(0.5));
      expect(a.reasons, isNotEmpty);
    });

    test('motor tremor enlarges tap targets and reduces motion', () {
      final a = adapt(const Profile({Need.motorTremor: 0.8}), Conditions.neutral);
      expect(a.tapTargetScale, greaterThan(1.3));
      expect(a.reduceMotion, isTrue);
    });

    test('cognitive load simplifies language', () {
      final a = adapt(const Profile({Need.cognitiveLoad: 0.7}), Conditions.neutral);
      expect(a.simplifyLanguage, isTrue);
    });

    test('photosensitive always reduces motion', () {
      final a = adapt(const Profile({Need.photosensitive: 0.3}), Conditions.neutral);
      expect(a.reduceMotion, isTrue);
    });

    test('no needs and neutral conditions → standard layout', () {
      final a = adapt(Profile.none, Conditions.neutral);
      expect(a.textScale, 1.0);
      expect(a.simplifyLanguage, isFalse);
      expect(a.reasons.single, contains('Standard'));
    });
  });

  group('adapt — combining dimensions', () {
    test('multiple needs compound but stay within bounds', () {
      final a = adapt(const Profile({Need.lowVision: 1.0, Need.motorTremor: 1.0, Need.cognitiveLoad: 1.0}), Conditions.neutral);
      expect(a.textScale, inInclusiveRange(1.0, 2.0));
      expect(a.contrast, inInclusiveRange(0.0, 1.0));
      expect(a.spacing, inInclusiveRange(1.0, 1.8));
      expect(a.tapTargetScale, inInclusiveRange(1.0, 1.8));
      expect(a.reasons.length, greaterThanOrEqualTo(3));
    });

    test('bright ambient light boosts contrast on top of the profile', () {
      final base = adapt(const Profile({Need.lowVision: 0.4}), Conditions.neutral);
      final bright = adapt(const Profile({Need.lowVision: 0.4}), const Conditions(ambientLight: 0.9));
      expect(bright.contrast, greaterThan(base.contrast));
    });

    test('device shake enlarges targets and reduces motion', () {
      final a = adapt(Profile.none, const Conditions(deviceShake: 0.8));
      expect(a.tapTargetScale, greaterThan(1.0));
      expect(a.reduceMotion, isTrue);
    });

    test('is deterministic', () {
      const p = Profile({Need.dyslexia: 0.6});
      const c = Conditions(readingDifficulty: 0.6);
      final a = adapt(p, c);
      final b = adapt(p, c);
      expect(a.textScale, b.textScale);
      expect(a.reasons, b.reasons);
    });
  });

  group('simplifyText', () {
    test('swaps complex words when simplify is on', () {
      expect(simplifyText('Please utilize this to commence', true), 'Please use this to start');
    });

    test('leaves text unchanged when simplify is off', () {
      expect(simplifyText('Please utilize this', false), 'Please utilize this');
    });
  });
}
