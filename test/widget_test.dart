import 'package:flutter_test/flutter_test.dart';
import 'package:clubmanager_sport/app/clubmanager_app.dart';

void main() {
  testWidgets('ClubManager Sport app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ClubManagerApp());

    expect(find.text('ClubManager Sport'), findsOneWidget);
    expect(
      find.text('Gestione semplice per società sportive dilettantistiche.'),
      findsOneWidget,
    );
  });
}
