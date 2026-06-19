// test/bloc/shop_bloc_test.dart
//
// Unit tests for ShopBloc.
// Tests cover the guard conditions (insufficient coins, already owned, level
// gate) that do NOT require a network call to AiEngineRepository.instance or
// Firebase, as those use a static singleton that can't be injected.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/shop/shop_bloc.dart';
import 'package:studymentor/src/bloc/shop/shop_event.dart';
import 'package:studymentor/src/bloc/shop/shop_state.dart';
import 'package:studymentor/src/data/providers/dataconnect_provider.dart';
import 'package:studymentor/src/domain/models/avatar_config.dart';
import 'package:studymentor/src/domain/models/avatar_item.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockDataConnectProvider extends Mock implements DataConnectProvider {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _studentUid = 'uid-student';

AvatarItem _itemFree({String id = 'item_free', int unlockLevel = 1}) =>
    AvatarItem(
      id: id,
      name: 'Free Item',
      category: ItemCategory.accessory,
      price: 0,
      emoji: '🎩',
      rarity: ItemRarity.common,
      fluttermojiKey: 'accessoriesType',
      fluttermojiIndex: 0,
      unlockLevel: unlockLevel,
    );

AvatarItem _itemPaid({
  String id = 'item_paid',
  int price = 50,
  int unlockLevel = 1,
}) =>
    AvatarItem(
      id: id,
      name: 'Paid Item',
      category: ItemCategory.hair,
      price: price,
      emoji: '💇',
      rarity: ItemRarity.rare,
      fluttermojiKey: 'topType',
      fluttermojiIndex: 1,
      unlockLevel: unlockLevel,
    );

ShopLoaded _loadedState({
  int coins = 100,
  int level = 5,
  Set<String>? owned,
}) =>
    ShopLoaded(
      catalog: [_itemFree(), _itemPaid()],
      ownedItemIds: owned ?? {'item_free'},
      avatarConfig: AvatarConfig.defaults,
      coins: coins,
      level: level,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockDataConnectProvider mockProvider;

  setUp(() {
    mockProvider = MockDataConnectProvider();
  });

  group('ShopBloc', () {
    // ── LoadShopRequested ────────────────────────────────────────────────────

    group('LoadShopRequested', () {
      blocTest<ShopBloc, ShopState>(
        'emits [ShopLoading, ShopLoaded] on success',
        build: () => ShopBloc(provider: mockProvider),
        setUp: () {
          when(() => mockProvider.getStudentOwnedItems(_studentUid))
              .thenAnswer((_) async => <String>{});
          when(() => mockProvider.getStudentAvatar(_studentUid))
              .thenAnswer((_) async => null);
        },
        act: (bloc) => bloc.add(
          const LoadShopRequested(
            studentUid: _studentUid,
            currentCoins: 100,
            currentLevel: 3,
          ),
        ),
        expect: () => [
          isA<ShopLoading>(),
          isA<ShopLoaded>()
              .having((s) => s.coins, 'coins', 100)
              .having((s) => s.level, 'level', 3),
        ],
      );

      blocTest<ShopBloc, ShopState>(
        'merges starter items with owned items in loaded state',
        build: () => ShopBloc(provider: mockProvider),
        setUp: () {
          when(() => mockProvider.getStudentOwnedItems(_studentUid))
              .thenAnswer((_) async => {'some_extra_item'});
          when(() => mockProvider.getStudentAvatar(_studentUid))
              .thenAnswer((_) async => null);
        },
        act: (bloc) => bloc.add(
          const LoadShopRequested(
            studentUid: _studentUid,
            currentCoins: 50,
            currentLevel: 1,
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as ShopLoaded;
          // extra purchased item should be in owned set
          expect(state.ownedItemIds.contains('some_extra_item'), isTrue);
        },
      );

      blocTest<ShopBloc, ShopState>(
        'emits ShopError when provider throws',
        build: () => ShopBloc(provider: mockProvider),
        setUp: () {
          when(() => mockProvider.getStudentOwnedItems(any()))
              .thenThrow(Exception('DB error'));
          when(() => mockProvider.getStudentAvatar(any()))
              .thenAnswer((_) async => null);
        },
        act: (bloc) => bloc.add(
          const LoadShopRequested(
            studentUid: _studentUid,
            currentCoins: 0,
            currentLevel: 1,
          ),
        ),
        expect: () => [isA<ShopLoading>(), isA<ShopError>()],
      );
    });

    // ── PurchaseItemRequested — guard conditions ──────────────────────────────

    group('PurchaseItemRequested', () {
      blocTest<ShopBloc, ShopState>(
        'blocks purchase when item is already owned',
        build: () => ShopBloc(provider: mockProvider),
        seed: () => _loadedState(owned: {'item_paid'}),
        act: (bloc) => bloc.add(
          PurchaseItemRequested(
            studentUid: _studentUid,
            item: _itemPaid(),
            currentCoins: 100,
          ),
        ),
        expect: () => [
          isA<ShopLoaded>().having(
            (s) => s.feedbackMessage,
            'feedbackMessage',
            contains('already'),
          ),
        ],
      );

      blocTest<ShopBloc, ShopState>(
        'blocks purchase when level is too low',
        build: () => ShopBloc(provider: mockProvider),
        seed: () => _loadedState(level: 2),
        act: (bloc) => bloc.add(
          PurchaseItemRequested(
            studentUid: _studentUid,
            item: _itemPaid(unlockLevel: 5),
            currentCoins: 500,
          ),
        ),
        expect: () => [
          isA<ShopLoaded>()
              .having(
                (s) => s.feedbackMessage,
                'feedbackMessage',
                contains('unlocks at Level'),
              )
              .having((s) => s.feedbackIsError, 'feedbackIsError', true),
        ],
      );

      blocTest<ShopBloc, ShopState>(
        'blocks purchase when coins are insufficient',
        build: () => ShopBloc(provider: mockProvider),
        seed: () => _loadedState(coins: 10),
        act: (bloc) => bloc.add(
          PurchaseItemRequested(
            studentUid: _studentUid,
            item: _itemPaid(price: 50),
            currentCoins: 10,
          ),
        ),
        expect: () => [
          isA<ShopLoaded>()
              .having(
                (s) => s.feedbackMessage,
                'feedbackMessage',
                contains('Not enough coins'),
              )
              .having((s) => s.feedbackIsError, 'feedbackIsError', true),
        ],
      );

      blocTest<ShopBloc, ShopState>(
        'does nothing when state is not ShopLoaded',
        build: () => ShopBloc(provider: mockProvider),
        // starts at ShopInitial
        act: (bloc) => bloc.add(
          PurchaseItemRequested(
            studentUid: _studentUid,
            item: _itemPaid(),
            currentCoins: 100,
          ),
        ),
        expect: () => <ShopState>[],
      );
    });

    // ── EquipItemToggled ─────────────────────────────────────────────────────

    group('EquipItemToggled', () {
      final testItem = _itemFree(id: 'item_free');

      blocTest<ShopBloc, ShopState>(
        'equips an item and updates avatar config',
        build: () => ShopBloc(provider: mockProvider),
        seed: () => _loadedState(owned: {'item_free'}),
        act: (bloc) => bloc.add(
          EquipItemToggled(
            studentUid: _studentUid,
            item: testItem,
            currentConfig: AvatarConfig.defaults,
          ),
        ),
        expect: () => [
          isA<ShopLoaded>().having(
            (s) => s.avatarConfig.equippedAccessory,
            'equippedAccessory',
            'item_free',
          ),
        ],
      );

      blocTest<ShopBloc, ShopState>(
        'unequips an already-equipped item',
        build: () => ShopBloc(provider: mockProvider),
        seed: () => ShopLoaded(
          catalog: [testItem],
          ownedItemIds: {'item_free'},
          avatarConfig: const AvatarConfig(equippedAccessory: 'item_free'),
          coins: 100,
          level: 1,
        ),
        act: (bloc) => bloc.add(
          EquipItemToggled(
            studentUid: _studentUid,
            item: testItem,
            currentConfig: const AvatarConfig(equippedAccessory: 'item_free'),
          ),
        ),
        expect: () => [
          isA<ShopLoaded>().having(
            (s) => s.avatarConfig.equippedAccessory,
            'equippedAccessory',
            isNull,
          ),
        ],
      );
    });

    // ── AvatarCustomizationChanged ───────────────────────────────────────────

    group('AvatarCustomizationChanged', () {
      blocTest<ShopBloc, ShopState>(
        'updates avatar config locally without a network call',
        build: () => ShopBloc(provider: mockProvider),
        seed: () => _loadedState(),
        act: (bloc) => bloc.add(
          AvatarCustomizationChanged(
            studentUid: _studentUid,
            newConfig: const AvatarConfig(gender: 'female', skinTone: 'light'),
          ),
        ),
        expect: () => [
          isA<ShopLoaded>()
              .having(
                (s) => s.avatarConfig.gender,
                'gender',
                'female',
              )
              .having(
                (s) => s.avatarConfig.skinTone,
                'skinTone',
                'light',
              ),
        ],
        verify: (_) {
          // Confirm no DB calls were made during local customisation
          verifyNever(() => mockProvider.upsertStudentAvatar(
                studentUid: any(named: 'studentUid'),
                gender: any(named: 'gender'),
                skinTone: any(named: 'skinTone'),
                equippedHair: any(named: 'equippedHair'),
                equippedOutfit: any(named: 'equippedOutfit'),
                equippedBottom: any(named: 'equippedBottom'),
                equippedShoes: any(named: 'equippedShoes'),
                equippedAccessory: any(named: 'equippedAccessory'),
                equippedBackground: any(named: 'equippedBackground'),
                equippedSpecial: any(named: 'equippedSpecial'),
                avatarConfig: any(named: 'avatarConfig'),
              ));
        },
      );
    });
  });
}
