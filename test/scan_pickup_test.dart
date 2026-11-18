import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_cashier_app/main.dart';
import 'package:delivery_cashier_app/models/delivery_order.dart';
import 'package:delivery_cashier_app/state/staff_state_scope.dart';

void main() {
  testWidgets('Scan pickup barcode flow: verify bag and transition to outForDelivery', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // 1. Log in as driver
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // 2. Locate order TG-8095 in Assigned Orders tab
    expect(find.text('TG-8095'), findsOneWidget);
    expect(find.text('Aaliyah Davis'), findsOneWidget);

    // Verify the direct action button "Scan Kitchen Bag to Pickup" exists on the card
    final scanBagButton = find.widgetWithText(
      ElevatedButton,
      'Scan Kitchen Bag to Pickup',
    );
    expect(scanBagButton, findsOneWidget);
    await tester.ensureVisible(scanBagButton);
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Tap "Scan Kitchen Bag to Pickup" from the card
    await tester.tap(scanBagButton);
    await tester.pump(); // Push route
    await tester.pump(const Duration(milliseconds: 400)); // Route animated in, postFrameCallback scheduled
    await tester.pump(const Duration(milliseconds: 400)); // BottomSheet opened & animated in

    // 4. Verify the scanner opened and triggered verification for TG-8095
    expect(find.text('Kitchen Bag Verified! ✓'), findsOneWidget);
    expect(find.text('Code: TG-BC-8095'), findsOneWidget);
    expect(find.text('Customer: Aaliyah Davis'), findsOneWidget);
    expect(find.text('🛵 Confirm Pickup'), findsOneWidget);

    // 5. Tap "Confirm Pickup"
    await tester.tap(find.text('🛵 Confirm Pickup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 6. Verify order status has transitioned to outForDelivery in the app state
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    final state = StaffStateScope.read(context);
    final order = state.assignedOrders.firstWhere((o) => o.id == 'TG-8095');
    expect(order.status, equals(DeliveryOrderStatus.outForDelivery));
  });

  testWidgets('Scanner screen quick chip selectors & simulate scan test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // Login
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Switch to Scan Pickup tab
    await tester.tap(find.text('Scan Pickup'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify quick scan selector chips are rendered
    expect(find.text('Quick Scan Selectors (Demo):'), findsOneWidget);
    expect(find.text('Bag #TG-8095'), findsOneWidget);
    expect(find.text('Doorstep #TG-8092'), findsOneWidget);

    // Tap the Doorstep #TG-8092 chip
    await tester.tap(find.text('Doorstep #TG-8092'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify doorstep verification sheet appears
    expect(find.text('Doorstep Handover Verified! ✓'), findsOneWidget);
    expect(find.text('Code: TG-BC-8092'), findsOneWidget);
    expect(find.text('Customer: Marcus Bennett'), findsOneWidget);
  });
}
