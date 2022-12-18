import 'app.dart';
import 'package:example/service/dbus_service.dart';
import 'package:flutter/material.dart';

void main(List<String> arguments) {
  // It is highly recommended to perform requests to the DBus daemon as close to
  // initialisation as possible.
  DbusService();
  runApp(MyApp(arguments));
}