import 'dart:io' if (dart.library.html) 'dart:html' show File;

import 'package:collection/collection.dart';

import '../group_name.dart';
import '../interface/write_to_file.dart';
import '../mixin/group_mixin.dart';
import '../mixin/unrecognised_entries_mixin.dart';
import 'unrecognised_entry.dart';

class UnrecognisedGroup
    with GroupMixin, UnrecognisedEntriesMixin
    implements FileWritable {
  UnrecognisedGroup(
      {required DesktopGroup group, required List<UnrecognisedEntry> entries}) {
    this.group = group;
    unrecognisedEntries = entries;
  }

  // To
  static Map<String, dynamic> toData(UnrecognisedGroup group) {
    return <String, dynamic>{
      GroupMixin.fieldGroup: DesktopGroup.toData(group.group),
      UnrecognisedEntriesMixin.fieldEntries: group.unrecognisedEntries
          .map((e) => UnrecognisedEntry.toData(e))
          .toList(growable: false)
    };
  }

  @override
  writeToFile(File file, _) {
    group.writeToFile(file, null);
    for (var entry in unrecognisedEntries) {
      entry.writeToFile(file, _);
    }
  }

  // From
  factory UnrecognisedGroup.fromMap(Map<String, dynamic> map) {
    return UnrecognisedGroup(
      group: map[GroupMixin.fieldGroup],
      entries:
          map[UnrecognisedEntriesMixin.fieldEntries] as List<UnrecognisedEntry>,
    );
  }

  @override
  operator ==(Object other) {
    return other is UnrecognisedGroup &&
        group == other.group &&
        const ListEquality()
            .equals(unrecognisedEntries, other.unrecognisedEntries);
  }

  @override
  int get hashCode => group.hashCode ^ unrecognisedEntries.hashCode;

  @override
  toString() {
    return 'UnrecognisedGroup{ '
        '${GroupMixin.fieldGroup}: $group, '
        '${UnrecognisedEntriesMixin.fieldEntries}: $unrecognisedEntries '
        '}';
  }
}
