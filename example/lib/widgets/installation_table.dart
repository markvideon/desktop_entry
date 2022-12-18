import 'dart:io';

import 'package:collection/collection.dart';
import 'package:example/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  @override
  initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      checkShellInstallation(toggleSetState: false);

      for (var e in [dataHome, ...dataDirs]) {
        checkDbusInstallation(e.path, toggleSetState: false);
        checkDesktopInstallation(e.path, toggleSetState: false);
        checkShellDesktopInstallation(e.path, toggleSetState: false);

        setState(() {
          //
        });
      }
    });
  }

  checkDesktopInstallation(String basePath, {bool toggleSetState = true}) {
    desktopInstallations[basePath] = desktopEntryFilePath(basePath, dbusName).existsSync();
    if (toggleSetState) {
      setState(() {
      //
      });
    }
  }

  checkDbusInstallation(String basePath, {bool toggleSetState = true}) {
    dBusInstallations[basePath] = dbusFilePath(basePath, dbusName).existsSync();
    if (toggleSetState) {
      setState(() {
        //
      });
    }
  }

  checkShellInstallation({bool toggleSetState = true}) async {
    final shellFile = await shellScriptFilePath();
    shellInstallation[shellFile.path] = shellFile.existsSync();
    if (toggleSetState) {
      setState(() {
      //
      });
    }
  }

  checkShellDesktopInstallation(String basePath, {bool toggleSetState = true}) {
    final exists = desktopEntryFilePath(basePath, shellScriptDesktopName).existsSync();
    shellDesktopInstallation[basePath] = exists;

    if (toggleSetState) {
      setState(() {
        //
      });
    }
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
                                    installAppDesktopFile(e.path).then((_) {
                                      checkDesktopInstallation(e.path);
                                    });
                                  }),
                              InstallButton(
                                canCall: desktopInstallations[e.path] == true,
                                label: 'Uninstall',
                                onCall: () async {
                                  uninstallAppDesktopFile(e.path).then((_) {
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
                                      installAppDbusServiceFile(e.path).then((_) {
                                        checkDbusInstallation(e.path);
                                      });
                                    }),
                                InstallButton(
                                  canCall: dBusInstallations[e.path] == true,
                                  label: 'Uninstall',
                                  onCall: () async {
                                    uninstallAppDbusServiceFile(e.path).then((_) {
                                      checkDbusInstallation(e.path);
                                    });
                                  },
                                ),
                              ])
                          ),
                          DataCell(
                            FutureBuilder(
                              future: shellScriptFilePath(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Row(
                                    children: [
                                      InstallButton(
                                          canCall: shellInstallation[snapshot.data!.path] == false,
                                          label: 'Install',
                                          onCall: () async {
                                            installShellScript(dbusName: dbusName, objectPath: objectPath).then((_) {
                                              checkShellInstallation();
                                            });
                                          }),
                                      InstallButton(
                                        canCall: shellInstallation[snapshot.data!.path] == true,
                                        label: 'Uninstall',
                                        onCall: () async {
                                          uninstallShellScript().then((_) {
                                            checkShellInstallation();
                                          });
                                        },
                                      ),
                                  ]);
                                }
                                return Row(children: [
                                  InstallButton(
                                      canCall: false,
                                      label: 'Install',
                                      onCall: () => null),
                                  InstallButton(
                                    canCall: false,
                                    label: 'Uninstall',
                                    onCall: () => null,
                                  ),
                                ]);
                              }
                            ),
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
                                  uninstallShellScriptDesktopEntry(e.path).then((_) {
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