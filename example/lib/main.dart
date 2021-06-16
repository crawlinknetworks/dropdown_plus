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
              dropdownHeight: 96,
            ),
            SizedBox(
              height: 16,
            ),
            DropdownFormField<String>(
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
                  (dynamic item, position, focused, selected, onTap) =>
                      ListTile(
                title: Text(
                  item,
                  style:
                      TextStyle(color: selected ? Colors.blue : Colors.black87),
                ),
                tileColor:
                    focused ? Color.fromARGB(10, 0, 0, 0) : Colors.transparent,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
