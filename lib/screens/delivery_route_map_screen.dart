import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../core/constants/nassau_route_data.dart';
import '../core/theme/app_colors.dart';
import '../models/delivery_order.dart';
import '../state/staff_state_scope.dart';

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
    final floatIndex = (progress * totalNodes).clamp(0.0, totalNodes.toDouble());
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
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    return math.atan2(y, x);
  }

  String _getInstruction(double progress) {
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

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: Icon(
              _isNavigating ? Icons.pause_circle_rounded : Icons.play_circle_fill_rounded,
              color: _isNavigating ? AppColors.tropicalYellowDark : AppColors.limeGreenDark,
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
        ],
      ),
      body: Stack(
        children: [
          // 1. High-Performance OpenStreetMap (Tiles & Polyline NEVER rebuild on ticks!)
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
              // Clean OSM Tiles (100% Free, Zero Watermark, Cached & Smooth)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tropicalgyros.courier',
                maxZoom: 19,
              ),

              // Strict 3.0-Mile Dispatch Boundary Circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: storeLocation,
                    radius: 4828,
                    useRadiusInMeter: true,
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                    borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                    borderStrokeWidth: 1.5,
                  ),
                ],
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
                  // Vibrant Blue Road Route (Like Google Maps / Reference Screenshot)
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

                  return MarkerLayer(
                    markers: [
                      // A. TG Flagship Kitchen Store
                      Marker(
                        point: storeLocation,
                        width: 75,
                        height: 50,
                        alignment: Alignment.topCenter,
                        child: _buildStorePin(),
                      ),

                      // B. Customer Doorstep (Black Home Pin like Reference Screenshot)
                      Marker(
                        point: customerLocation,
                        width: 75,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: _buildCustomerPin(),
                      ),

                      // C. Buttery Smooth 60 FPS Gliding 3D Courier Scooter
                      Marker(
                        point: courierPos,
                        width: 70,
                        height: 95,
                        alignment: Alignment.center,
                        child: _buildCourierPin(speed, heading),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // 2. Top Turn-by-Turn Guidance Banner (Updated smoothly via AnimatedBuilder)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final t = _animController.value;
                final instruction = _getInstruction(t);
                final speed = 24 + (math.sin(t * 12) * 8).abs().toInt();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(18),
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
                          color: AppColors.limeGreenDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.turn_slight_right_rounded,
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
                              'Destination: ${widget.order.deliveryAddress}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            bottom: 230,
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

          // 4. Bottom Order Dispatch & Doorstep Delivery Panel
          Positioned(
            bottom: 16,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tropicalYellowLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          color: AppColors.tropicalYellowDark,
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
                          backgroundColor: AppColors.limeGreen.withValues(alpha: 0.15),
                        ),
                        icon: const Icon(Icons.phone_rounded, color: AppColors.limeGreenDark),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling customer ${widget.order.customerPhone} 📞'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text(
                        'Mark Order Delivered at Doorstep',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        final state = StaffStateScope.read(context);
                        state.updateOrderStatus(widget.order.id, DeliveryOrderStatus.delivered);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order #${widget.order.id} marked as Delivered! 🎉'),
                            backgroundColor: AppColors.limeGreenDark,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
            'TG Store',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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

  // Black teardrop home pin matching reference screenshot
  Widget _buildCustomerPin() {
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
            'Home',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
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
          child: const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }

  // 3D Isometric Green Courier on Scooter (matching reference icon)
  Widget _buildCourierPin(int speed, double heading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speed Tag Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
              const SizedBox(width: 4),
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
        const SizedBox(height: 2),

        // 3D Isometric Green Courier on Scooter
        Transform.rotate(
          angle: heading,
          child: Image.asset(
            'assets/images/delivery_boy_3d.png',
            width: 52,
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
