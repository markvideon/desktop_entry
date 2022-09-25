// Reference: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html
import 'dart:io';

import 'package:collection/collection.dart' show IterableExtension, ListEquality;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' show Context, Style;
import '../util/build_line.dart';
import '../util/parse_line.dart';
import '../util/util.dart';
import 'parse_mode.dart';
import 'desktop_action.dart';
import 'shared_mixin.dart';
import 'specification_types.dart';

class DesktopEntry with DesktopSpecificationSharedMixin {
  DesktopEntry({
    required this.type,
    this.version,
    required localestring entryName,
    this.genericName,
    this.noDisplay,
    this.comment,
    iconstring? icon,
    this.hidden,
    this.onlyShowIn = const <string>[],
    this.notShowIn = const <string>[],
    this.dBusActivatable,
    this.tryExec,
    string? exec,
    this.path,
    this.terminal,
    this.actions = const <DesktopAction>[],
    this.mimeType = const <string>[],
    this.categories = const <string>[],
    this.implements = const <string>[],
    this.keywords = const <localestring>[],
    this.startupNotify,
    this.startupWmClass,
    this.url,
    this.prefersNonDefaultGpu,
    this.singleMainWindow,
    required this.fileComments
  }) {
    // URL
    if ((type.value == 'Link' && url is! string)) {
      throw Exception('URL must be defined for type `Link`.');
    }
    // Setting fields from mixin.
    name = entryName;
    this.icon = icon;
    this.exec = exec;
  }

  factory DesktopEntry.fromMap(Map<String, dynamic> map) {
    final actions = map[fieldActions] != null ?
    (map[fieldActions] as List).mapIndexed((idx, e) => DesktopAction.fromMap(e)).toList(growable: false) :
    <DesktopAction>[];

    return DesktopEntry(
      type: map[fieldType],
      version: map[fieldVersion],
      entryName: map[DesktopSpecificationSharedMixin.fieldName],
      genericName: map[fieldGenericName],
      noDisplay: map[fieldNoDisplay],
      comment: map[fieldComment],
      icon: map[DesktopSpecificationSharedMixin.fieldIcon],
      hidden: map[fieldHidden],
      onlyShowIn: map[fieldOnlyShowIn] ?? <string>[],
      notShowIn: map[fieldNotShowIn] ?? <string>[],
      dBusActivatable: map[fieldDBusActivatable],
      tryExec: map[fieldTryExec],
      exec: map[DesktopSpecificationSharedMixin.fieldExec],
      path: map[fieldPath],
      terminal: map[fieldTerminal],
      actions: actions,
      mimeType: map[fieldMimeType] ?? <string>[],
      categories: map[fieldCategories] ?? <string>[],
      implements: map[fieldImplements] ?? <string>[],
      keywords: map[fieldKeywords] ?? <localestring>[],
      startupNotify: map[fieldStartupNotify],
      startupWmClass: map[fieldStartupWmClass],
      url: map[fieldUrl],
      prefersNonDefaultGpu: map[fieldPrefersNonDefaultGpu],
      singleMainWindow: map[fieldSingleMainWindow],
      fileComments: map[fieldFileComments],
    );
  }

  static Map<String, dynamic> toMap(DesktopEntry entry) {
    return <String, dynamic> {
      fieldType: entry.type.copyWith(),
      if (entry.version is string) fieldVersion: entry.version!.copyWith(),
      DesktopSpecificationSharedMixin.fieldName: entry.name.copyWith(),
      if (entry.genericName is localestring) fieldGenericName: entry.genericName!.copyWith(),
      if (entry.noDisplay is boolean) fieldNoDisplay: entry.noDisplay!.copyWith(),
      if (entry.comment is localestring) fieldComment: entry.comment!.copyWith(),
      if (entry.icon is iconstring) DesktopSpecificationSharedMixin.fieldIcon: entry.icon!.copyWith(),
      if (entry.hidden is boolean) fieldHidden: entry.hidden!.copyWith(),
      if (entry.onlyShowIn.isNotEmpty) fieldOnlyShowIn: List.of(entry.onlyShowIn),
      if (entry.notShowIn.isNotEmpty) fieldNotShowIn: List.of(entry.notShowIn),
      if (entry.dBusActivatable is boolean) fieldDBusActivatable: entry.dBusActivatable!.copyWith(),
      if (entry.tryExec is string) fieldTryExec: entry.tryExec!.copyWith(),
      if (entry.exec is string) DesktopSpecificationSharedMixin.fieldExec: entry.exec!.copyWith(),
      if (entry.path is string) fieldPath: entry.path!.copyWith(),
      if (entry.terminal is boolean) fieldTerminal: entry.terminal!.copyWith(),
      if (entry.actions.isNotEmpty) fieldActions: entry.actions.map((action) => DesktopAction.toMap(action)).toList(growable: false),
      if (entry.mimeType.isNotEmpty) fieldMimeType: List.of(entry.mimeType),
      if (entry.categories.isNotEmpty) fieldCategories: List.of(entry.categories),
      if (entry.implements.isNotEmpty) fieldImplements: List.of(entry.implements),
      if (entry.keywords.isNotEmpty) fieldKeywords: List.of(entry.keywords),
      if (entry.startupNotify is boolean) fieldStartupNotify: entry.startupNotify!.copyWith(),
      if (entry.startupWmClass is string) fieldStartupWmClass: entry.startupWmClass!.copyWith(),
      if (entry.url is string) fieldUrl: entry.url,
      if (entry.prefersNonDefaultGpu is boolean) fieldPrefersNonDefaultGpu: entry.prefersNonDefaultGpu,
      if (entry.singleMainWindow is boolean) fieldSingleMainWindow: entry.singleMainWindow
    };
  }

  factory DesktopEntry.fromLines(Iterable<String> lines) {
    if (lines.isEmpty) {
      throw Exception('File appears to be empty.');
    }

    // First line should always be the desktop entry header.
    if (lines.first.trim() != DesktopEntry.header) {
      throw Exception('Unexpected contents in first line. Expected `[Desktop Entry]`. Got `${lines.first}`');
    }

    final map = <String, dynamic> {};
    int activeActionIdx = -1;

    DesktopSpecificationParseMode parseMode = DesktopSpecificationParseMode.desktopEntry;

    for (var line in lines) {
      final effectiveLine = line.trim();
      // Ignore empty lines, comments.
      if (effectiveLine.isNotEmpty && effectiveLine.startsWith('#') == false) {
        final mapEntry = parseLine(effectiveLine);

        if (mapEntry == null) {
          // Header cases handled here
          if (map[fieldActions] is List) {
            final keyIsActionHeader = (map[fieldActions] as List<Map>).any((element) => DesktopAction.buildHeader((element[DesktopAction.fieldEntryKey] as string).value) == effectiveLine);

            if (keyIsActionHeader) {
              parseMode = DesktopSpecificationParseMode.desktopAction;
              activeActionIdx =
                  (map[fieldActions] as List<Map>).indexWhere((element) => DesktopAction.buildHeader((element[DesktopAction.fieldEntryKey] as string).value) == effectiveLine);
            }
          }
        } else {
          // Expect all non-header lines to conform to
          // KEY=value[;value2;...;valueN]\n
          // Split the string at the first equals sign. It is possible that some
          // property could contain an equals sign - the choice not to use
          // the `split` method is deliberate.
          switch (parseMode) {
            case DesktopSpecificationParseMode.desktopEntry:
              switch (mapEntry.key) {
                case DesktopEntry.fieldType:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopEntry.fieldVersion:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopSpecificationSharedMixin.fieldName:
                  map[mapEntry.key] = localestring(mapEntry.value);
                  break;
                case DesktopEntry.fieldGenericName:
                  map[mapEntry.key] = localestring(mapEntry.value);
                  break;
                case DesktopEntry.fieldNoDisplay:
                  map[mapEntry.key] = boolean(stringToBool(mapEntry.value));
                  break;
                case DesktopEntry.fieldComment:
                  map[mapEntry.key] = localestring(mapEntry.value);
                  break;
                case DesktopSpecificationSharedMixin.fieldIcon:
                  map[mapEntry.key] = iconstring(mapEntry.value);
                  break;
                case DesktopEntry.fieldHidden:
                  map[mapEntry.key] = boolean(stringToBool(mapEntry.value));
                  break;
                case DesktopEntry.fieldOnlyShowIn:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) => string(e)).toList(growable: false);
                  break;
                case DesktopEntry.fieldNotShowIn:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) => string(e)).toList(growable: false);
                  break;
                case DesktopEntry.fieldDBusActivatable:
                  map[mapEntry.key] = boolean(mapEntry.value);
                  break;
                case DesktopEntry.fieldTryExec:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopSpecificationSharedMixin.fieldExec:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopEntry.fieldPath:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopEntry.fieldTerminal:
                  map[mapEntry.key] = boolean(mapEntry.value);
                  break;
                case DesktopEntry.fieldActions:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) {
                    return <String, dynamic>{
                      DesktopAction.fieldEntryKey: string(e),
                    };
                  }).toList(growable: false);
                  break;
                case DesktopEntry.fieldMimeType:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) {
                    return string(e);
                  }).toList(growable: false);
                  break;
                case DesktopEntry.fieldCategories:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) {
                    return string(e);
                  }).toList(growable: false);
                  break;
                case DesktopEntry.fieldImplements:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) {
                    return string(e);
                  }).toList(growable: false);
                  break;
                case DesktopEntry.fieldKeywords:
                  map[mapEntry.key] = (mapEntry.value as List).map((e) {
                    return string(e);
                  }).toList(growable: false);
                  break;
                case DesktopEntry.fieldStartupNotify:
                  map[mapEntry.key] = boolean(stringToBool(mapEntry.value));
                  break;
                case DesktopEntry.fieldStartupWmClass:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopEntry.fieldUrl:
                  map[mapEntry.key] = string(mapEntry.value);
                  break;
                case DesktopEntry.fieldPrefersNonDefaultGpu:
                  map[mapEntry.key] = boolean(stringToBool(mapEntry.value));
                  break;
                case DesktopEntry.fieldSingleMainWindow:
                  map[mapEntry.key] = boolean(stringToBool(mapEntry.value));
                  break;
              }
              break;
            case DesktopSpecificationParseMode.desktopAction:
              switch (mapEntry.key) {
                case DesktopSpecificationSharedMixin.fieldName:
                  final actionList = map[fieldActions] as List<Map>;
                  actionList[activeActionIdx][DesktopSpecificationSharedMixin.fieldName] = localestring(mapEntry.value);
                  break;
                case DesktopSpecificationSharedMixin.fieldIcon:
                  final actionList = map[fieldActions] as List<Map>;
                  actionList[activeActionIdx][DesktopSpecificationSharedMixin.fieldIcon] = iconstring(mapEntry.value);
                  break;
                case DesktopSpecificationSharedMixin.fieldExec:
                  final actionList = map[fieldActions] as List<Map>;
                  actionList[activeActionIdx][DesktopSpecificationSharedMixin.fieldExec] = string(mapEntry.value);
                  break;
              }
              break;
          }
        }
      }
    }

    return DesktopEntry.fromMap(map);
  }

  factory DesktopEntry.fromFile(File file) {
    final lines = file.readAsLinesSync().where((element) => element.trim().isNotEmpty);
    return DesktopEntry.fromLines(lines);
  }

  static Future<File> toFile(String name, DesktopEntry entry) async {
    // Create file
    final tempDir = await getTemporaryDirectory();
    final pathContext = Context(style: Style.posix);
    final absPath = pathContext.join(tempDir.path, '$name.desktop');
    final file = File(absPath);

    file.writeAsStringSync(buildLine(DesktopEntry.header), mode: FileMode.writeOnly);

    if (entry.version is string) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldVersion, entry.version!.value), mode: FileMode.writeOnlyAppend);
    }
    file.writeAsStringSync(buildLine(DesktopEntry.fieldType, entry.type.value), mode: FileMode.writeOnlyAppend);
    file.writeAsStringSync(buildLine(DesktopSpecificationSharedMixin.fieldName, entry.name.value), mode: FileMode.writeOnlyAppend);
    if (entry.genericName is localestring) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldGenericName, entry.genericName!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.noDisplay is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldNoDisplay, entry.noDisplay!.value.toString()), mode: FileMode.writeOnlyAppend);
    }
    if (entry.comment is localestring) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldComment, entry.comment!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.icon is iconstring) {
      file.writeAsStringSync(buildLine(DesktopSpecificationSharedMixin.fieldIcon, entry.icon!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.hidden is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldHidden, entry.hidden!.value.toString()), mode: FileMode.writeOnlyAppend);
    }
    if (entry.onlyShowIn.isNotEmpty) {
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldOnlyShowIn, entry.onlyShowIn.map((e) => e.value).toList(growable: false)), mode: FileMode.writeOnlyAppend);
    }
    if (entry.notShowIn.isNotEmpty) {
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldNotShowIn, entry.notShowIn.map((e) => e.value).toList(growable: false)), mode: FileMode.writeOnlyAppend);
    }
    if (entry.dBusActivatable is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldDBusActivatable, entry.dBusActivatable!.value.toString()), mode: FileMode.writeOnlyAppend);
    }
    if (entry.tryExec is string) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldTryExec, entry.tryExec!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.exec is string) {
      file.writeAsStringSync(buildLine(DesktopSpecificationSharedMixin.fieldExec, entry.exec!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.path is string) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldPath, entry.path!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.terminal is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldTerminal, entry.terminal!.value.toString()), mode: FileMode.writeOnlyAppend);
    }
    // Note that this corresponds only to the [Actions] field directly on a
    // [DesktopEntry] section.
    if (entry.actions.isNotEmpty) {
      final actionList = entry.actions.map((e) => e.entryKey.value).toList(growable: false);
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldActions, actionList), mode: FileMode.writeOnlyAppend);
    }
    if (entry.mimeType.isNotEmpty) {
      final mimeTypeList = entry.mimeType.map((e) => e.value).toList(growable: false);
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldMimeType, mimeTypeList), mode: FileMode.writeOnlyAppend);
    }
    if (entry.categories.isNotEmpty) {
      final categoriesList = entry.categories.map((e) => e.value).toList(growable: false);
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldCategories, categoriesList), mode: FileMode.writeOnlyAppend);
    }
    if (entry.implements.isNotEmpty) {
      final implementsList = entry.implements.map((e) => e.value).toList(growable: false);
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldImplements, implementsList), mode: FileMode.writeOnlyAppend);
    }
    if (entry.keywords.isNotEmpty) {
      final keywordsList = entry.keywords.map((e) => e.value).toList(growable: false);
      file.writeAsStringSync(buildListLine(DesktopEntry.fieldKeywords, keywordsList), mode: FileMode.writeOnlyAppend);
    }
    if (entry.startupNotify is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldStartupNotify, entry.startupNotify!.value.toString()), mode: FileMode.writeOnlyAppend);
    }
    if (entry.startupWmClass is string) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldStartupWmClass, entry.startupWmClass!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.url is string) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldStartupWmClass, entry.startupWmClass!.value), mode: FileMode.writeOnlyAppend);
    }
    if (entry.prefersNonDefaultGpu is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldPrefersNonDefaultGpu, entry.prefersNonDefaultGpu!.value.toString()), mode: FileMode.writeOnlyAppend);
    }
    if (entry.singleMainWindow is boolean) {
      file.writeAsStringSync(buildLine(DesktopEntry.fieldSingleMainWindow, entry.singleMainWindow!.value.toString()), mode: FileMode.writeOnlyAppend);
    }

    if (entry.actions.isNotEmpty) {
      for (var action in entry.actions) {
        file.writeAsStringSync(buildLine(''), mode: FileMode.writeOnlyAppend);

        file.writeAsStringSync(buildLine(DesktopAction.buildHeader(action.entryKey.value)), mode: FileMode.writeOnlyAppend);
        file.writeAsStringSync(buildLine(DesktopSpecificationSharedMixin.fieldName, action.name.value), mode: FileMode.writeOnlyAppend);
        if (action.icon is iconstring) {
          file.writeAsStringSync(buildLine(DesktopSpecificationSharedMixin.fieldIcon, action.icon!.value), mode: FileMode.writeOnlyAppend);
        }
        if (action.exec is string) {
          file.writeAsStringSync(buildLine(DesktopSpecificationSharedMixin.fieldExec, action.exec!.value), mode: FileMode.writeOnlyAppend);
        }
      }
    }

    return file;
  }

  static const header = '[Desktop Entry]';

  /// File comments, keys corresponding to the various fields defined below.
  /// Not explicitly defined as part of the specification, but the specification
  /// does describe preservation as expected behaviour with respect to comments.
  Map<String, List<String>> fileComments = {};
  static const fieldFileComments = 'fileComments';

  ///  This specification defines 3 types of desktop entries:
  ///  - Application (type 1),
  ///  - Link (type 2) and
  ///  - Directory (type 3).
  ///  To allow the addition of new types in the future,
  ///  implementations should ignore desktop entries with an unknown type.
  ///  Must be present on Types 1, 2, 3.
  string type;
  static const fieldType = 'Type';

  /// Version of the Desktop Entry Specification that the desktop entry
  /// conforms with.
  /// Entries that confirm with this version of the specification should use
  /// 1.5. Note that the version field is not required to be present.
  /// May be present on Types 1, 2, 3.
  string? version;
  static const fieldVersion = 'Version';

  ///  Generic name of the application, for example "Web Browser".
  ///  May be present on Types 1, 2, 3.
  localestring? genericName;
  static const fieldGenericName = 'GenericName';

  ///  NoDisplay means "this application exists,
  ///  but don't display it in the menus". This can be useful to
  ///  e.g. associate this application with MIME types, so that it gets
  ///  launched from a file manager (or other apps),
  ///  without having a menu entry for it
  ///  (there are tons of good reasons for this, including
  ///  e.g. the netscape -remote, or kfmclient openURL kind of stuff).
  ///  May be present on Types 1, 2, 3.
  boolean? noDisplay;
  static const fieldNoDisplay = 'NoDisplay';

  ///  Tooltip for the entry, for example "View sites on the Internet".
  ///  The value should not be redundant with the values of Name and GenericName.
  ///  May be present on Types 1, 2, 3.
  localestring? comment;
  static const fieldComment = 'Comment';

  ///  Hidden should have been called Deleted.
  ///  It means the user deleted (at his level) something that was present
  ///  (at an upper level, e.g. in the system dirs).
  ///  It's strictly equivalent to the .desktop file not existing at all,
  ///  as far as that user is concerned.
  ///  This can also be used to "uninstall" existing files
  ///  (e.g. due to a renaming) - by letting make install install a file with
  ///  Hidden=true in it.
  ///  May be present on Types 1, 2, 3.
  boolean? hidden;
  static const fieldHidden = 'Hidden';

  ///  A list of strings identifying the desktop environments that should
  ///  display/not display a given desktop entry. By default, a desktop file
  ///  should be shown, unless an OnlyShowIn key is present, in which case,
  ///  the default is for the file not to be shown. If $XDG_CURRENT_DESKTOP is
  ///  set then it contains a colon-separated list of strings.
  ///  In order, each string is considered. If a matching entry is found in
  ///  OnlyShowIn then the desktop file is shown.
  ///  If an entry is found in NotShowIn then the desktop file is not shown.
  ///  If none of the strings match then the default action is taken (as above).
  ///  $XDG_CURRENT_DESKTOP should have been set by the login manager,
  ///  according to the value of the DesktopNames found in the session file.
  ///  The entry in the session file has multiple values separated in the
  ///  usual way: with a semicolon. The same desktop name may not appear in
  ///  both OnlyShowIn and NotShowIn of a group.
  ///  May be present on Types 1, 2, 3.
  List<string> onlyShowIn;
  static const fieldOnlyShowIn = 'OnlyShowIn';

  List<string> notShowIn;
  static const fieldNotShowIn = 'NotShowIn';

  ///  A boolean value specifying if D-Bus activation is supported for this
  ///  application. If this key is missing, the default value is false.
  ///  If the value is true then implementations should ignore the Exec key
  ///  and send a D-Bus message to launch the application.
  ///  See D-Bus Activation for more information on how this works.
  ///  Applications should still include Exec= lines in their desktop files
  ///  for compatibility with implementations that do not understand the
  ///  DBusActivatable key.
  ///  No type specified.
  boolean? dBusActivatable;
  static const fieldDBusActivatable = 'DBusActivatable';

  ///  Path to an executable file on disk used to determine if the program is
  ///  actually installed. If the path is not an absolute path, the file is
  ///  looked up in the $PATH environment variable.
  ///  If the file is not present or if it is not executable, the entry may
  ///  be ignored (not be used in menus, for example).
  ///  May be present on Type 1.
  string? tryExec;
  static const fieldTryExec = 'TryExec';

  ///  If entry is of type Application, the working directory to run the
  ///  program in.
  ///  May be present on Type 1.
  string? path;
  static const fieldPath = 'Path';

  ///  Whether the program runs in a terminal window.
  ///  May be present on Type 1.
  boolean? terminal;
  static const fieldTerminal = 'Terminal';

  ///  Identifiers for application actions. This can be used to tell the
  ///  application to make a specific action, different from the default
  ///  behavior. The Application actions section describes how actions work.
  ///  May be present on Type 1.
  List<DesktopAction> actions;
  static const fieldActions = 'Actions';

  ///  The MIME type(s) supported by this application.
  ///  May be present on Type 1.
  List<string> mimeType;
  static const fieldMimeType = 'MimeType';

  ///  Categories in which the entry should be shown in a menu
  ///  (for possible values see the Desktop Menu Specification).
  ///  https://www.freedesktop.org/wiki/Specifications/menu-spec/
  ///  May be present on Type 1.
  List<string> categories;
  static const fieldCategories = 'Categories';

  ///  A list of interfaces that this application implements.
  ///  By default, a desktop file implements no interfaces.
  ///  See Interfaces for more information on how this works.
  ///  No type specified.
  List<string> implements;
  static const fieldImplements = 'Implements';

  ///  A list of strings which may be used in addition to other metadata to
  ///  describe this entry. This can be useful e.g. to facilitate searching
  ///  through entries. The values are not meant for display, and should not
  ///  be redundant with the values of Name or GenericName.
  ///  May be present on Type 1.
  List<localestring> keywords;
  static const fieldKeywords = 'Keywords';

  ///  If true, it is KNOWN that the application will send a "remove" message
  ///  when started with the DESKTOP_STARTUP_ID environment variable set.
  ///  If false, it is KNOWN that the application does not work with startup
  ///  notification at all (does not shown any window, breaks even when using
  ///  StartupWMClass, etc.). If absent, a reasonable handling is up to
  ///  implementations (assuming false, using StartupWMClass, etc.).
  ///  (See the Startup Notification Protocol Specification for more details).
  ///  May be present on Type 1.
  boolean? startupNotify;
  static const fieldStartupNotify = 'StartupNotify';

  ///  If specified, it is known that the application will map at least one
  ///  window with the given string as its WM class or WM name hint
  ///  (see the Startup Notification Protocol Specification for more details).
  ///  May be present on Type 1.
  string? startupWmClass;
  static const fieldStartupWmClass = 'StartupWMClass';

  ///  If entry is Link type, the URL to access.
  ///  Must be present on Type 2.
  string? url;
  static const fieldUrl = 'URL';

  ///  If true, the application prefers to be run on a more powerful discrete
  ///  GPU if available, which we describe as “a GPU other than the default
  ///  one” in this spec to avoid the need to define what a discrete GPU is
  ///  and in which cases it might be considered more powerful than the
  ///  default GPU. This key is only a hint and support might not be present
  ///  depending on the implementation.
  ///  May be present on Type 1.
  boolean? prefersNonDefaultGpu;
  static const fieldPrefersNonDefaultGpu = 'PrefersNonDefaultGPU';

  ///  If true, the application has a single main window, and does not support
  ///  having an additional one opened. This key is used to signal to the
  ///  implementation to avoid offering a UI to launch another window of the
  ///  app. This key is only a hint and support might not be present depending
  ///  on the implementation.
  ///  May be present on Type 1.
  boolean? singleMainWindow;
  static const fieldSingleMainWindow = 'SingleMainWindow';

  @override
  bool operator ==(Object other) {
    return other is DesktopEntry &&
        type == other.type &&
        version == other.version &&
        name == other.name &&
        genericName == other.genericName &&
        noDisplay == other.noDisplay &&
        comment == other.comment &&
        icon == other.icon &&
        hidden == other.hidden &&
        const ListEquality().equals(onlyShowIn, other.onlyShowIn) &&
        const ListEquality().equals(notShowIn, other.notShowIn) &&
        dBusActivatable == other.dBusActivatable &&
        tryExec == other.tryExec &&
        exec == other.exec &&
        path == other.path &&
        terminal == other.terminal &&
        const ListEquality().equals(actions, other.actions) &&
        const ListEquality().equals(mimeType, other.mimeType) &&
        const ListEquality().equals(categories, other.categories) &&
        const ListEquality().equals(implements, other.implements) &&
        const ListEquality().equals(keywords, other.keywords) &&
        startupNotify == other.startupNotify &&
        startupWmClass == other.startupWmClass &&
        url == other.url &&
        prefersNonDefaultGpu == other.prefersNonDefaultGpu &&
        singleMainWindow == other.singleMainWindow;
  }

  compareWith(DesktopEntry other) {
    if (type != other.type) {
      throw Exception('$fieldType: LHS: $type, RHS: ${other.type}');
    }
    if (version != other.version) {
      throw Exception('$fieldVersion: LHS: $version, RHS: ${other.version}');
    }
    if (name != other.name) {
      throw Exception('${DesktopSpecificationSharedMixin.fieldName}: LHS: $name, RHS: ${other.name}');
    }
    if (genericName != other.genericName) {
      throw Exception('$fieldGenericName: LHS: $genericName, RHS: ${other.genericName}');
    }
    if (noDisplay != other.noDisplay) {
      throw Exception('$fieldNoDisplay: LHS: $noDisplay, RHS: ${other.noDisplay}');
    }
    if (comment != other.comment) {
      throw Exception('$fieldComment: LHS: $comment, RHS: ${other.comment}');
    }
    if (icon != other.icon) {
      throw Exception('${DesktopSpecificationSharedMixin.fieldIcon}: LHS: $icon, RHS: ${other.icon}');
    }
    if (hidden != other.hidden) {
      throw Exception('$fieldHidden: LHS: $hidden, RHS: ${other.hidden}');
    }
    if (const ListEquality().equals(onlyShowIn, other.onlyShowIn) == false) {
      throw Exception('$fieldOnlyShowIn: LHS: ${onlyShowIn.map((e) => e.value)}, RHS: ${onlyShowIn.map((e) => e.value)}');
    }
    if (const ListEquality().equals(notShowIn, other.notShowIn) == false) {
      throw Exception('$fieldNotShowIn: LHS: ${notShowIn.map((e) => e.value)}, RHS: ${notShowIn.map((e) => e.value)}');
    }
    if (dBusActivatable != other.dBusActivatable) {
      throw Exception('$fieldDBusActivatable: LHS: $dBusActivatable, RHS: ${other.dBusActivatable}');
    }
    if (tryExec != other.tryExec) {
      throw Exception('$fieldTryExec: LHS: $tryExec, RHS: ${other.tryExec}');
    }
    if (exec != other.exec) {
      throw Exception('${DesktopSpecificationSharedMixin.fieldExec}: LHS: $exec, RHS: ${other.exec}');
    }
    if (path != other.path) {
      throw Exception('$fieldPath: LHS: $path, RHS: ${other.path}');
    }
    if (terminal != other.terminal) {
      throw Exception('$fieldTerminal: LHS: $terminal, RHS: ${other.terminal}');
    }
    if (const ListEquality().equals(actions, other.actions) == false) {
      throw Exception('$fieldActions: LHS: ${actions.map((e) => e.hashCode)}, RHS: ${other.actions.map((e) => e.hashCode)}');
    }
    if (const ListEquality().equals(mimeType, other.mimeType) == false) {
      throw Exception('$fieldMimeType: LHS: ${mimeType.map((e) => e.value)}, RHS: ${other.mimeType.map((e) => e.value)}');
    }
    if (const ListEquality().equals(categories, other.categories) == false) {
      throw Exception('$fieldCategories: LHS: ${categories.map((e) => e.value)}, RHS: ${other.categories.map((e) => e.value)}');
    }
    if (const ListEquality().equals(implements, other.implements) == false) {
      throw Exception('$fieldImplements: LHS: ${implements.map((e) => e.value)}, RHS: ${other.implements.map((e) => e.value)}');
    }
    if (const ListEquality().equals(keywords, other.keywords) == false) {
      throw Exception('$fieldKeywords: LHS: ${keywords.map((e) => e.value)}, RHS: ${other.keywords.map((e) => e.value)}');
    }
    if (startupNotify != other.startupNotify) {
      throw Exception('$fieldStartupNotify: LHS: $startupNotify, RHS: ${other.startupNotify}');
    }
    if (startupWmClass != other.startupWmClass) {
      throw Exception('$fieldStartupWmClass: LHS: $startupWmClass, RHS: ${other.startupWmClass}');
    }
    if (url != other.url) {
      throw Exception('$fieldUrl: LHS: $url, RHS: ${other.url}');
    }
    if (prefersNonDefaultGpu != other.prefersNonDefaultGpu) {
      throw Exception('$fieldPrefersNonDefaultGpu: LHS: $prefersNonDefaultGpu, RHS: ${other.prefersNonDefaultGpu}');
    }
    if (singleMainWindow != other.singleMainWindow) {
      throw Exception('$fieldSingleMainWindow: LHS: $singleMainWindow, RHS: ${other.singleMainWindow}');
    }
  }

  @override
  int get hashCode =>
      type.hashCode ^
      version.hashCode ^
      name.hashCode ^
      genericName.hashCode ^
      noDisplay.hashCode ^
      comment.hashCode ^
      icon.hashCode ^
      hidden.hashCode ^
      onlyShowIn.hashCode ^
      notShowIn.hashCode ^
      dBusActivatable.hashCode ^
      tryExec.hashCode ^
      exec.hashCode ^
      path.hashCode ^
      terminal.hashCode ^
      actions.hashCode ^
      mimeType.hashCode ^
      categories.hashCode ^
      implements.hashCode ^
      keywords.hashCode ^
      startupNotify.hashCode ^
      startupWmClass.hashCode ^
      url.hashCode ^
      prefersNonDefaultGpu.hashCode ^
      singleMainWindow.hashCode;
}
