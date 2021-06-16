# dropdown_plus

Simple and easy to use Dropdown in forms with search, keyboard navigation, offiline data source, remote data source and easy customization.

## Getting Started

Simple Text Dropdown.

![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen1.png?raw=true)
![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen6.png?raw=true)

```
TextDropdownFormField(
    options: ["Male", "Female"],
    decoration: InputDecoration(
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
        labelText: "Gender"),
    dropdownHeight: 120,
),
```

## Install

##### packages.yaml
```
dropdown_plus: <lastest version>
```

## Customizable Example

![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen4.png?raw=true)
![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen3.png?raw=true)
![](https://github.com/crawlinknetworks/dropdown_plus/blob/master/screenshots/screen5.png?raw=true)

```

 final List<Map<String, dynamic>> _roles = [
    {"name": "Super Admin", "desc": "Having full access rights", "role": 1},
    {
      "name": "Admin",
      "desc": "Having full access rights of a Organization",
      "role": 2
    },
    {
      "name": "Manager",
      "desc": "Having Magenent access rights of a Organization",
      "role": 3
    },
    {
      "name": "Technician",
      "desc": "Having Technician Support access rights",
      "role": 4
    },
    {
      "name": "Customer Support",
      "desc": "Having Customer Support access rights",
      "role": 5
    },
    {"name": "User", "desc": "Having End User access rights", "role": 6},
  ];


// ...
// ...

DropdownFormField<Map<String, dynamic>>(
    onEmptyActionPressed: () async {},
    decoration: InputDecoration(
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
        labelText: "Access"),
    onSaved: (dynamic str) {},
    onChanged: (dynamic str) {},
    validator: (dynamic str) {},
    displayItemFn: (dynamic item) => Text(
    item['name'] ?? '',
    style: TextStyle(fontSize: 16),
    ),
    findFn: (dynamic str) async => _roles,
    filterFn: (dynamic item, str) =>
        item['name'].toLowerCase().indexOf(str.toLowerCase()) >= 0,
    dropdownItemFn: (dynamic item, position, focused,
            dynamic lastSelectedItem, onTap) =>
        ListTile(
    title: Text(item['name']),
    subtitle: Text(
        item['desc'] ?? '',
    ),
    tileColor:
        focused ? Color.fromARGB(20, 0, 0, 0) : Colors.transparent,
    onTap: onTap,
    ),
),
```

