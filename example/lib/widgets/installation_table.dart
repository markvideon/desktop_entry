import 'dart:io';

import 'package:collection/collection.dart';
import 'package:example/const.dart';
import 'package:flutter/material.dart';
import 'package:xdg_directories/xdg_directories.dart';

import '../util.dart';
import 'install_button.dart';

class InstallationTable extends StatefulWidget {
  const InstallationTable({super.key});

  @override
  State<StatefulWidget> createState() => _InstallationTableState();
}

class _InstallationTableState extends State<InstallationTable> {
  Map<String, bool> desktopInstallations = {};
  Map<String, bool> dBusInstallations = {};
  Map<String, bool> shellInstallation = {};
  Map<String, bool> shellDesktopInstallation = {};

  checkDesktopInstallation(String basePath) {
    final exists = desktopEntryFilePath(basePath, dbusName).existsSync();
    setState(() {
      desktopInstallations[basePath] = exists;
    });
  }

  checkDbusInstallation(String basePath) {
    final exists = dbusFilePath(basePath, dbusName).existsSync();
    setState(() {
      dBusInstallations[basePath] = exists;
    });
  }

  checkShellInstallation() {
    final shellFile = shellScriptFilePath();
    final exists = shellScriptFilePath().existsSync();
    setState(() {
      shellInstallation[shellFile.path] = exists;
    });
  }

  checkShellDesktopInstallation(String basePath) {
    final exists = desktopEntryFilePath(basePath, shellScriptDesktopName).existsSync();
    setState(() {
      shellDesktopInstallation[basePath] = exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Installation', style: Theme.of(context).textTheme.headline6),
        Row(
          children: [
            Expanded(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Path')),
                  DataColumn(label: Text('App Desktop File')),
                  DataColumn(label: Text('App D-Bus Service File')),
                  DataColumn(label: Text('Shell Script')),
                  DataColumn(label: Text('Shell Script Desktop File')),
                ],
                rows: [
                  ...[dataHome, ...dataDirs].mapIndexed((idx, e) {
                    return DataRow(
                        cells: [
                          DataCell(
                              Text(e.path)
                          ),
                          DataCell(
                            Row(children: [
                              InstallButton(
                                  canCall: desktopInstallations[e.path] == false,
                                  label: 'Install',
                                  onCall: () async {
                                    installAppDesktopFile(e).then((_) {
                                      checkDesktopInstallation(e.path);
                                    });
                                  }),
                              InstallButton(
                                canCall: desktopInstallations[e.path] == true,
                                label: 'Uninstall',
                                onCall: () async {
                                  uninstallAppDesktopFile(e).then((_) {
                                    checkDesktopInstallation(e.path);
                                  });
                                },
                              ),
                            ]),
                          ),
                          DataCell(
                              Row(children: [
                                InstallButton(
                                    canCall: dBusInstallations[e.path] == false,
                                    label: 'Install',
                                    onCall: () async {
                                      installAppDbusServiceFile(e).then((_) {
                                        checkDbusInstallation(e.path);
                                      });
                                    }),
                                InstallButton(
                                  canCall: dBusInstallations[e.path] == true,
                                  label: 'Uninstall',
                                  onCall: () async {
                                    uninstallAppDbusServiceFile(e).then((_) {
                                      checkDbusInstallation(e.path);
                                    });
                                  },
                                ),
                              ])
                          ),
                          DataCell(
                              Row(children: [
                                InstallButton(
                                    canCall: shellInstallation[e.path] == false,
                                    label: 'Install',
                                    onCall: () async {
                                      installShellScript(dbusName: dbusName, objectPath: objectPath).then((_) {
                                        checkShellInstallation();
                                      });
                                    }),
                                InstallButton(
                                  canCall: shellInstallation[e.path] == true,
                                  label: 'Uninstall',
                                  onCall: () async {
                                    uninstallShellScript().then((_) {
                                      checkShellInstallation();
                                    });
                                  },
                                ),
                              ])
                          ),
                          DataCell(
                            Row(children: [
                              InstallButton(
                                  canCall: shellDesktopInstallation[e.path] == false,
                                  label: 'Install',
                                  onCall: () async {
                                    installShellScriptDesktopEntry(e.path).then((_) {
                                      checkShellDesktopInstallation(e.path);
                                    });
                                  }),
                              InstallButton(
                                canCall: shellDesktopInstallation[e.path] == true,
                                label: 'Uninstall',
                                onCall: () async {
                                  uninstallShellScriptDesktopEntry(e).then((_) {
                                    checkShellDesktopInstallation(e.path);
                                  });
                                },
                              ),
                            ])
                          ),
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
}