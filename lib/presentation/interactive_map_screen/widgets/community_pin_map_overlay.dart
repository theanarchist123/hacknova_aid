import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/community_pin.dart';
import 'dart:ui' as ui;

class CommunityPinMapOverlay extends StatelessWidget {
  final List<CommunityPin> pins;
  final Function(CommunityPin) onPinTap;
  final Function(CommunityPin)? onPinLongPress;
  final LatLng? selectedPinLocation;

  const CommunityPinMapOverlay({
    super.key,
    required this.pins,
    required this.onPinTap,
    this.onPinLongPress,
    this.selectedPinLocation,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: pins.map((pin) => _buildPinMarker(context, pin)).toList(),
    );
  }

  Marker _buildPinMarker(BuildContext context, CommunityPin pin) {
    final isSelected = selectedPinLocation != null &&
        selectedPinLocation!.latitude == pin.location.latitude &&
        selectedPinLocation!.longitude == pin.location.longitude;

    return Marker(
      point: pin.location,
      width: isSelected ? 60 : 40,
      height: isSelected ? 70 : 50,
      child: GestureDetector(
        onTap: () => onPinTap(pin),
        onLongPress: () => onPinLongPress?.call(pin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow
              Positioned(
                bottom: 2,
                child: Container(
                  width: isSelected ? 30 : 20,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Main pin
              Container(
                width: isSelected ? 50 : 35,
                height: isSelected ? 60 : 45,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pin background
                    CustomPaint(
                      size: Size(isSelected ? 50 : 35, isSelected ? 60 : 45),
                      painter: PinPainter(
                        color: _getPinColor(pin),
                        isSelected: isSelected,
                      ),
                    ),

                    // Pin icon
                    Positioned(
                      top: isSelected ? 8 : 5,
                      child: Container(
                        width: isSelected ? 32 : 24,
                        height: isSelected ? 32 : 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconData(pin.type.iconName),
                          color: _getPinColor(pin),
                          size: isSelected ? 20 : 16,
                        ),
                      ),
                    ),

                    // Priority indicator
                    if (pin.priority == PinPriority.high || pin.priority == PinPriority.critical)
                      Positioned(
                        top: isSelected ? 2 : 0,
                        right: isSelected ? 2 : 0,
                        child: Container(
                          width: isSelected ? 16 : 12,
                          height: isSelected ? 16 : 12,
                          decoration: BoxDecoration(
                            color: pin.priority == PinPriority.critical 
                                ? Colors.purple 
                                : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: isSelected ? 10 : 8,
                          ),
                        ),
                      ),

                    // Verification indicator
                    if (pin.verifiedBy.isNotEmpty)
                      Positioned(
                        top: isSelected ? 2 : 0,
                        left: isSelected ? 2 : 0,
                        child: Container(
                          width: isSelected ? 16 : 12,
                          height: isSelected ? 16 : 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: isSelected ? 10 : 8,
                          ),
                        ),
                      ),

                    // Sync status indicator
                    if (!pin.isSyncedToBluetooth)
                      Positioned(
                        bottom: isSelected ? 8 : 5,
                        child: Container(
                          width: isSelected ? 12 : 8,
                          height: isSelected ? 12 : 8,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            Icons.sync_problem,
                            color: Colors.white,
                            size: isSelected ? 8 : 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPinColor(CommunityPin pin) {
    // Base color on pin type
    if (pin.type.isHazard) {
      switch (pin.priority) {
        case PinPriority.critical:
          return Colors.purple;
        case PinPriority.high:
          return Colors.red;
        case PinPriority.medium:
          return Colors.orange;
        case PinPriority.low:
          return Colors.yellow[700]!;
      }
    } else if (pin.type.isResource) {
      switch (pin.priority) {
        case PinPriority.critical:
          return Colors.green[800]!;
        case PinPriority.high:
          return Colors.green;
        case PinPriority.medium:
          return Colors.green[600]!;
        case PinPriority.low:
          return Colors.green[400]!;
      }
    } else {
      // Other types
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'warning':
        return Icons.warning;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water;
      case 'waves':
        return Icons.waves;
      case 'landscape':
        return Icons.landscape;
      case 'landslide':
        return Icons.landscape;
      case 'block':
        return Icons.block;
      case 'water_drop':
        return Icons.water_drop;
      case 'home':
        return Icons.home;
      case 'medical_services':
        return Icons.medical_services;
      case 'restaurant':
        return Icons.restaurant;
      case 'security':
        return Icons.security;
      case 'shield':
        return Icons.shield;
      case 'directions_run':
        return Icons.directions_run;
      case 'emergency':
        return Icons.emergency;
      case 'contact_phone':
        return Icons.contact_phone;
      case 'inventory':
        return Icons.inventory;
      case 'place':
        return Icons.place;
      default:
        return Icons.place;
    }
  }
}

class PinPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  PinPainter({
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;

    final path = ui.Path();
    final radius = size.width * 0.4;
    final center = Offset(size.width / 2, radius);

    // Draw shadow first (slightly offset)
    final shadowPath = ui.Path();
    shadowPath.addOval(Rect.fromCircle(
      center: Offset(center.dx + 1, center.dy + 1),
      radius: radius,
    ));
    shadowPath.moveTo(center.dx + 1, center.dy + radius + 1);
    shadowPath.lineTo(size.width / 2 + 1, size.height - 2);
    shadowPath.lineTo(center.dx - radius * 0.3 + 1, center.dy + radius * 0.7 + 1);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main pin shape
    // Circle part
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Pointer part
    path.moveTo(center.dx, center.dy + radius);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(center.dx - radius * 0.3, center.dy + radius * 0.7);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is PinPainter &&
        (oldDelegate.color != color || oldDelegate.isSelected != isSelected);
  }
}

class PinClusterOverlay extends StatelessWidget {
  final Map<String, List<CommunityPin>> clusteredPins;
  final Function(List<CommunityPin>) onClusterTap;
  final double zoomLevel;

  const PinClusterOverlay({
    super.key,
    required this.clusteredPins,
    required this.onClusterTap,
    required this.zoomLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (zoomLevel > 12) {
      // Don't cluster at high zoom levels
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: clusteredPins.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => _buildClusterMarker(context, entry.value))
          .toList(),
    );
  }

  Marker _buildClusterMarker(BuildContext context, List<CommunityPin> pins) {
    final centerLat = pins.map((p) => p.location.latitude).reduce((a, b) => a + b) / pins.length;
    final centerLng = pins.map((p) => p.location.longitude).reduce((a, b) => a + b) / pins.length;
    final center = LatLng(centerLat, centerLng);

    final hazardCount = pins.where((p) => p.type.isHazard).length;
    final resourceCount = pins.where((p) => p.type.isResource).length;

    return Marker(
      point: center,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => onClusterTap(pins),
        child: Container(
          decoration: BoxDecoration(
            color: hazardCount > resourceCount ? Colors.red : Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pins.length.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hazardCount > 0 && resourceCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 8),
                    Text('$hazardCount', style: TextStyle(color: Colors.white, fontSize: 8)),
                    SizedBox(width: 2),
                    Icon(Icons.check_circle, color: Colors.white, size: 8),
                    Text('$resourceCount', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}