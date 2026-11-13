import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DropdownEditingController<T> extends ChangeNotifier {
  T? _value;
  DropdownEditingController({T? value}) : _value = value;

  T? get value => _value;

  /// Updates the selection and notifies listeners.
  ///
  /// Set to null to clear the field. [DropdownFormField] listens to this
  /// controller, so the change shows up on the next frame.
  set value(T? newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

/// Create a dropdown form field
class DropdownFormField<T> extends StatefulWidget {
  final bool autoFocus;

  /// It will trigger on user search
  final bool Function(T item, String str)? filterFn;

  /// Check item is selected
  final bool Function(T? item1, T? item2)? selectedFn;

  /// Return list of items what need to list for dropdown.
  /// The list may be offline, or remote data from server.
  final Future<List<T>> Function(String str) findFn;

  /// Build dropdown Items, it get called for all dropdown items
  ///  [item] = [dynamic value] List item to build dropdown ListTile
  /// [lasSelectedItem] = [null | dynamic value] last selected item, it gives user chance to highlight selected item
  /// [position] = [0,1,2...] Index of the list item
  /// [focused] = [true | false] is the item if focused, it gives user chance to highlight focused item
  /// [onTap] = [Function] *important! just assign this function to ListTile.onTap  = onTap, in case you missed this,
  /// the click event if the dropdown item will not work.
  ///
  final ListTile Function(
    T item,
    int position,
    bool focused,
    bool selected,
    Function() onTap,
  ) dropdownItemFn;

  /// Build widget to display selected item inside Form Field
  final Widget Function(T? item) displayItemFn;

  final InputDecoration? decoration;
  final Color? dropdownColor;
  final DropdownEditingController<T>? controller;
  final FutureOr<void> Function(T item)? onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;

  /// height of the dropdown overlay, Default: 240
  final double? dropdownHeight;

  /// Style the search box text
  final TextStyle? searchTextStyle;

  /// Message to display if the search does not match with any item, Default : "No matching found!"
  final String emptyText;

  /// Give action text if you want handle the empty search.
  final String emptyActionText;

  /// this function triggers on click of emptyAction button
  final Future<void> Function()? onEmptyActionPressed;

  DropdownFormField({
    Key? key,
    required this.dropdownItemFn,
    required this.displayItemFn,
    required this.findFn,
    this.filterFn,
    this.autoFocus = false,
    this.controller,
    this.validator,
    this.decoration,
    this.dropdownColor,
    this.onChanged,
    this.onSaved,
    this.dropdownHeight,
    this.searchTextStyle,
    this.emptyText = "No matching found!",
    this.emptyActionText = 'Create new',
    this.onEmptyActionPressed,
    this.selectedFn,
  }) : super(key: key);

  @override
  DropdownFormFieldState<T> createState() => DropdownFormFieldState<T>();
}

class DropdownFormFieldState<T> extends State<DropdownFormField<T>> {
  final FocusNode _widgetFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ValueNotifier<List<T>> _listItemsValueNotifier =
      ValueNotifier<List<T>>([]);
  final TextEditingController _searchTextController = TextEditingController();
  final GlobalKey<FormFieldState<T>> _formFieldKey =
      GlobalKey<FormFieldState<T>>();

  DropdownEditingController<T>? _ownedController;

  final bool Function(T?, T?) _selectedFn =
      (T? item1, T? item2) => item1 == item2;

  bool _isFocused = false;

  OverlayEntry? _overlayEntry;
  OverlayEntry? _overlayBackdropEntry;
  List<T>? _options;
  int _listItemFocusedPosition = 0;
  T? _selectedItem;
  Widget? _displayItem;
  Timer? _debounce;
  String? _lastSearchString;
  String _renderedSearchText = '';

  DropdownEditingController<T> get _effectiveController =>
      widget.controller ??
      (_ownedController ??= DropdownEditingController<T>());

  bool get _isEmpty =>
      _selectedItem == null &&
      (_overlayEntry == null || _searchTextController.text.isEmpty);

  @override
  void initState() {
    super.initState();

    if (widget.autoFocus) _widgetFocusNode.requestFocus();
    _selectedItem = _effectiveController.value;
    _effectiveController.addListener(_handleControllerChanged);
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _searchTextController.addListener(_handleSearchTextChanged);
  }

  @override
  void didUpdateWidget(DropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DropdownEditingController<T>? previous =
        oldWidget.controller ?? _ownedController;
    if (previous != _effectiveController) {
      previous?.removeListener(_handleControllerChanged);
      _effectiveController.addListener(_handleControllerChanged);
      _handleControllerChanged();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchTextController.removeListener(_handleSearchTextChanged);
    final OverlayEntry? entry = _overlayEntry;
    final OverlayEntry? backdrop = _overlayBackdropEntry;
    _overlayEntry = null;
    _overlayBackdropEntry = null;
    backdrop?.remove();
    entry?.remove();
    _effectiveController.removeListener(_handleControllerChanged);
    _ownedController?.dispose();
    _searchTextController.dispose();
    _widgetFocusNode.dispose();
    _searchFocusNode.dispose();
    _listItemsValueNotifier.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final T? value = _effectiveController.value;
    if (_selectedItem == value) return;
    setState(() {
      _selectedItem = value;
    });
    _formFieldKey.currentState?.didChange(value);
  }

  void _handleSearchFocusChange() {
    if (!mounted) return;
    if (!_searchFocusNode.hasFocus && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _handleSearchTextChanged() {
    if (!mounted || _searchTextController.text == _renderedSearchText) return;
    setState(() {
      _renderedSearchText = _searchTextController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    _displayItem = widget.displayItemFn(_selectedItem);

    final InputDecoration effectiveDecoration = widget.decoration ??
        const InputDecoration(
          border: UnderlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down),
        );

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          _widgetFocusNode.requestFocus();
          _toggleOverlay();
        },
        child: Focus(
          autofocus: widget.autoFocus,
          focusNode: _widgetFocusNode,
          onFocusChange: (bool focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          onKeyEvent: (FocusNode node, KeyEvent event) {
            return _onKeyPressed(event);
          },
          child: FormField<T>(
            key: _formFieldKey,
            initialValue: _selectedItem,
            validator: widget.validator,
            onSaved: widget.onSaved,
            builder: (FormFieldState<T> state) {
              return InputDecorator(
                decoration:
                    effectiveDecoration.copyWith(errorText: state.errorText),
                isEmpty: _isEmpty,
                isFocused: _isFocused,
                child: _overlayEntry != null
                    ? EditableText(
                        style: widget.searchTextStyle ??
                            const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                        controller: _searchTextController,
                        cursorColor:
                            widget.searchTextStyle?.color ?? Colors.black87,
                        focusNode: _searchFocusNode,
                        backgroundCursorColor: Colors.transparent,
                        onChanged: (String str) {
                          if (_overlayEntry == null) {
                            _addOverlay();
                          }
                          _onTextChanged(str);
                        },
                        onSubmitted: (String str) {
                          _searchTextController.value =
                              const TextEditingValue(text: "");
                          _setValue();
                          _removeOverlay();
                          _widgetFocusNode.nextFocus();
                        },
                        onEditingComplete: () {},
                      )
                    : _displayItem ?? Container(),
              );
            },
          ),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderObject = context.findRenderObject() as RenderBox;
    final Size size = renderObject.size;

    return OverlayEntry(builder: (BuildContext context) {
      return Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 3.0),
          child: Material(
            elevation: 4.0,
            color: widget.dropdownColor ?? Colors.white70,
            child: SizedBox(
              height: widget.dropdownHeight ?? 240,
              // Taps on the menu must stay in the search field's tap region.
              // Otherwise Flutter 3.7+ unfocuses the field and this state
              // removes the menu before ListTile.onTap can select the item.
              child: TextFieldTapRegion(
                child: ValueListenableBuilder<List<T>>(
                  valueListenable: _listItemsValueNotifier,
                  builder:
                      (BuildContext context, List<T> items, Widget? child) {
                    return _options != null && _options!.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _options!.length,
                            itemBuilder: (BuildContext context, int position) {
                              final T item = _options![position];
                              void onTap() {
                                _listItemFocusedPosition = position;
                                _searchTextController.value =
                                    const TextEditingValue(text: "");
                                _removeOverlay();
                                _setValue();
                              }

                              return widget.dropdownItemFn(
                                item,
                                position,
                                position == _listItemFocusedPosition,
                                (widget.selectedFn ?? _selectedFn)(
                                  _selectedItem,
                                  item,
                                ),
                                onTap,
                              );
                            },
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.emptyText,
                                  style: const TextStyle(color: Colors.black45),
                                ),
                                if (widget.onEmptyActionPressed != null)
                                  TextButton(
                                    onPressed: () async {
                                      await widget.onEmptyActionPressed!();
                                      _search(_searchTextController.value.text);
                                    },
                                    child: Text(widget.emptyActionText),
                                  ),
                              ],
                            ),
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  OverlayEntry _createBackdropOverlay() {
    return OverlayEntry(
      builder: (BuildContext context) => Positioned(
        left: 0,
        top: 0,
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        child: GestureDetector(
          onTap: _removeOverlay,
        ),
      ),
    );
  }

  void _addOverlay() {
    if (_overlayEntry != null) return;
    _search("");
    _overlayBackdropEntry = _createBackdropOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insertAll([_overlayBackdropEntry!, _overlayEntry!]);
    setState(() {});
    _searchFocusNode.requestFocus();
  }

  /// Detach overlay from the dropdown widget
  void _removeOverlay() {
    final OverlayEntry? entry = _overlayEntry;
    if (entry == null) return;
    final OverlayEntry? backdrop = _overlayBackdropEntry;
    _overlayEntry = null;
    _overlayBackdropEntry = null;
    backdrop?.remove();
    entry.remove();
    _searchTextController.value = TextEditingValue.empty;
    if (mounted) setState(() {});
  }

  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _addOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChanged(String? str) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_lastSearchString != str) {
        _lastSearchString = str;
        _search(str ?? "");
      }
    });
  }

  KeyEventResult _onKeyPressed(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _toggleOverlay();
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
      return KeyEventResult.handled;
    }

    final List<T>? items = _options;
    if (items == null || items.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      var next = _listItemFocusedPosition + 1;
      if (next >= items.length) next = 0;
      _listItemFocusedPosition = next;
      _listItemsValueNotifier.value = List<T>.from(items);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      var next = _listItemFocusedPosition - 1;
      if (next < 0) next = items.length - 1;
      _listItemFocusedPosition = next;
      _listItemsValueNotifier.value = List<T>.from(items);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _search(String str) async {
    List<T> items = await widget.findFn(str);
    if (!mounted) return;

    if (str.isNotEmpty && widget.filterFn != null) {
      items = items.where((T item) => widget.filterFn!(item, str)).toList();
    }

    _options = items;
    _listItemsValueNotifier.value = items;
  }

  void _setValue() {
    final List<T>? items = _options;
    if (items == null || items.isEmpty) return;
    var index = _listItemFocusedPosition;
    if (index < 0 || index >= items.length) index = 0;
    final T item = items[index];
    _selectedItem = item;

    _effectiveController.value = item;

    widget.onChanged?.call(item);
    _formFieldKey.currentState?.didChange(item);

    setState(() {});
  }
}
