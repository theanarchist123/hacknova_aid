## Ambee API Integration Documentation

### Overview
Your Flutter disaster response app now integrates with the **Ambee API** for real-time disaster alerts. This provides comprehensive, up-to-date information about natural disasters globally.

### API Key
- **Ambee API Key**: `8be48477679a11ccd019c9f1d2467a7e0325d4e386c3ce4bb44fca61ee2fb390`
- **Documentation**: https://docs.ambeedata.com/

### Integrated Endpoints

1. **Latest disasters by location** - `/disasters/latest/by-lat-lng`
   - Updates every 6 hours
   - Last 1 month data
   - Global coverage

2. **Latest disasters by country** - `/disasters/latest/by-country-code`
   - Country-specific alerts (e.g., India = 'IN')
   - Updates every 6 hours
   - Last 1 month data

3. **Latest disasters by continent** - `/disasters/latest/by-continent`
   - Continental coverage (Asia, Europe, etc.)
   - Updates every 6 hours
   - Last 1 month data

4. **Disaster history by location** - `/disasters/history/by-lat-lng`
   - Historical data for specific locations
   - Last 1 month coverage

5. **Global disaster history** - `/disasters/history`
   - Comprehensive historical data
   - Last 1 month coverage

### Features Implemented

#### 🔥 **Real-Time Data Integration**
- **Primary Source**: Ambee API for comprehensive disaster coverage
- **Supplementary**: USGS for additional earthquake data
- **Fallback**: Emergency system alerts if APIs fail
- **Location-Aware**: Uses device GPS for relevant local alerts

#### 📱 **Smart Alert Prioritization**
1. **Location-based alerts** (within 100km radius)
2. **Country-specific alerts** (India-specific when in Indian region)
3. **Continental alerts** (Asia-specific when in Asian region)
4. **Earthquake supplements** (USGS data for additional coverage)

#### 🌍 **Global Coverage with Local Focus**
- **Geofencing**: Automatically detects if user is in India/Asia
- **Relevant Filtering**: Shows most relevant disasters first
- **Distance Calculation**: Prioritizes nearby disasters
- **Multi-Source**: Combines Ambee + USGS for comprehensive coverage

### Technical Implementation

#### Core Service Files
```
lib/core/services/
├── ambee_service.dart          # Ambee API integration
├── disaster_alerts_service.dart # Main alerts coordinator
└── config/api_config.dart      # API keys and endpoints
```

#### Screen Updates
```
lib/presentation/disaster_alerts_screen/
└── disaster_alerts_screen.dart  # Updated to use real Ambee data
```

#### Test Files
```
test/
├── ambee_api_test.dart         # Ambee API integration test
└── shelter_api_test.dart       # Existing shelter API test
```

### Data Structure
Each disaster alert contains:
```dart
{
  'id': 'unique_event_id',
  'title': 'Disaster Alert Title',
  'type': 'earthquake|flood|cyclone|fire|drought|etc',
  'severity': 'critical|warning|info',
  'description': 'Detailed description',
  'affectedArea': 'Geographic location',
  'timestamp': 'ISO8601 datetime',
  'coordinates': {'latitude': lat, 'longitude': lng},
  'source': 'Ambee|USGS|Emergency System',
  'isRead': false,
  'isPinned': false,
  'status': 'active|resolved'
}
```

### Usage in App

#### 🚀 **Automatic Loading**
- App automatically loads alerts on startup
- Gets user location (with permission)
- Fetches relevant disasters from Ambee API
- Updates every time user refreshes

#### 🔄 **Manual Refresh**
- Pull-to-refresh to get latest data
- Loading indicators show real-time fetch status
- Error handling with fallback alerts

#### 🎯 **Smart Filtering**
- **Category**: Active, Warnings, Resolved
- **Severity**: Critical, Warning, Info
- **Type**: Earthquake, Flood, Cyclone, etc.
- **Date Range**: Custom date filtering

### Benefits of Ambee Integration

1. **Real-Time Accuracy**: Updates every 6 hours with latest disaster information
2. **Global Coverage**: Comprehensive worldwide disaster monitoring
3. **Multiple Disaster Types**: Earthquakes, floods, cyclones, fires, droughts, etc.
4. **Reliable Source**: Professional disaster monitoring service
5. **API Stability**: Enterprise-grade API with consistent uptime

### Testing

Run the API test to verify integration:
```bash
cd "d:\Disaster app"
dart test/ambee_api_test.dart
```

This will test:
- ✅ API connectivity
- ✅ Location-based alerts (Mumbai)
- ✅ Country alerts (India)
- ✅ Continental alerts (Asia)
- ✅ Historical data
- ✅ Data parsing and mapping

### Error Handling

The app gracefully handles:
- **Network failures**: Shows cached or fallback alerts
- **API rate limits**: Implements respectful request patterns
- **Invalid responses**: Validates and filters data
- **Location permission denial**: Uses general alerts when location unavailable
- **CORS issues**: Web platform automatically uses fallback data

### Next Steps

1. **Monitor Usage**: Track API calls and optimize requests
2. **Cache Implementation**: Store recent alerts for offline access
3. **Push Notifications**: Implement real-time alerts for critical disasters
4. **User Customization**: Allow users to customize alert types and severity
5. **Analytics**: Track which alerts users engage with most

Your disaster response app now has **real-time, professional-grade disaster monitoring** powered by Ambee's comprehensive API! 🎉
