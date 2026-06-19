// test/widgets/avatar_widget_test.dart
//
// Smoke tests for AvatarWidget — uses GetMaterialApp to satisfy GetX DI.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/src/domain/models/avatar_config.dart';
import 'package:studymentor/src/presentation/widgets/avatar_widget.dart';

Widget _wrap(Widget child) => GetMaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    // Reset GetX service locator between tests.
    Get.reset();
  });

  group('AvatarWidget', () {
    testWidgets('renders without throwing with default AvatarConfig',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const AvatarWidget(config: AvatarConfig.defaults)));
      await tester.pump();

      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('renders a SvgPicture inside a ClipOval', (tester) async {
      await tester.pumpWidget(
          _wrap(const AvatarWidget(config: AvatarConfig.defaults)));
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('respects the size parameter via SizedBox', (tester) async {
      await tester.pumpWidget(
          _wrap(const AvatarWidget(config: AvatarConfig.defaults, size: 80)));
      await tester.pump();

      final box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(ClipOval),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, 80);
      expect(box.height, 80);
    });

    testWidgets('renders with a custom AvatarConfig without crashing',
        (tester) async {
      const config = AvatarConfig(
        gender: 'female',
        skinTone: 'light',
      );
      await tester.pumpWidget(_wrap(const AvatarWidget(config: config)));
      await tester.pump();

      expect(find.byType(AvatarWidget), findsOneWidget);
    });
  });
}
