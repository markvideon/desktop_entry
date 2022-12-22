import 'package:example/pages/home_page.dart';
import 'package:example/service/dbus_service.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  MyApp(this.launchArguments, {super.key});

  final List<String> launchArguments;
  final DbusService dbusHandler = DbusService();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
          arguments: launchArguments, title: 'Flutter Demo Home Page'),
    );
  }
}
