import 'dart:convert';

/// Holds the student's current avatar configuration.
/// The 5 extra slots (eyes, eyebrow, mouth, skinTone, facialHairColor) are
/// persisted inside the existing avatarConfig text column as a JSON object.
class AvatarConfig {
  final String gender;
  final String skinTone;
  // ── Primary equipped slots (dedicated DB columns) ──────────────────────────
  final String? equippedHair;
  final String? equippedOutfit;
  final String? equippedHairColor;     // DB column: equipped_bottom
  final String? equippedOutfitColor;   // DB column: equipped_shoes
  final String? equippedAccessory;
  final String? equippedFacialHair;    // DB column: equipped_special
  final String? equippedBackground;
  // ── Extra slots (stored inside avatarConfig JSON column) ──────────────────
  final String? equippedFacialHairColor;
  final String? equippedEyes;
  final String? equippedEyebrow;
  final String? equippedMouth;
  final String? equippedSkinTone;

  const AvatarConfig({
    this.gender = 'male',
    this.skinTone = 'medium',
    this.equippedHair,
    this.equippedOutfit,
    this.equippedHairColor,
    this.equippedOutfitColor,
    this.equippedAccessory,
    this.equippedFacialHair,
    this.equippedBackground,
    this.equippedFacialHairColor,
    this.equippedEyes,
    this.equippedEyebrow,
    this.equippedMouth,
    this.equippedSkinTone,
  });

  static const AvatarConfig defaults = AvatarConfig();

  /// Serializes the extra slots to JSON for the avatarConfig DB column.
  String get extrasJson {
    final map = <String, dynamic>{};
    if (equippedFacialHairColor != null) map['facialHairColor'] = equippedFacialHairColor;
    if (equippedEyes != null) map['eyes'] = equippedEyes;
    if (equippedEyebrow != null) map['eyebrow'] = equippedEyebrow;
    if (equippedMouth != null) map['mouth'] = equippedMouth;
    if (equippedSkinTone != null) map['skinTone'] = equippedSkinTone;
    return jsonEncode(map);
  }

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    // Parse extra slots from the avatarConfig JSON column
    String? equippedFacialHairColor, equippedEyes, equippedEyebrow, equippedMouth, equippedSkinTone;
    final rawJson = map['avatar_config'] as String?;
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final extras = jsonDecode(rawJson) as Map<String, dynamic>;
        equippedFacialHairColor = extras['facialHairColor'] as String?;
        equippedEyes = extras['eyes'] as String?;
        equippedEyebrow = extras['eyebrow'] as String?;
        equippedMouth = extras['mouth'] as String?;
        equippedSkinTone = extras['skinTone'] as String?;
      } catch (_) {}
    }
    return AvatarConfig(
      gender: (map['gender'] as String?) ?? 'male',
      skinTone: (map['skin_tone'] as String?) ?? 'medium',
      equippedHair: map['equipped_hair'] as String?,
      equippedOutfit: map['equipped_outfit'] as String?,
      equippedHairColor: map['equipped_bottom'] as String?,
      equippedOutfitColor: map['equipped_shoes'] as String?,
      equippedAccessory: map['equipped_accessory'] as String?,
      equippedFacialHair: map['equipped_special'] as String?,
      equippedBackground: map['equipped_background'] as String?,
      equippedFacialHairColor: equippedFacialHairColor,
      equippedEyes: equippedEyes,
      equippedEyebrow: equippedEyebrow,
      equippedMouth: equippedMouth,
      equippedSkinTone: equippedSkinTone,
    );
  }

  AvatarConfig copyWith({
    String? gender,
    String? skinTone,
    Object? equippedHair = _s,
    Object? equippedOutfit = _s,
    Object? equippedHairColor = _s,
    Object? equippedOutfitColor = _s,
    Object? equippedAccessory = _s,
    Object? equippedFacialHair = _s,
    Object? equippedBackground = _s,
    Object? equippedFacialHairColor = _s,
    Object? equippedEyes = _s,
    Object? equippedEyebrow = _s,
    Object? equippedMouth = _s,
    Object? equippedSkinTone = _s,
  }) {
    return AvatarConfig(
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      equippedHair: equippedHair == _s ? this.equippedHair : equippedHair as String?,
      equippedOutfit: equippedOutfit == _s ? this.equippedOutfit : equippedOutfit as String?,
      equippedHairColor: equippedHairColor == _s ? this.equippedHairColor : equippedHairColor as String?,
      equippedOutfitColor: equippedOutfitColor == _s ? this.equippedOutfitColor : equippedOutfitColor as String?,
      equippedAccessory: equippedAccessory == _s ? this.equippedAccessory : equippedAccessory as String?,
      equippedFacialHair: equippedFacialHair == _s ? this.equippedFacialHair : equippedFacialHair as String?,
      equippedBackground: equippedBackground == _s ? this.equippedBackground : equippedBackground as String?,
      equippedFacialHairColor: equippedFacialHairColor == _s ? this.equippedFacialHairColor : equippedFacialHairColor as String?,
      equippedEyes: equippedEyes == _s ? this.equippedEyes : equippedEyes as String?,
      equippedEyebrow: equippedEyebrow == _s ? this.equippedEyebrow : equippedEyebrow as String?,
      equippedMouth: equippedMouth == _s ? this.equippedMouth : equippedMouth as String?,
      equippedSkinTone: equippedSkinTone == _s ? this.equippedSkinTone : equippedSkinTone as String?,
    );
  }

}

const _s = Object(); // sentinel for copyWith
