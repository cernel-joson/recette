import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_nutrition_app/widgets/dashboard_card.dart';

// A helper function to wrap our widget in a MaterialApp.
// This is necessary because widgets like Card and Icon need access to
// a theme and other app-level configurations to render correctly.
Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('DashboardCard Widget Tests', () {
    // This test verifies that the widget displays the correct text and icon.
    testWidgets('DashboardCard displays title, subtitle, and icon',
        (WidgetTester tester) async {
      // 1. Setup: Define the properties for our test card.
      const title = 'Test Title';
      const subtitle = 'Test Subtitle';
      const icon = Icons.favorite;

      // 2. Act: Render the widget in the test environment.
      await tester.pumpWidget(makeTestableWidget(
        child: DashboardCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: () {}, // onTap can be empty for this test
        ),
      ));

      // 3. Assert: Verify that the widgets we expect are on the screen.
      // Use `find` to locate widgets by their properties.
      expect(find.text(title), findsOneWidget);
      expect(find.text(subtitle), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    });

    // This test verifies that the onTap callback is triggered correctly.
    testWidgets('DashboardCard calls onTap when tapped',
        (WidgetTester tester) async {
      // 1. Setup: Create a variable to track if our function was called.
      bool wasTapped = false;

      // 2. Act: Render the widget with a callback that updates our variable.
      await tester.pumpWidget(makeTestableWidget(
        child: DashboardCard(
          title: 'Tap Test',
          subtitle: 'Tap me',
          icon: Icons.touch_app,
          onTap: () {
            wasTapped = true;
          },
        ),
      ));

      // Find the widget to tap. We can find it by its type.
      final cardFinder = find.byType(DashboardCard);

      // Simulate a user tap on the widget.
      await tester.tap(cardFinder);
      
      // Rebuild the widget tree after the tap (important for some state changes).
      await tester.pump();

      // 3. Assert: Check if our callback variable was changed to true.
      expect(wasTapped, isTrue);
    });
  });
}