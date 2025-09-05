import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/disaster_alerts_screen/disaster_alerts_screen.dart';
import '../presentation/interactive_map_screen/interactive_map_screen.dart';
import '../presentation/emergency_response_screen/emergency_response_screen.dart';
import '../presentation/incident_reporting_screen/incident_reporting_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String disasterAlerts = '/disaster-alerts-screen';
  static const String interactiveMap = '/interactive-map-screen';
  static const String emergencyResponse = '/emergency-response-screen';
  static const String incidentReporting = '/incident-reporting-screen';
  static const String homeDashboard = '/home-dashboard-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    disasterAlerts: (context) => const DisasterAlertsScreen(),
    interactiveMap: (context) => const InteractiveMapScreen(),
    emergencyResponse: (context) => const EmergencyResponseScreen(),
    incidentReporting: (context) => const IncidentReportingScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    // TODO: Add your other routes here
  };
}
