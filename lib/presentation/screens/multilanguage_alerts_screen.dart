import 'package:flutter/material.dart';
import '../../core/services/india_disaster_alert_service.dart';
import '../../core/services/language_preference_service.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/multilanguage_alert_card.dart';

/// Example screen demonstrating multi-language disaster alerts
class MultiLanguageAlertsScreen extends StatefulWidget {
  const MultiLanguageAlertsScreen({Key? key}) : super(key: key);

  @override
  State<MultiLanguageAlertsScreen> createState() => _MultiLanguageAlertsScreenState();
}

class _MultiLanguageAlertsScreenState extends State<MultiLanguageAlertsScreen> {
  List<DisasterAlert> _alerts = [];
  bool _isLoading = false;
  String? _selectedLanguage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndAlerts();
  }

  Future<void> _loadLanguageAndAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user's preferred language
      final language = await LanguagePreferenceService.getPreferredLanguage();
      setState(() {
        _selectedLanguage = language;
      });

      // Fetch localized alerts
      await _fetchAlerts();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading alerts: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAlerts() async {
    try {
      final alerts = await IndiaDisasterAlertService.getIndiaAlerts(
        languageCode: _selectedLanguage,
        limitResults: 10,
      );
      
      setState(() {
        _alerts = alerts;
        _errorMessage = alerts.isEmpty ? 'No alerts found for your area' : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch alerts: $e';
      });
    }
  }

  Future<void> _onLanguageChanged(String newLanguage) async {
    setState(() {
      _selectedLanguage = newLanguage;
      _isLoading = true;
    });

    // Refetch alerts with new language
    await _fetchAlerts();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshAlerts() async {
    await _fetchAlerts();
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LanguageSelector(
        initialLanguage: _selectedLanguage,
        onLanguageChanged: _onLanguageChanged,
        showTitle: true,
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading disaster alerts...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshAlerts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green[400],
              ),
              const SizedBox(height: 16),
              Text(
                _selectedLanguage == 'en' 
                    ? 'No active alerts in your area'
                    : 'आपके क्षेत्र में कोई सक्रिय अलर्ट नहीं',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLanguage == 'en'
                    ? 'Stay safe! We\'ll notify you if any disasters are detected nearby.'
                    : 'सुरक्षित रहें! यदि आसपास कोई आपदा का पता चलता है तो हम आपको सूचित करेंगे।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return MultiLanguageAlertCard(
          alert: alert,
          languageCode: _selectedLanguage,
          onTap: () => _showAlertDetails(alert),
        );
      },
    );
  }

  void _showAlertDetails(DisasterAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MultiLanguageAlertCard(
                    alert: alert,
                    languageCode: _selectedLanguage,
                    showPrecautions: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLanguage == 'en' 
            ? 'Disaster Alerts'
            : 'आपदा चेतावनी'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshAlerts,
            icon: const Icon(Icons.refresh),
            tooltip: _selectedLanguage == 'en' ? 'Refresh' : 'ताज़ा करें',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language selector
              _buildLanguageSelector(),
              
              // Alert summary
              if (_alerts.isNotEmpty && !_isLoading) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLanguage == 'en'
                                  ? '${_alerts.length} Active Alerts'
                                  : '${_alerts.length} सक्रिय चेतावनी',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedLanguage == 'en'
                                  ? 'Prioritized for Maharashtra region'
                                  : 'महाराष्ट्र क्षेत्र के लिए प्राथमिकता',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Alerts list
              _buildAlertsList(),
              
              // Footer padding
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}