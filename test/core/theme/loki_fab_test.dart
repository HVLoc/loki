import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loki/core/theme/app_theme.dart';
import 'package:loki/core/theme/app_widgets.dart';

void main() {
  Widget buildApp({required VoidCallback onPressed}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: LokiFabScrollView(
          fabLabel: 'Thêm thói quen',
          onFabPressed: onPressed,
          child: ListView.builder(
            itemCount: 60,
            itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Item $i')),
          ),
        ),
      ),
    );
  }

  testWidgets('FAB collapses on scroll down and expands on scroll up', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(buildApp(onPressed: () => taps++));
    await tester.pumpAndSettle();

    // Extended at top.
    expect(find.text('Thêm thói quen'), findsOneWidget);

    // Scroll down -> collapsed to icon-only circle.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Thêm thói quen'), findsNothing);
    final fabSize = tester.getSize(find.byType(LokiFab));
    expect(fabSize.width, closeTo(LokiFab.size, 0.5));
    expect(fabSize.height, closeTo(LokiFab.size, 0.5));

    // Still tappable while collapsed.
    await tester.tap(find.byType(LokiFab));
    expect(taps, 1);

    // Scroll up -> extended again.
    await tester.drag(find.byType(ListView), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(find.text('Thêm thói quen'), findsOneWidget);
  });
}
