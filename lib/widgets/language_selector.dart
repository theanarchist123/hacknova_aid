import 'package:flutter/material.dart';
import '../core/services/language_preference_service.dart';

/// Language selector widget for disaster alerts
class LanguageSelector extends StatefulWidget {
  final String? initialLanguage;
  final Function(String)? onLanguageChanged;
  final bool showTitle;

  const LanguageSelector({
    Key? key,
    this.initialLanguage,
    this.onLanguageChanged,
    this.showTitle = true,
  }) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String? _selectedLanguage;
  final Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'bn': 'বাংলা (Bengali)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'ur': 'اردو (Urdu)',
  };

  final Map<String, IconData> _languageIcons = {
    'en': Icons.language,
    'hi': Icons.translate,
    'mr': Icons.location_city,
    'gu': Icons.business,
    'ta': Icons.temple_hindu,
    'te': Icons.rice_bowl,
    'kn': Icons.local_florist,
    'bn': Icons.water,
    'pa': Icons.agriculture,
    'ur': Icons.mosque,
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final savedLanguage = await LanguagePreferenceService.getPreferredLanguage();
    setState(() {
      _selectedLanguage = widget.initialLanguage ?? savedLanguage;
    });
  }

  Future<void> _updateLanguage(String languageCode) async {
    await LanguagePreferenceService.setPreferredLanguage(languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    if (widget.onLanguageChanged != null) {
      widget.onLanguageChanged!(languageCode);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Language changed to ${_languageNames[languageCode]} 🌐',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String> _getRegionalSuggestion() async {
    // Using Andheri, Maharashtra coordinates as default for regional suggestion
    return LanguagePreferenceService.suggestLanguageForRegion(19.1136, 72.8697);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedLanguage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          const Text(
            'Alert Language / चेतावनी की भाषा',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your preferred language for disaster alerts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              hint: const Text('Select Language'),
              icon: const Icon(Icons.arrow_drop_down),
              items: _languageNames.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _languageIcons[entry.key] ?? Icons.language,
                        size: 20,
                        color: _selectedLanguage == entry.key 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: _selectedLanguage == entry.key 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                            color: _selectedLanguage == entry.key 
                              ? Theme.of(context).primaryColor 
                              : null,
                          ),
                        ),
                      ),
                      if (_selectedLanguage == entry.key)
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedLanguage) {
                  _updateLanguage(newValue);
                }
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Regional suggestion
        FutureBuilder<String>(
          future: _getRegionalSuggestion(),
          builder: (context, snapshot) {
            if (snapshot.hasData && 
                snapshot.data != null && 
                snapshot.data != _selectedLanguage) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, 
                         color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For Maharashtra region, we suggest ${_languageNames[snapshot.data!]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _updateLanguage(snapshot.data!),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(60, 30),
                      ),
                      child: const Text('Use', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}