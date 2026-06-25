enum ItemCategory { hair, outfit, hairColor, outfitColor, accessory, facialHair, facialHairColor, eyes, eyebrow, mouth, skinTone }

class AvatarItem {
  final String id;
  final String name;
  final ItemCategory category;
  final int price;       // 0 = free starter item
  final String emoji;   // visual representation (emoji character)
  final int unlockLevel; // minimum level required to buy

  // Fluttermoji mapping
  final String fluttermojiKey;   // e.g., 'topType', 'clotheType', 'accessoriesType'
  final int fluttermojiIndex;    // e.g., 0, 1, 2, 3...

  const AvatarItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.emoji,
    required this.fluttermojiKey,
    required this.fluttermojiIndex,
    this.unlockLevel = 1,
  });

  bool get isFree => price == 0;
}
