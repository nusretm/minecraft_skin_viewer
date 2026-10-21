import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer_example/main.dart';

void main() {
  testWidgets('R1 overlay controls work without a GPU context', (tester) async {
    bool? updatedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MtnMinecraftRendererControls(
            overlayEnabled: true,
            enabled: true,
            onOverlayChanged: (value) => updatedValue = value,
          ),
        ),
      ),
    );

    expect(find.text('Head overlay'), findsOneWidget);
    expect(find.text('Drag to orbit · Wheel to zoom · Head: 8×8 PNG / nearest sampling'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    expect(updatedValue, isFalse);
  });
}
