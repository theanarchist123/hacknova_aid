# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter-based emergency disaster management application (`hacknova_aid`) focused on emergency response, alerts, and safety. The app provides real-time disaster alerts, interactive emergency maps, incident reporting, and emergency response tools designed for critical situations.

## Essential Development Commands

### Basic Commands
```bash
# Install dependencies
flutter pub get

# Run the application
flutter run

# Run on specific platform
flutter run -d windows
flutter run -d android
flutter run -d ios

# Hot reload is available during development
# Press 'r' to hot reload, 'R' to hot restart
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Analysis
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/
```

### Building for Production
```bash
# Build APK for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for Windows
flutter build windows --release
```

## Code Architecture

### Core Structure
- **`lib/main.dart`**: Application entry point with critical device orientation lock and custom error handling
- **`lib/core/app_export.dart`**: Centralized exports for connectivity, routing, widgets, and theming
- **`lib/routes/app_routes.dart`**: Navigation configuration with disaster-specific screens

### Key Architectural Patterns

#### Emergency-First Design
The app is structured around emergency scenarios with:
- **Priority-based navigation**: Critical functions (SOS, emergency response) are always accessible
- **Offline-ready widgets**: Components designed to work without internet connectivity
- **Emergency mode states**: UI adapts for high-stress emergency situations

#### Screen Organization
```
lib/presentation/
├── splash_screen/              # App initialization
├── home_dashboard_screen/      # Main hub with quick actions and recent alerts
├── disaster_alerts_screen/     # Alert management and filtering
├── interactive_map_screen/     # Emergency map with shelters, hospitals, hazards
├── emergency_response_screen/  # Emergency actions, SOS, first aid
└── incident_reporting_screen/  # User incident reporting with location/photos
```

#### Theme System (`lib/theme/app_theme.dart`)
- **Emergency-Ready Minimalism**: High-contrast design optimized for emergency situations
- **Critical color palette**: Red for emergencies, amber for warnings, green for safety
- **Accessibility focus**: Large touch targets, high contrast ratios, clear typography
- **Both light and dark themes** optimized for day/night emergency situations

#### Widget Architecture
- **Emergency-specific widgets**: Alert cards, SOS buttons, emergency action cards
- **Responsive design**: Uses `sizer` package for consistent sizing across devices
- **Custom icon system**: Emergency-focused iconography through `CustomIconWidget`
- **Contextual actions**: Widgets provide relevant emergency actions based on situation

### Critical Dependencies
- **`sizer: ^2.0.15`**: Responsive design system (DO NOT REMOVE)
- **`flutter_svg: ^2.0.9`**: SVG icon support (DO NOT REMOVE)
- **`google_fonts: ^6.1.0`**: Typography system (replaces local fonts)
- **`flutter_map: ^8.1.1`**: Interactive emergency mapping
- **`geolocator: ^13.0.4`**: Location services for emergency features
- **`permission_handler: ^11.1.0`**: Device permissions for emergency functions

## Development Guidelines

### Emergency UI Principles
1. **Critical actions** (SOS, emergency contacts) must be accessible within 2 taps
2. **High contrast colors** for visibility in stress situations
3. **Large touch targets** (minimum 44dp) for emergency interactions
4. **Clear visual hierarchy** with emergency severity indicators

### Code Quality Requirements
- **Error handling**: Custom error widget with user-friendly messages
- **Null safety**: All code must be null-safe
- **Device orientation**: App is locked to portrait mode for consistency
- **Text scaling**: Disabled to maintain emergency UI integrity

### Asset Management Rules
- **Only use existing asset directories**: `assets/` and `assets/images/`
- **DO NOT add new asset directories** (no `assets/svg/`, `assets/icons/`, etc.)
- **Use Google Fonts instead of local fonts**

### Screen Development Pattern
Each emergency screen follows this structure:
1. **Status indicator** showing current threat level/emergency state
2. **Primary actions** for immediate emergency response
3. **Secondary information** and contextual tools
4. **Navigation** that maintains emergency access

### Testing Strategy
- **Widget tests** for critical emergency components
- **Integration tests** for emergency workflows
- **Accessibility testing** for emergency situations
- **Offline functionality testing**

### Emergency Data Handling
- **Mock data structure** includes severity levels, coordinates, timestamps
- **Location-based services** with proper permission handling
- **Offline-capable** data structures for emergency scenarios

## Navigation Rules

### Route Structure
All routes are defined in `AppRoutes` class with emergency-priority ordering:
- `/` → SplashScreen (initialization)
- `/home-dashboard-screen` → Main emergency hub
- `/disaster-alerts-screen` → Alert management
- `/emergency-response-screen` → Emergency actions and SOS
- `/interactive-map-screen` → Emergency mapping
- `/incident-reporting-screen` → Report new incidents

### Emergency Access Pattern
Critical emergency functions must be accessible from any screen through:
- Bottom navigation (persistent emergency access)
- Floating action buttons (SOS functionality)
- Emergency mode toggles (priority UI states)

## Key Features to Understand

### Emergency Response System
- **SOS activation** with location broadcasting
- **Emergency contacts** with quick-dial functionality  
- **First aid guides** available offline
- **Shelter finder** with capacity and distance information

### Interactive Emergency Map
- **Real-time disaster markers** with severity coding
- **Emergency infrastructure** (hospitals, shelters, food centers)
- **Emergency mode** with auto-enabled critical filters
- **Custom incident reporting** via map interaction

### Alert Management
- **Severity-based filtering** (critical, warning, info)
- **Location-based alerts** with affected area mapping
- **Swipe actions** for alert management
- **Pin important alerts** functionality

## Development Notes

- The app name is `hacknova_aid` but displays as "HackNova Aid" in UI
- Windows app title is set to "hacknova_aid" in `windows/runner/main.cpp`
- Portrait orientation is enforced for emergency UI consistency
- Text scaling is disabled to maintain emergency interface integrity
- Custom error handling prevents crashes during critical operations
