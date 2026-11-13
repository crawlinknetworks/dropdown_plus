import 'dart:async';

import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openDropdown(WidgetTester tester) async {
    await tester.tap(find.byType(InputDecorator));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('tapping a menu item selects it and calls onChanged', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextDropdownFormField(
            options: const ['Male', 'Female'],
            onChanged: (String item) {
              selected = item;
            },
          ),
        ),
      ),
    );

    await openDropdown(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Female'));
    await tester.pump();

    expect(selected, 'Female');
    expect(find.widgetWithText(ListTile, 'Female'), findsNothing);
    expect(find.text('Female'), findsOneWidget);
  });

  testWidgets('onChanged may be asynchronous', (WidgetTester tester) async {
    final Completer<String> selected = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextDropdownFormField(
            options: const ['Male', 'Female'],
            onChanged: (String item) async {
              selected.complete(item);
            },
          ),
        ),
      ),
    );

    await openDropdown(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Male'));
    await tester.pump();

    expect(await selected.future, 'Male');
  });

  testWidgets('typing in the search field filters items and does not throw', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextDropdownFormField(
            options: const ['Male', 'Female'],
          ),
        ),
      ),
    );

    await openDropdown(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(EditableText), 'fe');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(ListTile, 'Female'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Male'), findsNothing);
  });

  testWidgets('arrow keys move the highlighted item',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextDropdownFormField(
            options: const ['Male', 'Female'],
          ),
        ),
      ),
    );

    await openDropdown(tester);
    ListTile tile(String label) => tester.widget<ListTile>(
          find.widgetWithText(ListTile, label),
        );

    expect(tile('Male').tileColor, const Color.fromARGB(20, 0, 0, 0));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(tile('Female').tileColor, const Color.fromARGB(20, 0, 0, 0));
    expect(tile('Male').tileColor, Colors.transparent);
  });

  testWidgets('validator result is shown on the field',
      (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextDropdownFormField(
              options: const ['Male', 'Female'],
              validator: (String? value) => value == null ? 'Required' : null,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('searchTextStyle is applied to the search field', (
    WidgetTester tester,
  ) async {
    const TextStyle style = TextStyle(fontSize: 22, color: Color(0xFF112233));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownFormField<String>(
            searchTextStyle: style,
            findFn: (String query) async => const ['Male', 'Female'],
            displayItemFn: (String? item) => Text(item ?? ''),
            dropdownItemFn: (item, position, focused, selected, onTap) =>
                ListTile(title: Text(item), onTap: onTap),
          ),
        ),
      ),
    );

    await openDropdown(tester);

    expect(tester.widget<EditableText>(find.byType(EditableText)).style, style);
  });

  testWidgets('hint is hidden while a search query is typed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextDropdownFormField(
            options: const ['Male', 'Female'],
            decoration: const InputDecoration(hintText: 'Choose gender'),
          ),
        ),
      ),
    );

    expect(find.text('Choose gender'), findsOneWidget);

    await openDropdown(tester);
    await tester.enterText(find.byType(EditableText), 'm');
    await tester.pump();

    final AnimatedOpacity hintOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Choose gender'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(hintOpacity.opacity, 0);
  });

  testWidgets('controller updates and clears the selection', (
    WidgetTester tester,
  ) async {
    final DropdownEditingController<String> controller =
        DropdownEditingController<String>(value: 'Male');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextDropdownFormField(
            options: const ['Male', 'Female'],
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('Male'), findsOneWidget);

    controller.value = 'Female';
    await tester.pump();
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Male'), findsNothing);

    controller.value = null;
    await tester.pump();
    expect(find.text('Female'), findsNothing);
    expect(find.text('Male'), findsNothing);
  });
}
