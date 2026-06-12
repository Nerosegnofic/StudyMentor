import 'package:bloc/bloc.dart';
import '../../data/catalog/avatar_items_catalog.dart';
import '../../data/repositories/ai_engine_repository.dart';
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
    on<SaveAvatarRequested>(_onSaveAvatar);
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
        AiEngineRepository.instance.spendCoins(
          event.studentUid,
          event.item.price,
          'SHOP_PURCHASE',
        ),
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

    // Local update only — Firebase is written when the user taps Done.
    emit(current.copyWith(avatarConfig: newConfig));
  }

  Future<void> _onCustomizationChanged(
    AvatarCustomizationChanged event,
    Emitter<ShopState> emit,
  ) async {
    final current = state;
    if (current is! ShopLoaded) return;

    // Local update only — Firebase is written when the user taps Done.
    emit(current.copyWith(avatarConfig: event.newConfig));
  }

  Future<void> _onSaveAvatar(
    SaveAvatarRequested event,
    Emitter<ShopState> emit,
  ) async {
    final current = state;
    if (current is! ShopLoaded) return;
    try {
      await _provider.upsertStudentAvatar(
        studentUid: event.studentUid,
        gender: current.avatarConfig.gender,
        skinTone: current.avatarConfig.skinTone,
        equippedHair: current.avatarConfig.equippedHair,
        equippedOutfit: current.avatarConfig.equippedOutfit,
        equippedBottom: current.avatarConfig.equippedHairColor,
        equippedShoes: current.avatarConfig.equippedOutfitColor,
        equippedAccessory: current.avatarConfig.equippedAccessory,
        equippedBackground: current.avatarConfig.equippedBackground,
        equippedSpecial: current.avatarConfig.equippedFacialHair,
        avatarConfig: current.avatarConfig.extrasJson,
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
      ItemCategory.hairColor => config.copyWith(equippedHairColor: item.id),
      ItemCategory.outfitColor => config.copyWith(equippedOutfitColor: item.id),
      ItemCategory.accessory => config.copyWith(equippedAccessory: item.id),
      ItemCategory.facialHair => config.copyWith(equippedFacialHair: item.id),
      ItemCategory.facialHairColor => config.copyWith(equippedFacialHairColor: item.id),
      ItemCategory.eyes => config.copyWith(equippedEyes: item.id),
      ItemCategory.eyebrow => config.copyWith(equippedEyebrow: item.id),
      ItemCategory.mouth => config.copyWith(equippedMouth: item.id),
      ItemCategory.skinTone => config.copyWith(equippedSkinTone: item.id),
    };
  }

  AvatarConfig _unequip(AvatarConfig config, ItemCategory category) {
    return switch (category) {
      ItemCategory.hair => config.copyWith(equippedHair: null),
      ItemCategory.outfit => config.copyWith(equippedOutfit: null),
      ItemCategory.hairColor => config.copyWith(equippedHairColor: null),
      ItemCategory.outfitColor => config.copyWith(equippedOutfitColor: null),
      ItemCategory.accessory => config.copyWith(equippedAccessory: null),
      ItemCategory.facialHair => config.copyWith(equippedFacialHair: null),
      ItemCategory.facialHairColor => config.copyWith(equippedFacialHairColor: null),
      ItemCategory.eyes => config.copyWith(equippedEyes: null),
      ItemCategory.eyebrow => config.copyWith(equippedEyebrow: null),
      ItemCategory.mouth => config.copyWith(equippedMouth: null),
      ItemCategory.skinTone => config.copyWith(equippedSkinTone: null),
    };
  }
}
