import 'package:flutter_test/flutter_test.dart';
import 'package:absensi/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AbsensiApp());
    expect(find.byType(AbsensiApp), findsOneWidget);
  });
}
