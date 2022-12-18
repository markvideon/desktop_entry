import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desktop_entry/src/model/mixin/comments_mixin.dart';
import 'package:desktop_entry/src/util/build_line.dart';
import 'package:path/path.dart' show Context, Style;
import 'package:path_provider/path_provider.dart';

import '../../util/parse_line.dart';
import '../../util/util.dart';
import '../group_name.dart';
import '../mixin/group_mixin.dart';
import '../mixin/shared_mixin.dart';
import '../mixin/unrecognised_entries_mixin.dart';
import '../mixin/unsupported_groups_mixin.dart';
import '../parse_mode.dart';
import '../specification_types.dart';
import '../unrecognised/unrecognised_entry.dart';
import '../unrecognised/unrecognised_group.dart';
import 'desktop_action.dart';
import 'desktop_entry.dart';

// There could be unsupported groups.
// There could be unsupported keys within supported groups.
// There could be comments.
  // - If a (trimmed) line starts with a comment character, treat the line as a comment.
  // Collect comments on a per-FIELD basis. E.g. map[GROUP][FIELD] = [...listOfComments];

class DesktopFileContents with TrailingCommentsMixin, UnrecognisedGroupsMixin {
  DesktopFileContents({
    required this.entry,
    required this.actions,
    required List<UnrecognisedGroup> unrecognisedGroups,
    List<String>? trailingComments
  }) {
    if (trailingComments is List<String>) {
      this.trailingComments = trailingComments;
    }

    this.unrecognisedGroups = unrecognisedGroups;
  }

  final DesktopEntry entry;
  final List<DesktopAction> actions;

  static const fieldEntry = 'entry';
  static const fieldActions = 'actions';

  // To
  static Future<File> toFile(String name, DesktopFileContents contents) async {
    // Create file
    final tempDir = await getTemporaryDirectory();
    final pathContext = Context(style: Style.posix);
    final absPath = pathContext.join(tempDir.path, '$name.desktop');
    final file = File(absPath);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    // Clear the file
    file.writeAsStringSync('');

    contents.entry.writeToFile(file, null);
    for (var action in contents.actions) {
      action.writeToFile(file, null);
    }

    for (var group in contents.unrecognisedGroups) {
      group.writeToFile(file, null);
    }

    for (var element in contents.trailingComments) {
      file.writeAsStringSync(buildComment(element), mode: FileMode.writeOnlyAppend);
    }

    return file;
  }

  static Map<String, dynamic> toData(DesktopFileContents contents) {
    return <String, dynamic> {
      fieldEntry: DesktopEntry.toData(contents.entry),
      fieldActions: contents.actions.map((e) => DesktopAction.toData(e)).toList(growable: false),
      UnrecognisedGroupsMixin.fieldUnrecognisedGroups: contents.unrecognisedGroups.map((e) => UnrecognisedGroup.toData(e)).toList(growable: false),
      TrailingCommentsMixin.fieldTrailingComments: List.of(contents.trailingComments)
    };
  }

  // From
  factory DesktopFileContents.fromMap(Map<String, dynamic> map) {
    return DesktopFileContents(
      entry: DesktopEntry.fromMap(map[fieldEntry]),
      actions: (map[fieldActions] as Iterable<Map<String, dynamic>>).map((e) => DesktopAction.fromMap(e)).toList(growable: false),
      unrecognisedGroups: (map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups] as Iterable<Map<String, dynamic>>).map((e) => UnrecognisedGroup.fromMap(e)).toList(growable: false),
      trailingComments: map[TrailingCommentsMixin.fieldTrailingComments] != null ? List.of(map[TrailingCommentsMixin.fieldTrailingComments]) : <String>[]
    );
  }

  factory DesktopFileContents.fromLines(Iterable<String> lines) {
    if (lines.isEmpty) {
      throw Exception('File appears to be empty.');
    }

    final map = <String, dynamic> {};
    map[fieldEntry] = <String, dynamic>{ UnrecognisedEntriesMixin.fieldEntries: <UnrecognisedEntry>[] };
    map[fieldActions] = <Map<String, dynamic>>[];
    map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups] = <Map<String, dynamic>>[];
    int activeActionIdx = -1;
    int activeUnrecognisedGroupIdx = -1;

    DesktopSpecificationParseMode parseMode = DesktopSpecificationParseMode.unrecognisedGroup;
    List<String> relevantComments = <String>[];

    for (var line in lines) {
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
          if (extractedGroupName.first == 'Desktop Entry') {
            parseMode = DesktopSpecificationParseMode.desktopEntry;
            final actionMap = <String, dynamic> {
              GroupMixin.fieldGroup: DesktopGroup('Desktop Entry', comments: relevantComments),
              UnrecognisedEntriesMixin.fieldEntries: <UnrecognisedEntry>[]
            };

            map[DesktopFileContents.fieldEntry] = actionMap;
          }
          // Desktop Action
          else if (extractedGroupName.first.startsWith('Desktop Action ')) {
            parseMode = DesktopSpecificationParseMode.desktopAction;

            // First match is `Desktop Action x`
            // Second match is `Desktop Action `
            // Third match is `x`
            final actionGroupName = DesktopGroup(
                DesktopAction.groupRegExp.firstMatch(extractedGroupName.first)!.group(1)!,
                comments: relevantComments);
            final actionMap = <String, dynamic> {
              GroupMixin.fieldGroup: actionGroupName,
              UnrecognisedEntriesMixin.fieldEntries: <UnrecognisedEntry>[]
            };
            map[fieldActions] = <Map<String, dynamic>>[...map[fieldActions], actionMap];
            activeActionIdx++;
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

          // todo: Handle the localised values
          switch (parseMode) {
            case DesktopSpecificationParseMode.desktopEntry:
              switch (possibleMapEntry.key) {
                case DesktopEntry.fieldType:
                  map[fieldEntry][DesktopEntry.fieldType] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldVersion:
                  map[fieldEntry][DesktopEntry.fieldVersion] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopSpecificationSharedMixin.fieldName:
                  handleLocalisableString(map[fieldEntry], DesktopSpecificationSharedMixin.fieldName, possibleMapEntry, relevantComments);
                  continue;
                case DesktopEntry.fieldGenericName:
                  handleLocalisableString(map[fieldEntry], DesktopEntry.fieldGenericName, possibleMapEntry, relevantComments);
                  continue;
                case DesktopEntry.fieldNoDisplay:
                  map[fieldEntry][DesktopEntry.fieldNoDisplay] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldComment:
                  handleLocalisableString(map[fieldEntry], DesktopEntry.fieldComment, possibleMapEntry, relevantComments);
                  continue;
                case DesktopSpecificationSharedMixin.fieldIcon:
                  map[fieldEntry][DesktopSpecificationSharedMixin.fieldIcon] = SpecificationIconString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldHidden:
                  map[fieldEntry][DesktopEntry.fieldHidden] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldOnlyShowIn:
                  map[fieldEntry][DesktopEntry.fieldOnlyShowIn] = SpecificationTypeList<SpecificationString>(
                      (possibleMapEntry.value as List).map((e) => SpecificationString(e)).toList(growable: false),
                      comments: relevantComments,
                  );
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldNotShowIn:
                  map[fieldEntry][DesktopEntry.fieldNotShowIn] = SpecificationTypeList<SpecificationString>(
                      (possibleMapEntry.value as List).map((e) => SpecificationString(e)).toList(growable: false),
                      comments: relevantComments,
                  );
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldDBusActivatable:
                  map[fieldEntry][DesktopEntry.fieldDBusActivatable] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldTryExec:
                  map[fieldEntry][DesktopEntry.fieldTryExec] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopSpecificationSharedMixin.fieldExec:
                  map[fieldEntry][DesktopSpecificationSharedMixin.fieldExec] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldPath:
                  map[fieldEntry][DesktopEntry.fieldPath] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldTerminal:
                  map[fieldEntry][DesktopEntry.fieldTerminal] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldActions:
                  map[fieldEntry][DesktopEntry.fieldActions] = SpecificationTypeList<SpecificationString>(
                    (possibleMapEntry.value as List).map((e) => SpecificationString(e)).toList(growable: false),
                    comments: relevantComments,
                  );
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldMimeType:
                  map[fieldEntry][DesktopEntry.fieldMimeType] = SpecificationTypeList<SpecificationString>(
                      (possibleMapEntry.value as List).map((e) => SpecificationString(e)).toList(growable: false),
                      comments: relevantComments,
                  );
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldCategories:
                  map[fieldEntry][DesktopEntry.fieldCategories] = SpecificationTypeList<SpecificationString>(
                    (possibleMapEntry.value as List).map((e) => SpecificationString(e)).toList(growable: false),
                    comments: relevantComments,
                  );
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldImplements:
                  map[fieldEntry][DesktopEntry.fieldImplements] = SpecificationTypeList<SpecificationString>(
                      (possibleMapEntry.value as List).map((e) => SpecificationString(e)).toList(growable: false),
                      comments: relevantComments,
                  );
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldKeywords:
                  handleLocalisableList<SpecificationLocaleString>(map[fieldEntry], DesktopEntry.fieldKeywords, possibleMapEntry, relevantComments, (value) => SpecificationLocaleString(value));
                  continue;
                case DesktopEntry.fieldStartupNotify:
                  map[fieldEntry][DesktopEntry.fieldStartupNotify] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldStartupWmClass:
                  map[fieldEntry][DesktopEntry.fieldStartupWmClass] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldUrl:
                  map[fieldEntry][DesktopEntry.fieldUrl] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldPrefersNonDefaultGpu:
                  map[fieldEntry][DesktopEntry.fieldPrefersNonDefaultGpu] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopEntry.fieldSingleMainWindow:
                  map[fieldEntry][DesktopEntry.fieldSingleMainWindow] = SpecificationBoolean(stringToBool(possibleMapEntry.value), comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                default:
                  final unrecognisedEntry = UnrecognisedEntry(
                    key: possibleMapEntry.key,
                    values: possibleMapEntry.value is List ? possibleMapEntry.value : [possibleMapEntry.value],
                    comments: relevantComments
                  );
                  (map[fieldEntry][UnrecognisedEntriesMixin.fieldEntries] as List).add(unrecognisedEntry);
                  relevantComments = <String>[];
                  continue;
              }
            case DesktopSpecificationParseMode.desktopAction:
              switch (possibleMapEntry.key) {
                case DesktopSpecificationSharedMixin.fieldExec:
                  (map[fieldActions] as List)[activeActionIdx][DesktopSpecificationSharedMixin.fieldExec] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopSpecificationSharedMixin.fieldIcon:
                  (map[fieldActions] as List)[activeActionIdx][DesktopSpecificationSharedMixin.fieldIcon] = SpecificationIconString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = <String>[];
                  continue;
                case DesktopSpecificationSharedMixin.fieldName:
                  handleLocalisableString(map[fieldActions][activeActionIdx], DesktopSpecificationSharedMixin.fieldName, possibleMapEntry, relevantComments);
                  continue;
                default:
                  final unrecognisedEntry = UnrecognisedEntry(
                    key: possibleMapEntry.key,
                    values: possibleMapEntry.value is List<String> ? possibleMapEntry.value : <String>[possibleMapEntry.value],
                    comments: relevantComments
                  );
                  ((map[fieldActions] as List)[activeActionIdx][UnrecognisedEntriesMixin.fieldEntries] as List<UnrecognisedEntry>).add(unrecognisedEntry);
                  relevantComments = <String>[];
                  continue;
              }
            case DesktopSpecificationParseMode.unrecognisedGroup:
              final unrecognisedEntry = UnrecognisedEntry(
                  key: possibleMapEntry.key,
                  values: possibleMapEntry.value is List<String> ? possibleMapEntry.value : <String>[possibleMapEntry.value],
                  comments: relevantComments
              );
              ((map[UnrecognisedGroupsMixin.fieldUnrecognisedGroups] as List).elementAt(activeUnrecognisedGroupIdx)[UnrecognisedEntriesMixin.fieldEntries] as List<UnrecognisedEntry>).add(unrecognisedEntry);
              relevantComments = <String>[];
              continue;
            case DesktopSpecificationParseMode.dbusService:
              // Do nothing.
              break;
          }
          //relevantComments = <String>[];
        }
      }
    }

    // Any outstanding lines are appended to the end
    map[TrailingCommentsMixin.fieldTrailingComments] = relevantComments;
    return DesktopFileContents.fromMap(map);
  }

  factory DesktopFileContents.fromFile(File file) {
    final lines = file.readAsLinesSync();
    return DesktopFileContents.fromLines(lines);
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopFileContents &&
      const ListEquality().equals(actions, other.actions) &&
      const ListEquality().equals(unrecognisedGroups, other.unrecognisedGroups) &&
      const ListEquality().equals(trailingComments, other.trailingComments) &&
      entry == other.entry;
  }

  @override
  int get hashCode => actions.hashCode ^
  unrecognisedGroups.hashCode ^
  trailingComments.hashCode ^
  entry.hashCode;
}