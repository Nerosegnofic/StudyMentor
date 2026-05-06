import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/shop/shop_bloc.dart';
import '../../../bloc/shop/shop_event.dart';
import '../../../domain/models/avatar_config.dart';
import '../../widgets/avatar_widget.dart';

class StudentAvatarCustomization extends StatefulWidget {
  final String uid;
  final AvatarConfig config;

  const StudentAvatarCustomization({
    super.key,
    required this.uid,
    required this.config,
  });

  @override
  State<StudentAvatarCustomization> createState() =>
      _StudentAvatarCustomizationState();
}

class _StudentAvatarCustomizationState
    extends State<StudentAvatarCustomization> {
  late AvatarConfig _config;

  static const _skinTones = [
    ('light', Color(0xFFFFDBAC), '🏻'),
    ('medium_light', Color(0xFFEEC27B), '🏼'),
    ('medium', Color(0xFFC68642), '🏽'),
    ('medium_dark', Color(0xFF8D5524), '🏾'),
    ('dark', Color(0xFF4A2C0A), '🏿'),
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _setGender(String gender) {
    setState(() => _config = _config.copyWith(gender: gender));
  }

  void _setSkin(String tone) {
    setState(() => _config = _config.copyWith(skinTone: tone));
  }

  void _save() {
    context.read<ShopBloc>().add(
          AvatarCustomizationChanged(
            studentUid: widget.uid,
            newConfig: _config,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        backgroundColor: const Color(0xFFF5F7FF),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF4A6CF7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar preview ─────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  AvatarWidget(config: _config, size: 150),
                  const SizedBox(height: 12),
                  Text(
                    'Looking great! ✨',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Gender selection ───────────────────────────────────────────
            _sectionLabel('Gender'),
            const SizedBox(height: 10),
            Row(
              children: [
                _GenderButton(
                  label: '♂ Boy',
                  selected: _config.gender == 'male',
                  color: const Color(0xFF4A6CF7),
                  onTap: () => _setGender('male'),
                ),
                const SizedBox(width: 12),
                _GenderButton(
                  label: '♀ Girl',
                  selected: _config.gender == 'female',
                  color: const Color(0xFFE91E8C),
                  onTap: () => _setGender('female'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Skin tone ─────────────────────────────────────────────────
            _sectionLabel('Skin Tone'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _skinTones
                  .map(
                    (t) => GestureDetector(
                      onTap: () => _setSkin(t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: t.$2,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _config.skinTone == t.$1
                                ? const Color(0xFF4A6CF7)
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: _config.skinTone == t.$1
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4A6CF7)
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: _config.skinTone == t.$1
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),

            // ── Equipped summary ───────────────────────────────────────────
            _sectionLabel('Currently Equipped'),
            const SizedBox(height: 10),
            _EquippedSummary(config: _config),
            const SizedBox(height: 24),

            // ── Save button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Save Avatar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      );
}

// ─── Gender button ────────────────────────────────────────────────────────────

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Equipped summary ─────────────────────────────────────────────────────────

class _EquippedSummary extends StatelessWidget {
  final AvatarConfig config;

  const _EquippedSummary({required this.config});

  @override
  Widget build(BuildContext context) {
    final slots = [
      ('Hair', config.equippedHair),
      ('Outfit', config.equippedOutfit),
      ('Bottom', config.equippedBottom),
      ('Shoes', config.equippedShoes),
      ('Accessory', config.equippedAccessory),
      ('Background', config.equippedBackground),
      ('Special', config.equippedSpecial),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: slots.map((slot) {
          final equipped = slot.$2 != null;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    slot.$1,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                equipped
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          slot.$2!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        'None',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400]),
                      ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
