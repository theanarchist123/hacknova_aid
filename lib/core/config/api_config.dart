class ApiConfig {
  // Google APIs
  static const String googleApiKey = 'AIzaSyAxASAVnfdE_c9Axulg_dG0TBcTWGaN79I';
  
  // Free API endpoints
  static const String usgsEarthquakeApi = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.geojson';
  static const String gdacsApi = 'https://www.gdacs.org/gdacsapi/api/events/geteventlist/MAP';
  
  // Google Services URLs
  static const String googlePlacesApi = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const String googlePlaceDetailsApi = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String googleDirectionsApi = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String googleGeocodingApi = 'https://maps.googleapis.com/maps/api/geocode/json';
  
  // Emergency contact numbers (customize for your region)
  static const Map<String, String> emergencyContacts = {
    'police': '911',
    'fire': '911', 
    'medical': '911',
    'disaster': '1-800-621-3362',
  };
}
