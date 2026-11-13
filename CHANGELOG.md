## 0.0.10

* Target Flutter 3.50. Material widgets now come from `package:material_ui/material_ui.dart`. `package:flutter/material.dart` is deprecated as of 3.47 and is not used.
* Fix menu item taps. The menu was closing before `onTap` ran, so `onChanged` never fired.
* Handle keyboard input with `KeyEventResult`, so typing in the search field no longer throws.
* Return the `validator` result and show it on the field.
* Apply `searchTextStyle` to the search field, and hide the hint while a query is typed.
* Keep the field in sync with `DropdownEditingController`, including clearing it by setting the value to null.
* Allow `onChanged` to be asynchronous.

## 0.0.8

* Fixed onSave issue.

## 0.0.8

* DropdownEditingController added.

## 0.0.7

* Bug Fixes.

## 0.0.6

* selectedFn added.

## 0.0.5

* Widget name Change to DropdownFormField.

## 0.0.4

* Bug fix value change.

## 0.0.3

* Documentation updated.

## 0.0.2

* Bug fix release.

## 0.0.1

* First release.
