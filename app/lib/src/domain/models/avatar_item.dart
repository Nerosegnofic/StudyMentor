enum ItemCategory { hair, outfit, hairColor, outfitColor, accessory, facialHair, facialHairColor, eyes, eyebrow, mouth, skinTone }

enum ItemRarity { common, rare, epic, legendary }

enum GenderCompatibility { all, male, female }

class AvatarItem {
  final String id;
  final String name;
  final ItemCategory category;
  final int price;       // 0 = free starter item
  final String emoji;   // visual representation (emoji character)
  final ItemRarity rarity;
  final int unlockLevel; // minimum level required to buy
  final GenderCompatibility genderCompatibility;

  // New fields for Fluttermoji mapping
  final String fluttermojiKey;   // e.g., 'topType', 'clotheType', 'accessoriesType'
  final int fluttermojiIndex;    // e.g., 0, 1, 2, 3...

  const AvatarItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.emoji,
    required this.rarity,
    required this.fluttermojiKey,
    required this.fluttermojiIndex,
    this.unlockLevel = 1,
    this.genderCompatibility = GenderCompatibility.all,
  });

  bool get isFree => price == 0;

  bool isAvailableForGender(String gender) {
    if (genderCompatibility == GenderCompatibility.all) return true;
    if (genderCompatibility == GenderCompatibility.male) return gender == 'male';
    return gender == 'female';
  }
}
