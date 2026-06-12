import 'package:equatable/equatable.dart';
import '../../domain/models/avatar_item.dart';
import '../../domain/models/avatar_config.dart';

abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);
  @override
  List<Object?> get props => [message];
}

class ShopLoaded extends ShopState {
  final List<AvatarItem> catalog;
  final Set<String> ownedItemIds;
  final AvatarConfig avatarConfig;
  final int coins;
  final int level;

  /// Non-null for one event cycle → UI shows a SnackBar then clears it.
  final String? feedbackMessage;
  final bool feedbackIsError;

  const ShopLoaded({
    required this.catalog,
    required this.ownedItemIds,
    required this.avatarConfig,
    required this.coins,
    required this.level,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  bool isOwned(String itemId) => ownedItemIds.contains(itemId);

  bool isEquipped(AvatarItem item) {
    return switch (item.category) {
      ItemCategory.hair => avatarConfig.equippedHair == item.id,
      ItemCategory.outfit => avatarConfig.equippedOutfit == item.id,
      ItemCategory.hairColor => avatarConfig.equippedHairColor == item.id,
      ItemCategory.outfitColor => avatarConfig.equippedOutfitColor == item.id,
      ItemCategory.accessory => avatarConfig.equippedAccessory == item.id,
      ItemCategory.facialHair => avatarConfig.equippedFacialHair == item.id,
      ItemCategory.facialHairColor => avatarConfig.equippedFacialHairColor == item.id,
      ItemCategory.eyes => avatarConfig.equippedEyes == item.id,
      ItemCategory.eyebrow => avatarConfig.equippedEyebrow == item.id,
      ItemCategory.mouth => avatarConfig.equippedMouth == item.id,
      ItemCategory.skinTone => avatarConfig.equippedSkinTone == item.id,
    };
  }

  ShopLoaded copyWith({
    Set<String>? ownedItemIds,
    AvatarConfig? avatarConfig,
    int? coins,
    String? feedbackMessage,
    bool? feedbackIsError,
  }) {
    return ShopLoaded(
      catalog: catalog,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      coins: coins ?? this.coins,
      level: level,
      // feedbackMessage is intentionally NOT preserved — it is transient.
      // Any copyWith call that doesn't explicitly pass it clears it to null,
      // preventing the SnackBar from re-firing on the next state change.
      feedbackMessage: feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }

  @override
  List<Object?> get props => [
    ownedItemIds, avatarConfig.gender, avatarConfig.skinTone,
    avatarConfig.equippedHair, avatarConfig.equippedOutfit,
    avatarConfig.equippedHairColor, avatarConfig.equippedOutfitColor,
    avatarConfig.equippedAccessory, avatarConfig.equippedBackground,
    avatarConfig.equippedFacialHair, avatarConfig.equippedFacialHairColor,
    avatarConfig.equippedEyes, avatarConfig.equippedEyebrow,
    avatarConfig.equippedMouth, avatarConfig.equippedSkinTone,
    coins, level, feedbackMessage,
  ];
}
