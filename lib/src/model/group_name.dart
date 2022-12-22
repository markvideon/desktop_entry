import 'dart:io' if (dart.library.html) 'dart:html' show File, FileMode;

import 'package:collection/collection.dart';

import 'interface/write_to_file.dart';
import 'mixin/comments_mixin.dart';

class DesktopGroup with CommentsMixin implements FileWritable {
  DesktopGroup(this.value, {List<String>? comments}) {
    this.comments = comments ?? <String>[];
  }

  String value;
  static const fieldValue = 'value';

  // From
  factory DesktopGroup.fromMap(Map<String, dynamic> map) {
    return DesktopGroup(map[fieldValue],
        comments: map[CommentsMixin.fieldComments]);
  }

  // To
  static Map<String, dynamic> toData(DesktopGroup groupName) {
    return <String, dynamic>{
      fieldValue: groupName.value,
      CommentsMixin.fieldComments: List.of(groupName.comments)
    };
  }

  @override
  writeToFile(File file, String? key) {
    final asLines = <String>[...comments, '[$value]']
        .map((e) => '$e\n')
        .toList(growable: false);

    for (var line in asLines) {
      file.writeAsStringSync(line, mode: FileMode.writeOnlyAppend);
    }
  }

  DesktopGroup copyWith({String? value, List<String>? comments}) {
    return DesktopGroup(value ?? this.value,
        comments: comments ?? List.of(this.comments));
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopGroup &&
        value == other.value &&
        const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode => value.hashCode ^ comments.hashCode;

  @override
  toString() {
    return 'DesktopGroup{ '
        '$fieldValue: $value, '
        '${CommentsMixin.fieldComments}: $comments ${comments.length}'
        '}';
  }
}
