enum ItemCategory { hair, outfit, bottom, shoes, accessory, background, special }

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

  const AvatarItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.emoji,
    required this.rarity,
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
