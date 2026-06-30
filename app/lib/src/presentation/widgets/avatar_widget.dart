import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/avatar/fluttermojiController.dart';
import '../../data/catalog/avatar_items_catalog.dart';
import '../../domain/models/avatar_config.dart';

// Safe defaults that only use free/starter items so the first-render avatar
// never shows paid content before the user has equipped anything.
const Map<String, int> _safeDefaults = {
  'topType': 0,          // Bald (free)
  'accessoriesType': 0,  // None (free)
  'hairColor': 0,        // Auburn (free)
  'facialHairType': 0,   // Clean Shaven (free)
  'facialHairColor': 0,  // Auburn (free)
  'clotheType': 0,       // Crew Neck Tee (free)
  'eyeType': 0,          // Default eyes (free)
  'eyebrowType': 0,      // Default eyebrow (free)
  'mouthType': 8,        // Smile (free)
  'skinColor': 3,        // Brown (free)
  'clotheColor': 0,      // Blue (free)
  'style': 0,            // No Background (free)
  'graphicType': 0,
};

class AvatarWidget extends StatefulWidget {
  final AvatarConfig config;
  final double size;

  const AvatarWidget({
    super.key,
    required this.config,
    this.size = 120,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  late String _svgString;
  late String _cacheKey;

  @override
  void initState() {
    super.initState();
    _cacheKey = _configKey(widget.config);
    _svgString = _buildSvg(widget.config);
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate the (expensive) SVG only when the equipped slots actually
    // change. AvatarConfig has no value equality, so compare a derived key
    // rather than the instance — otherwise a new-but-identical config (common
    // on rebuilds) would needlessly re-run Fluttermoji generation + parsing.
    final newKey = _configKey(widget.config);
    if (newKey != _cacheKey) {
      _cacheKey = newKey;
      _svgString = _buildSvg(widget.config);
    }
  }

  /// Key over only the fields that affect the rendered SVG (the equipped slots).
  static String _configKey(AvatarConfig c) => [
        c.equippedHair,
        c.equippedOutfit,
        c.equippedHairColor,
        c.equippedOutfitColor,
        c.equippedAccessory,
        c.equippedBackground,
        c.equippedFacialHair,
        c.equippedFacialHairColor,
        c.equippedEyes,
        c.equippedEyebrow,
        c.equippedMouth,
        c.equippedSkinTone,
      ].join('|');

  static String _buildSvg(AvatarConfig config) {
    final controller = Get.put(FluttermojiController());

    // Start from safe defaults to avoid null cast errors when selectedOptions
    // hasn't been loaded from SharedPreferences yet (async init race condition).
    final Map<String, dynamic> options = Map.from(_safeDefaults);

    void apply(String? itemId) {
      if (itemId == null) return;
      final item = AvatarItemsCatalog.findById(itemId);
      if (item != null) options[item.fluttermojiKey] = item.fluttermojiIndex;
    }

    apply(config.equippedHair);
    apply(config.equippedOutfit);
    apply(config.equippedHairColor);
    apply(config.equippedOutfitColor);
    apply(config.equippedAccessory);
    apply(config.equippedBackground);
    apply(config.equippedFacialHair);
    apply(config.equippedFacialHairColor);
    apply(config.equippedEyes);
    apply(config.equippedEyebrow);
    apply(config.equippedMouth);
    apply(config.equippedSkinTone);

    controller.selectedOptions = options;
    return controller.getFluttermojiFromOptions();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipOval(
          child: Container(
            color: Colors.white,
            child: SvgPicture.string(
              _svgString,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
