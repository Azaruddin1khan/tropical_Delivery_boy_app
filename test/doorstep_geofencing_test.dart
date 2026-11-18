import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_cashier_app/widgets/swipe_to_deliver_button.dart';
import 'package:delivery_cashier_app/screens/delivery_route_map_screen.dart';
import 'package:delivery_cashier_app/models/delivery_order.dart';
import 'package:delivery_cashier_app/models/order_item.dart';
import 'package:delivery_cashier_app/state/staff_app_state.dart';
import 'package:delivery_cashier_app/state/staff_state_scope.dart';

void main() {
  group('Doorstep Geofence & SwipeToDeliver Tests', () {
    testWidgets('SwipeToDeliverButton is locked when enabled: false', (
      WidgetTester tester,
    ) async {
      bool deliveredCalled = false;
      bool disabledTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: SwipeToDeliverButton(
                  enabled: false,
                  disabledLabel: '🔒 Reach Drop Location (1.8 km)',
                  onDisabledTap: () {
                    disabledTapCalled = true;
                  },
                  onDelivered: () {
                    deliveredCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Verify disabled label is displayed with lock icon
      expect(find.text('🔒 Reach Drop Location (1.8 km)'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      // Tap the disabled button
      await tester.tap(find.byType(SwipeToDeliverButton));
      await tester.pump();

      // Verify onDisabledTap was invoked and onDelivered was NOT invoked
      expect(disabledTapCalled, isTrue);
      expect(deliveredCalled, isFalse);

      // Drag attempt while disabled
      await tester.drag(
        find.byType(SwipeToDeliverButton),
        const Offset(200, 0),
      );
      await tester.pump();

      expect(deliveredCalled, isFalse);
    });

    testWidgets(
      'SwipeToDeliverButton triggers onDelivered when enabled: true',
      (WidgetTester tester) async {
        bool deliveredCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: SwipeToDeliverButton(
                    enabled: true,
                    label: 'Delivered',
                    onDelivered: () {
                      deliveredCalled = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Delivered'), findsOneWidget);

        // Swipe from left to right
        await tester.drag(
          find.byType(SwipeToDeliverButton),
          const Offset(280, 0),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(deliveredCalled, isTrue);
      },
    );

    testWidgets(
      'DeliveryRouteMapScreen displays geofence UI and blocks delivery when far',
      (WidgetTester tester) async {
        final order = DeliveryOrder(
          id: 'TG-TEST-01',
          customerName: 'Test Customer',
          customerPhone: '+1 (242) 555-9999',
          deliveryAddress: 'Cable Beach, Nassau, Bahamas',
          orderTime: DateTime.now(),
          items: const [
            OrderItem(name: 'Gyro Bowl', quantity: 1, unitPrice: 12.0),
          ],
          subtotal: 12.0,
          deliveryFee: 3.0,
          tax: 1.0,
          totalAmount: 16.0,
          paymentMethod: 'Credit Card',
          isPaid: true,
          status: DeliveryOrderStatus.outForDelivery,
          barcodeCode: 'TG-BC-TEST',
          qrCode: 'TG-QR-TEST',
          orderType: 'delivery',
        );

        final state = StaffAppState();

        await tester.pumpWidget(
          MaterialApp(
            home: StaffStateScope(
              state: state,
              child: DeliveryRouteMapScreen(order: order),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        // Verify Screen title
        expect(
          find.text('Live Street Navigation • #TG-TEST-01'),
          findsOneWidget,
        );

        // Initial state is at store (>200m away), so geofence warning is displayed
        expect(find.byIcon(Icons.location_off_rounded), findsWidgets);

        // Tap disabled swipe to trigger proximity check dialog
        await tester.tap(find.byType(SwipeToDeliverButton));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Doorstep Geofence dialog appears
        expect(find.text('Doorstep Geofence'), findsOneWidget);
        expect(find.text('⚡ Test: Jump to Doorstep'), findsOneWidget);

        // Tap Jump to Doorstep shortcut
        await tester.tap(find.text('⚡ Test: Jump to Doorstep'));
        await tester.pump(const Duration(milliseconds: 300));

        // Now within 200m! Doorstep green badge should appear
        expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      },
    );
  });
}
