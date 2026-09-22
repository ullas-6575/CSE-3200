import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/app.dart';

void main() {
  testWidgets('home page shows image actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Take Image'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('No image selected'), findsOneWidget);
  });
}
