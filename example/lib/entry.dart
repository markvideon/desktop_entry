import 'dart:io';

import 'package:desktop_entry/desktop_entry.dart';
import 'package:example/util.dart';

import 'const.dart';

Future<DesktopFileContents> launcher() async {
  final file = await shellScriptFilePath();

  return DesktopFileContents(
      entry: DesktopEntry(
          type: SpecificationString('Application'),
          name: SpecificationLocaleString('FlutterDesktopEntryExampleLauncher'),
          exec: SpecificationString('${file.path} %u'),
      mimeType: SpecificationTypeList([SpecificationString('x-scheme-handler/$schemeName')])
  ),
  actions: <DesktopAction>[],
  unrecognisedGroups: <UnrecognisedGroup>[],
  trailingComments: <String>[]
  );
}

final entry = DesktopFileContents(
    entry: DesktopEntry(
      type: SpecificationString('Application'),
      name: SpecificationLocaleString('FlutterDesktopEntryExample'),
      dBusActivatable: SpecificationBoolean(true),
      implements: SpecificationTypeList([
        SpecificationString(interfaceName),
      ]),
      exec: SpecificationString('${Platform.resolvedExecutable} %u'),
    ),
    actions: <DesktopAction>[],
    unrecognisedGroups: <UnrecognisedGroup>[],
    trailingComments: <String>[]
);

final dbus = DBusFileContents(
    dBusServiceDefinition: DBusServiceDefinition(
      name: SpecificationInterfaceName(dbusName),
      exec: SpecificationFilePath(
          Uri.file(Platform.executable)
      ),
    ),
    unrecognisedGroups: [],
    trailingComments: []
);