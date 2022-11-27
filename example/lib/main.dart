import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';

// Query DBus
// dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames
import 'package:path/path.dart' show Context, Style;

import 'package:dbus/dbus.dart';
import 'package:desktop_entry/desktop_entry.dart';
import 'package:flutter/material.dart';
import 'model/dbus-interface.dart';
import 'package:xdg_directories/xdg_directories.dart';

// https://dbus.freedesktop.org/doc/dbus-specification.html
void main(List<String> arguments) {
  print('Environment: ${Platform.environment}');
  print('Executable Arguments: ${Platform.executableArguments}');
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
      home: MyHomePage(arguments: launchArguments, title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({this.arguments = const <String>[], super.key, required this.title});

  final String title;
  final List<String> arguments;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DBusClient client;
  bool dbusServerStarted = false;

  static const dbusName = 'dev.markvideon.DesktopEntryExample';
  DevMarkvideonDesktopEntryExampleObject? myObject;

  final myKey = GlobalKey();
  List<bool> desktopInstallations = [];
  List<bool> dBusInstallations = [];
  Map<String, dynamic> latestPlatformData = {};

  final entry = DesktopFileContents(
    entry: DesktopEntry(
      type: SpecificationString('Application'),
      name: SpecificationLocaleString('FlutterDesktopEntryExample'),
      dBusActivatable: SpecificationBoolean(true),
      implements: SpecificationTypeList([
        SpecificationString('org.freedesktop.Application'),
        SpecificationString('dev.markvideon.DesktopEntryExample'),
      ]),
      exec: SpecificationString('${Platform.resolvedExecutable} %u'),
      mimeType: SpecificationTypeList([SpecificationString('x-scheme-handler/markvideon')])
    ),
    actions: <DesktopAction>[],
    unrecognisedGroups: <UnrecognisedGroup>[],
    trailingComments: <String>[]
  );

  final dbus = DBusFileContents(
    dBusServiceDefinition: DBusServiceDefinition(
      name: SpecificationInterfaceName('dev.markvideon.DesktopEntryExample'),
      exec: SpecificationFilePath(
        Uri.file('/home/mark/Documents/dartdesktopentry/example/build/linux/x64/debug/bundle/example')
      ),
    ),
    unrecognisedGroups: [],
    trailingComments: []
  );


  @override
  initState() {
    super.initState();
    myObject = DevMarkvideonDesktopEntryExampleObject(callback: (data) {
      setState(() {
        latestPlatformData = data;
      });
    });

    initDbus();
    initCheckInstallation();
  }

  initCheckInstallation() async {
    final desktopStatuses = [dataHome, ...dataDirs].map((e) async {
      try {
        final result = await File('${e.path}/applications/$dbusName.desktop').exists();
        return result;
      } catch (error) {
        print(error);
      }

      return false;
    }).toList(growable: false);
    final desktopResults = await Future.wait(desktopStatuses);

    final dbusStatuses = [dataHome, ...dataDirs].map((e) async {
      try {
        final result = await File('${e.path}/dbus-1/services/$dbusName.service').exists();
        return result;
      } catch (error) {
        print(error);
      }

      return false;
    }).toList(growable: false);
    final dBusResults = await Future.wait(dbusStatuses);

    setState(() {
      desktopInstallations = desktopResults;
      dBusInstallations = dBusResults;
    });
  }

  initDbus() async {
    client = DBusClient.session();

    final dbusId = await client.getId();
    print('DBus ID: $dbusId');
    final result = await client.requestName(dbusName);
    print('Result name: ' + result.name);
    await client.registerObject(myObject!);
  }

  @override
  dispose() {
    client.close();
    super.dispose();
  }

  Column buildRuntimeArgsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Runtime Arguments',
          style: Theme.of(context).textTheme.headline6,
        ),
        Row(
          children: [
            Expanded(
              child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Index')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    if (widget.arguments.isEmpty) DataRow(cells: [DataCell(Text('-')), DataCell(Text('No arguments provided.'))])
                    else ...widget.arguments.mapIndexed((index, e) => DataRow(cells: [DataCell(Text('$index')), DataCell(Text(e,))]))
                  ]
              ),
            )
          ],
        ),
      ],
    );
  }

  Column buildPlatformDataTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Data',
          style: Theme.of(context).textTheme.headline6,
        ),
        Row(
          children: [
            Expanded(
              child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Key')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    if (widget.arguments.isEmpty) DataRow(cells: [DataCell(Text('-')), DataCell(Text('No arguments provided.'))])
                    else ...latestPlatformData.keys.map((e) => DataRow(cells: [DataCell(Text('$e')), DataCell(Text('${latestPlatformData[e]}'))]))
                  ]
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column buildEnvironmentVarTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Environment Variables',
          style: Theme.of(context).textTheme.headline6,
        ),
        Row(
          children: [
            Expanded(
              child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Key')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    if (Platform.environment.isEmpty) DataRow(
                        cells: [
                          DataCell(Text('-')),
                          DataCell(Text('No arguments provided.'))
                        ])
                    else ...Platform.environment.keys.map((e) => DataRow(
                        cells: [
                          DataCell(Text('$e')),
                          DataCell(Text('${Platform.environment[e]}', softWrap: true))
                        ])
                    )
                  ]
              ),
            ),
          ],
        )
      ],
    );
  }

  Column buildInstallationTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Installation', style: Theme.of(context).textTheme.headline6,),
        Row(
          children: [
            Expanded(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Path')),
                  DataColumn(label: Text('Desktop File')),
                  DataColumn(label: Text('D-Bus Service File')),
                ],
                rows: [
                  ...[dataHome, ...dataDirs].mapIndexed((idx, e) {
                    return DataRow(
                        cells: [
                          DataCell(
                              Text('${e.path}')
                          ),
                          DataCell(
                            Row(children: [
                              InstallButton(
                                  canCall: desktopInstallations.length > idx ? !desktopInstallations[idx] : false,
                                  label: 'Install',
                                  onCall: () async {
                                    await installDesktopFileFromMemory(contents: entry, filenameNoExtension: dbusName, installationPath: e.path.endsWith('/') ? '${e.path}applications/' : '${e.path}/applications/');

                                    initCheckInstallation();
                                  }),
                              InstallButton(
                                canCall: desktopInstallations.length > idx ? desktopInstallations[idx] : false,
                                label: 'Uninstall',
                                onCall: () async {
                                  final file = File('${e.path}/applications/$dbusName.desktop');
                                  await uninstallDesktopFile(file);
                                  initCheckInstallation();
                                },
                              ),
                            ]),
                          ),
                          DataCell(
                              Row(children: [
                                InstallButton(
                                    canCall: dBusInstallations.length > idx ? !dBusInstallations[idx] : false,
                                    label: 'Install',
                                    onCall: () async {
                                      await installDbusServiceFromMemory(
                                          dBusServiceContents: dbus,
                                          filenameNoExtension: dbusName,
                                          installationPath: e.path.endsWith('/') ? '${e.path}dbus-1/services/' : '${e.path}/dbus-1/services/'
                                      );

                                      initCheckInstallation();
                                    }),
                                InstallButton(
                                  canCall: dBusInstallations.length > idx ? dBusInstallations[idx] : false,
                                  label: 'Uninstall',
                                  onCall: () async {
                                    final file = File('${e.path}/dbus-1/services/$dbusName.service');
                                    await uninstallDesktopFile(file);
                                  },
                                ),
                              ])
                          )
                        ]
                    );
                  }).toList(growable: false)
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                child: Column(
                  children: [
                    buildRuntimeArgsTable(),
                    const SizedBox(height: 30),
                    buildPlatformDataTable(),
                    const SizedBox(height: 30),
                    buildEnvironmentVarTable(),
                    const SizedBox(height: 30),
                    buildInstallationTable(),
                    const SizedBox(height: 124),
                  ],
                ),
              )
            ),
          ),
        ],
      ),
    );
  }
}

class InstallButton extends StatelessWidget {
  const InstallButton({super.key,
    required this.onCall,
    required this.canCall,
    required this.label
  });

  final Function onCall;
  final bool canCall;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canCall ? () async {
        try {
          await onCall.call();
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$error'),
          ));
        }
      } : null,
      child: Text(
        label
      ),
    );
  }
}