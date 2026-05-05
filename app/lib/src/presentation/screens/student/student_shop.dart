import 'package:flutter/material.dart';

class StudentShop extends StatelessWidget {
  const StudentShop({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_outlined,
              size: 44,
              color: Color(0xFF4A6CF7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Shop',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4A6CF7).withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A6CF7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Spend your coins on rewards\nand unlock exciting items!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
