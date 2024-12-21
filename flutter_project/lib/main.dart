import 'package:flutter/material.dart';
import 'package:flutter_project/Homepage.dart';
import 'package:flutter_project/login.dart';
// import 'package:flutter_project/login.dart';
// import 'package:flutter_project/register.dart';
// import 'package:flutter_project/welcome.dart';
// import 'package:flutter_project/DismissibleListView.dart';
// import 'package:flutter_project/welcome.dart';

void main() => runApp(App06DismissibleListView());

class App06DismissibleListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: false),
      home: Login(),
    );
  }
}
