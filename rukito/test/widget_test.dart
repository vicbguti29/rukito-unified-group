import 'package:flutter_test/flutter_test.dart';
import 'package:rukito/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RukitoApp());
    
    // Wait for the MockApiService and initial load
    await tester.pumpAndSettle();

    // Verify that Dashboard exists (Sidebar navigation item)
    expect(find.text('Dashboard'), findsWidgets);
  });
}