import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme.dart';

/// Sizing only: this app never initializes or loads an advertisement.
class BannerPlaceholder extends StatefulWidget {
  const BannerPlaceholder({super.key});
  static const androidTestUnit = 'ca-app-pub-3940256099942544/9214589741';
  static const iosTestUnit = 'ca-app-pub-3940256099942544/2435281174';
  @override
  State<BannerPlaceholder> createState() => _BannerPlaceholderState();
}

class _BannerPlaceholderState extends State<BannerPlaceholder> {
  Future<AnchoredAdaptiveBannerAdSize?>? _size;
  int? _width;
  Orientation? _orientation;
  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();
          final orientation = MediaQuery.orientationOf(context);
          if (_width != width || _orientation != orientation) {
            _width = width;
            _orientation = orientation;
            _size = AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              width,
            ).catchError((Object _) => null);
          }
          return FutureBuilder<AnchoredAdaptiveBannerAdSize?>(
            future: _size,
            builder: (context, snapshot) => Container(
              width: width.toDouble(),
              height: snapshot.data?.height.toDouble() ?? 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.cream,
                border: Border.all(color: Palette.line),
              ),
              child: const Text(
                'Banner Ad Placeholder',
                style: TextStyle(fontSize: 12, color: Palette.muted),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HintButton extends StatelessWidget {
  const HintButton({
    super.key,
    this.advice =
        'Look for a row or column with only one empty tile. Solve that equation first, then follow its crossing.',
  });
  final String advice;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Hint',
    icon: const Icon(Icons.lightbulb_outline_rounded),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('A little nudge'),
        content: Text(
          '$advice\n\nExtra hints are coming soon. For now, take your time—there is no timer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    ),
  );
}
