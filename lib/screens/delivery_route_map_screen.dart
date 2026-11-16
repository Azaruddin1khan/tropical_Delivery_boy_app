import 'dart:async';
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

class _DeliveryRouteMapScreenState extends State<DeliveryRouteMapScreen> {
  late final MapController _mapController;
  Timer? _simulationTimer;

  // Nassau, Bahamas Key Landmarks
  static final ll.LatLng storeLocation = kNassauStreetRoute.first;
  static final ll.LatLng customerLocation = kNassauStreetRoute.last;

  double _progress = 0.35; // Start courier 35% along the road
  int _speedKmh = 28;
  bool _isNavigating = true;
  bool _autoFollow = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startGpsSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startGpsSimulation() {
    // Advances courier smoothly along real street nodes
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted || !_isNavigating) return;

      setState(() {
        _progress += 0.015;
        if (_progress >= 1.0) {
          _progress = 0.999;
          _speedKmh = 0;
        } else {
          // Dynamic speed variations around turns and straights
          _speedKmh = 22 + (math.sin(_progress * 20) * 10).abs().toInt();
        }

        if (_autoFollow) {
          _mapController.move(_currentCourierPosition, _mapController.camera.zoom);
        }
      });
    });
  }

  ll.LatLng get _currentCourierPosition {
    if (kNassauStreetRoute.isEmpty) return storeLocation;
    final totalNodes = kNassauStreetRoute.length - 1;
    final floatIndex = (_progress * totalNodes).clamp(0.0, totalNodes.toDouble());
    final index = floatIndex.floor().clamp(0, totalNodes - 1);
    final frac = floatIndex - index;

    final p1 = kNassauStreetRoute[index];
    final p2 = kNassauStreetRoute[index + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

    return ll.LatLng(lat, lng);
  }

  double get _currentHeadingAngle {
    if (kNassauStreetRoute.length < 2) return 0.0;
    final totalNodes = kNassauStreetRoute.length - 1;
    final index = (_progress * totalNodes).floor().clamp(0, totalNodes - 1);
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

  String get _turnByTurnInstruction {
    if (_progress < 0.15) {
      return 'Head West on Bay Street towards Downtown';
    } else if (_progress < 0.45) {
      return 'Follow West Bay Street curve along the coast';
    } else if (_progress < 0.75) {
      return 'Continue straight past Saunders Beach on West Bay St';
    } else if (_progress < 0.95) {
      return 'In 150m, prepare to turn into Customer Gate';
    } else {
      return 'You have arrived at Customer Destination!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final courierPos = _currentCourierPosition;
    final headingAngle = _currentHeadingAngle;

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
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full-Screen Interactive OpenStreetMap with Street-Snapped Routing
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: courierPos,
              initialZoom: 15.2,
              minZoom: 11.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // 100% Free OpenStreetMap Clean Tiles (Zero Watermark)
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

              // Real Road-Snapped Polyline (Turn-by-turn road geometry)
              PolylineLayer(
                polylines: [
                  // Outer Glow / Border for High Contrast
                  Polyline(
                    points: kNassauStreetRoute,
                    color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                    strokeWidth: 8.0,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  // Vibrant Blue Road Route (Like Google Maps / Image 2)
                  Polyline(
                    points: kNassauStreetRoute,
                    color: const Color(0xFF1E88E5),
                    strokeWidth: 5.2,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // A. TG Flagship Kitchen Store Marker
                  Marker(
                    point: storeLocation,
                    width: 75,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: _buildStorePin(),
                  ),

                  // B. Customer Doorstep Marker (Black Home Pin like Image 2)
                  Marker(
                    point: customerLocation,
                    width: 75,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: _buildCustomerPin(),
                  ),

                  // C. Moving Vehicle Marker (Red Scooter rotated to street heading)
                  Marker(
                    point: courierPos,
                    width: 80,
                    height: 58,
                    alignment: Alignment.center,
                    child: _buildCourierPin(_speedKmh, headingAngle),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Turn-by-Turn Guidance Banner
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark slate like Image 1
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
                          _turnByTurnInstruction,
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
                      '$_speedKmh km/h',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Recenter / Auto-Follow Toggle Button
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: _autoFollow ? AppColors.oceanBlueDark : AppColors.textSecondary,
              elevation: 4,
              onPressed: () {
                setState(() {
                  _autoFollow = true;
                });
                _mapController.move(courierPos, 15.5);
              },
              child: Icon(_autoFollow ? Icons.my_location_rounded : Icons.location_searching_rounded),
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

  // Black teardrop home pin matching screenshot 2
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
            'Customer',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Black icon pin like screenshot 2
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

  // Red Scooter vehicle marker rotated to street heading angle (matching screenshot 2)
  Widget _buildCourierPin(int speed, double heading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            '$speed km/h',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFBBF24),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Transform.rotate(
          angle: heading,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626), // Red Scooter like screenshot 2
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
