import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropdown Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<UserRole> _roles = [
    UserRole(
      "Super Admin",
      "Having full access rights",
      1,
    ),
    UserRole(
      "Admin",
      "Having full access rights of a Organization",
      2,
    ),
    UserRole(
      "Manager",
      "Having Management access rights of a Organization",
      3,
    ),
    UserRole(
      "Technician",
      "Having Technician Support access rights",
      4,
    ),
    UserRole(
      "Customer Support",
      "Having Customer Support access rights",
      5,
    ),
    UserRole(
      "User",
      "Having End User access rights",
      6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dropdown Plus Demo'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextDropdownFormField(
              options: ["Male", "Female"],
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  labelText: "Gender"),
              dropdownHeight: 120,
            ),
            SizedBox(
              height: 16,
            ),
            DropdownFormField<UserRole>(
              onEmptyActionPressed: () async {},
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  labelText: "Access"),
              onSaved: (role) {},
              onChanged: (role) {},
              validator: (role) {
                return null;
              },
              displayItemFn: (item) => Text(
                item?.name ?? '',
                style: TextStyle(fontSize: 16),
              ),
              findFn: (str) async => _roles,
              selectedFn: (item1, item2) {
                if (item1 != null && item2 != null) {
                  return item1.name == item2.name;
                }
                return false;
              },
              filterFn: (item, str) =>
                  item.name.toLowerCase().indexOf(str.toLowerCase()) >= 0,
              dropdownItemFn: (item, int position, bool focused, bool selected,
                      Function() onTap) =>
                  ListTile(
                title: Text(item.name),
                subtitle: Text(item.description),
                tileColor:
                    focused ? Color.fromARGB(20, 0, 0, 0) : Colors.transparent,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserRole {
  final String name;
  final String description;
  final int number;

  UserRole(this.name, this.description, this.number);
}
