import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jangolo/main.dart'; // Assure-toi que le nom du package = nom du dossier (jangolo)

void main() {
  testWidgets('Le compteur s’incrémente de 0 à 1', (WidgetTester tester) async {
    // Monte l’appli
    await tester.pumpWidget(const AfricaPhoneApp());

    // Au départ, on voit "Compteur: 0"
    expect(find.text('Compteur: 0'), findsOneWidget);
    expect(find.text('Compteur: 1'), findsNothing);

    // Appuie sur le bouton +
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // déclenche rebuild

    // Maintenant, on doit voir "Compteur: 1"
    expect(find.text('Compteur: 0'), findsNothing);
    expect(find.text('Compteur: 1'), findsOneWidget);
  });
}
