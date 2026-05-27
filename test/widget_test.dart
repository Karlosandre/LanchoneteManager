import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LanchoneteApp());
    expect(find.byType(LanchoneteApp), findsOneWidget);
  });
}
