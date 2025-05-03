import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:HealthChain/main.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Mock SharedPreferences to control onboarding and login state
    SharedPreferences.setMockInitialValues({
      'hasSeenOnboarding': true, // Skip onboarding
      'isLoggedIn': false, // Ensure we navigate to LoginScreen
    });

    // Build the app and trigger a frame
    await tester.pumpWidget(HealthChainApp(initialRoute: '/login'));

    // Wait for the splash screen to complete (3 seconds delay)
    // and for navigation to settle
    await tester.pump(Duration(seconds: 3)); // Match the splash screen delay
    await tester.pumpAndSettle();

    // Verify that the HealthChain title is displayed
    expect(find.text('HealthChain'), findsOneWidget);

    // Verify that the email and password fields are present
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify that the login button is present
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    // Verify that the sign-up link is present
    expect(find.widgetWithText(TextButton, 'Sign Up'), findsOneWidget);

    // Verify that the Remember Me checkbox is present
    expect(find.text('Remember Me'), findsOneWidget);

    // Verify that the Forgot Password link is present
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
}
