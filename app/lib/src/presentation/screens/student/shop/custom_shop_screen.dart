import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../bloc/shop/shop_bloc.dart';
import '../../../../bloc/shop/shop_event.dart';
import '../../../../bloc/shop/shop_state.dart';
import '../../../../domain/models/avatar_item.dart';
import '../../../../../core/avatar/fluttermojiController.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Study Mentor design-system tokens (Student app)
// ---------------------------------------------------------------------------
// File-local, mirroring the convention used in student_quiz.dart.
const _kBg = Color(0xFFF5F7FA); // Soft Cloud scaffold
const _kGreen = Color(0xFF4CAF50); // primary actions / active / equipped
const _kAmberLight = Color(0xFFFFF8E1); // coin / price pill background
const _kAmberDark = Color(0xFFF57F17); // coin / price text on light amber
const _kLevelLock = Color(0xFF64748B); // slate — level-lock badge (neutral, not blue)
const _kLevelLockBg = Color(0xFFEEF1F5); // level-lock badge background
const _kInk = Color(0xFF1A1F3C); // heading text
const _kMuted = Color(0xFF8B93A7); // secondary text
const _kHairline = Color(0xFFE3E8EF); // neutral card border
const _kDisabled = Color(0xFFCFD6E0); // locked / disabled fill
const _kRed = Color(0xFFEA4335); // error

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
      _showInfoSnack(
        context,
        icon: Icons.lock_rounded,
        color: _kLevelLock,
        message: 'Reach Level ${item.unlockLevel} to unlock this item.',
      );
    } else if (state.coins < item.price) {
      _showInfoSnack(
        context,
        icon: Icons.monetization_on_rounded,
        color: _kAmberDark,
        message:
            'Not enough coins — you need ${item.price - state.coins} more.',
      );
    } else {
      // Block opening a second purchase dialog while one is already processing.
      if (state.isPurchasing) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Buy ${item.name}?',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kAmberLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '${item.price} coins',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kAmberDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Balance after: ${state.coins - item.price} 🪙',
                style: GoogleFonts.roboto(fontSize: 13, color: _kMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: TextButton.styleFrom(foregroundColor: _kMuted),
              child: Text(
                'Cancel',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Buy',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
  }

  // A single branded, floating snackbar used for every shop message.
  void _showInfoSnack(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildItemCard(BuildContext context, ShopLoaded state, AvatarItem item) {
    final isOwned = state.isOwned(item.id);
    final isEquipped = state.isEquipped(item);
    final meetsLevel = state.level >= item.unlockLevel;
    final canAfford = state.coins >= item.price;
    // Two distinct lock reasons so the student understands why an item is gated.
    final isLevelLocked = !isOwned && !meetsLevel; // needs a higher level
    final isCoinLocked = !isOwned && meetsLevel && !canAfford; // needs coins
    final isLocked = isLevelLocked || isCoinLocked;

    String svgString = _fluttermojiController.getComponentSVG(
        item.fluttermojiKey, item.fluttermojiIndex);

    Widget itemVisual = SvgPicture.string(svgString, height: 60, width: 60);

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

    // Price pill stays amber when affordable or coin-locked (the amber lock
    // glyph differentiates); muted grey when level-locked (level is the gate).
    final priceBg = isLevelLocked ? _kDisabled : _kAmberLight;
    final priceFg = isLevelLocked ? _kMuted : _kAmberDark;

    return GestureDetector(
      onTap: () => _handleItemTap(context, state, item, isOwned, meetsLevel),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isEquipped ? _kGreen : _kHairline,
            width: isEquipped ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isEquipped)
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.2),
                blurRadius: 8,
              )
          ],
        ),
        child: Stack(
          children: [
            Center(child: itemVisual),
            if (!isOwned)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priceBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🪙 ${item.price}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: priceFg,
                    ),
                  ),
                ),
              ),
            // Level lock → slate badge that shows the required level.
            if (isLevelLocked)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kLevelLockBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 11, color: _kLevelLock),
                      const SizedBox(width: 2),
                      Text(
                        'Lv ${item.unlockLevel}',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kLevelLock,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Coin lock → amber lock glyph (the amber price shows the cost).
            if (isCoinLocked)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: _kAmberLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 12, color: _kAmberDark),
                ),
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
          _showInfoSnack(
            context,
            icon: state.feedbackIsError
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded,
            color: state.feedbackIsError ? _kRed : _kGreen,
            message: state.feedbackMessage!,
          );
        }
      },
      builder: (context, state) {
        if (state is ShopLoading || state is ShopInitial) {
          return const Scaffold(
            backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kGreen)),
          );
        }

        if (state is ShopError) {
          return Scaffold(
            backgroundColor: _kBg,
            body: Center(
              child: Text(
                state.message,
                style: GoogleFonts.roboto(color: _kMuted),
              ),
            ),
          );
        }

        final loadedState = state as ShopLoaded;

        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Avatar Shop',
              style: GoogleFonts.cairo(
                color: _kInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            iconTheme: const IconThemeData(color: _kInk),
            actions: [
              Container(
                margin: const EdgeInsetsDirectional.only(end: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kAmberLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '${loadedState.coins}',
                      style: GoogleFonts.roboto(
                        color: _kAmberDark,
                        fontWeight: FontWeight.w700,
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
              labelColor: _kGreen,
              unselectedLabelColor: _kMuted,
              indicatorColor: _kGreen,
              labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.roboto(fontWeight: FontWeight.w500),
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
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.check),
            label: Text(
              'Done',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
