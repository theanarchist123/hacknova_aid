import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'indian_alerts_formatter.dart';

/// India-specific disaster alert sources using reliable, CORS-safe APIs
class IndiaAlertSources {
  static const String _userAgent = 'DisasterReliefApp/1.0 (emergency.relief.app@gmail.com)';
  
  // India bounding box for filtering
  static const double _indiaMinLat = 6.5;
  static const double _indiaMaxLat = 37.1;
  static const double _indiaMinLon = 68.0;
  static const double _indiaMaxLon = 97.5;

  /// Fetch India-specific disaster reports from ReliefWeb (UN OCHA)
  /// Returns news-style headlines and descriptions
  static Future<List<Map<String, dynamic>>> fetchReliefWebIndia({int limit = 30}) async {
    try {
      print('🇮🇳 Fetching ReliefWeb India reports...');
      
      // Fetch reports specifically for India
      final uri = Uri.parse(
        'https://api.reliefweb.int/v1/reports'
        '?appname=disaster-relief-app'
        '&filter[field]=country'
        '&filter[value]=India'
        '&profile=full'
        '&limit=$limit'
        '&sort[0][field]=date.created'
        '&sort[0][direction]=desc',
      );
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        print('❌ ReliefWeb reports HTTP ${response.statusCode}');
        return [];
      }
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List items = (data['data'] ?? []) as List;
      
      final alerts = <Map<String, dynamic>>[];
      for (final item in items) {
        final fields = (item['fields'] ?? {}) as Map<String, dynamic>;
        final itemId = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Extract disaster-related reports only
        final title = (fields['title'] ?? '').toString();
        final body = (fields['body'] ?? '').toString();
        final headline = (fields['headline'] ?? '').toString();
        
        // Skip if not disaster-related
        if (!_isDisasterRelated(title) && !_isDisasterRelated(body) && !_isDisasterRelated(headline)) {
          continue;
        }
        
        final description = headline.isNotEmpty ? headline : 
                          (body.isNotEmpty ? _extractFirstParagraph(body) : 
                           'Disaster-related report from India');
        
        final createdDate = fields['date']?['created'];
        final timestamp = createdDate != null ? 
            DateTime.tryParse(createdDate)?.toIso8601String() ?? 
            DateTime.now().toIso8601String() :
            DateTime.now().toIso8601String();
        
        alerts.add({
          'id': 'reliefweb_$itemId',
          'title': title,
          'description': IndianAlertsFormatter.buildRegionalDescription(description, 'India'),
          'type': _inferDisasterType(title + ' ' + description),
          'category': 'relief_report',
          'severity': 'warning',
          'severityLevel': 3,
          'source': 'ReliefWeb (UN OCHA)',
          'sourceUrl': fields['url']?.toString() ?? 'https://reliefweb.int/',
          'timestamp': timestamp,
          'country': 'India',
          'isIndiaRelated': true,
          'priority': 1,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
      
      print('✅ ReliefWeb: Found ${alerts.length} India disaster reports');
      return alerts;
      
    } catch (e) {
      print('❌ ReliefWeb India fetch failed: $e');
      return [];
    }
  }

  /// Fetch disasters specifically for India from ReliefWeb disasters endpoint
  static Future<List<Map<String, dynamic>>> fetchReliefWebIndiaDisasters({int limit = 20}) async {
    try {
      print('🇮🇳 Fetching ReliefWeb India disasters...');
      
      final uri = Uri.parse(
        'https://api.reliefweb.int/v1/disasters'
        '?appname=disaster-relief-app'
        '&filter[field]=country.iso3'
        '&filter[value]=IND'
        '&profile=full'
        '&limit=$limit'
        '&sort[0][field]=date.event'
        '&sort[0][direction]=desc',
      );
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        print('❌ ReliefWeb disasters HTTP ${response.statusCode}');
        return [];
      }
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List items = (data['data'] ?? []) as List;
      
      final alerts = <Map<String, dynamic>>[];
      for (final item in items) {
        final fields = (item['fields'] ?? {}) as Map<String, dynamic>;
        final itemId = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        final name = (fields['name'] ?? 'Disaster in India').toString();
        final description = (fields['description'] ?? '').toString();
        final eventDate = fields['date']?['event'];
        
        final timestamp = eventDate != null ? 
            DateTime.tryParse(eventDate)?.toIso8601String() ?? 
            DateTime.now().toIso8601String() :
            DateTime.now().toIso8601String();
        
        // Get disaster type
        final types = (fields['type'] ?? []) as List;
        final disasterType = types.isNotEmpty ? 
            types[0]['name']?.toString().toLowerCase() ?? 'disaster' : 
            'disaster';
        
        alerts.add({
          'id': 'reliefweb_disaster_$itemId',
          'title': name,
          'description': description.isNotEmpty ? description : 'Disaster event in India reported by UN OCHA',
          'type': _mapReliefWebDisasterType(disasterType),
          'category': disasterType,
          'severity': 'warning',
          'severityLevel': 3,
          'source': 'ReliefWeb Disasters (UN OCHA)',
          'sourceUrl': fields['url']?.toString() ?? 'https://reliefweb.int/',
          'timestamp': timestamp,
          'country': 'India',
          'isIndiaRelated': true,
          'priority': 1,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
      
      print('✅ ReliefWeb: Found ${alerts.length} India disaster events');
      return alerts;
      
    } catch (e) {
      print('❌ ReliefWeb India disasters fetch failed: $e');
      return [];
    }
  }

  /// Fetch global disasters from GDACS and filter for India region
  static Future<List<Map<String, dynamic>>> fetchGdacsIndia({int days = 7}) async {
    try {
      print('🌍 Fetching GDACS events and filtering for India...');
      
      final uri = Uri.parse(
        'https://www.gdacs.org/gdacsapi/api/events/geteventlist/MAP'
        '?alertlevel=Green;Orange;Red'
        '&eventtype=EQ;TC;FL;VO;WF;DR'
        '&fromDate=${DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0]}'
        '&toDate=${DateTime.now().toIso8601String().split('T')[0]}',
      );
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        print('❌ GDACS HTTP ${response.statusCode}');
        return [];
      }
      
      // Parse XML response (GDACS returns XML, not JSON)
      final xmlContent = response.body;
      final alerts = _parseGdacsXml(xmlContent);
      
      // Filter for India region only
      final indiaAlerts = alerts.where((alert) {
        final lat = alert['lat'] as double?;
        final lon = alert['lon'] as double?;
        if (lat == null || lon == null) return false;
        return _isInIndiaRegion(lat, lon);
      }).toList();
      
      print('✅ GDACS: Found ${indiaAlerts.length} India-region events from ${alerts.length} total');
      return indiaAlerts;
      
    } catch (e) {
      print('❌ GDACS India fetch failed: $e');
      return [];
    }
  }

  /// Parse GDACS XML response to extract disaster events
  static List<Map<String, dynamic>> _parseGdacsXml(String xmlContent) {
    final alerts = <Map<String, dynamic>>[];
    
    // Simple XML parsing for GDACS events
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final items = itemRegex.allMatches(xmlContent);
    
    for (final match in items) {
      final itemContent = match.group(1) ?? '';
      
      try {
        final title = _extractXmlValue(itemContent, 'title');
        final description = _extractXmlValue(itemContent, 'description');
        final link = _extractXmlValue(itemContent, 'link');
        final pubDate = _extractXmlValue(itemContent, 'pubDate');
        
        // Extract coordinates from geometry or description
        final (lat, lon) = _extractCoordinatesFromGdacs(itemContent);
        
        if (title.isNotEmpty && lat != null && lon != null) {
          alerts.add({
            'id': 'gdacs_${title.hashCode}_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}',
            'title': title,
            'description': description.isNotEmpty ? description : title,
            'type': _inferDisasterTypeFromGdacs(title),
            'category': 'gdacs_alert',
            'severity': _extractGdacsSeverity(title),
            'severityLevel': _extractGdacsSeverityLevel(title),
            'source': 'GDACS (Global Disaster Alert and Coordination System)',
            'sourceUrl': link,
            'lat': lat,
            'lon': lon,
            'timestamp': _parseGdacsDate(pubDate),
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        print('❌ Error parsing GDACS item: $e');
        continue;
      }
    }
    
    return alerts;
  }

  /// Extract value from XML tag
  static String _extractXmlValue(String xml, String tag) {
    final regex = RegExp('<$tag(?:[^>]*)>(.*?)</$tag>', dotAll: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }

  /// Extract coordinates from GDACS XML content
  static (double?, double?) _extractCoordinatesFromGdacs(String content) {
    // Look for geo:Point or coordinates in various formats
    final geoRegex = RegExp(r'<geo:Point.*?<geo:lat>(.*?)</geo:lat>.*?<geo:long>(.*?)</geo:long>', dotAll: true);
    final geoMatch = geoRegex.firstMatch(content);
    
    if (geoMatch != null) {
      final lat = double.tryParse(geoMatch.group(1)?.trim() ?? '');
      final lon = double.tryParse(geoMatch.group(2)?.trim() ?? '');
      return (lat, lon);
    }
    
    // Alternative coordinate extraction
    final coordRegex = RegExp(r'(\d+\.?\d*),\s*(\d+\.?\d*)');
    final coordMatch = coordRegex.firstMatch(content);
    
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1) ?? '');
      final lon = double.tryParse(coordMatch.group(2) ?? '');
      return (lat, lon);
    }
    
    return (null, null);
  }

  /// Parse GDACS date format
  static String _parseGdacsDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now().toIso8601String();
    
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) return parsed.toIso8601String();
      
      // Try RFC 2822 format (common in RSS)
      final parts = dateStr.split(' ');
      if (parts.length >= 4) {
        final day = int.tryParse(parts[1]) ?? 1;
        final month = _monthNameToNumber(parts[2]);
        final year = int.tryParse(parts[3]) ?? DateTime.now().year;
        
        if (month > 0) {
          final date = DateTime(year, month, day);
          return date.toIso8601String();
        }
      }
    } catch (e) {
      print('❌ Error parsing GDACS date: $dateStr');
    }
    
    return DateTime.now().toIso8601String();
  }

  /// Convert month name to number
  static int _monthNameToNumber(String monthName) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return months[monthName] ?? 0;
  }

  /// Check if coordinates are in India or nearby region
  static bool _isInIndiaRegion(double lat, double lon) {
    // Expanded region to include nearby areas that might affect India
    return lat >= _indiaMinLat - 2 && lat <= _indiaMaxLat + 2 &&
           lon >= _indiaMinLon - 2 && lon <= _indiaMaxLon + 2;
  }

  /// Check if text is disaster-related
  static bool _isDisasterRelated(String text) {
    final lowerText = text.toLowerCase();
    final disasterKeywords = [
      'earthquake', 'flood', 'cyclone', 'tsunami', 'landslide', 'drought',
      'wildfire', 'storm', 'hurricane', 'typhoon', 'tornado', 'avalanche',
      'volcanic', 'eruption', 'emergency', 'disaster', 'calamity', 'crisis',
      'evacuation', 'rescue', 'relief', 'damage', 'casualties', 'missing',
      'monsoon', 'heavy rain', 'flash flood', 'mudslide', 'tremor',
      'aftershock', 'seismic', 'meteorological', 'weather warning'
    ];
    
    return disasterKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Infer disaster type from text content
  static String _inferDisasterType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('earthquake') || lowerText.contains('tremor') || lowerText.contains('seismic')) return 'earthquake';
    if (lowerText.contains('flood') || lowerText.contains('flooding')) return 'flood';
    if (lowerText.contains('cyclone') || lowerText.contains('hurricane') || lowerText.contains('typhoon')) return 'cyclone';
    if (lowerText.contains('tsunami')) return 'tsunami';
    if (lowerText.contains('landslide') || lowerText.contains('mudslide')) return 'landslide';
    if (lowerText.contains('drought')) return 'drought';
    if (lowerText.contains('wildfire') || lowerText.contains('forest fire')) return 'wildfire';
    if (lowerText.contains('storm') || lowerText.contains('severe weather')) return 'storm';
    if (lowerText.contains('avalanche')) return 'avalanche';
    if (lowerText.contains('volcanic') || lowerText.contains('eruption')) return 'volcanic';
    
    return 'disaster';
  }

  /// Map ReliefWeb disaster types
  static String _mapReliefWebDisasterType(String type) {
    final lowerType = type.toLowerCase();
    
    if (lowerType.contains('earthquake')) return 'earthquake';
    if (lowerType.contains('flood')) return 'flood';
    if (lowerType.contains('cyclone') || lowerType.contains('storm')) return 'cyclone';
    if (lowerType.contains('drought')) return 'drought';
    if (lowerType.contains('landslide')) return 'landslide';
    if (lowerType.contains('fire')) return 'wildfire';
    
    return lowerType;
  }

  /// Infer disaster type from GDACS title
  static String _inferDisasterTypeFromGdacs(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('earthquake') || lowerTitle.contains('eq')) return 'earthquake';
    if (lowerTitle.contains('flood') || lowerTitle.contains('fl')) return 'flood';
    if (lowerTitle.contains('cyclone') || lowerTitle.contains('tc')) return 'cyclone';
    if (lowerTitle.contains('volcano') || lowerTitle.contains('vo')) return 'volcanic';
    if (lowerTitle.contains('wildfire') || lowerTitle.contains('wf')) return 'wildfire';
    if (lowerTitle.contains('drought') || lowerTitle.contains('dr')) return 'drought';
    
    return 'disaster';
  }

  /// Extract severity from GDACS title
  static String _extractGdacsSeverity(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('red')) return 'extreme';
    if (lowerTitle.contains('orange')) return 'severe';
    if (lowerTitle.contains('green')) return 'moderate';
    
    return 'warning';
  }

  /// Extract severity level from GDACS title
  static int _extractGdacsSeverityLevel(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('red')) return 5;
    if (lowerTitle.contains('orange')) return 4;
    if (lowerTitle.contains('green')) return 3;
    
    return 2;
  }

  /// Extract first paragraph from HTML/text content
  static String _extractFirstParagraph(String content) {
    // Remove HTML tags
    final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Split by paragraphs and take first substantial one
    final paragraphs = cleanContent.split(RegExp(r'\n\s*\n|\r\n\s*\r\n'));
    
    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.length > 50) { // Substantial paragraph
        return trimmed.length > 300 ? '${trimmed.substring(0, 300)}...' : trimmed;
      }
    }
    
    // Fallback to first 300 characters
    final trimmed = cleanContent.trim();
    return trimmed.length > 300 ? '${trimmed.substring(0, 300)}...' : trimmed;
  }

  /// Test connectivity to all India alert sources
  static Future<Map<String, bool>> testConnectivity() async {
    final results = <String, bool>{};
    
    // Test ReliefWeb Reports
    try {
      final reportUri = Uri.parse('https://api.reliefweb.int/v1/reports?limit=1');
      final reportResponse = await http.get(reportUri).timeout(Duration(seconds: 10));
      results['ReliefWeb_Reports'] = reportResponse.statusCode == 200;
    } catch (e) {
      results['ReliefWeb_Reports'] = false;
    }
    
    // Test ReliefWeb Disasters
    try {
      final disasterUri = Uri.parse('https://api.reliefweb.int/v1/disasters?limit=1');
      final disasterResponse = await http.get(disasterUri).timeout(Duration(seconds: 10));
      results['ReliefWeb_Disasters'] = disasterResponse.statusCode == 200;
    } catch (e) {
      results['ReliefWeb_Disasters'] = false;
    }
    
    // Test GDACS
    try {
      final gdacsUri = Uri.parse('https://www.gdacs.org/gdacsapi/api/events/geteventlist/MAP');
      final gdacsResponse = await http.get(gdacsUri).timeout(Duration(seconds: 10));
      results['GDACS'] = gdacsResponse.statusCode == 200;
    } catch (e) {
      results['GDACS'] = false;
    }
    
    print('🔗 India Alert Sources connectivity: $results');
    return results;
  }
}