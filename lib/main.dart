import 'package:flutter/material.dart';
import 'core/adapt.dart';

void main() => runApp(const SenseGuardApp());

class SenseGuardApp extends StatelessWidget {
  const SenseGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SenseGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0A0C12)),
      home: const GuardScreen(),
    );
  }
}

const _needLabels = {
  Need.lowVision: 'Low vision',
  Need.motorTremor: 'Motor / tremor',
  Need.cognitiveLoad: 'Cognitive load',
  Need.dyslexia: 'Dyslexia',
  Need.photosensitive: 'Photosensitive',
};

class GuardScreen extends StatefulWidget {
  const GuardScreen({super.key});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  final Map<Need, double> _needs = {};
  double _light = 0.4;
  double _shake = 0.0;

  Profile get _profile => Profile(_needs);
  Conditions get _conditions => Conditions(ambientLight: _light, deviceShake: _shake);

  void _toggle(Need n) {
    setState(() {
      if ((_needs[n] ?? 0) > 0) {
        _needs.remove(n);
      } else {
        _needs[n] = 0.8;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = adapt(_profile, _conditions);
    const baseText = 15.0;
    final txt = baseText * a.textScale;
    final onColor = Color.lerp(const Color(0xFFC7CEDB), Colors.white, a.contrast)!;
    final cardBorder = Color.lerp(const Color(0x22FFFFFF), Colors.white, a.contrast * 0.5)!;
    final blurb = simplifyText(
      'We will utilize your preferences to commence a calmer layout. Subsequently the app adapts approximately in real time.',
      a.simplifyLanguage,
    );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SenseGuard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  const Text('The interface adapts to how you need it', style: TextStyle(color: Color(0xFF8891A6), fontSize: 12.5)),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: a.reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
                            padding: EdgeInsets.all(14 * a.spacing),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF141826),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your account', style: TextStyle(color: onColor, fontWeight: FontWeight.w700, fontSize: txt + 2, height: a.spacing)),
                                SizedBox(height: 8 * a.spacing),
                                Text(blurb, style: TextStyle(color: onColor, fontSize: txt, height: 1.3 * a.spacing)),
                                SizedBox(height: 12 * a.spacing),
                                _AdaptiveButton(label: 'Continue', scale: a.tapTargetScale, textSize: txt, contrast: a.contrast),
                                SizedBox(height: 8 * a.spacing),
                                _AdaptiveButton(label: 'Not now', scale: a.tapTargetScale, textSize: txt, contrast: a.contrast, ghost: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0x1134D9C8), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x3334D9C8))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [Icon(Icons.info_outline, size: 15, color: Color(0xFF34D9C8)), SizedBox(width: 6), Text('Why the UI changed', style: TextStyle(color: Color(0xFF34D9C8), fontSize: 12.5, fontWeight: FontWeight.w600))]),
                                const SizedBox(height: 6),
                                for (final r in a.reasons)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text('• $r', style: const TextStyle(color: Color(0xFFC7CEDB), fontSize: 12, height: 1.35)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in Need.values)
                        GestureDetector(
                          onTap: () => _toggle(n),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_needs[n] ?? 0) > 0 ? const Color(0x3334D9C8) : const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: (_needs[n] ?? 0) > 0 ? const Color(0xFF34D9C8) : const Color(0x22FFFFFF)),
                            ),
                            child: Text(_needLabels[n]!, style: TextStyle(color: (_needs[n] ?? 0) > 0 ? Colors.white : const Color(0xFF98A2B8), fontSize: 12.5)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _slider('Ambient light', _light, (v) => setState(() => _light = v)),
                  _slider('Movement', _shake, (v) => setState(() => _shake = v)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double v, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label, style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 12))),
        Expanded(child: Slider(value: v, activeColor: const Color(0xFF34D9C8), onChanged: onChanged)),
      ],
    );
  }
}

class _AdaptiveButton extends StatelessWidget {
  const _AdaptiveButton({required this.label, required this.scale, required this.textSize, required this.contrast, this.ghost = false});
  final String label;
  final double scale;
  final double textSize;
  final double contrast;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ghost ? Colors.transparent : Color.lerp(const Color(0xFF7C6CFF), Colors.white, contrast * 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ghost ? const Color(0x33FFFFFF) : Colors.transparent),
      ),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: textSize, fontWeight: FontWeight.w600)),
    );
  }
}
