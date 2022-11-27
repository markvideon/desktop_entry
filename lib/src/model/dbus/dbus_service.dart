import 'dart:io';

import 'package:collection/collection.dart';

import '../../util/build_line.dart';
import '../group_name.dart';
import '../interface/write_to_file.dart';
import '../mixin/comments_mixin.dart';
import '../mixin/group_mixin.dart';
import '../mixin/shared_mixin.dart';
import '../mixin/unrecognised_entries_mixin.dart';
import '../specification_types.dart';
import '../unrecognised/unrecognised_entry.dart';

class DBusServiceDefinition with
    GroupMixin, UnrecognisedEntriesMixin, TrailingCommentsMixin
  implements FileWritable {
  DBusServiceDefinition({
    DesktopGroup? group,
    required this.name,
    required this.exec,
    this.user,
    this.systemDService,
    this.assumedAppArmorLabel,
    List<UnrecognisedEntry>? unrecognisedEntries,
    List<String>? trailingComments
  }) {
    this.group = group ?? DesktopGroup('D-BUS Service');
    this.unrecognisedEntries = unrecognisedEntries ?? [];
    this.trailingComments = trailingComments ?? <String>[];
  }

  SpecificationInterfaceName name;
  static const fieldName = 'Name';

  SpecificationFilePath exec;
  static const fieldExec = 'Exec';

  SpecificationString? user;
  static const fieldUser = 'User';

  SpecificationInterfaceName? systemDService;
  static const fieldSystemDService = 'SystemdService';

  SpecificationFilePath? assumedAppArmorLabel;
  static const fieldAssumedAppArmorLabel = 'AssumedAppArmorLabel';

  @override
  writeToFile(File file, _) {
    group.writeToFile(file, null);
    name.writeToFile(file, fieldName);
    exec.writeToFile(file, fieldExec);

    user?.writeToFile(file, fieldUser);
    systemDService?.writeToFile(file, fieldSystemDService);
    assumedAppArmorLabel?.writeToFile(file, fieldAssumedAppArmorLabel);

    for (var unrecognisedEntry in unrecognisedEntries) {
      unrecognisedEntry.writeToFile(file, _);
    }
    for (var comment in trailingComments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }
  }

  static Map<String, dynamic> toData(DBusServiceDefinition contents) {
    return <String, dynamic> {
      GroupMixin.fieldGroup: DesktopGroup.toData(contents.group),
      DesktopSpecificationSharedMixin.fieldName: contents.name,
      if (contents.exec is SpecificationString) DesktopSpecificationSharedMixin.fieldExec: contents.exec,
      if (contents.user is SpecificationString) fieldUser: contents.user!,
      if (contents.systemDService is String) fieldSystemDService: contents.systemDService,
      if (contents.assumedAppArmorLabel is Uri) fieldAssumedAppArmorLabel: contents.assumedAppArmorLabel,
      UnrecognisedEntriesMixin.fieldEntries: List.of(contents.unrecognisedEntries, growable: false),
      TrailingCommentsMixin.fieldTrailingComments: List.of(contents.trailingComments, growable: false)
    };
  }

  factory DBusServiceDefinition.fromMap(Map<String, dynamic> map) {
    print('$map');
    return DBusServiceDefinition(
      name: map[fieldName],
      exec: map[fieldExec],
      user: map[fieldUser],
      systemDService: map[fieldSystemDService],
      assumedAppArmorLabel: map[fieldAssumedAppArmorLabel],
      unrecognisedEntries: map[UnrecognisedEntriesMixin.fieldEntries],
    );
  }

  DBusServiceDefinition copyWith({
    SpecificationInterfaceName? name,
    SpecificationFilePath? exec,
    SpecificationString? user,
    SpecificationInterfaceName? systemDService,
    SpecificationFilePath? assumedAppArmorLabel,
    List<UnrecognisedEntry>? unrecognisedEntries,
    List<String>? trailingComments
  }) {
    return DBusServiceDefinition(
      name: name ?? this.name,
      exec: exec ?? this.exec,
      user: user ?? this.user,
      systemDService: systemDService ?? this.systemDService,
      assumedAppArmorLabel: assumedAppArmorLabel ?? this.assumedAppArmorLabel,
      unrecognisedEntries: unrecognisedEntries ?? List.of(this.unrecognisedEntries),
      trailingComments: trailingComments ?? List.of(this.trailingComments)
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DBusServiceDefinition &&
      name == other.name &&
      group == other.group &&
      exec == other.exec &&
      user == other.user &&
      systemDService == other.systemDService &&
      assumedAppArmorLabel == other.assumedAppArmorLabel &&
      const ListEquality().equals(unrecognisedEntries, other.unrecognisedEntries) &&
      const ListEquality().equals(trailingComments, other.trailingComments);
  }

  @override
  int get hashCode => name.hashCode ^
    group.hashCode ^
    exec.hashCode ^
    user.hashCode ^
    systemDService.hashCode ^
    assumedAppArmorLabel.hashCode ^
    unrecognisedEntries.hashCode ^
    trailingComments.hashCode;

  @override
  toString() {
    return 'DBusServiceDefinition{ '
      'group: $group, '
      '$fieldName: $name, '
      '$fieldExec: $exec, '
      '$fieldUser: $user, '
      '$fieldSystemDService: $systemDService, '
      '$fieldAssumedAppArmorLabel: $assumedAppArmorLabel, '
      '${UnrecognisedEntriesMixin.fieldEntries}: $unrecognisedEntries, '
      '${TrailingCommentsMixin.fieldTrailingComments}: $trailingComments '
    '}';
  }
}