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
      ItemCategory.bottom => avatarConfig.equippedBottom == item.id,
      ItemCategory.shoes => avatarConfig.equippedShoes == item.id,
      ItemCategory.accessory => avatarConfig.equippedAccessory == item.id,
      ItemCategory.background => avatarConfig.equippedBackground == item.id,
      ItemCategory.special => avatarConfig.equippedSpecial == item.id,
    };
  }

  ShopLoaded copyWith({
    Set<String>? ownedItemIds,
    AvatarConfig? avatarConfig,
    int? coins,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return ShopLoaded(
      catalog: catalog,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      coins: coins ?? this.coins,
      level: level,
      feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }

  @override
  List<Object?> get props =>
      [ownedItemIds, avatarConfig.gender, avatarConfig.skinTone,
       avatarConfig.equippedHair, avatarConfig.equippedOutfit,
       avatarConfig.equippedBottom, avatarConfig.equippedShoes,
       avatarConfig.equippedAccessory, avatarConfig.equippedBackground,
       avatarConfig.equippedSpecial, coins, level, feedbackMessage];
}
