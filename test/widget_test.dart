import 'package:flutter_test/flutter_test.dart';
import 'package:moto_gastos_app/main.dart';

void main() {
  testWidgets('Carregamento inicial do app', (WidgetTester tester) async {
    await tester.pumpWidget(const MotoGastosApp());
  });
}