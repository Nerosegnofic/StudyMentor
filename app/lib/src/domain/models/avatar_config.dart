import 'package:flutter/material.dart';

/// Holds the student's current avatar configuration — equipped item IDs per slot.
/// A null slot means nothing is equipped (renders the default for that slot).
class AvatarConfig {
  final String gender;      // 'male' | 'female'
  final String skinTone;    // 'light' | 'medium_light' | 'medium' | 'medium_dark' | 'dark'
  final String? equippedHair;
  final String? equippedOutfit;
  final String? equippedBottom;
  final String? equippedShoes;
  final String? equippedAccessory;
  final String? equippedBackground;
  final String? equippedSpecial;

  const AvatarConfig({
    this.gender = 'male',
    this.skinTone = 'medium',
    this.equippedHair,
    this.equippedOutfit,
    this.equippedBottom,
    this.equippedShoes,
    this.equippedAccessory,
    this.equippedBackground,
    this.equippedSpecial,
  });

  static const AvatarConfig defaults = AvatarConfig();

  AvatarConfig copyWith({
    String? gender,
    String? skinTone,
    Object? equippedHair = _sentinel,
    Object? equippedOutfit = _sentinel,
    Object? equippedBottom = _sentinel,
    Object? equippedShoes = _sentinel,
    Object? equippedAccessory = _sentinel,
    Object? equippedBackground = _sentinel,
    Object? equippedSpecial = _sentinel,
  }) {
    return AvatarConfig(
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      equippedHair: equippedHair == _sentinel
          ? this.equippedHair
          : equippedHair as String?,
      equippedOutfit: equippedOutfit == _sentinel
          ? this.equippedOutfit
          : equippedOutfit as String?,
      equippedBottom: equippedBottom == _sentinel
          ? this.equippedBottom
          : equippedBottom as String?,
      equippedShoes: equippedShoes == _sentinel
          ? this.equippedShoes
          : equippedShoes as String?,
      equippedAccessory: equippedAccessory == _sentinel
          ? this.equippedAccessory
          : equippedAccessory as String?,
      equippedBackground: equippedBackground == _sentinel
          ? this.equippedBackground
          : equippedBackground as String?,
      equippedSpecial: equippedSpecial == _sentinel
          ? this.equippedSpecial
          : equippedSpecial as String?,
    );
  }

  factory AvatarConfig.fromMap(Map<String, dynamic> map) => AvatarConfig(
        gender: (map['gender'] as String?) ?? 'male',
        skinTone: (map['skin_tone'] as String?) ?? 'medium',
        equippedHair: map['equipped_hair'] as String?,
        equippedOutfit: map['equipped_outfit'] as String?,
        equippedBottom: map['equipped_bottom'] as String?,
        equippedShoes: map['equipped_shoes'] as String?,
        equippedAccessory: map['equipped_accessory'] as String?,
        equippedBackground: map['equipped_background'] as String?,
        equippedSpecial: map['equipped_special'] as String?,
      );

  // ── Skin tone to Color ────────────────────────────────────────────────────
  static const Map<String, Color> skinToneColors = {
    'light': Color(0xFFFFDBAC),
    'medium_light': Color(0xFFEEC27B),
    'medium': Color(0xFFC68642),
    'medium_dark': Color(0xFF8D5524),
    'dark': Color(0xFF4A2C0A),
  };

  Color get skinColor => skinToneColors[skinTone] ?? skinToneColors['medium']!;
}

// Sentinel value for copyWith to distinguish null from "not provided"
const _sentinel = Object();
