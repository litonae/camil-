import 'package:flutter_test/flutter_test.dart';
import 'package:barber_camil/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Camil App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CamilApp(),
      ),
    );

    // Verify that the splash screen text appears.
    expect(find.text('CAMIL'), findsOneWidget);
    expect(find.text('BARBER EXPERIENCE'), findsOneWidget);
  });
}
