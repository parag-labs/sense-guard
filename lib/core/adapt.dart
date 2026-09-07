/// The adaptive-accessibility engine — the deterministic core of SenseGuard. It combines an
/// accessibility [Profile] (the user's stated needs) with live [Conditions] (ambient light,
/// motion/shakiness, reading difficulty) and produces a [UiAdaptation] describing how to transform
/// the interface: text scale, contrast, spacing, tap-target size, motion reduction, and language
/// simplification. Each adaptation carries a plain-language reason. Pure Dart, so it is
/// unit-testable and reproducible.
library;

/// The accessibility needs a user can turn on. Multiple can apply at once.
enum Need { lowVision, motorTremor, cognitiveLoad, dyslexia, photosensitive }

/// The user's profile: which needs are active and how strongly (0..1).
class Profile {
  const Profile(this.needs);

  /// Need → strength in [0, 1].
  final Map<Need, double> needs;

  double strength(Need n) => (needs[n] ?? 0).clamp(0.0, 1.0);

  static const none = Profile({});
}

/// Live conditions the device can sense.
class Conditions {
  const Conditions({this.ambientLight = 0.5, this.deviceShake = 0.0, this.readingDifficulty = 0.0});

  /// 0 = dark room, 1 = bright/glare.
  final double ambientLight;

  /// 0 = steady, 1 = very shaky (walking, tremor, vehicle).
  final double deviceShake;

  /// 0 = reading smoothly, 1 = struggling (long dwell, re-reads).
  final double readingDifficulty;

  static const neutral = Conditions();
}

/// The concrete UI transformation to apply.
class UiAdaptation {
  const UiAdaptation({
    required this.textScale,
    required this.contrast,
    required this.spacing,
    required this.tapTargetScale,
    required this.reduceMotion,
    required this.simplifyLanguage,
    required this.reasons,
  });

  /// Multiplier on base font size, e.g. 1.0 .. 1.8.
  final double textScale;

  /// 0 = normal, 1 = maximum contrast.
  final double contrast;

  /// Multiplier on base spacing/line-height, e.g. 1.0 .. 1.6.
  final double spacing;

  /// Multiplier on minimum tap-target size, e.g. 1.0 .. 1.6.
  final double tapTargetScale;

  final bool reduceMotion;
  final bool simplifyLanguage;

  /// Plain-language explanations of every change made — always shown to the user.
  final List<String> reasons;
}

double _clamp(double v, double lo, double hi) => v.clamp(lo, hi).toDouble();

/// Compute the adaptation from a profile and live conditions. Deterministic and total. Effects
/// are additive and clamped, and each contributing factor adds a human-readable reason.
UiAdaptation adapt(Profile profile, Conditions conditions) {
  var textScale = 1.0;
  var contrast = 0.15;
  var spacing = 1.0;
  var tapTarget = 1.0;
  var reduceMotion = false;
  var simplify = false;
  final reasons = <String>[];

  // Low vision → larger text and higher contrast.
  final lv = profile.strength(Need.lowVision);
  if (lv > 0) {
    textScale += lv * 0.6;
    contrast += lv * 0.6;
    reasons.add('Larger text and higher contrast for low-vision comfort.');
  }

  // Motor tremor → bigger tap targets, more spacing, reduced motion.
  final mt = profile.strength(Need.motorTremor);
  if (mt > 0) {
    tapTarget += mt * 0.6;
    spacing += mt * 0.3;
    reduceMotion = reduceMotion || mt >= 0.4;
    reasons.add('Bigger, more spaced controls that are easier to hit.');
  }

  // Cognitive load → simplified language, more spacing, less motion.
  final cl = profile.strength(Need.cognitiveLoad);
  if (cl > 0) {
    simplify = simplify || cl >= 0.4;
    spacing += cl * 0.4;
    reduceMotion = reduceMotion || cl >= 0.5;
    reasons.add('Simpler wording and calmer layout to reduce load.');
  }

  // Dyslexia → more spacing and simplified language.
  final dx = profile.strength(Need.dyslexia);
  if (dx > 0) {
    spacing += dx * 0.4;
    textScale += dx * 0.15;
    simplify = simplify || dx >= 0.5;
    reasons.add('Extra letter/line spacing to aid reading.');
  }

  // Photosensitive → reduce motion.
  final ph = profile.strength(Need.photosensitive);
  if (ph > 0) {
    reduceMotion = true;
    reasons.add('Animations reduced to avoid discomfort.');
  }

  // Live conditions layer on top of the profile.
  if (conditions.ambientLight >= 0.7) {
    contrast += 0.25;
    reasons.add('Boosted contrast for bright surroundings.');
  }
  if (conditions.deviceShake >= 0.5) {
    tapTarget += 0.25;
    reduceMotion = true;
    reasons.add('Larger targets and less motion while you\'re moving.');
  }
  if (conditions.readingDifficulty >= 0.5) {
    textScale += 0.15;
    spacing += 0.2;
    simplify = true;
    reasons.add('Adjusted for easier reading right now.');
  }

  return UiAdaptation(
    textScale: _clamp(textScale, 1.0, 2.0),
    contrast: _clamp(contrast, 0.0, 1.0),
    spacing: _clamp(spacing, 1.0, 1.8),
    tapTargetScale: _clamp(tapTarget, 1.0, 1.8),
    reduceMotion: reduceMotion,
    simplifyLanguage: simplify,
    reasons: reasons.isEmpty ? const ['Standard layout — no adaptations needed.'] : reasons,
  );
}

/// A tiny language simplifier used by the demo: swaps a few complex phrases for plain ones when
/// [simplify] is on. Deterministic.
String simplifyText(String text, bool simplify) {
  if (!simplify) return text;
  const swaps = {
    'utilize': 'use',
    'commence': 'start',
    'terminate': 'end',
    'subsequently': 'then',
    'approximately': 'about',
    'sufficient': 'enough',
    'endeavour': 'try',
    'endeavor': 'try',
  };
  var out = text;
  swaps.forEach((k, v) {
    out = out.replaceAll(RegExp('\\b$k\\b', caseSensitive: false), v);
  });
  return out;
}
