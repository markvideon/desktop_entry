import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';

import 'package:path/path.dart' show Context, Style;

import 'package:dbus/dbus.dart';
import 'package:desktop_entry/desktop_entry.dart';
import 'package:flutter/material.dart';
import 'model/dbus-interface2.dart';
import 'package:xdg_directories/xdg_directories.dart';

void main(List<String> arguments) {
  runApp(MyApp(arguments));
}

class MyApp extends StatelessWidget {
  const MyApp(this.launchArguments, {super.key});

  final List<String> launchArguments;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DBusClient client;
  bool dbusServerStarted = false;

  static const dbusName = 'dev.markvideon.DesktopEntryExample';
  DevMarkvideonDesktopEntryExampleObject? myObject;
  final myKey = GlobalKey();
  List<bool> installationStatuses = [];

  final entry = DesktopContents(
    entry: DesktopEntry(
      type: SpecificationString('Application'),
      name: SpecificationLocaleString('FlutterDesktopEntryExample'),
      dBusActivatable: SpecificationBoolean(true),
      implements: SpecificationTypeList([SpecificationString('dev.markvideon.DesktopEntryExample')]),
      exec: SpecificationString('${Platform.resolvedExecutable} %u'),
      mimeType: SpecificationTypeList([SpecificationString('x-scheme-handler/markvideon;')])
    ),
    actions: <DesktopAction>[],
    unrecognisedGroups: <UnrecognisedGroup>[],
    trailingComments: <String>[]
  );

  @override
  initState() {
    super.initState();
    print(Platform.resolvedExecutable);
    myObject = DevMarkvideonDesktopEntryExampleObject(callback: () {
      print('I do be calling back.');
      setState(() {
        // ;)
      });
    });

    initDbus();
    initCheckInstallation();
  }

  initCheckInstallation() async {
    final statuses = dataDirs.map((e) async {
      try {
        final result = await File('${e.path}/applications/$dbusName.desktop').exists();
        return result;
      } catch (error) {
        print(error);
      }

      return false;
    }).toList(growable: false);
    final results = await Future.wait(statuses);

    setState(() {
      installationStatuses = results;
    });
  }

  initDbus() async {
    client = DBusClient.session();

    await client.requestName(dbusName);
    await client.registerObject(myObject!);
  }

  @override
  dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: myKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FlexColumnWidth(),
                  2: IntrinsicColumnWidth(),
                },
                children: [
                  const TableRow(
                    children: [
                      Center(child: Text('Path')),
                      Text('Installed'),
                      Text('Action')
                    ]
                  ),
                  ...dataDirs.mapIndexed((idx, e) {
                  return TableRow(
                    children: [
                      Text('${e.path}'),
                      installationStatuses.length > idx ?
                        Icon(installationStatuses[idx] ? Icons.check : Icons.cancel)
                        : CircularProgressIndicator(),
                      ElevatedButton(
                        onPressed: installationStatuses.length > idx ? () async {
                          // todo:

                          try {
                            if (!installationStatuses[idx]) {
                              await installFromMemory(contents: entry, filename: '$dbusName.desktop', installationPath: e.path);
                            } else {
                              final file = File('${e.path}/applications/$dbusName.desktop');
                              await uninstall(file);
                            }
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('$error'),
                            ));
                          }

                          initCheckInstallation();
                        } : null,
                        child: Text(
                            installationStatuses.length > idx ?
                          (installationStatuses[idx] ?
                            'Uninstall' :
                            'Install') : 'N/A'
                        ),
                      )
                    ]
                  );
                }).toList(growable: false)],
              ),
            ),
          ],
        )
      ),
    );
  }
}
