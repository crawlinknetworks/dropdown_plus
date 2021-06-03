# dropdown_plus

Simple and easy to use Dropdown in forms with search, keyboard navigation, offiline data source, remote data source and easy customization.

## Getting Started

Simple Text Dropdown.

![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen1.png?raw=true)

```
TextDropdown(
    options: ["Male", "Female"],
    decoration: InputDecoration(
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
        labelText: "Gender"),
    dropdownHeight: 96,
),
```

## Install

##### packages.yaml
```
dropdown_plus: <lastest version>
```

## Customizable Example

![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen2.png?raw=true)

```
Dropdown<String>(
    decoration: InputDecoration(
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
        labelText: "Designation"),
    onSaved: (dynamic str) {},
    onChanged: (dynamic str) {},
    validator: (dynamic str) {},
    displayItemFn: (dynamic str) => Text(
    str ?? '',
    style: TextStyle(fontSize: 16),
    ),
    findFn: (dynamic str) async => [
    "Admin",
    "Branch Manager",
    "Area Manager",
    "Team Lead",
    "Developer",
    "Executive",
    "Helper"
    ],
    filterFn: (dynamic item, str) =>
        item.toLowerCase().indexOf(str.toLowerCase()) >= 0,
    dropdownItemFn:
        (dynamic item, position, focushed, selected, onTap) =>
            ListTile(
    title: Text(
        item,
        style:
            TextStyle(color: selected ? Colors.blue : Colors.black87),
    ),
    tileColor:
        focushed ? Color.fromARGB(10, 0, 0, 0) : Colors.transparent,
    onTap: onTap,
    ),
),
```

