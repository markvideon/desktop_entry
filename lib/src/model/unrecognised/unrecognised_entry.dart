import 'dart:io' if (dart.library.html) 'dart:html' show File;

import 'package:collection/collection.dart';
import 'package:desktop_entry/desktop_entry.dart';

import '../interface/write_to_file.dart';
import '../mixin/comments.dart';

class UnrecognisedEntry with CommentsMixin implements FileWritable {
  UnrecognisedEntry({
    required this.key,
    this.values,
    List<String>? comments
  }) {
    this.comments = comments ?? <String>[];
  }

  final String key;
  final List<String>? values;

  static const fieldKey = 'key';
  static const fieldValue = 'value';

  // To
  static Map<String, dynamic> toData(UnrecognisedEntry entry) {
    return <String, dynamic> {
      fieldKey: entry.key.startsWith('X-') ? entry.key : 'X-${entry.key}',
      if (entry.values is String) fieldValue: entry.values,
      CommentsMixin.fieldComments: List.of(entry.comments)
    };
  }

  @override
  writeToFile(File file) {
    StringBuffer buffer = StringBuffer("");

    for (var comment in comments) {
      buffer.writeln(comment);
    }

    buffer.write(key);

    if (values is List) {
      buffer.write("=");

      values?.forEach((value) {
        buffer.write('$value;');
      });
    }
    buffer.write('\n');

    file.writeAsStringSync(buffer.toString());
  }

  // From
  factory UnrecognisedEntry.fromMap(Map<String, dynamic> map) {
    return UnrecognisedEntry(
      key: map[fieldKey],
      values: map[fieldValue],
      comments: map[CommentsMixin.fieldComments]
    );
  }

  @override
  int get hashCode => key.hashCode ^ values.hashCode ^ comments.hashCode;

  @override
  bool operator ==(Object other) {
    return other is UnrecognisedEntry &&
      key == other.key &&
      const ListEquality().equals(values, other.values) &&
      const ListEquality().equals(comments, other.comments);
  }

  @override
  toString() {
    return 'UnrecognisedEntry{ '
      '$fieldKey: $key, '
      '$fieldValue: $values, '
      '${CommentsMixin.fieldComments}: $comments '
    '}';
  }
}