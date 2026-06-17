import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../bloc/shop/shop_bloc.dart';
import '../../../../bloc/shop/shop_event.dart';
import '../../../../bloc/shop/shop_state.dart';
import '../../../../domain/models/avatar_item.dart';
import '../../../../../core/avatar/fluttermojiController.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../utils/error_localizer.dart';

class CustomShopScreen extends StatefulWidget {
  final String studentUid;
  final int currentCoins;
  final int currentLevel;

  const CustomShopScreen({
    super.key,
    required this.studentUid,
    required this.currentCoins,
    required this.currentLevel,
  });

  @override
  State<CustomShopScreen> createState() => _CustomShopScreenState();
}

class _CustomShopScreenState extends State<CustomShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FluttermojiController _fluttermojiController = Get.put(FluttermojiController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ItemCategory.values.length, vsync: this);
    context.read<ShopBloc>().add(LoadShopRequested(
      studentUid: widget.studentUid,
      currentCoins: widget.currentCoins,
      currentLevel: widget.currentLevel,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations loc, ItemCategory cat) {
    return switch (cat) {
      ItemCategory.hair => loc.categoryHairStyle,
      ItemCategory.outfit => loc.categoryOutfit,
      ItemCategory.hairColor => loc.categoryHairColor,
      ItemCategory.outfitColor => loc.categoryOutfitColor,
      ItemCategory.accessory => loc.categoryAccessory,
      ItemCategory.facialHair => loc.categoryFacialHair,
      ItemCategory.facialHairColor => loc.categoryBeardColor,
      ItemCategory.eyes => loc.categoryEyes,
      ItemCategory.eyebrow => loc.categoryEyebrows,
      ItemCategory.mouth => loc.categoryMouth,
      ItemCategory.skinTone => loc.categorySkinTone,
    };
  }

  void _handleItemTap(
      BuildContext context, ShopLoaded state, AvatarItem item, bool isOwned, bool meetsLevel) {
    final loc = AppLocalizations.of(context);
    if (isOwned) {
      context.read<ShopBloc>().add(
            EquipItemToggled(
              studentUid: widget.studentUid,
              item: item,
              currentConfig: state.avatarConfig,
            ),
          );
    } else if (!meetsLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.unlocksAtLevelMessage(item.unlockLevel))),
      );
    } else if (state.coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.notEnoughCoinsMessage(item.price - state.coins))),
      );
    } else {
      // Block opening a second purchase dialog while one is already processing.
      if (state.isPurchasing) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(loc.buyItemTitle(item.name)),
          content: Text(loc.itemCostMessage(item.price)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(loc.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<ShopBloc>().add(
                      PurchaseItemRequested(
                        studentUid: widget.studentUid,
                        item: item,
                        currentCoins: state.coins,
                      ),
                    );
              },
              child: Text(loc.buyButton),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildItemCard(BuildContext context, ShopLoaded state, AvatarItem item) {
    final isOwned = state.isOwned(item.id);
    final isEquipped = state.isEquipped(item);
    final meetsLevel = state.level >= item.unlockLevel;
    final canAfford = state.coins >= item.price;
    final isLocked = !isOwned && (!canAfford || !meetsLevel);

    String svgString = _fluttermojiController.getComponentSVG(
        item.fluttermojiKey, item.fluttermojiIndex);

    Widget itemVisual = SvgPicture.string(
      svgString,
      height: 60,
      width: 60,
    );

    if (isLocked) {
      itemVisual = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: itemVisual,
      );
    }

    return GestureDetector(
      onTap: () => _handleItemTap(context, state, item, isOwned, meetsLevel),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isEquipped ? const Color(0xFF4A6CF7) : Colors.grey[300]!,
            width: isEquipped ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isEquipped)
              BoxShadow(
                color: const Color(0xFF4A6CF7).withValues(alpha: 0.2),
                blurRadius: 8,
              )
          ],
        ),
        child: Stack(
          children: [
            Center(child: itemVisual),
            if (!isOwned)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: meetsLevel ? Colors.amber[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🪙 ${item.price}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: meetsLevel ? Colors.amber[900] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            if (!meetsLevel)
              Positioned(
                top: 4,
                left: 4,
                child: Icon(Icons.lock, size: 16, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<ShopBloc, ShopState>(
      listenWhen: (prev, curr) =>
          curr is ShopLoaded &&
          (curr.feedbackMessage != null || curr.avatarSaved),
      listener: (context, state) {
        if (state is ShopLoaded) {
          if (state.avatarSaved) {
            Navigator.pop(context);
            return;
          }
          final loc = AppLocalizations.of(context);
          final rawMsg = state.feedbackMessage!;
          final displayMsg = switch (rawMsg) {
            'SHOP_PURCHASED' => loc.shopItemPurchasedMessage,
            'SHOP_FAILED' => loc.errPurchaseFailed,
            _ => localizeError(rawMsg, loc),
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMsg),
              backgroundColor: state.feedbackIsError ? Colors.red : Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ShopLoading || state is ShopInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ShopError) {
          return Scaffold(
            body: Center(child: Text(state.message)),
          );
        }

        final loadedState = state as ShopLoaded;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              loc.avatarShopTitle,
              style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
            actions: [
              Container(
                margin: const EdgeInsetsDirectional.only(end: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '${loadedState.coins}',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF4A6CF7),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4A6CF7),
              tabs: ItemCategory.values.map((cat) {
                return Tab(text: _categoryLabel(loc, cat));
              }).toList(),
            ),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Center(
                  child: AvatarWidget(config: loadedState.avatarConfig, size: 140.0),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: ItemCategory.values.map((cat) {
                    final items = loadedState.catalog
                        .where((i) => i.category == cat)
                        .toList();

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(context, loadedState, items[index]);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.read<ShopBloc>().add(
                SaveAvatarRequested(studentUid: widget.studentUid),
              );
              // Navigator.pop is handled by the listener once the DB write completes.
            },
            backgroundColor: const Color(0xFF4A6CF7),
            icon: const Icon(Icons.check),
            label: Text(loc.doneButton),
          ),
        );
      },
    );
  }
}
