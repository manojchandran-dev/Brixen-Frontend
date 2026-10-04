import 'package:brixen/shared/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distinctOptions: unique, sorted, blank-free, readable labels', () {
    final opts = distinctOptions<String?>(
      ['active', 'on_leave', 'active', null, '  ', 'Inactive'],
      (v) => v,
    );
    expect(opts.map((o) => o.$1), ['active', 'Inactive', 'on_leave']);
    expect(opts.map((o) => o.$2), ['Active', 'Inactive', 'On leave']);
  });

  testWidgets('SearchFilterBar: ✕ clears the search, filter button taps', (
    tester,
  ) async {
    final ctrl = TextEditingController();
    var query = 'x';
    var filterTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchFilterBar(
            controller: ctrl,
            hintText: 'Search…',
            onChanged: (v) => query = v,
            filterActive: false,
            onFilter: () => filterTaps++,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'priya');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(ctrl.text, isEmpty);
    expect(query, isEmpty);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    expect(filterTaps, 1);
  });
}
