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

class AvatarWidget extends StatelessWidget {
  final AvatarConfig config;
  final double size;

  const AvatarWidget({
    super.key,
    required this.config,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
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
    final svgString = controller.getFluttermojiFromOptions();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          color: Colors.white,
          child: SvgPicture.string(
            svgString,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
