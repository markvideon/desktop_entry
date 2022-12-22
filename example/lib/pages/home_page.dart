import 'package:example/widgets/dbus_table.dart';
import 'package:example/widgets/environment_table.dart';
import 'package:example/widgets/installation_table.dart';
import 'package:example/widgets/runtime_args_table.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {this.arguments = const <String>[], super.key, required this.title});

  final String title;
  final List<String> arguments;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final myKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: myKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
                child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  RuntimeArgsTable(arguments: widget.arguments),
                  const SizedBox(height: 30),
                  const DBusTable(),
                  const SizedBox(height: 30),
                  const EnvironmentTable(),
                  const SizedBox(height: 30),
                  const InstallationTable(),
                  const SizedBox(height: 124),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }
}
