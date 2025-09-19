/// Simple disaster precautions service
class DisasterPrecautionsService {
  static List<String> getPrecautions(String disasterType, String languageCode) {
    // Basic precautions based on disaster type
    switch (disasterType.toLowerCase()) {
      case 'flood':
        return [
          'Move to higher ground immediately',
          'Avoid walking through floodwater',
          'Stay away from electrical equipment'
        ];
      case 'earthquake':
        return [
          'Drop, cover, and hold on',
          'Stay away from windows and heavy objects',
          'If outdoors, move away from buildings'
        ];
      case 'cyclone':
        return [
          'Stay indoors and away from windows',
          'Have emergency supplies ready',
          'Follow evacuation orders if given'
        ];
      default:
        return [
          'Stay informed about the situation',
          'Follow local emergency guidelines',
          'Keep emergency contact numbers handy'
        ];
    }
  }
}