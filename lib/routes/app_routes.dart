import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/disaster_alerts_screen/disaster_alerts_screen.dart';
import '../presentation/interactive_map_screen/interactive_map_screen.dart';
import '../presentation/emergency_response_screen/emergency_response_screen.dart';
import '../presentation/incident_reporting_screen/incident_reporting_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/comprehensive_dashboard/comprehensive_dashboard_screen.dart';
import '../presentation/ocr_screen/ocr_screen.dart';
import '../presentation/bluetooth_sos_screen/bluetooth_sos_screen.dart';
import '../presentation/speech_qna_screen/speech_qna_screen.dart';
import '../presentation/ocr_summarizer_clean.dart';
import '../presentation/disaster_safety_screen/disaster_safety_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String disasterAlerts = '/disaster-alerts-screen';
  static const String interactiveMap = '/interactive-map-screen';
  static const String emergencyResponse = '/emergency-response-screen';
  static const String incidentReporting = '/incident-reporting-screen';
  static const String homeDashboard = '/home-dashboard-screen';
  static const String comprehensiveDashboard = '/comprehensive-dashboard-screen';
  static const String ocr = '/ocr-screen';
  static const String ocrSummarizer = '/ocr-summarizer-screen';
  static const String bluetoothSOS = '/bluetooth-sos-screen';
  static const String speechQna = '/speech-qna-screen';
  static const String disasterSafety = '/disaster-safety-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    disasterAlerts: (context) => const DisasterAlertsScreen(),
    interactiveMap: (context) => const InteractiveMapScreen(),
    emergencyResponse: (context) => const EmergencyResponseScreen(),
    incidentReporting: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return IncidentReportingScreen(
        initialLocation: args?['location'] as String?,
        initialLatitude: args?['latitude'] as double?,
        initialLongitude: args?['longitude'] as double?,
      );
    },
    homeDashboard: (context) => const HomeDashboardScreen(),
    comprehensiveDashboard: (context) => const ComprehensiveDashboardScreen(),
    ocr: (context) => OCRScreen(),
    ocrSummarizer: (context) => const OCRSummarizerPageSimple(),
    bluetoothSOS: (context) => const BluetoothSosScreen(),
    speechQna: (context) => const SpeechQnaScreen(),
    disasterSafety: (context) => const DisasterSafetyScreen(),
    // TODO: Add your other routes here
  };
}
