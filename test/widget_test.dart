import 'package:flutter_test/flutter_test.dart';

import 'package:crave_app/main.dart';
import 'package:crave_app/views/login_screen.dart';

void main() {
  testWidgets('Sin sesión iniciada, la app abre en LoginScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
