import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

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

  // Nassau, Bahamas Standard Locations
  static const ll.LatLng storeLocation = ll.LatLng(25.0478, -77.3554); // Bay St Flagship Store
  static const ll.LatLng customerLocation = ll.LatLng(25.0680, -77.3950); // Customer Destination

  // Nassau delivery route waypoints
  static const List<ll.LatLng> nassauRoute = [
    ll.LatLng(25.0478, -77.3554), // Store
    ll.LatLng(25.0515, -77.3620), // Downtown Bay St
    ll.LatLng(25.0560, -77.3710), // Arawak Cay
    ll.LatLng(25.0610, -77.3820), // Saunders Beach
    ll.LatLng(25.0680, -77.3950), // Customer Address
  ];

  double _progress = 0.40;
  int _speedKmh = 29;
  bool _isNavigating = true;

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
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isNavigating) return;

      setState(() {
        _progress += 0.04;
        if (_progress >= 0.98) {
          _progress = 0.98;
          _speedKmh = 0;
        } else {
          _speedKmh = 24 + (_progress * 12).toInt() % 10;
        }
      });
    });
  }

  ll.LatLng get _currentCourierPosition {
    if (nassauRoute.length < 2) return storeLocation;
    final totalSegments = nassauRoute.length - 1;
    final segment = (_progress * totalSegments).floor().clamp(0, totalSegments - 1);
    final segmentProgress = (_progress * totalSegments) - segment;

    final p1 = nassauRoute[segment];
    final p2 = nassauRoute[segment + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * segmentProgress;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * segmentProgress;

    return ll.LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final courierPos = _currentCourierPosition;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Route Navigation • #${widget.order.id}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
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
          // 1. Full-Screen Interactive OpenStreetMap Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: courierPos,
              initialZoom: 14.2,
              minZoom: 11.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Free OpenStreetMap Tiles (Zero Watermark)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tropicalgyros.courier',
                maxZoom: 19,
              ),

              // 3.0-Mile Strict Operational Dispatch Boundary
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: storeLocation,
                    radius: 4828, // 3.0 miles in meters
                    useRadiusInMeter: true,
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.07),
                    borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.7),
                    borderStrokeWidth: 1.6,
                  ),
                ],
              ),

              // Route Polyline Connecting Store to Customer
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: nassauRoute,
                    color: AppColors.oceanBlue,
                    strokeWidth: 5.0,
                    borderStrokeWidth: 2.5,
                    borderColor: AppColors.oceanBlueDark.withValues(alpha: 0.35),
                  ),
                ],
              ),

              // Map Markers
              MarkerLayer(
                markers: [
                  // A. Flagship Store Marker
                  Marker(
                    point: storeLocation,
                    width: 70,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: _buildStorePin(),
                  ),

                  // B. Customer Destination Marker
                  Marker(
                    point: customerLocation,
                    width: 70,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: _buildCustomerPin(),
                  ),

                  // C. Moving Courier Marker
                  Marker(
                    point: courierPos,
                    width: 80,
                    height: 55,
                    alignment: Alignment.topCenter,
                    child: _buildCourierPin(_speedKmh),
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
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
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
                        const Text(
                          'In 350m, continue on West Bay St',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Towards: ${widget.order.deliveryAddress}',
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

          // 3. Floating Recenter GPS Button
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.oceanBlueDark,
              elevation: 4,
              onPressed: () {
                _mapController.move(courierPos, 15.0);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // 4. Bottom Order Dispatch & Delivery Panel
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
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 16,
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
          ),
          child: const Text(
            'TG Store',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.warningOrange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 12),
        ),
      ],
    );
  }

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
          ),
          child: const Text(
            'Customer',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.limeGreenDark,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 12),
        ),
      ],
    );
  }

  Widget _buildCourierPin(int speed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(5),
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
        const SizedBox(height: 1),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.oceanBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.8),
          ),
          child: const Icon(Icons.delivery_dining, color: Colors.white, size: 14),
        ),
      ],
    );
  }
}
