import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vial_systems/main.dart';
import 'package:vial_systems/core/providers/auth_provider.dart';
import 'package:vial_systems/features/auth/data/repositories/local_auth_repository.dart';

void main() {
  testWidgets('App starts and shows LoginScreen by default', (WidgetTester tester) async {
    // Set mock initial values for SharedPreferences to prevent hanging/timeout in tests
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(LocalAuthRepository())),
        ],
        child: const VialSystemsApp(),
      ),
    );

    // Wait for the authProvider to check initial session and for the CircularProgressIndicator to settle
    await tester.pump(); // Start the async check
    await tester.pump(const Duration(milliseconds: 100)); // Advance timer/microtasks for repository check to complete
    await tester.pumpAndSettle(); // Complete transitions

    // Verify that LoginScreen is shown (it has 'VialSystems' and 'Fase 01 - Login' texts)
    expect(find.text('Fase 01 - Login'), findsOneWidget);
  });
}
