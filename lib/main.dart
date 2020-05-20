import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/models/item.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  var items = new List<Item>();

  HomePage() {
    items = [];
  }

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var newTaskController = TextEditingController();

  _HomePageState() {
    load();
  }

  void add() {
    if (newTaskController.text.isEmpty) return;
    setState(() {
      widget.items.add(Item(
        id: Uuid().v4(),
        title: newTaskController.text,
        done: false,
      ));
      newTaskController.clear();
      save();
    });
  }

  void remove(int index) {
    saveOnTrash(index);
    setState(() {
      widget.items.removeAt(index);
      save();
    });
  }

  Future load() async {
    var preferences = await SharedPreferences.getInstance();
    var data = preferences.getString('data');
    if (data != null) {
      Iterable decoded = jsonDecode(data);
      List<Item> result = decoded.map((o) => Item.fromJson((o))).toList();
      setState(() {
        widget.items = result;
      });
    }
  }

  save() async {
    var json = jsonEncode(widget.items);
    var preferences = await SharedPreferences.getInstance();
    await preferences.setString('data', json);
  }

  saveOnTrash(index) async {
    var json = jsonEncode(widget.items[index]);
    var preferences = await SharedPreferences.getInstance();
    await preferences.setString('data-trash', json);
  }

  undo() async {
    var preferences = await SharedPreferences.getInstance();
    var data = preferences.getString('data-trash');
    if (data != null) {
      Map decoded = jsonDecode(data);
      Item result = Item.fromJson(decoded);
      setState(() {
        widget.items.add(result);
        save();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: newTaskController,
          keyboardType: TextInputType.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            labelText: "Nova tarefa",
            labelStyle: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.items[index];
          return Dismissible(
            key: Key(item.id),
            child: CheckboxListTile(
              title: Text(item.title),
              value: item.done,
              onChanged: (value) {
                setState(() {
                  item.done = value;
                  save();
                });
              },
            ),
            background: Container(
              alignment: AlignmentDirectional.centerStart,
              color: Colors.blue.withOpacity(0.7),
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            secondaryBackground: Container(
              alignment: AlignmentDirectional.centerEnd,
              color: Colors.red.withOpacity(0.7),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: Icon(
                  Icons.cancel,
                  color: Colors.white,
                ),
              ),
            ),
            onDismissed: (direction) {
              print(direction);
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text("'${item.title}' foi excluído"),
                  action: SnackBarAction(
                    label: "Undo",
                    textColor: Colors.yellow,
                    onPressed: () {
                      undo();
                    },
                  ),
                ),
              );
              remove(index);
            },
            // confirmDismiss: (direction) async {
            //   if (direction == DismissDirection.startToEnd) {
            //     /// edit item
            //     return false;
            //   } else if (direction == DismissDirection.endToStart) {
            //     /// delete
            //     return true;
            //   }
            // },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: Icon(Icons.add),
      ),
    );
  }
}
