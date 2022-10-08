import 'dart:io' if (dart.library.html) 'dart:html' show File;

import '../model/mixin/unrecognised_entries_mixin.dart';

import 'group_name.dart';
import 'interface/write_to_file.dart';
import 'mixin/group_mixin.dart';
import 'mixin/shared_mixin.dart';
import 'specification_types.dart';
import 'unrecognised/unrecognised_entry.dart';

class DesktopAction with DesktopSpecificationSharedMixin, GroupMixin, UnrecognisedEntriesMixin
  implements FileWritable {
  DesktopAction({
    required DesktopGroup group,
    required SpecificationLocaleString name,
    SpecificationIconString? icon,
    SpecificationString? exec,
    List<UnrecognisedEntry>? unrecognisedEntries
  }) {
    this.group = group;
    this.name = name;
    this.icon = icon;
    this.exec = exec;
    this.unrecognisedEntries = unrecognisedEntries ?? <UnrecognisedEntry>[];
  }

  static final RegExp groupRegExp = RegExp(r'(Desktop Action )(\w+)');

  // To
  static Map<String, dynamic> toData(DesktopAction action) {
    return <String, dynamic> {
      GroupMixin.fieldGroup: DesktopGroup.toData(action.group),
      DesktopSpecificationSharedMixin.fieldName: action.name.copyWith(),
      if (action.icon is SpecificationIconString) DesktopSpecificationSharedMixin.fieldIcon: action.icon!.copyWith(),
      if (action.exec is SpecificationString) DesktopSpecificationSharedMixin.fieldExec: action.exec!.copyWith(),
      if (action.unrecognisedEntries.isNotEmpty) UnrecognisedEntriesMixin.fieldEntries: List.of(action.unrecognisedEntries)
    };
  }

  @override
  writeToFile(File file) {
    group.writeToFile(file, clearFile: false);
    name.writeToFile(file);
    icon?.writeToFile(file);
    exec?.writeToFile(file);
    // todo: Write unrecognised entries
    for (var unrecognisedEntry in unrecognisedEntries) {
      unrecognisedEntry.writeToFile(file);
    }
  }

  // From
  factory DesktopAction.fromMap(Map<String, dynamic> map) {
    return DesktopAction(
      group: DesktopGroup.fromMap(map[GroupMixin.fieldGroup]),
      name: map[DesktopSpecificationSharedMixin.fieldName],
      icon: map[DesktopSpecificationSharedMixin.fieldIcon],
      exec: map[DesktopSpecificationSharedMixin.fieldExec]
    );
  }

  DesktopAction copyWith({
    SpecificationLocaleString? name,
    DesktopGroup? group,
    SpecificationIconString? icon,
    SpecificationString? exec
  }) {
    return DesktopAction(
      name: name ?? this.name,
      group: group ?? this.group,
      icon: icon ?? this.icon,
      exec: exec ?? this.exec
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopAction &&
        name == other.name &&
        group == other.group &&
        icon == other.icon &&
        exec == other.exec;
  }

  @override
  int get hashCode => name.hashCode ^
  group.hashCode ^
  icon.hashCode ^
  exec.hashCode;
}