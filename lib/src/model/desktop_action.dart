import 'dart:io' if (dart.library.html) 'dart:html' show File;

import 'package:collection/collection.dart';

import '../model/mixin/unrecognised_entries_mixin.dart';

import 'group_name.dart';
import 'interface/write_to_file.dart';
import 'mixin/group_mixin.dart';
import 'mixin/shared_mixin.dart';
import 'specification_types.dart';
import 'unrecognised/unrecognised_entry.dart';

class DesktopAction with DesktopSpecificationSharedMixin, GroupMixin,
    UnrecognisedEntriesMixin implements FileWritable {
  DesktopAction({
    required DesktopGroup group,
    required SpecificationLocaleString name,
    SpecificationIconString? icon,
    SpecificationString? exec,
    List<UnrecognisedEntry>? unrecognisedEntries,
  }) {
    this.group = group;
    this.name = name;
    this.icon = icon;
    this.exec = exec;
    this.unrecognisedEntries = unrecognisedEntries ?? <UnrecognisedEntry>[];
  }

  static const desktopActionPrefix = 'Desktop Action';
  static final RegExp groupRegExp = RegExp(r'(' + desktopActionPrefix + r' [\w\s\d]+)');

  // To
  static Map<String, dynamic> toData(DesktopAction action) {
    return <String, dynamic> {
      GroupMixin.fieldGroup: DesktopGroup.toData(action.group),
      DesktopSpecificationSharedMixin.fieldName: action.name.copyWith(),
      if (action.icon is SpecificationIconString) DesktopSpecificationSharedMixin.fieldIcon: action.icon!.copyWith(),
      if (action.exec is SpecificationString) DesktopSpecificationSharedMixin.fieldExec: action.exec!.copyWith(),
      UnrecognisedEntriesMixin.fieldEntries: List.of(action.unrecognisedEntries, growable: false),
    };
  }

  @override
  writeToFile(File file, _) {
    group.writeToFile(file, desktopActionPrefix);
    name.writeToFile(file, DesktopSpecificationSharedMixin.fieldName);
    icon?.writeToFile(file, DesktopSpecificationSharedMixin.fieldIcon);
    exec?.writeToFile(file, DesktopSpecificationSharedMixin.fieldExec);
    for (var unrecognisedEntry in unrecognisedEntries) {
      unrecognisedEntry.writeToFile(file, _);
    }
  }

  // From
  factory DesktopAction.fromMap(Map<String, dynamic> map) {
    return DesktopAction(
      group: map[GroupMixin.fieldGroup],
      name: map[DesktopSpecificationSharedMixin.fieldName],
      icon: map[DesktopSpecificationSharedMixin.fieldIcon],
      exec: map[DesktopSpecificationSharedMixin.fieldExec],
      unrecognisedEntries: map[UnrecognisedEntriesMixin.fieldEntries],
    );
  }

  DesktopAction copyWith({
    SpecificationLocaleString? name,
    DesktopGroup? group,
    SpecificationIconString? icon,
    SpecificationString? exec,
    List<UnrecognisedEntry>? unrecognisedEntries,
  }) {
    return DesktopAction(
      name: name ?? this.name.copyWith(),
      group: group ?? this.group.copyWith(),
      icon: icon ?? this.icon?.copyWith(),
      exec: exec ?? this.exec?.copyWith(),
      unrecognisedEntries: unrecognisedEntries ?? List.of(this.unrecognisedEntries),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopAction &&
        name == other.name &&
        group == other.group &&
        icon == other.icon &&
        exec == other.exec &&
      const ListEquality().equals(unrecognisedEntries, other.unrecognisedEntries);
  }

  @override
  int get hashCode => name.hashCode ^
    group.hashCode ^
    icon.hashCode ^
    exec.hashCode ^
    unrecognisedEntries.hashCode;
}