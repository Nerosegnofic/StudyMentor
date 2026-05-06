import 'package:bloc/bloc.dart';
import '../../data/catalog/avatar_items_catalog.dart';
import '../../data/providers/dataconnect_provider.dart';
import '../../domain/models/avatar_config.dart';
import '../../domain/models/avatar_item.dart';
import 'shop_event.dart';
import 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final DataConnectProvider _provider;

  ShopBloc({DataConnectProvider? provider})
      : _provider = provider ?? DataConnectProvider(),
        super(const ShopInitial()) {
    on<LoadShopRequested>(_onLoad);
    on<PurchaseItemRequested>(_onPurchase);
    on<EquipItemToggled>(_onEquipToggle);
    on<AvatarCustomizationChanged>(_onCustomizationChanged);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadShopRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(const ShopLoading());
    try {
      final results = await Future.wait([
        _provider.getStudentOwnedItems(event.studentUid),
        _provider.getStudentAvatar(event.studentUid),
      ]);

      final ownedIds = results[0] as Set<String>;
      final avatarMap = results[1] as Map<String, dynamic>?;

      // Starters are always owned
      final allOwned = {...AvatarItemsCatalog.starterItemIds, ...ownedIds};

      final config = avatarMap != null
          ? AvatarConfig.fromMap(avatarMap)
          : AvatarConfig.defaults;

      emit(ShopLoaded(
        catalog: AvatarItemsCatalog.all,
        ownedItemIds: allOwned,
        avatarConfig: config,
        coins: event.currentCoins,
        level: event.currentLevel,
      ));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onPurchase(
    PurchaseItemRequested event,
    Emitter<ShopState> emit,
  ) async {
    final current = state;
    if (current is! ShopLoaded) return;

    // Already owned?
    if (current.isOwned(event.item.id)) {
      emit(current.copyWith(
        feedbackMessage: '${event.item.name} is already in your inventory!',
        feedbackIsError: false,
      ));
      return;
    }

    // Level requirement
    if (current.level < event.item.unlockLevel) {
      emit(current.copyWith(
        feedbackMessage:
            '${event.item.name} unlocks at Level ${event.item.unlockLevel}.',
        feedbackIsError: true,
      ));
      return;
    }

    // Insufficient coins
    if (event.currentCoins < event.item.price) {
      emit(current.copyWith(
        feedbackMessage:
            'Not enough coins! You need ${event.item.price - event.currentCoins} more.',
        feedbackIsError: true,
      ));
      return;
    }

    try {
      final newCoins = event.currentCoins - event.item.price;
      await Future.wait([
        _provider.insertStudentOwnedItem(
          studentUid: event.studentUid,
          itemId: event.item.id,
        ),
        _provider.updateStudentCoins(newCoins),
      ]);

      final newOwned = {...current.ownedItemIds, event.item.id};
      emit(current.copyWith(
        ownedItemIds: newOwned,
        coins: newCoins,
        feedbackMessage: '${event.item.name} purchased! 🎉',
        feedbackIsError: false,
      ));
    } catch (e) {
      emit(current.copyWith(
        feedbackMessage: 'Purchase failed. Please try again.',
        feedbackIsError: true,
      ));
    }
  }

  Future<void> _onEquipToggle(
    EquipItemToggled event,
    Emitter<ShopState> emit,
  ) async {
    final current = state;
    if (current is! ShopLoaded) return;

    // Toggle: if already equipped → unequip, otherwise equip
    final alreadyEquipped = current.isEquipped(event.item);
    final newConfig = alreadyEquipped
        ? _unequip(event.currentConfig, event.item.category)
        : _equip(event.currentConfig, event.item);

    // Optimistic update
    emit(current.copyWith(avatarConfig: newConfig));

    try {
      await _provider.upsertStudentAvatar(
        studentUid: event.studentUid,
        gender: newConfig.gender,
        skinTone: newConfig.skinTone,
        equippedHair: newConfig.equippedHair,
        equippedOutfit: newConfig.equippedOutfit,
        equippedBottom: newConfig.equippedBottom,
        equippedShoes: newConfig.equippedShoes,
        equippedAccessory: newConfig.equippedAccessory,
        equippedBackground: newConfig.equippedBackground,
        equippedSpecial: newConfig.equippedSpecial,
      );
    } catch (_) {
      // Roll back on failure
      emit(current.copyWith(avatarConfig: event.currentConfig));
    }
  }

  Future<void> _onCustomizationChanged(
    AvatarCustomizationChanged event,
    Emitter<ShopState> emit,
  ) async {
    final current = state;
    if (current is! ShopLoaded) return;

    emit(current.copyWith(avatarConfig: event.newConfig));

    try {
      await _provider.upsertStudentAvatar(
        studentUid: event.studentUid,
        gender: event.newConfig.gender,
        skinTone: event.newConfig.skinTone,
        equippedHair: event.newConfig.equippedHair,
        equippedOutfit: event.newConfig.equippedOutfit,
        equippedBottom: event.newConfig.equippedBottom,
        equippedShoes: event.newConfig.equippedShoes,
        equippedAccessory: event.newConfig.equippedAccessory,
        equippedBackground: event.newConfig.equippedBackground,
        equippedSpecial: event.newConfig.equippedSpecial,
      );
    } catch (_) {
      // Silently fail; avatar is visual-only
    }
  }

  // ── Equip/Unequip helpers ─────────────────────────────────────────────────

  AvatarConfig _equip(AvatarConfig config, AvatarItem item) {
    return switch (item.category) {
      ItemCategory.hair => config.copyWith(equippedHair: item.id),
      ItemCategory.outfit => config.copyWith(equippedOutfit: item.id),
      ItemCategory.bottom => config.copyWith(equippedBottom: item.id),
      ItemCategory.shoes => config.copyWith(equippedShoes: item.id),
      ItemCategory.accessory => config.copyWith(equippedAccessory: item.id),
      ItemCategory.background => config.copyWith(equippedBackground: item.id),
      ItemCategory.special => config.copyWith(equippedSpecial: item.id),
    };
  }

  AvatarConfig _unequip(AvatarConfig config, ItemCategory category) {
    return switch (category) {
      ItemCategory.hair => config.copyWith(equippedHair: null),
      ItemCategory.outfit => config.copyWith(equippedOutfit: null),
      ItemCategory.bottom => config.copyWith(equippedBottom: null),
      ItemCategory.shoes => config.copyWith(equippedShoes: null),
      ItemCategory.accessory => config.copyWith(equippedAccessory: null),
      ItemCategory.background => config.copyWith(equippedBackground: null),
      ItemCategory.special => config.copyWith(equippedSpecial: null),
    };
  }
}
