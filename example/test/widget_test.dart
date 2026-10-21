import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer_example/main.dart';

void main() {
  testWidgets('R1 prototype shows the viewer controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MtnMinecraftRendererPrototype(),
      ),
    );

    expect(find.text('Minecraft Skin Viewer — R1 renderer test'), findsOneWidget);
    expect(find.text('Head overlay'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });
}
