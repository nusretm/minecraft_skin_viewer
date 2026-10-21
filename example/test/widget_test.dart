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
    expect(find.text('Drag to orbit · Mouse wheel to zoom · Test cuboids only'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    expect(updatedValue, isFalse);
  });
}
