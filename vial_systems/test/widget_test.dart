import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vial_systems/main.dart';
import 'package:vial_systems/core/providers/auth_provider.dart';
import 'package:vial_systems/features/auth/data/repositories/local_auth_repository.dart';

void main() {
  testWidgets('App starts and shows LoginScreen by default', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(LocalAuthRepository())),
        ],
        child: const VialSystemsApp(),
      ),
    );

    // Wait for the authProvider to check initial session
    await tester.pumpAndSettle();

    // Verify that LoginScreen is shown (it has 'VialSystems' and 'Fase 01 - Login' texts)
    expect(find.text('Fase 01 - Login'), findsOneWidget);
  });
}
