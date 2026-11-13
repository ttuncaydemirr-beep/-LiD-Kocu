import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_kocu/ui/tema.dart';

void main() {
  for (final b in [Brightness.light, Brightness.dark]) {
    testWidgets('govde metni Cairo, tema rengi, 16 px ($b)', (t) async {
      final tema = temaOlustur(b);
      late TextStyle? stil;
      await t.pumpWidget(MaterialApp(
        theme: tema,
        home: Builder(builder: (c) {
          stil = Theme.of(c).textTheme.bodyMedium;
          return const SizedBox();
        }),
      ));
      expect(stil?.fontFamily, 'Cairo');
      expect(stil?.color, tema.colorScheme.onSurface);
      expect(stil?.fontSize, 16);
    });
  }
}
