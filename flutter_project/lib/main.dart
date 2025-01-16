import 'package:flutter/material.dart';
import 'package:flutter_project/Outfoproduct/outfoproduct.dart';

void main() => runApp(App06DismissibleListView());

class App06DismissibleListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: false),
      home: ManageProductPage(),
    );
  }
}
