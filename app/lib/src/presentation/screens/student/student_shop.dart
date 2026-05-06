import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/shop/shop_bloc.dart';
import '../../../bloc/shop/shop_event.dart';
import '../../../bloc/shop/shop_state.dart';
import '../../../data/catalog/avatar_items_catalog.dart';
import '../../../domain/models/avatar_item.dart';
import '../../../domain/models/avatar_config.dart';
import '../../widgets/avatar_widget.dart';
import 'student_avatar_customization.dart';

class StudentShop extends StatefulWidget {
  final String uid;
  final int coins;
  final int level;

  const StudentShop({
    super.key,
    required this.uid,
    required this.coins,
    required this.level,
  });

  @override
  State<StudentShop> createState() => _StudentShopState();
}

class _StudentShopState extends State<StudentShop>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categoryTabs = [
    (label: 'All', category: null),
    (label: 'Hair', category: ItemCategory.hair),
    (label: 'Outfits', category: ItemCategory.outfit),
    (label: 'Shoes', category: ItemCategory.shoes),
    (label: 'Access.', category: ItemCategory.accessory),
    (label: 'BG', category: ItemCategory.background),
    (label: 'Special', category: ItemCategory.special),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
    context.read<ShopBloc>().add(
          LoadShopRequested(
            studentUid: widget.uid,
            currentCoins: widget.coins,
            currentLevel: widget.level,
          ),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShopBloc, ShopState>(
      listenWhen: (_, current) =>
          current is ShopLoaded && current.feedbackMessage != null,
      listener: (context, state) {
        if (state is ShopLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              backgroundColor:
                  state.feedbackIsError ? Colors.red[700] : Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FF),
          body: switch (state) {
            ShopLoading() => const Center(child: CircularProgressIndicator()),
            ShopError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<ShopBloc>().add(
                      LoadShopRequested(
                        studentUid: widget.uid,
                        currentCoins: widget.coins,
                        currentLevel: widget.level,
                      ),
                    ),
              ),
            ShopLoaded() => _ShopBody(
                state: state as ShopLoaded,
                uid: widget.uid,
                tabController: _tabController,
                categoryTabs: _categoryTabs,
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

// ─── Shop body ────────────────────────────────────────────────────────────────

class _ShopBody extends StatefulWidget {
  final ShopLoaded state;
  final String uid;
  final TabController tabController;
  final List<({String label, ItemCategory? category})> categoryTabs;

  const _ShopBody({
    required this.state,
    required this.uid,
    required this.tabController,
    required this.categoryTabs,
  });

  @override
  State<_ShopBody> createState() => _ShopBodyState();
}

class _ShopBodyState extends State<_ShopBody> {
  bool _showInventory = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        final s = state is ShopLoaded ? state : widget.state;

        return CustomScrollView(
          slivers: [
            // ── Header: avatar preview + coin balance ──────────────────────
            SliverToBoxAdapter(child: _AvatarHeader(state: s, uid: widget.uid)),

            // ── Marketplace / My Inventory toggle ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _ToggleRow(
                  showInventory: _showInventory,
                  onToggle: (v) => setState(() => _showInventory = v),
                ),
              ),
            ),

            if (!_showInventory) ...[
              // ── Category tabs ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _CategoryTabBar(
                  tabController: widget.tabController,
                  tabs: widget.categoryTabs,
                ),
              ),
              // ── Item grid ─────────────────────────────────────────────
              SliverFillRemaining(
                child: TabBarView(
                  controller: widget.tabController,
                  children: widget.categoryTabs.map((tab) {
                    final items = tab.category == null
                        ? s.catalog
                        : s.catalog
                            .where((i) => i.category == tab.category)
                            .toList();
                    return _ItemGrid(
                      items: items,
                      state: s,
                      uid: widget.uid,
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              // ── Inventory grid ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                sliver: _InventoryGrid(state: s, uid: widget.uid),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Avatar header ────────────────────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  final ShopLoaded state;
  final String uid;

  const _AvatarHeader({required this.state, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar preview
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ShopBloc>(),
                  child: StudentAvatarCustomization(
                    uid: uid,
                    config: state.avatarConfig,
                  ),
                ),
              ),
            ),
            child: Stack(
              children: [
                AvatarWidget(config: state.avatarConfig, size: 100),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap avatar to customize',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                _CoinBadge(coins: state.coins),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Coin badge ───────────────────────────────────────────────────────────────

class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCA28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF57F17),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'coins',
            style: TextStyle(fontSize: 12, color: Colors.amber[800]),
          ),
        ],
      ),
    );
  }
}

// ─── Marketplace / Inventory toggle ──────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final bool showInventory;
  final ValueChanged<bool> onToggle;

  const _ToggleRow({required this.showInventory, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Marketplace',
            selected: !showInventory,
            onTap: () => onToggle(false),
          ),
          _Tab(
            label: 'My Inventory',
            selected: showInventory,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4A6CF7) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF4A6CF7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category tab bar ─────────────────────────────────────────────────────────

class _CategoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<({String label, ItemCategory? category})> tabs;

  const _CategoryTabBar({required this.tabController, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: const Color(0xFF4A6CF7),
      labelColor: const Color(0xFF4A6CF7),
      unselectedLabelColor: Colors.grey[500],
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      tabs: tabs.map((t) => Tab(text: t.label)).toList(),
    );
  }
}

// ─── Item grid (marketplace) ──────────────────────────────────────────────────

class _ItemGrid extends StatelessWidget {
  final List<AvatarItem> items;
  final ShopLoaded state;
  final String uid;

  const _ItemGrid({required this.items, required this.state, required this.uid});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items in this category.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemCard(
        item: items[i],
        state: state,
        uid: uid,
      ),
    );
  }
}

// ─── Inventory grid ───────────────────────────────────────────────────────────

class _InventoryGrid extends StatelessWidget {
  final ShopLoaded state;
  final String uid;

  const _InventoryGrid({required this.state, required this.uid});

  @override
  Widget build(BuildContext context) {
    final owned = state.catalog
        .where((i) => state.isOwned(i.id))
        .toList();

    if (owned.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                const Text('🎒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Your inventory is empty!',
                    style: TextStyle(
                        color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Buy items from the Marketplace.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) => _ItemCard(item: owned[i], state: state, uid: uid),
        childCount: owned.length,
      ),
    );
  }
}

// ─── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final AvatarItem item;
  final ShopLoaded state;
  final String uid;

  const _ItemCard({required this.item, required this.state, required this.uid});

  Color get _rarityColor => switch (item.rarity) {
        ItemRarity.common => const Color(0xFF9E9E9E),
        ItemRarity.rare => const Color(0xFF2196F3),
        ItemRarity.epic => const Color(0xFF9C27B0),
        ItemRarity.legendary => const Color(0xFFFF8F00),
      };

  String get _rarityLabel => switch (item.rarity) {
        ItemRarity.common => 'Common',
        ItemRarity.rare => 'Rare',
        ItemRarity.epic => 'Epic',
        ItemRarity.legendary => 'Legendary',
      };

  bool get _owned => state.isOwned(item.id);
  bool get _equipped => state.isEquipped(item);
  bool get _locked => state.level < item.unlockLevel;
  bool get _canAfford => state.coins >= item.price;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _equipped
                ? const Color(0xFF4A6CF7)
                : _rarityColor.withOpacity(0.3),
            width: _equipped ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (_equipped
                      ? const Color(0xFF4A6CF7)
                      : _rarityColor)
                  .withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Item emoji preview ──────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _rarityColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  // Owned / equipped checkmark
                  if (_owned)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _equipped
                              ? const Color(0xFF4A6CF7)
                              : Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  // Lock badge
                  if (_locked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock,
                                  color: Colors.white, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                'Lv.${item.unlockLevel}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Rarity pill
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _rarityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _rarityLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Name + action button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
    if (_locked) {
      return _ActionButton(
        label: '🔒 Lv.${item.unlockLevel}',
        color: Colors.grey[400]!,
        enabled: false,
      );
    }
    if (_owned) {
      return _ActionButton(
        label: _equipped ? '✓ Equipped' : 'Equip',
        color: _equipped ? const Color(0xFF4A6CF7) : Colors.green[600]!,
        enabled: true,
      );
    }
    if (item.isFree) {
      return const _ActionButton(
          label: 'Free', color: Colors.green, enabled: false);
    }
    return _ActionButton(
      label: '🪙 ${item.price}',
      color: _canAfford ? const Color(0xFF4A6CF7) : Colors.grey[400]!,
      enabled: _canAfford,
    );
  }

  void _onTap(BuildContext context) {
    if (_locked) return;
    final bloc = context.read<ShopBloc>();
    final s = state;
    if (_owned) {
      bloc.add(EquipItemToggled(
        studentUid: uid,
        item: item,
        currentConfig: s.avatarConfig,
      ));
    } else {
      bloc.add(PurchaseItemRequested(
        studentUid: uid,
        item: item,
        currentCoins: s.coins,
      ));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;

  const _ActionButton(
      {required this.label, required this.color, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        onPressed: enabled ? () {} : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.5),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
