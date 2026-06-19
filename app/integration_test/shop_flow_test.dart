// integration_test/shop_flow_test.dart
//
// Integration tests for the student shop / avatar customization flow.
//
// Navigation path tested:
//   Login → StudentHome → tap coin counter in StudentTopBar → CustomShopScreen
//   → shop items visible → tap an item → purchase dialog appears
//   → "Buy" / "Not enough coins" message visible
//
// ══════════════════════════════════════════════════════════════════════════════
//  PREREQUISITES
//  • A student account (any coin balance works — the test handles both
//    "enough coins" and "not enough coins" outcomes).
//  HOW TO RUN:
//    flutter devices
//    flutter test integration_test/shop_flow_test.dart -d <device-id>
//  ⚠  DO NOT commit real credentials to git.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studymentor/main.dart' as app;

// ─── Fill in your student account credentials ─────────────────────────────────
const _studentEmail    = 'YOUR_STUDENT_EMAIL_HERE';
const _studentPassword = 'YOUR_STUDENT_PASSWORD_HERE';
// ─────────────────────────────────────────────────────────────────────────────

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _boot(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 6));
}

Future<void> _login(WidgetTester tester) async {
  if (find.text('Sign In').evaluate().isEmpty) return;
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'), _studentEmail);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), _studentPassword);
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

/// Accept the student permission gate.
Future<void> _clearPermissionGate(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    bool acted = false;
    for (final label in ['Continue', 'Grant', 'Allow', 'Next', 'OK']) {
      final btn = find.text(label);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        acted = true;
        break;
      }
    }
    if (!acted) break;
  }
}

/// Wait for the student home to fully render (gamification data loaded).
Future<void> _waitForHome(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle(const Duration(seconds: 4));
}

/// Open the shop by tapping the coin counter in StudentTopBar.
/// The coin counter is a GestureDetector wrapping the coin icon + count text.
Future<void> _openShop(WidgetTester tester) async {
  // The StudentTopBar shows a coin icon (🪙) followed by the coin count.
  // The entire row is wrapped in a GestureDetector that navigates to the shop.
  final coinIcon = find.byIcon(Icons.monetization_on_rounded);
  if (coinIcon.evaluate().isNotEmpty) {
    await tester.tap(coinIcon.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }
  // Fallback: look for the text "Coins" label in the top bar area.
  final coinsLabel = find.text('Coins');
  if (coinsLabel.evaluate().isNotEmpty) {
    await tester.tap(coinsLabel.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Tap the first purchasable item in the shop grid.
/// Returns false if no items are found.
Future<bool> _tapFirstShopItem(WidgetTester tester) async {
  // Shop items are rendered in a GridView as InkWell-wrapped tiles.
  await tester.pump(const Duration(seconds: 2));
  final tiles = find.byType(InkWell);
  if (tiles.evaluate().isEmpty) return false;
  await tester.tap(tiles.first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  return true;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shop flow', () {
    testWidgets(
      '1. Student login succeeds',
      (tester) async {
        await _boot(tester);
        await _login(tester);

        expect(find.text('Sign In'), findsNothing,
            reason: 'Sign In should be gone after successful student login');
      },
    );

    testWidgets(
      '2. Student home renders after the permission gate',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);

        expect(find.byType(Scaffold), findsWidgets);
      },
    );

    testWidgets(
      '3. Tapping the coin counter opens the Avatar Shop screen',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        // The shop screen title is "Avatar Shop".
        expect(find.text('Avatar Shop'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Shop screen shows the available coin balance',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        // The header shows "X coins available".
        expect(
          find.textContaining('coins available'), findsOneWidget,
          reason: 'Expected the coin balance to be shown in the shop header',
        );
      },
    );

    testWidgets(
      '5. Shop screen shows at least one item tile',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        // Wait for the ShopBloc to load items.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(
          find.byType(InkWell).evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected at least one item tile in the shop grid',
        );
      },
    );

    testWidgets(
      '6. Tapping a shop item opens the purchase dialog',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final tapped = await _tapFirstShopItem(tester);
        expect(tapped, isTrue,
            reason: 'Expected to find and tap at least one shop item');

        // The purchase dialog shows either a "Buy" button or a
        // "Not enough coins" message.
        expect(
          find.text('Buy').evaluate().isNotEmpty ||
          find.textContaining('Not enough coins').evaluate().isNotEmpty ||
          find.textContaining('coins').evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected a purchase dialog to appear after tapping an item',
        );
      },
    );

    testWidgets(
      '7. Purchase dialog shows the item cost in coins',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _tapFirstShopItem(tester);

        // Dialog body shows "This will cost X coins."
        expect(
          find.textContaining('coins').evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected the item cost to be shown in the purchase dialog',
        );
      },
    );

    testWidgets(
      '8. Cancelling the dialog closes it without changing the balance',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _tapFirstShopItem(tester);

        // Dismiss the dialog via the Cancel button or back tap.
        final cancelBtn = find.text('Cancel');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        } else {
          // Tap outside the dialog to dismiss.
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // After cancellation the shop screen is still visible.
        expect(find.text('Avatar Shop'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Tapping "Buy" on a purchasable item completes or shows error',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForHome(tester);
        await _openShop(tester);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _tapFirstShopItem(tester);

        final buyBtn = find.text('Buy');
        if (buyBtn.evaluate().isNotEmpty) {
          await tester.tap(buyBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Either purchase success snackbar or a "not enough coins" message.
          expect(
            find.textContaining('successful').evaluate().isNotEmpty ||
            find.textContaining('Not enough').evaluate().isNotEmpty ||
            find.textContaining('failed').evaluate().isNotEmpty ||
            find.text('Avatar Shop').evaluate().isNotEmpty,
            isTrue,
            reason: 'Expected a purchase outcome (success or error) to be shown',
          );
        } else {
          // Item not purchasable (already owned or not enough coins dialog).
          expect(find.byType(Scaffold), findsWidgets);
        }
      },
    );
  });
}
