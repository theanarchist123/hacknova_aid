import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/india_disaster_alert_service.dart';
import '../core/services/language_preference_service.dart';
import '../core/services/disaster_translation_service.dart';

/// Widget to display disaster alerts with multi-language support
class MultiLanguageAlertCard extends StatefulWidget {
  final DisasterAlert alert;
  final String? languageCode;
  final VoidCallback? onTap;
  final bool showPrecautions;

  const MultiLanguageAlertCard({
    Key? key,
    required this.alert,
    this.languageCode,
    this.onTap,
    this.showPrecautions = false,
  }) : super(key: key);

  @override
  State<MultiLanguageAlertCard> createState() => _MultiLanguageAlertCardState();
}

class _MultiLanguageAlertCardState extends State<MultiLanguageAlertCard> {
  String? _currentLanguage;
  bool _showingPrecautions = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = widget.languageCode ?? 
                    await LanguagePreferenceService.getPreferredLanguage();
    setState(() {
      _currentLanguage = language;
      _showingPrecautions = widget.showPrecautions;
    });
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red[700]!;
      case AlertSeverity.severe:
        return Colors.orange[700]!;
      case AlertSeverity.warning:
        return Colors.yellow[700]!;
      case AlertSeverity.info:
        return Colors.blue[700]!;
    }
  }

  IconData _getDisasterIcon(DisasterType type) {
    switch (type) {
      case DisasterType.earthquake:
        return Icons.vibration;
      case DisasterType.flood:
        return Icons.water;
      case DisasterType.cyclone:
        return Icons.cyclone;
      case DisasterType.wildfire:
        return Icons.local_fire_department;
      case DisasterType.tsunami:
        return Icons.waves;
      case DisasterType.landslide:
        return Icons.landscape;
      case DisasterType.storm:
        return Icons.thunderstorm;
      case DisasterType.drought:
        return Icons.water_drop_outlined;
      case DisasterType.other:
        return Icons.warning;
    }
  }

  Widget _buildSeverityBadge() {
    final color = _getSeverityColor(widget.alert.severity);
    final severityText = _currentLanguage != null 
        ? widget.alert.getTranslatedSeverityLevel(_currentLanguage!)
        : widget.alert.severity.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        severityText.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrecautionsCard() {
    if (_currentLanguage == null) return const SizedBox.shrink();

    final precautions = widget.alert.getPrecautions(_currentLanguage!);
    
    if (precautions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                _currentLanguage == 'en' 
                    ? 'Safety Precautions'
                    : DisasterTranslationService.translateTerm('safety_precautions', _currentLanguage!),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...precautions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[600],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLanguage == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final translatedTitle = widget.alert.getTranslatedTitle(_currentLanguage!);
    final translatedDescription = widget.alert.getTranslatedDescription(_currentLanguage!);
    final translatedType = widget.alert.getTranslatedTypeName(_currentLanguage!);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getSeverityColor(widget.alert.severity).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, type, and severity
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(widget.alert.severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDisasterIcon(widget.alert.type),
                      color: _getSeverityColor(widget.alert.severity),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translatedType,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getSeverityColor(widget.alert.severity),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(widget.alert.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSeverityBadge(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Alert title
              Text(
                translatedTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Alert description
              Text(
                translatedDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              
              // Location info from metadata if available
              if (widget.alert.metadata.containsKey('distance')) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.alert.metadata['distance']} away',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Source: ${widget.alert.source}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              
              // Language indicator
              if (_currentLanguage != 'en') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.translate, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Translated to ${LanguagePreferenceService.getLanguageName(_currentLanguage!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Safety precautions toggle
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showingPrecautions = !_showingPrecautions;
                        });
                      },
                      icon: Icon(_showingPrecautions ? Icons.expand_less : Icons.expand_more),
                      label: Text(
                        _currentLanguage == 'en' 
                            ? 'Safety Precautions'
                            : DisasterTranslationService.translateTerm('safety_precautions', _currentLanguage!),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getSeverityColor(widget.alert.severity),
                        side: BorderSide(color: _getSeverityColor(widget.alert.severity)),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Precautions card
              if (_showingPrecautions) _buildPrecautionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}