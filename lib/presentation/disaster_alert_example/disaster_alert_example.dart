import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/disaster_alert_store.dart';
import '../../core/services/location_service.dart';
import '../../core/services/india_disaster_alert_service.dart';

/// Example widget showing how to integrate the disaster alert system
class DisasterAlertExample extends StatefulWidget {
  const DisasterAlertExample({super.key});

  @override
  _DisasterAlertExampleState createState() => _DisasterAlertExampleState();
}

class _DisasterAlertExampleState extends State<DisasterAlertExample> {
  List<DisasterAlert> _alerts = [];
  Map<String, dynamic>? _alertSummary;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alertStore = DisasterAlertStore.instance;
      
      // Fetch fresh alerts
      final alerts = await alertStore.fetchAndStoreAlerts();
      
      // Get alert summary with location info
      final summary = await alertStore.getAlertSummary();
      
      setState(() {
        _alerts = alerts;
        _alertSummary = summary;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disaster Alerts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Alert Summary Card
          if (_alertSummary != null) _buildSummaryCard(),
          
          // Error Message
          if (_errorMessage != null) _buildErrorCard(),
          
          // Loading Indicator
          if (_isLoading) _buildLoadingIndicator(),
          
          // Alerts List
          Expanded(child: _buildAlertsList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _alertSummary!;
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', summary['total']?.toString() ?? '0', Colors.blue),
                _buildSummaryItem('Nearby', summary['nearby']?.toString() ?? '0', Colors.orange),
                _buildSummaryItem('Critical', summary['critical']?.toString() ?? '0', Colors.red),
                _buildSummaryItem('Severe', summary['severe']?.toString() ?? '0', Colors.deepOrange),
              ],
            ),
            if (summary['has_location'] == true) ...[
              SizedBox(height: 8),
              Text(
                'Location: ${summary['user_region']} (Near ${summary['nearest_city']})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error: $_errorMessage',
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Loading disaster alerts...'),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_alerts.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No disaster alerts available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Pull to refresh or check back later',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildAlertCard(DisasterAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final typeIcon = _getTypeIcon(alert.type);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(typeIcon, color: severityColor, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSeverityChip(alert.severity),
                ],
              ),
              SizedBox(height: 8),
              
              // Description
              Text(
                alert.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              
              // Footer row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Source: ${alert.source}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatTime(alert.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              // Distance if available
              if (alert.metadata['distance_km'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '📍 ${alert.metadata['distance_km']}km away',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(AlertSeverity severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.severe:
        return Colors.deepOrange;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(DisasterType type) {
    switch (type) {
      case DisasterType.earthquake:
        return Icons.landscape;
      case DisasterType.flood:
        return Icons.water;
      case DisasterType.cyclone:
        return Icons.cyclone;
      case DisasterType.tsunami:
        return Icons.waves;
      case DisasterType.wildfire:
        return Icons.local_fire_department;
      case DisasterType.storm:
        return Icons.thunderstorm;
      case DisasterType.drought:
        return Icons.wb_sunny;
      case DisasterType.landslide:
        return Icons.terrain;
      case DisasterType.other:
        return Icons.warning;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showAlertDetails(DisasterAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.description),
              SizedBox(height: 16),
              Text('Type: ${alert.type.name}'),
              Text('Severity: ${alert.severity.name}'),
              Text('Source: ${alert.source}'),
              Text('Time: ${alert.timestamp}'),
              Text('Location: ${alert.location.latitude.toStringAsFixed(4)}, ${alert.location.longitude.toStringAsFixed(4)}'),
              if (alert.metadata.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Additional Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...alert.metadata.entries.map((e) => Text('${e.key}: ${e.value}')),
              ],
            ],
          ),
        ),
        actions: [
          if (alert.sourceUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                // Open source URL
                Navigator.pop(context);
              },
              child: Text('View Source'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}