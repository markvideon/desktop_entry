import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desktop_entry/desktop_entry.dart';
import 'package:desktop_entry/src/model/mixin/comments_mixin.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../util/build_line.dart';
import '../../util/parse_line.dart';
import '../mixin/group_mixin.dart';
import '../mixin/unrecognised_entries_mixin.dart';
import '../mixin/unsupported_groups_mixin.dart';
import '../parse_mode.dart';

// https://dbus.freedesktop.org/doc/dbus-specification.html
// https://bootlin.com/pub/conferences/2016/meetup/dbus/josserand-dbus-meetup.pdf
class DBusFileContents with TrailingCommentsMixin, UnrecognisedGroupsMixin {
  DBusFileContents({
    required this.dBusServiceDefinition,
    required List<UnrecognisedGroup> unrecognisedGroups,
    List<String>? trailingComments,
  }) {
    if (trailingComments is List<String>) {
      this.trailingComments = trailingComments;
    }
    this.unrecognisedGroups = unrecognisedGroups;
  }

  static const fieldDBusServiceDefinition = 'dBusServiceDefinition';
  DBusServiceDefinition dBusServiceDefinition;


  static Future<File> toFile(String name, DBusFileContents contents) async {
    // Create file
    final tempDir = await getTemporaryDirectory();
    final pathContext = Context(style: Style.posix);
    final absPath = pathContext.join(tempDir.path, '$name.service');
    final file = File(absPath);
    print('Trying to create file at: ${file.path}');
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    // Clear the file
    file.writeAsStringSync('');

    contents.dBusServiceDefinition.writeToFile(file, null);

    for (var group in contents.unrecognisedGroups) {
      group.writeToFile(file, null);
    }

    for (var element in contents.trailingComments) {
      file.writeAsStringSync(buildComment(element), mode: FileMode.writeOnlyAppend);
    }

    return file;
  }

  // From
  factory DBusFileContents.fromMap(Map<String, dynamic> map) {
    return DBusFileContents(
      dBusServiceDefinition: DBusServiceDefinition.fromMap(map[fieldDBusServiceDefinition]),
      unrecognisedGroups: (map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups] as Iterable<Map<String, dynamic>>).map((e) => UnrecognisedGroup.fromMap(e)).toList(growable: false),
      trailingComments: map[TrailingCommentsMixin.fieldTrailingComments] != null ? List.of(map[TrailingCommentsMixin.fieldTrailingComments]) : <String>[]
    );
  }

  factory DBusFileContents.fromFile(File file) {
    final lines = file.readAsLinesSync();
    return DBusFileContents.fromLines(lines);
  }

  factory DBusFileContents.fromLines(Iterable<String> lines) {
    if (lines.isEmpty) {
      throw Exception('File appears to be empty.');
    }

    final map = <String, dynamic> {
      DBusFileContents.fieldDBusServiceDefinition: <String, dynamic>{
        UnrecognisedEntriesMixin.fieldEntries: <UnrecognisedEntry>[]
      },
      UnrecognisedGroupsMixin.fieldUnrecognisedGroups: <Map<String, dynamic>>[]
    };

    int activeUnrecognisedGroupIdx = -1;

    DesktopSpecificationParseMode parseMode = DesktopSpecificationParseMode.unrecognisedGroup;

    List<String> relevantComments = <String>[];
    int i = 0;
    for (var line in lines) {
      i++;
      final effectiveLine = line.trim();
      final isCommentLine = effectiveLine.startsWith('#') || effectiveLine.isEmpty;
      final isGroupLine = (effectiveLine.startsWith('[') && effectiveLine.endsWith(']'));

      if (isCommentLine) {
        relevantComments.add(line);
      } else {
        if (isGroupLine) {
          final extractedGroupName = extractContents(effectiveLine, '[', ']');

          if (extractedGroupName.isEmpty) {
            throw Exception('Extracted Group Name attempt yielded empty list.');
          }

          // Desktop Entry
          if (extractedGroupName.first == 'D-BUS Service') {
            // No need to do anything
            parseMode = DesktopSpecificationParseMode.dbusService;
          }
          // Unrecognised Group
          else {
            parseMode = DesktopSpecificationParseMode.unrecognisedGroup;
            final unrecognisedGroupName = DesktopGroup(extractedGroupName.first, comments: relevantComments);
            final unrecognisedGroupMap = <String, dynamic>{
              GroupMixin.fieldGroup: unrecognisedGroupName,
              UnrecognisedEntriesMixin.fieldEntries: <UnrecognisedEntry>[]
            };
            map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups] = <Map<String, dynamic>>[...map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups], unrecognisedGroupMap];
            activeUnrecognisedGroupIdx++;
          }

          // Create new list for comments
          relevantComments = <String>[];
        } else {
          // (Key, value) or (comment) in a DesktopEntry, DesktopAction, or UnrecognisedGroup
          final possibleMapEntry = parseLine(line);
          if (possibleMapEntry == null) {
            relevantComments.add(line);
            continue;
          }

          switch (parseMode) {
            case DesktopSpecificationParseMode.dbusService:
              print('Key: ${possibleMapEntry.key}');
              switch (possibleMapEntry.key) {
                case DBusServiceDefinition.fieldName:
                  map[DBusFileContents.fieldDBusServiceDefinition][DBusServiceDefinition.fieldName] = SpecificationInterfaceName(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DBusServiceDefinition.fieldExec:
                  map[DBusFileContents.fieldDBusServiceDefinition][DBusServiceDefinition.fieldExec] = SpecificationFilePath(Uri.file(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DBusServiceDefinition.fieldUser:
                  map[DBusFileContents.fieldDBusServiceDefinition][DBusServiceDefinition.fieldUser] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DBusServiceDefinition.fieldSystemDService:
                  map[DBusFileContents.fieldDBusServiceDefinition][DBusServiceDefinition.fieldSystemDService] = SpecificationInterfaceName(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DBusServiceDefinition.fieldAssumedAppArmorLabel:
                  map[DBusFileContents.fieldDBusServiceDefinition][DBusServiceDefinition.fieldAssumedAppArmorLabel] = SpecificationFilePath(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                default:
                  final unrecognisedEntry = UnrecognisedEntry(
                    key: possibleMapEntry.key,
                    values: possibleMapEntry.value is List ? possibleMapEntry.value : [possibleMapEntry.value],
                    comments: relevantComments
                  );
                  (map[DBusFileContents.fieldDBusServiceDefinition][UnrecognisedEntriesMixin.fieldEntries] as List).add(unrecognisedEntry);
                  relevantComments = <String>[];
                  continue;
              }
              continue;
            case DesktopSpecificationParseMode.unrecognisedGroup:
              final unrecognisedEntry = UnrecognisedEntry(
                  key: possibleMapEntry.key,
                  values: possibleMapEntry.value is List<String> ? possibleMapEntry.value : <String>[possibleMapEntry.value],
                  comments: relevantComments
              );
              ((map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups] as List).elementAt(activeUnrecognisedGroupIdx)[UnrecognisedEntriesMixin.fieldEntries] as List<UnrecognisedEntry>).add(unrecognisedEntry);
              relevantComments = <String>[];
              continue;
            default:
              continue;
          }
        }
      }
    }

    // Any outstanding lines are appended to the end
    map[TrailingCommentsMixin.fieldTrailingComments] = relevantComments;
    return DBusFileContents.fromMap(map);
  }

  @override
  toString() {
    return 'DBusContents{ '
      '$fieldDBusServiceDefinition: $dBusServiceDefinition, '
      '${UnrecognisedGroupsMixin.fieldUnrecognisedGroups}: $unrecognisedGroups, '
      '${TrailingCommentsMixin.fieldTrailingComments}: $trailingComments'
    ' }';
  }

  @override
  bool operator ==(Object other) {
    return other is DBusFileContents &&
      dBusServiceDefinition == other.dBusServiceDefinition &&
      const ListEquality().equals(unrecognisedGroups, other.unrecognisedGroups) &&
      const ListEquality().equals(trailingComments, other.trailingComments);
  }

  @override
  int get hashCode => dBusServiceDefinition.hashCode ^
    unrecognisedGroups.hashCode ^
    trailingComments.hashCode;
}