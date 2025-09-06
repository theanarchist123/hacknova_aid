import 'package:flutter/material.dart';
import '../../core/services/enhanced_disaster_service.dart';
import '../../core/services/google_services.dart';
import '../../core/services/location_service.dart';

class ComprehensiveDashboardScreen extends StatefulWidget {
  const ComprehensiveDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ComprehensiveDashboardScreen> createState() => _ComprehensiveDashboardScreenState();
}

class _ComprehensiveDashboardScreenState extends State<ComprehensiveDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _enhancedData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEnhancedData();
  }

  Future<void> _loadEnhancedData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await EnhancedDisasterService.getEnhancedDisasterInfo();
      setState(() {
        _enhancedData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadEnhancedData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEnhancedData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (_enhancedData == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadEnhancedData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildWeatherCard(),
            const SizedBox(height: 16),
            _buildRiskAssessmentCard(),
            const SizedBox(height: 16),
            _buildDisasterAlertsCard(),
            const SizedBox(height: 16),
            _buildRecommendationsCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = _enhancedData!['location'];
    final coordinates = location['coordinates'];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text('Current Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              location['address'] ?? 'Unknown Location',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${coordinates['latitude'].toStringAsFixed(4)}, Lng: ${coordinates['longitude'].toStringAsFixed(4)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _enhancedData!['weather'];
    if (weather == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue),
                SizedBox(width: 8),
                Text('Weather Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeatherItem('Temperature', '${weather['temperature']}°C', Icons.thermostat),
                _buildWeatherItem('Humidity', '${weather['humidity']}%', Icons.water_drop),
                _buildWeatherItem('Wind', '${weather['wind_speed']} km/h', Icons.air),
              ],
            ),
            if (weather['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                weather['description'],
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRiskAssessmentCard() {
    final risk = _enhancedData!['risk_assessment'];
    if (risk == null) return const SizedBox.shrink();

    final riskColor = _getRiskColor(risk['level']);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: riskColor),
                const SizedBox(width: 8),
                const Text('Risk Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    risk['level'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Score: ${risk['score']}'),
              ],
            ),
            if (risk['factors'] != null && risk['factors'].isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Risk Factors:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...List<Widget>.from(risk['factors'].map<Widget>((factor) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(factor)),
                  ],
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisasterAlertsCard() {
    final alerts = _enhancedData!['disaster_alerts'] as List<dynamic>?;
    if (alerts == null || alerts.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Active Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.take(3).map<Widget>((alert) => _buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity']?.toLowerCase() ?? '';
    final color = severity.contains('extreme') || severity.contains('severe') 
        ? Colors.red 
        : severity.contains('moderate') 
            ? Colors.orange 
            : Colors.yellow.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert['severity'] ?? 'Alert',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert['type'] ?? 'Disaster Alert',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert['title'] ?? 'Alert'),
          if (alert['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              alert['description'],
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _enhancedData!['recommendations'] as List<dynamic>?;
    if (recommendations == null || recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green),
                SizedBox(width: 8),
                Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.take(3).map<Widget>((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority']?.toLowerCase() ?? 'medium';
    final color = priority == 'extreme' || priority == 'high' 
        ? Colors.red 
        : priority == 'medium' 
            ? Colors.orange 
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Text(
            recommendation['icon'] ?? '💡',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'] ?? 'Recommendation',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation['description'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange),
                SizedBox(width: 8),
                Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
              children: [
                _buildQuickActionButton('Find Hospital', Icons.local_hospital, () => _findNearby('hospital')),
                _buildQuickActionButton('Find Police', Icons.local_police, () => _findNearby('police')),
                _buildQuickActionButton('Get Directions', Icons.directions, () => _getEmergencyDirections()),
                _buildQuickActionButton('Call Emergency', Icons.phone, () => _callEmergency()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'extreme': return Colors.red;
      case 'high': return Colors.orange;
      case 'moderate': return Colors.yellow.shade700;
      case 'low': return Colors.lightGreen;
      case 'minimal': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _findNearby(String type) {
    // Navigate to search results or show dialog with nearby places
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finding nearby ${type}s...'),
        content: const CircularProgressIndicator(),
      ),
    );

    // Implement the search functionality
    _searchNearbyPlaces(type);
  }

  Future<void> _searchNearbyPlaces(String type) async {
    try {
      if (_enhancedData != null) {
        final location = _enhancedData!['location']['coordinates'];
        final places = await GoogleServices.searchPlaces(
          latitude: location['latitude'],
          longitude: location['longitude'],
          type: type,
        );

        Navigator.of(context).pop(); // Close loading dialog

        if (places.isNotEmpty) {
          _showPlacesDialog(places, type);
        } else {
          _showMessage('No ${type}s found nearby');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showMessage('Error searching for ${type}s: $e');
    }
  }

  void _showPlacesDialog(List<Map<String, dynamic>> places, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nearby ${type.toUpperCase()}s'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(place['name'] ?? 'Unknown Place'),
                subtitle: Text(place['vicinity'] ?? 'No address'),
                trailing: Text('★${(place['rating'] ?? 0.0).toStringAsFixed(1)}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getDirectionsToPlace(place);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _getDirectionsToPlace(Map<String, dynamic> place) async {
    if (_enhancedData != null) {
      final currentLocation = _enhancedData!['location']['coordinates'];
      
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Getting directions...'),
          content: CircularProgressIndicator(),
        ),
      );

      try {
        final directions = await GoogleServices.getDirections(
          originLat: currentLocation['latitude'],
          originLng: currentLocation['longitude'],
          destLat: place['latitude'],
          destLng: place['longitude'],
        );

        Navigator.of(context).pop(); // Close loading dialog

        if (directions != null) {
          _showDirectionsDialog(place, directions);
        } else {
          _showMessage('Could not get directions');
        }
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        _showMessage('Error getting directions: $e');
      }
    }
  }

  void _showDirectionsDialog(Map<String, dynamic> place, Map<String, dynamic> directions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Directions to ${place['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${directions['distance']}'),
            Text('Duration: ${directions['duration']}'),
            const SizedBox(height: 12),
            if (directions['start_address'] != null)
              Text('From: ${directions['start_address']}'),
            if (directions['end_address'] != null)
              Text('To: ${directions['end_address']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _getEmergencyDirections() async {
    if (_enhancedData != null) {
      final location = _enhancedData!['location']['coordinates'];
      final result = await EnhancedDisasterService.getEmergencyDirections(
        location['latitude'],
        location['longitude'],
        'hospital',
      );

      if (result != null) {
        _showDirectionsDialog(result['facility'], result['directions']);
      } else {
        _showMessage('Could not get emergency directions');
      }
    }
  }

  void _callEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text('Police'),
              subtitle: const Text('911'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessage('Calling 911...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text('Medical Emergency'),
              subtitle: const Text('911'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessage('Calling 911...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fire_truck, color: Colors.orange),
              title: const Text('Fire Department'),
              subtitle: const Text('911'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessage('Calling 911...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
