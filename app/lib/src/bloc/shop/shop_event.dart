import 'package:equatable/equatable.dart';
import '../../domain/models/avatar_item.dart';
import '../../domain/models/avatar_config.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();
  @override
  List<Object?> get props => [];
}

/// Load owned items, avatar config, and coin balance from DB.
class LoadShopRequested extends ShopEvent {
  final String studentUid;
  final int currentCoins;
  final int currentLevel;

  const LoadShopRequested({
    required this.studentUid,
    required this.currentCoins,
    required this.currentLevel,
  });

  @override
  List<Object?> get props => [studentUid, currentCoins, currentLevel];
}

/// Buy an item from the marketplace.
class PurchaseItemRequested extends ShopEvent {
  final String studentUid;
  final AvatarItem item;
  final int currentCoins;

  const PurchaseItemRequested({
    required this.studentUid,
    required this.item,
    required this.currentCoins,
  });

  @override
  List<Object?> get props => [studentUid, item.id, currentCoins];
}

/// Equip or unequip an item (toggle).
class EquipItemToggled extends ShopEvent {
  final String studentUid;
  final AvatarItem item;
  final AvatarConfig currentConfig;

  const EquipItemToggled({
    required this.studentUid,
    required this.item,
    required this.currentConfig,
  });

  @override
  List<Object?> get props => [studentUid, item.id];
}

/// Persist the current avatar config to Firebase — fired once when the user taps Done.
class SaveAvatarRequested extends ShopEvent {
  final String studentUid;

  const SaveAvatarRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
