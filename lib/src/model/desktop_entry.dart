// Reference: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html
import 'dart:io' if (dart.library.html) 'dart:html' show File, FileMode;

import 'package:collection/collection.dart' show ListEquality;
import 'mixin/unrecognised_entries_mixin.dart';
import 'group_name.dart';
import 'interface/write_to_file.dart';

import '../util/build_line.dart';
import 'mixin/group_mixin.dart';
import 'mixin/shared_mixin.dart';
import 'specification_types.dart';
import 'unrecognised/unrecognised_entry.dart';

class DesktopEntry with DesktopSpecificationSharedMixin, UnrecognisedEntriesMixin, GroupMixin implements FileWritable {
  DesktopEntry({
    DesktopGroup? group,
    required this.type,
    this.version,
    required SpecificationLocaleString name,
    this.genericName,
    this.noDisplay,
    this.comment,
    SpecificationIconString? icon,
    this.hidden,
    this.onlyShowIn,
    this.notShowIn,
    this.dBusActivatable,
    this.tryExec,
    SpecificationString? exec,
    this.path,
    this.terminal,
    this.actions,
    this.mimeType,
    this.categories,
    this.implements,
    this.keywords,
    this.startupNotify,
    this.startupWmClass,
    this.url,
    this.prefersNonDefaultGpu,
    this.singleMainWindow,
    List<UnrecognisedEntry>? unrecognisedEntries
  }) {
    // URL
    if ((type.value == 'Link' && url is! SpecificationString)) {
      throw Exception('URL must be defined for type `Link`.');
    }
    this.group = group ?? DesktopGroup('Desktop Entry');
    // Setting fields from mixin.
    this.name = name;
    this.icon = icon;
    this.exec = exec;
    this.unrecognisedEntries = unrecognisedEntries ?? <UnrecognisedEntry>[];
  }

  ///  This specification defines 3 types of desktop entries:
  ///  - Application (type 1),
  ///  - Link (type 2) and
  ///  - Directory (type 3).
  ///  To allow the addition of new types in the future,
  ///  implementations should ignore desktop entries with an unknown type.
  ///  Must be present on Types 1, 2, 3.
  SpecificationString type;
  static const fieldType = 'Type';

  /// Version of the Desktop Entry Specification that the desktop entry
  /// conforms with.
  /// Entries that confirm with this version of the specification should use
  /// 1.5. Note that the version field is not required to be present.
  /// May be present on Types 1, 2, 3.
  SpecificationString? version;
  static const fieldVersion = 'Version';

  ///  Generic name of the application, for example "Web Browser".
  ///  May be present on Types 1, 2, 3.
  SpecificationLocaleString? genericName;
  static const fieldGenericName = 'GenericName';

  ///  NoDisplay means "this application exists,
  ///  but don't display it in the menus". This can be useful to
  ///  e.g. associate this application with MIME types, so that it gets
  ///  launched from a file manager (or other apps),
  ///  without having a menu entry for it
  ///  (there are tons of good reasons for this, including
  ///  e.g. the netscape -remote, or kfmclient openURL kind of stuff).
  ///  May be present on Types 1, 2, 3.
  SpecificationBoolean? noDisplay;
  static const fieldNoDisplay = 'NoDisplay';

  ///  Tooltip for the entry, for example "View sites on the Internet".
  ///  The value should not be redundant with the values of Name and GenericName.
  ///  May be present on Types 1, 2, 3.
  SpecificationLocaleString? comment;
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
  SpecificationBoolean? hidden;
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
  SpecificationTypeList<SpecificationString>? onlyShowIn;
  static const fieldOnlyShowIn = 'OnlyShowIn';

  SpecificationTypeList<SpecificationString>? notShowIn;
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
  SpecificationBoolean? dBusActivatable;
  static const fieldDBusActivatable = 'DBusActivatable';

  ///  Path to an executable file on disk used to determine if the program is
  ///  actually installed. If the path is not an absolute path, the file is
  ///  looked up in the $PATH environment variable.
  ///  If the file is not present or if it is not executable, the entry may
  ///  be ignored (not be used in menus, for example).
  ///  May be present on Type 1.
  SpecificationString? tryExec;
  static const fieldTryExec = 'TryExec';

  ///  If entry is of type Application, the working directory to run the
  ///  program in.
  ///  May be present on Type 1.
  SpecificationString? path;
  static const fieldPath = 'Path';

  ///  Whether the program runs in a terminal window.
  ///  May be present on Type 1.
  SpecificationBoolean? terminal;
  static const fieldTerminal = 'Terminal';

  ///  Identifiers for application actions. This can be used to tell the
  ///  application to make a specific action, different from the default
  ///  behavior. The Application actions section describes how actions work.
  ///  May be present on Type 1.
  SpecificationTypeList<SpecificationString>? actions;
  static const fieldActions = 'Actions';

  ///  The MIME type(s) supported by this application.
  ///  May be present on Type 1.
  SpecificationTypeList<SpecificationString>? mimeType;
  static const fieldMimeType = 'MimeType';

  ///  Categories in which the entry should be shown in a menu
  ///  (for possible values see the Desktop Menu Specification).
  ///  https://www.freedesktop.org/wiki/Specifications/menu-spec/
  ///  May be present on Type 1.
  SpecificationTypeList<SpecificationString>? categories;
  static const fieldCategories = 'Categories';

  ///  A list of interfaces that this application implements.
  ///  By default, a desktop file implements no interfaces.
  ///  See Interfaces for more information on how this works.
  ///  No type specified.
  SpecificationTypeList<SpecificationString>? implements;
  static const fieldImplements = 'Implements';

  ///  A list of strings which may be used in addition to other metadata to
  ///  describe this entry. This can be useful e.g. to facilitate searching
  ///  through entries. The values are not meant for display, and should not
  ///  be redundant with the values of Name or GenericName.
  ///  May be present on Type 1.
  LocalisableSpecificationTypeList<SpecificationLocaleString>? keywords;
  static const fieldKeywords = 'Keywords';

  ///  If true, it is KNOWN that the application will send a "remove" message
  ///  when started with the DESKTOP_STARTUP_ID environment variable set.
  ///  If false, it is KNOWN that the application does not work with startup
  ///  notification at all (does not shown any window, breaks even when using
  ///  StartupWMClass, etc.). If absent, a reasonable handling is up to
  ///  implementations (assuming false, using StartupWMClass, etc.).
  ///  (See the Startup Notification Protocol Specification for more details).
  ///  May be present on Type 1.
  SpecificationBoolean? startupNotify;
  static const fieldStartupNotify = 'StartupNotify';

  ///  If specified, it is known that the application will map at least one
  ///  window with the given string as its WM class or WM name hint
  ///  (see the Startup Notification Protocol Specification for more details).
  ///  May be present on Type 1.
  SpecificationString? startupWmClass;
  static const fieldStartupWmClass = 'StartupWMClass';

  ///  If entry is Link type, the URL to access.
  ///  Must be present on Type 2.
  SpecificationString? url;
  static const fieldUrl = 'URL';

  ///  If true, the application prefers to be run on a more powerful discrete
  ///  GPU if available, which we describe as “a GPU other than the default
  ///  one” in this spec to avoid the need to define what a discrete GPU is
  ///  and in which cases it might be considered more powerful than the
  ///  default GPU. This key is only a hint and support might not be present
  ///  depending on the implementation.
  ///  May be present on Type 1.
  SpecificationBoolean? prefersNonDefaultGpu;
  static const fieldPrefersNonDefaultGpu = 'PrefersNonDefaultGPU';

  ///  If true, the application has a single main window, and does not support
  ///  having an additional one opened. This key is used to signal to the
  ///  implementation to avoid offering a UI to launch another window of the
  ///  app. This key is only a hint and support might not be present depending
  ///  on the implementation.
  ///  May be present on Type 1.
  SpecificationBoolean? singleMainWindow;
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

  // To
  DesktopEntry copyWith({
    DesktopGroup? groupName,
    SpecificationString? type,
    SpecificationString? version,
    SpecificationLocaleString? name,
    SpecificationLocaleString? genericName,
    SpecificationBoolean? noDisplay,
    SpecificationLocaleString? comment,
    SpecificationIconString? icon,
    SpecificationBoolean? hidden,
    SpecificationTypeList<SpecificationString>? onlyShowIn,
    SpecificationTypeList<SpecificationString>? notShowIn,
    SpecificationBoolean? dBusActivatable,
    SpecificationString? tryExec,
    SpecificationString? exec,
    SpecificationString? path,
    SpecificationBoolean? terminal,
    SpecificationTypeList<SpecificationString>? actions,
    SpecificationTypeList<SpecificationString>? mimeType,
    SpecificationTypeList<SpecificationString>? categories,
    SpecificationTypeList<SpecificationString>? implements,
    LocalisableSpecificationTypeList<SpecificationLocaleString>? keywords,
    SpecificationBoolean? startupNotify,
    SpecificationString? startupWmClass,
    SpecificationString? url,
    SpecificationBoolean? prefersNonDefaultGpu,
    SpecificationBoolean? singleMainWindow,
  }) {
    return DesktopEntry(
      group: groupName ?? group.copyWith(),
      type: type ?? this.type.copyWith(),
      version: version ?? this.version?.copyWith(),
      name: name ?? this.name.copyWith(),
      genericName: genericName ?? this.genericName?.copyWith(),
      noDisplay: noDisplay ?? this.noDisplay?.copyWith(),
      comment: comment ?? this.comment?.copyWith(),
      icon: icon ?? this.icon?.copyWith(),
      hidden: hidden ?? this.hidden?.copyWith(),
      onlyShowIn: onlyShowIn ?? this.onlyShowIn?.copyWith(),
      notShowIn: notShowIn ?? this.notShowIn?.copyWith(),
      dBusActivatable: dBusActivatable ?? this.dBusActivatable?.copyWith(),
      tryExec: tryExec ?? this.tryExec?.copyWith(),
      exec: exec ?? this.exec?.copyWith(),
      path: path ?? this.path?.copyWith(),
      terminal: terminal ?? this.terminal?.copyWith(),
      actions: actions ?? this.actions?.copyWith(),
      mimeType: mimeType ?? this.mimeType?.copyWith(),
      categories: categories ?? this.categories?.copyWith(),
      implements: implements ?? this.implements?.copyWith(),
      keywords: keywords ?? this.keywords?.copyWith(),
      startupNotify: startupNotify ?? this.startupNotify?.copyWith(),
      url: url ?? this.url?.copyWith(),
      prefersNonDefaultGpu: prefersNonDefaultGpu ?? this.prefersNonDefaultGpu?.copyWith(),
      singleMainWindow: singleMainWindow ?? this.singleMainWindow?.copyWith()
    );
  }
  static Map<String, dynamic> toData(DesktopEntry entry) {
    return <String, dynamic> {
      fieldType: entry.type.copyWith(),
      if (entry.version is SpecificationString) fieldVersion: entry.version!.copyWith(),
      DesktopSpecificationSharedMixin.fieldName: entry.name.copyWith(),
      if (entry.genericName is SpecificationLocaleString) fieldGenericName: entry.genericName!.copyWith(),
      if (entry.noDisplay is SpecificationBoolean) fieldNoDisplay: entry.noDisplay!.copyWith(),
      if (entry.comment is SpecificationLocaleString) fieldComment: entry.comment!.copyWith(),
      if (entry.icon is SpecificationIconString) DesktopSpecificationSharedMixin.fieldIcon: entry.icon!.copyWith(),
      if (entry.hidden is SpecificationBoolean) fieldHidden: entry.hidden!.copyWith(),
      if (entry.onlyShowIn is SpecificationTypeList<SpecificationString> && entry.onlyShowIn!.isNotEmpty) fieldOnlyShowIn: entry.onlyShowIn!.copyWith(),
      if (entry.notShowIn is SpecificationTypeList<SpecificationString> && entry.notShowIn!.isNotEmpty) fieldNotShowIn: entry.notShowIn!.copyWith(),
      if (entry.dBusActivatable is SpecificationBoolean) fieldDBusActivatable: entry.dBusActivatable!.copyWith(),
      if (entry.tryExec is SpecificationString) fieldTryExec: entry.tryExec!.copyWith(),
      if (entry.exec is SpecificationString) DesktopSpecificationSharedMixin.fieldExec: entry.exec!.copyWith(),
      if (entry.path is SpecificationString) fieldPath: entry.path!.copyWith(),
      if (entry.terminal is SpecificationBoolean) fieldTerminal: entry.terminal!.copyWith(),
      if (entry.actions is SpecificationTypeList<SpecificationString> && entry.actions!.isNotEmpty) fieldActions: entry.actions!.copyWith(),
      if (entry.mimeType is SpecificationTypeList<SpecificationString> && entry.mimeType!.isNotEmpty) fieldMimeType: entry.mimeType!.copyWith(),
      if (entry.categories is SpecificationTypeList<SpecificationString> && entry.categories!.isNotEmpty) fieldCategories: entry.categories!.copyWith(),
      if (entry.implements is SpecificationTypeList<SpecificationString> && entry.implements!.isNotEmpty) fieldImplements: entry.implements!.copyWith(),
      if (entry.keywords is LocalisableSpecificationTypeList && entry.keywords!.isNotEmpty) fieldKeywords: entry.keywords!.copyWith(),
      if (entry.startupNotify is SpecificationBoolean) fieldStartupNotify: entry.startupNotify!.copyWith(),
      if (entry.startupWmClass is SpecificationString) fieldStartupWmClass: entry.startupWmClass!.copyWith(),
      if (entry.url is SpecificationString) fieldUrl: entry.url,
      if (entry.prefersNonDefaultGpu is SpecificationBoolean) fieldPrefersNonDefaultGpu: entry.prefersNonDefaultGpu,
      if (entry.singleMainWindow is SpecificationBoolean) fieldSingleMainWindow: entry.singleMainWindow
    };
  }

  @override
  writeToFile(File file, String? _) {
    group.writeToFile(file, _);
    type.writeToFile(file, fieldType);
    version?.writeToFile(file, fieldVersion);
    name.writeToFile(file, DesktopSpecificationSharedMixin.fieldName);
    genericName?.writeToFile(file, fieldGenericName);
    noDisplay?.writeToFile(file, fieldNoDisplay);

    comment?.writeToFile(file, fieldComment);
    icon?.writeToFile(file, DesktopSpecificationSharedMixin.fieldIcon);
    hidden?.writeToFile(file, fieldHidden);
    if (onlyShowIn is SpecificationTypeList<SpecificationString> && onlyShowIn!.isNotEmpty) {
      final onlyShowInComments = onlyShowIn!.map((e) => e.comments)
        .fold(<String>[], (previousValue, element) => [...previousValue, ...element])
        .map((e) => buildComment(e))
        .toList(growable: false);

      for (var comment in onlyShowInComments) {
        file.writeAsStringSync(comment, mode: FileMode.writeOnlyAppend);
      }

      final onlyShowInValues = onlyShowIn!.map((e) => e.value).toList(growable: false);
      final onlyShowInLine = buildListLine(fieldOnlyShowIn, onlyShowInValues);
      file.writeAsStringSync(onlyShowInLine, mode: FileMode.writeOnlyAppend);
    }
    if (notShowIn is SpecificationTypeList<SpecificationString> && notShowIn!.isNotEmpty) {
      final notShowInComments = notShowIn!.map((e) => e.comments)
          .fold(<String>[], (previousValue, element) => [...previousValue, ...element])
          .map((e) => buildComment(e))
          .toList(growable: false);

      for (var comment in notShowInComments) {
        file.writeAsStringSync(comment, mode: FileMode.writeOnlyAppend);
      }

      final notShowInValues = notShowIn!.map((e) => e.value).toList(growable: false);
      final notShowInLine = buildListLine(fieldNotShowIn, notShowInValues);
      file.writeAsStringSync(notShowInLine, mode: FileMode.writeOnlyAppend);
    }

    dBusActivatable?.writeToFile(file, fieldDBusActivatable);
    tryExec?.writeToFile(file, fieldTryExec);
    exec?.writeToFile(file, DesktopSpecificationSharedMixin.fieldExec);
    path?.writeToFile(file, fieldPath);
    terminal?.writeToFile(file, fieldTerminal);

    if (actions is SpecificationTypeList<SpecificationString> && actions!.isNotEmpty) {
      final actionComments = actions!.map((e) => e.comments)
          .fold(<String>[], (previousValue, element) => [...previousValue, ...element])
          .map((e) => buildComment(e))
          .toList(growable: false);

      for (var comment in actionComments) {
        file.writeAsStringSync(comment, mode: FileMode.writeOnlyAppend);
      }

      final actionValues = actions!.map((e) => e.value).toList(growable: false);
      final actionLine = buildListLine(fieldActions, actionValues);
      file.writeAsStringSync(actionLine, mode: FileMode.writeOnlyAppend);
    }

    if (mimeType is SpecificationTypeList<SpecificationString> && mimeType!.isNotEmpty) {
      final mimeTypeComments = mimeType!.map((e) => e.comments)
          .fold(<String>[], (previousValue, element) => [...previousValue, ...element])
          .map((e) => buildComment(e))
          .toList(growable: false);

      for (var comment in mimeTypeComments) {
        file.writeAsStringSync(comment, mode: FileMode.writeOnlyAppend);
      }

      final mimeTypeValues = mimeType!.map((e) => e.value).toList(growable: false);
      final mimeTypeLine = buildListLine(fieldMimeType, mimeTypeValues);
      file.writeAsStringSync(mimeTypeLine, mode: FileMode.writeOnlyAppend);
    }

    if (categories is SpecificationTypeList<SpecificationString> && categories!.isNotEmpty) {
      final categoriesComments = categories!.map((e) => e.comments)
          .fold(<String>[], (previousValue, element) => [...previousValue, ...element])
          .map((e) => buildComment(e))
          .toList(growable: false);

      for (var comment in categoriesComments) {
        file.writeAsStringSync(comment, mode: FileMode.writeOnlyAppend);
      }

      final categoriesValues = categories!.map((e) => e.value).toList(growable: false);
      final categoriesLine = buildListLine(fieldCategories, categoriesValues);
      file.writeAsStringSync(categoriesLine, mode: FileMode.writeOnlyAppend);
    }

    if (implements is SpecificationTypeList<SpecificationString> && implements!.isNotEmpty) {
      final implementsComments = implements!.map((e) => e.comments)
          .fold(<String>[], (previousValue, element) => [...previousValue, ...element])
          .map((e) => buildComment(e))
          .toList(growable: false);

      for (var comment in implementsComments) {
        file.writeAsStringSync(comment, mode: FileMode.writeOnlyAppend);
      }

      final implementsValues = implements!.map((e) => e.value).toList(growable: false);
      final implementsLine = buildListLine(fieldImplements, implementsValues);
      file.writeAsStringSync(implementsLine, mode: FileMode.writeOnlyAppend);
    }

    keywords?.writeToFile(file, fieldKeywords);

    startupNotify?.writeToFile(file, fieldStartupNotify);
    startupWmClass?.writeToFile(file, fieldStartupWmClass);
    url?.writeToFile(file, fieldUrl);
    prefersNonDefaultGpu?.writeToFile(file, fieldPrefersNonDefaultGpu);
    singleMainWindow?.writeToFile(file, fieldSingleMainWindow);

    for (var element in unrecognisedEntries) {
      element.writeToFile(file, _);
    }
  }

  // From
  factory DesktopEntry.fromMap(Map<String, dynamic> map) {
    return DesktopEntry(
      group: map[GroupMixin.fieldGroup],
      type: map[fieldType],
      version: map[fieldVersion],
      name: map[DesktopSpecificationSharedMixin.fieldName],
      genericName: map[fieldGenericName],
      noDisplay: map[fieldNoDisplay],
      comment: map[fieldComment],
      icon: map[DesktopSpecificationSharedMixin.fieldIcon],
      hidden: map[fieldHidden],
      onlyShowIn: map[fieldOnlyShowIn],
      notShowIn: map[fieldNotShowIn],
      dBusActivatable: map[fieldDBusActivatable],
      tryExec: map[fieldTryExec],
      exec: map[DesktopSpecificationSharedMixin.fieldExec],
      path: map[fieldPath],
      terminal: map[fieldTerminal],
      actions: map[fieldActions],
      mimeType: map[fieldMimeType],
      categories: map[fieldCategories],
      implements: map[fieldImplements],
      keywords: map[fieldKeywords],
      startupNotify: map[fieldStartupNotify],
      startupWmClass: map[fieldStartupWmClass],
      url: map[fieldUrl],
      prefersNonDefaultGpu: map[fieldPrefersNonDefaultGpu],
      singleMainWindow: map[fieldSingleMainWindow],
      unrecognisedEntries: map[UnrecognisedEntriesMixin.fieldEntries]
    );
  }
}
