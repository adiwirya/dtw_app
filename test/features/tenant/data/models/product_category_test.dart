import 'package:dtw_app/features/tenant/data/models/product_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductCategory.fromJson parses id and name', () {
    final category = ProductCategory.fromJson(const {
      'id': 'cat-1',
      'name': 'Sahabat Series',
      'parent_category_id': null,
      'sequence_order': 1,
      'is_active': true,
    });

    expect(category.id, 'cat-1');
    expect(category.name, 'Sahabat Series');
  });
}
