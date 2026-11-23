import 'package:flutter_test/flutter_test.dart';
import 'package:loki/core/constants/starter_templates.dart';

void main() {
  test('StarterTemplates contains all 6 core weakness templates', () {
    expect(StarterTemplates.weaknesses.length, 6);
  });
}
