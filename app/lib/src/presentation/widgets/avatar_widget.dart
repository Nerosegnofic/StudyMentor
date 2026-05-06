import 'package:flutter/material.dart';
import '../../data/catalog/avatar_items_catalog.dart';
import '../../domain/models/avatar_config.dart';

/// Renders a layered avatar using a Flutter Stack.
/// Each "layer" is a separate positioned widget: background → special effect →
/// body/outfit → face/head → hair → accessory.
/// All visuals use emoji + colored shapes — no image assets required.
class AvatarWidget extends StatelessWidget {
  final AvatarConfig config;
  final double size;

  const AvatarWidget({
    super.key,
    required this.config,
    this.size = 120,
  });

  // ── Background gradients per equipped background ID ───────────────────────
  static const Map<String?, List<Color>> _bgGradients = {
    null: [Color(0xFFE8EDFF), Color(0xFFD4DCFF)],
    'bg_default': [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
    'bg_sunset': [Color(0xFFFF8A65), Color(0xFFFFB74D)],
    'bg_ocean': [Color(0xFF26C6DA), Color(0xFF00838F)],
    'bg_cherry': [Color(0xFFFFB7C5), Color(0xFFFF8FAB)],
    'bg_space': [Color(0xFF1A237E), Color(0xFF4527A0)],
    'bg_neon': [Color(0xFF1A0E2A), Color(0xFF6A1B9A)],
    'bg_rainbow': [Color(0xFFFF6B9D), Color(0xFFC44DFF)],
    'bg_northern': [Color(0xFF0D1B2A), Color(0xFF1565C0)],
  };

  // ── Outfit color per equipped outfit ID ───────────────────────────────────
  static const Map<String?, Color> _outfitColors = {
    null: Color(0xFF9E9E9E),
    'outfit_default': Color(0xFF42A5F5),
    'outfit_hoodie': Color(0xFF7E57C2),
    'outfit_jersey': Color(0xFFEF5350),
    'outfit_jacket': Color(0xFF5C6BC0),
    'outfit_graduation': Color(0xFF2E7D32),
    'outfit_ninja': Color(0xFF212121),
    'outfit_royal': Color(0xFF6A1B9A),
  };

  List<Color> get _backgroundColors {
    final key = config.equippedBackground;
    return _bgGradients[key] ?? _bgGradients[null]!;
  }

  Color get _outfitColor {
    return _outfitColors[config.equippedOutfit] ?? const Color(0xFF78909C);
  }

  String get _faceEmoji => config.gender == 'female' ? '🙂' : '🙂';

  String? _emojiFor(String? itemId) {
    if (itemId == null) return null;
    return AvatarItemsCatalog.findById(itemId)?.emoji;
  }

  @override
  Widget build(BuildContext context) {
    final faceSize = size * 0.52;
    final bodyH = size * 0.38;
    final bodyW = size * 0.58;
    final hairEmoji = _emojiFor(config.equippedHair);
    final accEmoji = _emojiFor(config.equippedAccessory);
    final outfitEmoji = _emojiFor(config.equippedOutfit);
    final shoesEmoji = _emojiFor(config.equippedShoes);
    final specialEmoji = _emojiFor(config.equippedSpecial);

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _backgroundColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Layer 0: Special effect (behind everything, faded) ─────────
              if (specialEmoji != null)
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.25,
                      child: Text(
                        specialEmoji,
                        style: TextStyle(fontSize: size * 0.9),
                      ),
                    ),
                  ),
                ),

              // ── Layer 1: Body / outfit block ───────────────────────────────
              Positioned(
                bottom: -size * 0.06,
                left: (size - bodyW) / 2,
                child: Container(
                  width: bodyW,
                  height: bodyH,
                  decoration: BoxDecoration(
                    color: _outfitColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(size * 0.18),
                    ),
                  ),
                  child: outfitEmoji != null
                      ? Center(
                          child: Text(
                            outfitEmoji,
                            style: TextStyle(fontSize: size * 0.17),
                          ),
                        )
                      : null,
                ),
              ),

              // ── Layer 2: Face circle (skin tone) ───────────────────────────
              Positioned(
                top: size * 0.1,
                left: (size - faceSize) / 2,
                child: Container(
                  width: faceSize,
                  height: faceSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.skinColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _faceEmoji,
                      style: TextStyle(fontSize: size * 0.24),
                    ),
                  ),
                ),
              ),

              // ── Layer 3: Hair (top of head) ────────────────────────────────
              if (hairEmoji != null)
                Positioned(
                  top: size * 0.03,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      hairEmoji,
                      style: TextStyle(fontSize: size * 0.22),
                    ),
                  ),
                ),

              // ── Layer 4: Accessory (top-right of head) ─────────────────────
              if (accEmoji != null)
                Positioned(
                  top: size * 0.04,
                  right: size * 0.07,
                  child: Text(
                    accEmoji,
                    style: TextStyle(fontSize: size * 0.21),
                  ),
                ),

              // ── Layer 5: Shoes (bottom) ────────────────────────────────────
              if (shoesEmoji != null)
                Positioned(
                  bottom: size * 0.01,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      shoesEmoji,
                      style: TextStyle(fontSize: size * 0.14),
                    ),
                  ),
                ),

              // ── Layer 6: Special effect foreground sparkle ─────────────────
              if (specialEmoji != null)
                Positioned(
                  bottom: size * 0.28,
                  right: size * 0.06,
                  child: Text(
                    specialEmoji,
                    style: TextStyle(fontSize: size * 0.18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
