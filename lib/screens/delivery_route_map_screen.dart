import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../core/constants/app_constants.dart';
import '../core/constants/nassau_route_data.dart';
import '../core/theme/app_colors.dart';
import '../models/delivery_order.dart';
import '../state/staff_app_state.dart';
import '../state/staff_state_scope.dart';
import 'barcode_scanner_screen.dart';

class DeliveryRouteMapScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryRouteMapScreen({super.key, required this.order});

  @override
  State<DeliveryRouteMapScreen> createState() => _DeliveryRouteMapScreenState();
}

class _DeliveryRouteMapScreenState extends State<DeliveryRouteMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _animController;

  // Nassau, Bahamas Key Landmarks
  static final ll.LatLng storeLocation = kNassauStreetRoute.first;
  static final ll.LatLng customerLocation = kNassauStreetRoute.last;

  bool _isNavigating = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // 60 FPS Buttery-Smooth Continuous Route Animation (Zero Lag, Zero Hang)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    );

    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Smooth position interpolation across 407 street nodes (at 60 FPS)
  ll.LatLng _getCourierPosition(double progress) {
    if (kNassauStreetRoute.isEmpty) return storeLocation;
    final totalNodes = kNassauStreetRoute.length - 1;
    final floatIndex = (progress * totalNodes).clamp(
      0.0,
      totalNodes.toDouble(),
    );
    final index = floatIndex.floor().clamp(0, totalNodes - 1);
    final frac = floatIndex - index;

    final p1 = kNassauStreetRoute[index];
    final p2 = kNassauStreetRoute[index + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

    return ll.LatLng(lat, lng);
  }

  // Smooth bearing / rotation angle calculation along street curves
  double _getHeadingAngle(double progress) {
    if (kNassauStreetRoute.length < 2) return 0.0;
    final totalNodes = kNassauStreetRoute.length - 1;
    final index = (progress * totalNodes).floor().clamp(0, totalNodes - 1);
    final p1 = kNassauStreetRoute[index];
    final p2 = kNassauStreetRoute[index + 1];

    final dLng = (p2.longitude - p1.longitude) * (math.pi / 180.0);
    final lat1 = p1.latitude * (math.pi / 180.0);
    final lat2 = p2.latitude * (math.pi / 180.0);

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    return math.atan2(y, x);
  }

  // Calculate distance between current courier position and customer doorstep (in meters)
  double _getDistanceToDropMeters(ll.LatLng courierPos) {
    const distanceCalc = ll.Distance();
    return distanceCalc.as(ll.LengthUnit.Meter, courierPos, customerLocation);
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    } else {
      final km = meters / 1000;
      final miles = meters / AppConstants.metersPerMile;
      return '${miles.toStringAsFixed(1)} mi (${km.toStringAsFixed(1)} km)';
    }
  }

  String _getInstruction(double progress, bool isNearDrop) {
    if (isNearDrop) {
      return 'Arrived at Customer Doorstep!';
    }
    if (progress < 0.15) {
      return 'Head West on Bay Street towards Downtown';
    } else if (progress < 0.45) {
      return 'Follow West Bay Street curve along the coast';
    } else if (progress < 0.75) {
      return 'Continue straight past Saunders Beach on West Bay St';
    } else if (progress < 0.95) {
      return 'In 150m, prepare to turn into Customer Gate';
    } else {
      return 'Arriving at Customer Doorstep!';
    }
  }

  void _jumpToDoorstep() {
    _animController.stop();
    setState(() {
      _isNavigating = false;
      _animController.value = 1.0; // Directly at customer doorstep (0m)
    });
    final doorstepPos = _getCourierPosition(1.0);
    _mapController.move(doorstepPos, 16.5);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚡ Arrived within 200m Doorstep Zone! Swipe to Deliver is now UNLOCKED! 🎉',
        ),
        backgroundColor: AppColors.limeGreenDark,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetToStore() {
    _animController.stop();
    setState(() {
      _isNavigating = false;
      _animController.value = 0.0;
    });
    _mapController.move(storeLocation, 14.2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⏮️ Reset to Store (>200m away) — Swipe to Deliver is now LOCKED!',
        ),
        backgroundColor: Color(0xFFF59E0B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showManualCodeEntryDialog(BuildContext context) {
    final textController = TextEditingController(
      text: widget.order.customerDropCode,
    );
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.pin_rounded, color: AppColors.oceanBlue),
                SizedBox(width: 8),
                Text(
                  'Enter Drop Code',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask the customer for their Delivery Pass code (from customer app "View Delivery Pass"):',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Drop Pass Code',
                    hintText: 'e.g. DROP-${widget.order.id}',
                    prefixIcon: const Icon(Icons.qr_code_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText: errorMessage,
                  ),
                ),
                if (widget.order.requiresCashCollection) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrangeLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cash to Collect (COD):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warningOrange,
                          ),
                        ),
                        Text(
                          '${AppConstants.currency}${widget.order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final inputCode = textController.text
                            .trim()
                            .toUpperCase();
                        if (inputCode.isEmpty) {
                          setDialogState(
                            () => errorMessage = 'Please enter a code',
                          );
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final dialogNav = Navigator.of(dialogCtx);
                        final state = StaffStateScope.read(context);

                        try {
                          final verifiedOrder = await state
                              .findOrderByCodeOrFetch(inputCode);
                          if (verifiedOrder == null) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = 'Invalid code. Order not found.';
                            });
                            return;
                          }

                          if (verifiedOrder.id != widget.order.id) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage =
                                  'This code is for a different order (#${verifiedOrder.id}).';
                            });
                            return;
                          }

                          // Check if Kitchen Bag code was entered by mistake
                          final isKitchenBagCode =
                              inputCode.startsWith('KB') ||
                              inputCode.contains('KB-') ||
                              inputCode.contains('/KITCHEN');
                          if (isKitchenBagCode) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage =
                                  'This is the kitchen pickup code. Please enter the Customer Delivery Pass code (DROP-${widget.order.id}).';
                            });
                            return;
                          }

                          // Success! Complete delivery
                          state.markOrderDelivered(widget.order.id);
                          dialogNav.pop();
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order #${widget.order.id} verified and marked Delivered! 🎉',
                              ),
                              backgroundColor: AppColors.limeGreenDark,
                            ),
                          );
                        } on OrderAssignmentException catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = e.message;
                          });
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = 'Verification failed: $e';
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify & Deliver'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = StaffStateScope.of(context);
    final activeOrder = state.findOrderByCode(widget.order.id);
    if (activeOrder == null ||
        activeOrder.status == DeliveryOrderStatus.delivered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    // Initial camera centered comfortably on Nassau route
    const initialCenter = ll.LatLng(25.0590, -77.3750);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Live Street Navigation • #${widget.order.id}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          // Scan Customer Drop Pass button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Customer Drop Pass',
            color: AppColors.oceanBlueDark,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BarcodeScannerScreen(
                    targetOrderCode: widget.order.customerDropCode,
                  ),
                ),
              );
            },
          ),

          // Play / Pause GPS stream simulation
          IconButton(
            icon: Icon(
              _isNavigating
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_fill_rounded,
              color: _isNavigating
                  ? AppColors.tropicalYellowDark
                  : AppColors.limeGreenDark,
              size: 26,
            ),
            tooltip: _isNavigating ? 'Pause GPS Stream' : 'Resume GPS Stream',
            onPressed: () {
              setState(() {
                _isNavigating = !_isNavigating;
                if (_isNavigating) {
                  _animController.repeat();
                } else {
                  _animController.stop();
                }
              });
            },
          ),

          // Demo Geofence Shortcuts Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Geofence Demo Shortcuts',
            onSelected: (val) {
              if (val == 'jump') _jumpToDoorstep();
              if (val == 'reset') _resetToStore();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'jump',
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: AppColors.limeGreenDark,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text('⚡ Test: Arrive at Doorstep (<200m)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text('⏮️ Reset to Store (>200m)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. High-Performance OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0,
              minZoom: 11.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Clean OSM Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tropicalgyros.courier',
                maxZoom: 19,
              ),

              // Strict 3.0-Mile Restaurant Dispatch Geofence & 200m Doorstep Geofence
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final t = _animController.value;
                  final courierPos = _getCourierPosition(t);
                  final distanceMeters = _getDistanceToDropMeters(courierPos);
                  final isNearDrop =
                      distanceMeters <=
                      AppConstants.dropLocationProximityMeters;

                  return CircleLayer(
                    circles: [
                      // A. 3.0-Mile Dispatch Boundary Circle around TG Store
                      CircleMarker(
                        point: storeLocation,
                        radius: AppConstants.deliveryRadiusMeters,
                        useRadiusInMeter: true,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                        borderColor: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.6),
                        borderStrokeWidth: 1.5,
                      ),

                      // B. Strict 200-Meter Customer Doorstep Delivery Geofence Circle
                      CircleMarker(
                        point: customerLocation,
                        radius: AppConstants.dropLocationProximityMeters,
                        useRadiusInMeter: true,
                        color: isNearDrop
                            ? const Color(0xFF10B981).withValues(alpha: 0.22)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.10),
                        borderColor: isNearDrop
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.8),
                        borderStrokeWidth: isNearDrop ? 2.5 : 1.5,
                      ),
                    ],
                  );
                },
              ),

              // Real Road-Snapped Route (Static 60 FPS GPU rendered)
              PolylineLayer(
                polylines: [
                  // Outer subtle border
                  Polyline(
                    points: kNassauStreetRoute,
                    color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                    strokeWidth: 8.0,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  // Vibrant Blue Road Route
                  Polyline(
                    points: kNassauStreetRoute,
                    color: const Color(0xFF1E88E5),
                    strokeWidth: 5.2,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),

              // Markers Layer: ONLY the moving marker is rebuilt at 60 FPS!
              AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final t = _animController.value;
                  final courierPos = _getCourierPosition(t);
                  final heading = _getHeadingAngle(t);
                  final speed = 24 + (math.sin(t * 12) * 8).abs().toInt();
                  final distanceMeters = _getDistanceToDropMeters(courierPos);
                  final isNearDrop =
                      distanceMeters <=
                      AppConstants.dropLocationProximityMeters;

                  return MarkerLayer(
                    markers: [
                      // A. TG Flagship Kitchen Store
                      Marker(
                        point: storeLocation,
                        width: 100,
                        height: 65,
                        alignment: Alignment.topCenter,
                        child: _buildStorePin(),
                      ),

                      // B. Customer Doorstep Pin (With Proximity Status Badge)
                      Marker(
                        point: customerLocation,
                        width: 100,
                        height: 65,
                        alignment: Alignment.topCenter,
                        child: _buildCustomerPin(isNearDrop),
                      ),

                      // C. Smooth 60 FPS Gliding 3D Courier Scooter
                      Marker(
                        point: courierPos,
                        width: 90,
                        height: 105,
                        alignment: Alignment.center,
                        child: _buildCourierPin(speed, heading),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // 2. Top Turn-by-Turn Guidance Banner
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final t = _animController.value;
                final courierPos = _getCourierPosition(t);
                final distanceMeters = _getDistanceToDropMeters(courierPos);
                final isNearDrop =
                    distanceMeters <= AppConstants.dropLocationProximityMeters;
                final instruction = _getInstruction(t, isNearDrop);
                final speed = 24 + (math.sin(t * 12) * 8).abs().toInt();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isNearDrop
                        ? const Color(0xFF064E3B)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(18),
                    border: isNearDrop
                        ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isNearDrop
                              ? const Color(0xFF10B981)
                              : AppColors.limeGreenDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isNearDrop
                              ? Icons.verified_rounded
                              : Icons.turn_slight_right_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              instruction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isNearDrop
                                  ? 'Within 200m zone • Ready for delivery completion'
                                  : 'Destination: ${widget.order.deliveryAddress} • ${_formatDistance(distanceMeters)} away',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isNearDrop
                                    ? const Color(0xFFA7F3D0)
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: isNearDrop
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$speed km/h',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Floating Recenter Courier Button
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.oceanBlueDark,
              elevation: 4,
              onPressed: () {
                final currentPos = _getCourierPosition(_animController.value);
                _mapController.move(currentPos, 15.2);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // 4. Bottom Order Dispatch & Doorstep Delivery Panel with Strict Geofence Protection
          Positioned(
            bottom: 16,
            left: 14,
            right: 14,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final t = _animController.value;
                final courierPos = _getCourierPosition(t);
                final distanceMeters = _getDistanceToDropMeters(courierPos);
                final isNearDrop =
                    distanceMeters <= AppConstants.dropLocationProximityMeters;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: isNearDrop
                        ? Border.all(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.6),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Customer info & direct call button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isNearDrop
                                  ? const Color(0xFFD1FAE5)
                                  : AppColors.tropicalYellowLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: isNearDrop
                                  ? const Color(0xFF059669)
                                  : AppColors.tropicalYellowDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  widget.order.deliveryAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.limeGreen.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            icon: const Icon(
                              Icons.phone_rounded,
                              color: AppColors.limeGreenDark,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Calling customer ${widget.order.customerPhone} 📞',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Proximity Status Pill Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isNearDrop
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isNearDrop
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isNearDrop
                                  ? Icons.check_circle_rounded
                                  : Icons.location_off_rounded,
                              size: 16,
                              color: isNearDrop
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isNearDrop
                                    ? '✓ At Customer Doorstep (${distanceMeters.toInt()}m) • Ready to Deliver'
                                    : 'Drop Geofence: ${_formatDistance(distanceMeters)} away • Reach within 200m to deliver',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isNearDrop
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Verification requirement notice
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: AppColors.oceanBlueDark,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Scan customer pass or enter code to complete delivery.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.oceanBlueDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Button 1: Scan Customer Drop Pass (Camera QR / Barcode)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Scan Customer Drop Pass',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.limeGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BarcodeScannerScreen(
                                  targetOrderCode:
                                      widget.order.customerDropCode,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Button 2: Enter Drop Code Manually
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.keyboard_alt_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Enter Drop Code Manually',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.oceanBlue,
                            side: const BorderSide(color: AppColors.oceanBlue),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _showManualCodeEntryDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorePin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3,
              ),
            ],
          ),
          child: const Text(
            'TG Flagship',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.warningOrange,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 12),
        ),
      ],
    );
  }

  // Teardrop customer pin with live proximity color update
  Widget _buildCustomerPin(bool isNearDrop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: isNearDrop ? const Color(0xFF10B981) : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isNearDrop ? Colors.white : AppColors.border,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Text(
            isNearDrop ? 'Doorstep ✓' : 'Drop Location',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isNearDrop ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isNearDrop
                ? const Color(0xFF10B981)
                : const Color(0xFF0F172A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  // 3D Isometric Green Courier on Scooter
  Widget _buildCourierPin(int speed, double heading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speed Tag Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '$speed km/h',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),

        // 3D Isometric Green Courier on Scooter
        Builder(
          builder: (context) {
            final isWestbound = math.sin(heading) < 0;
            final banking = (math.cos(heading) * 0.12).clamp(-0.16, 0.16);

            return Transform.rotate(
              angle: banking,
              child: Transform.scale(
                scaleX: isWestbound ? -1.0 : 1.0,
                child: Image.asset(
                  'assets/images/delivery_boy_3d.png',
                  width: 54,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
