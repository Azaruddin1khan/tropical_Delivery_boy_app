import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_cashier_app/main.dart';
import 'package:delivery_cashier_app/core/constants/app_constants.dart';

void main() {
  testWidgets('Staff login smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // Verify login screen elements
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Sign In (Demo)'), findsOneWidget);

    // Tap Sign In button
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify navigation to MainNavigation
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Scan Pickup'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('Assigned orders view and navigation test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // Login
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify orders are displayed
    expect(find.text('TG-8092'), findsOneWidget);
    expect(find.text('Marcus Bennett'), findsOneWidget);

    // Tap order to open details
    await tester.tap(find.text('TG-8092'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify order details screen
    expect(find.text('Order TG-8092'), findsOneWidget);
    expect(find.text('Customer & Destination'), findsOneWidget);
    expect(find.text('Jerk Chicken Gyro'), findsOneWidget);
  });

  testWidgets('Mark cash received local state test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // Login
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Open TG-8092 which requires cash
    await tester.tap(find.text('TG-8092'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Cash Due button exists and scroll to it
    final cashButton = find.text('Mark Cash Received (\$58.21)');
    expect(cashButton, findsOneWidget);
    await tester.ensureVisible(cashButton);
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Mark Cash Received
    await tester.tap(cashButton);
    await tester.pump(const Duration(milliseconds: 400));

    // Confirm in dialog
    expect(find.text('Confirm Cash Collection'), findsOneWidget);
    await tester.tap(find.text('Confirm Cash Received'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify cash button is gone (already paid)
    expect(find.text('Mark Cash Received (\$58.21)'), findsNothing);
  });

  testWidgets('Barcode scan screen tab test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // Login
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Switch to Scan Pickup tab
    await tester.tap(find.text('Scan Pickup'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify scanner screen
    expect(find.text('Scan Customer Order Barcode / QR'), findsOneWidget);
    expect(find.text('Simulate Scan Customer Barcode (Demo)'), findsOneWidget);
  });

  testWidgets('Delivery history records view test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DeliveryCashierApp());

    // Login
    await tester.tap(find.text('Sign In (Demo)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Switch to History tab
    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify history records
    expect(find.text('Completed Today'), findsOneWidget);
    expect(find.text('TG-8080'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
  });
}
