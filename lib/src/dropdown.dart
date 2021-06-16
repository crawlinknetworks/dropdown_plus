import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DropdownFormField<T> extends StatefulWidget {
  final bool autoFocus;
  final bool Function(T item, String str)? filterFn;
  final Future<List<T>> Function(String str) findFn;
  final ListTile Function(
    T item,
    int position,
    bool focused,
    bool selected,
    Function() onTap,
  ) dropdownItemFn;
  final Widget Function(T? item) displayItemFn;
  final InputDecoration? decoration;
  final Color? dropdownColor;
  final ValueNotifier<T>? controller;
  final void Function(T item)? onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;
  final double? dropdownHeight;

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
  }) : super(key: key);

  @override
  DropdownFormFieldState createState() => DropdownFormFieldState<T>();
}

class DropdownFormFieldState<T> extends State<DropdownFormField>
    with SingleTickerProviderStateMixin {
  final FocusNode _widgetFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ValueNotifier<List<T>> _listItemsValueNotifier =
      ValueNotifier<List<T>>([]);
  final TextEditingController? _searchTextController = TextEditingController();

  bool _isFocused = false;
  OverlayEntry? _overlayEntry;
  List<T>? _options;
  int _listItemFocusedPosition = 0;
  T? _selectedItem;
  Widget? _displayItem;
  Timer? _debounce;
  String? _lastSearchString;

  bool get _isEmpty => _selectedItem == null;

  DropdownFormFieldState() : super() {}

  @override
  void initState() {
    super.initState();

    if (widget.autoFocus) _widgetFocusNode.requestFocus();
    if (widget.controller != null) _selectedItem = widget.controller!.value;

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _overlayEntry != null) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _debounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // print("_overlayEntry : $_overlayEntry");

    _displayItem = widget.displayItemFn(_selectedItem);

    return CompositedTransformTarget(
      link: this._layerLink,
      child: GestureDetector(
        onTap: () {
          _widgetFocusNode.requestFocus();
          _toggleOverlay();
        },
        child: Focus(
          autofocus: widget.autoFocus,
          focusNode: _widgetFocusNode,
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          onKey: (focusNode, event) {
            return _onKeyPressed(event);
          },
          child: FormField(
              validator: widget.validator ?? (str) {},
              onSaved: widget.onSaved ?? (str) {},
              builder: (state) {
                return InputDecorator(
                  decoration: widget.decoration ??
                      InputDecoration(
                        border: UnderlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                  isEmpty: _isEmpty,
                  isFocused: _isFocused,
                  child: this._overlayEntry != null
                      ? EditableText(
                          style: TextStyle(fontSize: 16),
                          controller: _searchTextController!,
                          cursorColor: Colors.black87,
                          focusNode: _searchFocusNode,
                          backgroundCursorColor: Colors.transparent,
                          onChanged: (str) {
                            if (_overlayEntry == null) {
                              _addOverlay();
                            }
                            _onTextChanged(str);
                          },
                          onSubmitted: (str) {
                            _searchTextController?.value =
                                TextEditingValue(text: "");
                            _setValue();
                          },
                          onEditingComplete: () {},
                        )
                      : _displayItem ?? Container(),
                );
              }),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    final renderObject = context.findRenderObject() as RenderBox;
    // print(renderObject);
    final Size size = renderObject.size;

    var overlay = OverlayEntry(builder: (context) {
      return Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: this._layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 3.0),
          child: Material(
              elevation: 4.0,
              child: SizedBox(
                height: widget.dropdownHeight ?? 240,
                child: Container(
                  color: widget.dropdownColor ?? Colors.white70,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                            valueListenable: _listItemsValueNotifier,
                            builder: (context, List<T> items, child) {
                              // print(
                              //     'ValueListenableBuilder $_listItemFocusedPosition : ${items.length}');
                              return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _options!.length,
                                  itemBuilder: (context, position) {
                                    T item = _options![position];
                                    Function() onTap = () {
                                      _listItemFocusedPosition = position;
                                      _searchTextController?.value =
                                          TextEditingValue(text: "");
                                      _removeOverlay();
                                      _setValue();
                                    };
                                    ListTile listTile = widget.dropdownItemFn(
                                      item,
                                      position,
                                      position == _listItemFocusedPosition,
                                      item != null && _selectedItem == item,
                                      onTap,
                                    );

                                    return listTile;
                                  });
                            }),
                      ),
                    ],
                  ),
                ),
              )),
        ),
      );
    });

    return overlay;
  }

  _addOverlay() {
    if (_overlayEntry == null) {
      _search("");
      _overlayEntry = _createOverlayEntry();
      if (_overlayEntry != null) {
        Overlay.of(context)!.insert(_overlayEntry!);
        setState(() {
          _searchFocusNode.requestFocus();
        });
      }
    }
  }

  /// Dettach overlay from the dropdown widget
  _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      setState(() {});
    }
  }

  _toggleOverlay() {
    if (_overlayEntry == null)
      _addOverlay();
    else
      _removeOverlay();
  }

  _onTextChanged(String? str) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // print("_onChanged: $_lastSearchString = $str");
      if (_lastSearchString != str) {
        _lastSearchString = str;
        _search(str ?? "");
      }
    });
  }

  _onKeyPressed(RawKeyEvent event) {
    // print('_onKeyPressed : ${event.character}');
    if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      if (_searchFocusNode.hasFocus) {
        _toggleOverlay();
      } else {
        _toggleOverlay();
      }
      return false;
    } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
      _removeOverlay();
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      int v = _listItemFocusedPosition;
      v++;
      if (v >= _options!.length) v = 0;
      _listItemFocusedPosition = v;
      _listItemsValueNotifier.value = List<T>.from(_options ?? []);
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      int v = _listItemFocusedPosition;
      v--;
      if (v < 0) v = _options!.length - 1;
      _listItemFocusedPosition = v;
      _listItemsValueNotifier.value = List<T>.from(_options ?? []);
      return true;
    }
    return false;
  }

  _search(String str) async {
    List<T> items = await widget.findFn(str) as List<T>;

    if (str.isNotEmpty && widget.filterFn != null) {
      items = items.where((item) => widget.filterFn!(item, str)).toList();
    }

    _options = items;

    _listItemsValueNotifier.value = items;

    // print('_search ${_options!.length}');
  }

  _setValue() {
    var item = _options![_listItemFocusedPosition];
    _selectedItem = item;

    if (widget.controller != null) {
      widget.controller!.value = _selectedItem;
    }

    if (widget.onChanged != null) {
      widget.onChanged!(_selectedItem);
    }

    setState(() {});
  }

  _clearValue() {
    var item;
    if (widget.controller != null) {
      widget.controller!.value = item;
    }
    if (widget.onChanged != null) {
      widget.onChanged!(_selectedItem);
    }
    _searchTextController?.value = TextEditingValue(text: "");
  }
}
