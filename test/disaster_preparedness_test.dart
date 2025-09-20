import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacknova_aid/presentation/disaster_preparedness_screen/disaster_preparedness_screen.dart';
import 'package:hacknova_aid/routes/app_routes.dart';

void main() {
  group('Disaster Preparedness Screen Tests', () {
    testWidgets('should display disaster preparedness screen with language selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DisasterPreparednessScreen(),
        ),
      );

      // Verify that the screen loads
      expect(find.text('Disaster Preparedness'), findsOneWidget);
      expect(find.text('Select Language'), findsOneWidget);
      
      // Verify language dropdown exists
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Verify disaster type cards are present
      expect(find.text('Floods'), findsOneWidget);
      expect(find.text('Earthquakes'), findsOneWidget);
      expect(find.text('Cyclones/Hurricanes'), findsOneWidget);
      expect(find.text('Forest Fires'), findsOneWidget);
      expect(find.text('Landslides'), findsOneWidget);
    });

    testWidgets('should change language when dropdown value changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DisasterPreparednessScreen(),
        ),
      );

      // Find and tap the language dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select Hindi
      await tester.tap(find.text('हिंदी (Hindi)').last);
      await tester.pumpAndSettle();

      // Verify that titles changed to Hindi
      expect(find.text('आपदा तैयारी'), findsOneWidget);
      expect(find.text('भाषा चुनें'), findsOneWidget);
      expect(find.text('बाढ़'), findsOneWidget);
      expect(find.text('भूकंप'), findsOneWidget);
    });

    testWidgets('should open disaster details modal when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DisasterPreparednessScreen(),
        ),
      );

      // Tap on floods card
      await tester.tap(find.text('Floods'));
      await tester.pumpAndSettle();

      // Verify modal opened with tabs
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('During'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      
      // Verify some instruction content
      expect(find.textContaining('Stay informed about flood warnings'), findsOneWidget);
    });

    testWidgets('should verify navigation route is configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.disasterPreparedness,
        ),
      );

      // Verify that the route works and screen loads
      expect(find.text('Disaster Preparedness'), findsOneWidget);
    });
  });
}