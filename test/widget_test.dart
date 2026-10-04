import 'package:flutter_test/flutter_test.dart';
import 'package:ianova_app/main.dart';

void main() {
  testWidgets('IANOVA app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const IanovaApp());

    expect(find.text('Shop smart.'), findsOneWidget);
    expect(find.text('Live better.'), findsOneWidget);
    expect(find.text('Flash deals'), findsOneWidget);
    expect(find.text('Popular picks'), findsOneWidget);
  });
}
