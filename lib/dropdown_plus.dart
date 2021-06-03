library dropdown_plus;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class Dropdown<T> extends StatefulWidget {
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
  final Widget Function(T item) displayItemFn;
  final InputDecoration? decoration;
  final Color? dropdownColor;
  final ValueNotifier<T>? controller;
  final void Function(T item)? onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;
  final double? dropdownHeight;

  Dropdown({
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
  DropdownState createState() => DropdownState<T>();
}

class DropdownState<T> extends State<Dropdown>
    with SingleTickerProviderStateMixin {
  final FocusNode _widgetFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final _textChangeSubject = PublishSubject<String>();
  final ValueNotifier<List<T>> _listItemsValueNotifier =
      ValueNotifier<List<T>>([]);
  final TextEditingController? _searchTextController = TextEditingController();

  bool _isEmpty = false;
  bool _isFocused = false;
  OverlayEntry? _overlayEntry;
  List<T>? _options;
  int _listItemFocusedposition = 0;
  T? _selectedItem;
  Widget? _displayItem;

  DropdownState() : super() {}

  @override
  void initState() {
    if (widget.autoFocus) _widgetFocusNode.requestFocus();
    if (widget.controller != null) _selectedItem = widget.controller!.value;

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _overlayEntry != null) {
        _removeOverlay();
      }
    });

    _textChangeSubject.stream
        .debounceTime(Duration(milliseconds: 300))
        .map((str) => str.trim().toLowerCase())
        .distinct()
        .listen(_search);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print("_overlayEntry : $_overlayEntry");
    // _displayItem = widget.displayItemFn(_selectedItem??"");

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
            print('focused : $focused');
            if (focused) {
              // _searchFocusNode.requestFocus();
            }
            setState(() {
              _isEmpty = !focused;
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
                height:   widget.dropdownHeight??240,
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
                              //     'ValueListenableBuilder $_listItemFocusedposition : ${items.length}');
                              return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _options!.length,
                                  itemBuilder: (context, posistion) {
                                    T item = _options![posistion];
                                    Function() onTap = () {
                                      _listItemFocusedposition = posistion;
                                      _searchTextController?.value =
                                          TextEditingValue(text: "");
                                      _removeOverlay();
                                      _setValue();
                                    };
                                    ListTile listTile = widget.dropdownItemFn(
                                      item,
                                      posistion,
                                      posistion == _listItemFocusedposition,
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
    // print('_onTextChanged $str');
    _textChangeSubject.add(str ?? '');
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
      int v = _listItemFocusedposition;
      v++;
      if (v >= _options!.length) v = 0;
      _listItemFocusedposition = v;
      _listItemsValueNotifier.value = List<T>.from(_options ?? []);
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      int v = _listItemFocusedposition;
      v--;
      if (v < 0) v = _options!.length - 1;
      _listItemFocusedposition = v;
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
    var item = _options![_listItemFocusedposition];
    _selectedItem = item;
    _displayItem = widget.displayItemFn(_selectedItem);
    widget.onChanged!(_selectedItem);
    widget.controller?.value = item;
    setState(() {});
  }

  _clearValue() {
    var item;
    widget.controller?.value = item;
    _searchTextController?.value = TextEditingValue(text: "");
  }
}

/// Simple dorpdown whith plain text as a dropdown items.
class TextDropdown extends StatelessWidget {
  final List<String> options;
  final InputDecoration? decoration;
  final ValueNotifier<String>? controller;
  final void Function(String item)? onChanged;
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final bool Function(String item, String str)? filterFn;
  final Future<List<String>> Function(String str)? findFn;
  final double? dropdownHeight;

  TextDropdown({
    Key? key,
    required this.options,
    this.decoration,
    this.onSaved,
    this.controller,
    this.onChanged,
    this.validator,
    this.findFn,
    this.filterFn,
    this.dropdownHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dropdown<String>(
      decoration: decoration,
      onSaved: onSaved,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      dropdownHeight: dropdownHeight,
      displayItemFn: (dynamic str) => Text(
        str ?? '',
        style: TextStyle(fontSize: 16),
      ),
      findFn: findFn ?? (dynamic str) async => options,
      filterFn: filterFn ??
          (dynamic item, str) =>
              item.toLowerCase().indexOf(str.toLowerCase()) >= 0,
      dropdownItemFn: (dynamic item, position, focushed, selected, onTap) =>
          ListTile(
        title: Text(
          item,
          style: TextStyle(color: selected ? Colors.blue : Colors.black87),
        ),
        tileColor: focushed ? Color.fromARGB(10, 0, 0, 0) : Colors.transparent,
        onTap: onTap,
      ),
    );
  }
}
