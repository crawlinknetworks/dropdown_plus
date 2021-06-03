import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropdown Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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
            TextDropdown(
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
          ],
        ),
      ),
    );
  }
}
