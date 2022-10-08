import 'dart:io';

import 'mixin/shared_mixin.dart';
import 'unrecognised/unrecognised_entry.dart';
import '../util/parse_line.dart';

import 'group_name.dart';
import 'mixin/group_mixin.dart';
import 'mixin/unrecognised_entries_mixin.dart';
import 'specification_types.dart';
import 'unrecognised/unrecognised_group.dart';
import '../util/util.dart';
import 'package:path/path.dart' show Context, Style;
import 'package:path_provider/path_provider.dart';

import 'desktop_action.dart';
import 'desktop_entry.dart';
import 'parse_mode.dart';

// There could be unsupported groups.
// There could be unsupported keys within supported groups.
// There could be comments.
  // - If a (trimmed) line starts with a comment character, treat the line as a comment.
  // Collect comments on a per-FIELD basis. E.g. map[GROUP][FIELD] = [...listOfComments];

class DesktopContents {
  DesktopContents({
    required this.entry,
    required this.actions,
    required this.unrecognisedGroups,
    required this.trailingComments
  });

  final DesktopEntry entry;
  final List<DesktopAction> actions;
  final List<UnrecognisedGroup> unrecognisedGroups;
  final List<String> trailingComments;


  static const fieldEntry = 'entry';
  static const fieldActions = 'actions';
  static const fieldUnrecognisedGroups = 'unrecognisedGroups';
  static const fieldTrailingComments = 'trailingComments';

  // To
  static Future<File> toFile(String name, DesktopContents contents) async {
    // Create file
    final tempDir = await getTemporaryDirectory();
    final pathContext = Context(style: Style.posix);
    final absPath = pathContext.join(tempDir.path, '$name.desktop');
    final file = File(absPath);

    contents.entry.writeToFile(file);

    for (var action in contents.actions) {
      action.writeToFile(file);
    }

    for (var group in contents.unrecognisedGroups) {
      group.writeToFile(file);
    }

    return file;
  }

  static Map<String, dynamic> toData(DesktopContents contents) {
    return <String, dynamic> {
      fieldEntry: DesktopEntry.toData(contents.entry),
      if (contents.actions.isNotEmpty) fieldActions: contents.actions.map((e) => DesktopAction.toData(e)).toList(growable: false),
      if (contents.unrecognisedGroups.isNotEmpty) fieldUnrecognisedGroups: contents.unrecognisedGroups.map((e) => UnrecognisedGroup.toData(e)).toList(growable: false),
      if (contents.trailingComments.isNotEmpty) fieldTrailingComments: List.of(contents.trailingComments)
    };
  }

  // From
  factory DesktopContents.fromMap(Map<String, dynamic> map) {
    return DesktopContents(
      entry: DesktopEntry.fromMap(map[fieldEntry]),
      actions: (map[fieldActions] as Iterable).map((e) => DesktopAction.fromMap(e)).toList(growable: false),
      unrecognisedGroups: (map[fieldUnrecognisedGroups] as Iterable).map((e) => UnrecognisedGroup.fromMap(e)).toList(growable: false),
      trailingComments: map[fieldTrailingComments] != null ? List.of(map[fieldTrailingComments]) : <String>[]
    );
  }

  factory DesktopContents.fromLines(Iterable<String> lines) {
    if (lines.isEmpty) {
      throw Exception('File appears to be empty.');
    }

    final map = <String, dynamic> {};
    map[fieldEntry] = <String, dynamic>{ UnrecognisedEntriesMixin.fieldEntries: [] };
    map[fieldActions] = <Map<String, dynamic>>[];
    map[fieldUnrecognisedGroups] = <Map<String, dynamic>>[];
    int activeActionIdx = -1;
    int activeUnrecognisedGroupIdx = -1;

    DesktopSpecificationParseMode parseMode = DesktopSpecificationParseMode.unrecognisedGroup;
    List<String> relevantComments = [];

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
              UnrecognisedEntriesMixin.fieldEntries: []
            };

            map[DesktopContents.fieldEntry] = actionMap;
            break;
          } 
          // Desktop Action
          else if (extractedGroupName.first.startsWith('Desktop Action ')) {
            parseMode = DesktopSpecificationParseMode.desktopAction;

            // First match is `Desktop Action x`
            // Second match is `Desktop Action `
            // Third match is `x`
            final actionGroupName = DesktopGroup(
                DesktopAction.groupRegExp.firstMatch(extractedGroupName.first)!.group(2)!,
                comments: relevantComments);
            final actionMap = <String, dynamic> {
              GroupMixin.fieldGroup: actionGroupName,
              UnrecognisedEntriesMixin.fieldEntries: []
            };
            map[fieldActions] = [...map[fieldActions], actionMap];
            activeActionIdx++;
          } 
          // Unrecognised Group
          else {
            parseMode = DesktopSpecificationParseMode.unrecognisedGroup;

            final unrecognisedGroupName = DesktopGroup(extractedGroupName.first, comments: relevantComments);
            final unrecognisedGroupMap = <String, dynamic>{
              GroupMixin.fieldGroup: unrecognisedGroupName,
              UnrecognisedEntriesMixin.fieldEntries: []
            };
            map[fieldUnrecognisedGroups] = [...map[fieldUnrecognisedGroups], unrecognisedGroupMap];
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
          // todo: Handle comments on a per-field basis
          switch (parseMode) {
            case DesktopSpecificationParseMode.desktopEntry:
              switch (possibleMapEntry.key) {
                case DesktopEntry.fieldType:
                  map[fieldEntry][DesktopEntry.fieldType] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldVersion:
                  map[fieldEntry][DesktopEntry.fieldVersion] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopSpecificationSharedMixin.fieldName:
                  map[fieldEntry][DesktopSpecificationSharedMixin.fieldName] = SpecificationLocaleString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldGenericName:
                  map[fieldEntry][DesktopEntry.fieldGenericName] = SpecificationLocaleString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldNoDisplay:
                  map[fieldEntry][DesktopEntry.fieldNoDisplay] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldComment:
                  map[fieldEntry][DesktopEntry.fieldComment] = SpecificationLocaleString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopSpecificationSharedMixin.fieldIcon:
                  map[fieldEntry][DesktopSpecificationSharedMixin.fieldIcon] = SpecificationIconString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldHidden:
                  map[fieldEntry][DesktopEntry.fieldHidden] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                // todo: Consider converting to a list
                case DesktopEntry.fieldOnlyShowIn:

                  map[fieldEntry][DesktopEntry.fieldOnlyShowIn] = LocalisableSpecificationTypeList<SpecificationString>(
                      possibleMapEntry.value,
                      comments: relevantComments,
                      elementConstructor: () => SpecificationString('')
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldNotShowIn:
                  map[fieldEntry][DesktopEntry.fieldNotShowIn] = LocalisableSpecificationTypeList<SpecificationString>(
                      possibleMapEntry.value,
                      comments: relevantComments,
                      elementConstructor: () => SpecificationString('')
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldDBusActivatable:
                  map[fieldEntry][DesktopEntry.fieldDBusActivatable] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldTryExec:
                  map[fieldEntry][DesktopEntry.fieldTryExec] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopSpecificationSharedMixin.fieldExec:
                  map[fieldEntry][DesktopSpecificationSharedMixin.fieldExec] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldPath:
                  map[fieldEntry][DesktopEntry.fieldPath] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldTerminal:
                  map[fieldEntry][DesktopEntry.fieldTerminal] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldActions:
                  map[fieldEntry][DesktopEntry.fieldActions] = LocalisableSpecificationTypeList<SpecificationString>(
                    possibleMapEntry.value,
                    comments: relevantComments,
                    elementConstructor: () => SpecificationString('')
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldMimeType:
                  map[fieldEntry][DesktopEntry.fieldMimeType] = LocalisableSpecificationTypeList<SpecificationString>(
                      possibleMapEntry.value,
                      comments: relevantComments,
                      elementConstructor: () => SpecificationString('')
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldCategories:
                  map[fieldEntry][DesktopEntry.fieldCategories] = LocalisableSpecificationTypeList<SpecificationString>(
                    possibleMapEntry.value,
                    comments: relevantComments,
                    elementConstructor: () => SpecificationString('')
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldImplements:
                  map[fieldEntry][DesktopEntry.fieldImplements] = LocalisableSpecificationTypeList<SpecificationString>(
                      possibleMapEntry.value,
                      comments: relevantComments,
                      elementConstructor: () => SpecificationString('')
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldKeywords:
                  map[fieldEntry][DesktopEntry.fieldKeywords] = LocalisableSpecificationTypeList<SpecificationLocaleString>(
                    (possibleMapEntry.value as Iterable).map((e) => SpecificationLocaleString(e)).toList(growable: false),
                    elementConstructor: () => SpecificationLocaleString(''),
                    comments: relevantComments
                  );
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldStartupNotify:
                  map[fieldEntry][DesktopEntry.fieldStartupNotify] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldStartupWmClass:
                  map[fieldEntry][DesktopEntry.fieldStartupWmClass] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldUrl:
                  map[fieldEntry][DesktopEntry.fieldUrl] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldPrefersNonDefaultGpu:
                  map[fieldEntry][DesktopEntry.fieldPrefersNonDefaultGpu] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopEntry.fieldSingleMainWindow:
                  map[fieldEntry][DesktopEntry.fieldSingleMainWindow] = SpecificationBoolean(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                default:
                  final unrecognisedEntry = UnrecognisedEntry(
                    key: possibleMapEntry.key,
                    values: possibleMapEntry.value is List ? possibleMapEntry.value : [possibleMapEntry.value.first],
                    comments: relevantComments
                  );
                  (map[fieldEntry][UnrecognisedEntriesMixin.fieldEntries] as List).add(unrecognisedEntry);
                  relevantComments = [];
                  break;
              }
              break;
            // todo:
            case DesktopSpecificationParseMode.desktopAction:
              switch (possibleMapEntry.key) {
                case DesktopSpecificationSharedMixin.fieldExec:
                  (map[fieldActions] as List)[activeActionIdx] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopSpecificationSharedMixin.fieldIcon:
                  (map[fieldActions] as List)[activeActionIdx] = SpecificationIconString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                case DesktopSpecificationSharedMixin.fieldName:
                  (map[fieldActions] as List)[activeActionIdx] = SpecificationString(possibleMapEntry.value, comments: relevantComments);
                  relevantComments = [];
                  break;
                default:
                  final unrecognisedEntry = UnrecognisedEntry(
                    key: possibleMapEntry.key,
                    values: possibleMapEntry.value is List ? possibleMapEntry.value : [possibleMapEntry.value.first],
                    comments: relevantComments
                  );
                  ((map[fieldActions] as List)[activeActionIdx][UnrecognisedEntriesMixin.fieldEntries] as List).add(unrecognisedEntry);
                  break;
              }
              break;
            case DesktopSpecificationParseMode.unrecognisedGroup:
              final unrecognisedEntry = UnrecognisedEntry(
                  key: possibleMapEntry.key,
                  values: possibleMapEntry.value is List ? possibleMapEntry.value : [possibleMapEntry.value.first],
                  comments: relevantComments
              );
              ((map[fieldUnrecognisedGroups] as List).elementAt(activeUnrecognisedGroupIdx)[UnrecognisedEntriesMixin.fieldEntries] as List).add(unrecognisedEntry);
              break;
          }
          relevantComments = [];
        }
      }
    }

    // Any outstanding lines are appended to the end
    map[fieldTrailingComments] = relevantComments;

    return DesktopContents.fromMap(map);
  }

  factory DesktopContents.fromFile(File file) {
    final lines = file.readAsLinesSync().where((element) => element.trim().isNotEmpty);
    return DesktopContents.fromLines(lines);
  }
}