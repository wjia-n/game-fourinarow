import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/arcade_themes.dart';
import '../theme/arcade_widgets.dart';
import '../theme/themed_widgets.dart';

/// Four in a Row PRO: Free-vs-Pro comparison, real purchase, restore,
/// and tip jar. All prices come from the store — never hardcoded,
/// never placeholders.
class ProScreen extends StatefulWidget {
  final F4Audio audio;
  final F4Settings settings;
  final F4Store store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  F4ArcadeThemeDef get _t => F4ArcadeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: F4Text.body.copyWith(color: _t.ivory)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return Scaffold(
      backgroundColor: t.woodDeep,
      body: F4WoodBackdrop(
        theme: t,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              t.accentLight,
                              t.accent,
                              t.accentDark
                            ],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.woodDeep,
                          ),
                          child: Icon(Icons.arrow_back,
                              color: t.accentLight, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ChromePlaque(
                        text: 'PRO', fontSize: 24, accent: t.accentDark),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: s,
                  builder: (_, _) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    child: Column(
                      children: [
                                                _TipsCard(
                          theme: t,
                          store: store,
                          audio: widget.audio,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.


// ---------------------------------------------------------------------------
class _TipsCard extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final F4Store store;
  final F4Audio audio;
  const _TipsCard({
    required this.theme,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.woodMid.withValues(alpha: 0.9),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('Tip the Maker',
              style: F4Text.headline(20, color: theme.ivory)),
          const SizedBox(height: 8),
          Text(
            'Four in a Row is free forever. A small tip keeps new games coming!',
            style: F4Text.body.copyWith(color: theme.ivory),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: F4Text.body.copyWith(
                  fontSize: 13,
                  color: theme.ivory.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: F4Text.body.copyWith(
                    fontSize: 13,
                    color: theme.ivory.withValues(alpha: 0.6)))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    theme: theme,
                    label:
                        '${p.id == F4Store.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _TipChip(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: F4Text.mono(14, color: theme.ivory)),
      ),
    );
  }
}
