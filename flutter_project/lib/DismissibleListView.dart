import 'package:flutter/material.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // List of items to display
  List<String> _items = List.generate(10, (index) => 'รายการ ${index + 1}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dismissible ListView')),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key('${_items[index]}'),
            background: bgDismissible(),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                _items.removeAt(index); // Remove item from list
              });
            },
            child: cardItem(context, index),
          );
        },
      ),
    );
  }

  // Build card item widget
  Widget cardItem(BuildContext ctx, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      elevation: 10,
      shape: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: ListTile(
        leading: imageNetwork(index),
        title: Text(
          '${_items[index]}',
          style: TextStyle(fontSize: 18),
        ),
        subtitle: Text('&${Random().nextInt(1000)}'),
      ),
    );
  }

  // Widget for network image
  Widget imageNetwork(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          'https://picsum.photos/250/150?random=${index + 100}',
        ),
      ),
    );
  }

  // Background for dismissible widget
  Widget bgDismissible() {
    return Container(
      color: Colors.red,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
    );
  }
}
