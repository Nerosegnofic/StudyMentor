import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandedHeader extends StatelessWidget {
  final String parentName;

  const BrandedHeader({super.key, required this.parentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Flat rectangle — no border-radius. Shadow cast downward so scrolled
      // content visibly slides under the sticky header.
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000), // soft dark shadow on bottom edge
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: 28.0,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Circular profile avatar (50x50px)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  parentName.isNotEmpty ? parentName[0].toUpperCase() : 'P',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            // Center: "Study Mentor" — Cairo Bold, white, 24px
            Text(
              'Study Mentor',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.3,
              ),
            ),

            // Right: Bell icon with green notification dot
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
