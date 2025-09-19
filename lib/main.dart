import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'core/services/community_pin_store.dart';
import 'core/services/disaster_bluetooth_service.dart';
import 'core/services/alert_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  try {
    // Initialize CommunityPinStore
    CommunityPinStore.initialize();
    print('✅ Database initialized successfully');
    
    // Ensure Bluetooth service also has database initialized
    DisasterBluetoothService.ensureDatabaseInitialized();
    print('✅ Bluetooth service database initialized');

    // REMOVE eager background service start - will start after first frame
    // AlertBackgroundService.startBackgroundMonitoring();
    // print('✅ Alert background service started');
  } catch (e) {
    print('⚠️ Database initialization warning: $e');
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _alertServiceStarted = false;

  @override
  void initState() {
    super.initState();
    
    // Start background alert service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_alertServiceStarted) return;
      _alertServiceStarted = true;
      
      try {
        await Future.delayed(Duration(seconds: 2)); // Small delay to let app settle
        await AlertBackgroundService.startBackgroundMonitoring();
        print('✅ Alert background service started (post-frame)');
      } catch (e) {
        print('⚠️ Failed to start alert background service: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'hacknova_aid',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}
