import 'dart:io' if (dart.library.html) 'dart:html' show File;

import '../interface/write_to_file.dart';
import '../mixin/group_mixin.dart';
import '../mixin/unrecognised_entries_mixin.dart';

import '../group_name.dart';
import 'unrecognised_entry.dart';

class UnrecognisedGroup with GroupMixin, UnrecognisedEntriesMixin implements FileWritable {
  UnrecognisedGroup({
    required DesktopGroup group,
    required List<UnrecognisedEntry> entries
  }) {
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
  writeToFile(File file) {
    group.writeToFile(file);
    for (var entry in unrecognisedEntries) {
      entry.writeToFile(file);
    }
  }

  // From
  factory UnrecognisedGroup.fromMap(Map<String, dynamic> map) {
    return UnrecognisedGroup(
      group: DesktopGroup.fromMap(map[GroupMixin.fieldGroup]),
      entries: (map[UnrecognisedEntriesMixin.fieldEntries] as Iterable)
          .map((e) => UnrecognisedEntry.fromMap(e))
          .toList(growable: false)
    );
  }
}