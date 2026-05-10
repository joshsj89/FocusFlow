import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusFlowApp());
    expect(find.text('25:00'), findsOneWidget);
  });
}
