import 'dart:io' if (dart.library.html) 'dart:html' show File, FileMode;

import 'package:collection/collection.dart';
import 'package:desktop_entry/src/model/mixin/supports_modifiers_mixin.dart';

import '../../util/build_line.dart';
import '../../util/util.dart';
import '../interface/write_to_file.dart';
import '../mixin/comments_mixin.dart';

class UnrecognisedEntry
    with CommentsMixin, SupportsModifiersMixin<UnrecognisedEntry>
    implements FileWritable {
  UnrecognisedEntry(
      {required this.key,
      this.values,
      List<String>? comments,
      Map<String, UnrecognisedEntry>? modifiers}) {
    this.comments = comments ?? <String>[];
    this.modifiers = modifiers ?? <String, UnrecognisedEntry>{};
  }

  final String key;
  final List<String>? values;

  static const fieldKey = 'key';
  static const fieldValue = 'value';

  static String wrapKeyWithPrefix(String originalKey) {
    return originalKey.startsWith('X-') ? originalKey : 'X-$originalKey';
  }

  // To
  static Map<String, dynamic> toData(UnrecognisedEntry entry) {
    return <String, dynamic>{
      fieldKey: wrapKeyWithPrefix(entry.key),
      if (entry.values is String) fieldValue: entry.values,
      CommentsMixin.fieldComments: List.of(entry.comments),
      SupportsModifiersMixin.fieldModifiers: Map.of(entry.modifiers)
    };
  }

  @override
  writeToFile(File file, _) {
    StringBuffer buffer = StringBuffer("");

    for (var comment in comments) {
      buffer.writeln(comment);
    }

    buffer.write(wrapKeyWithPrefix(key));

    if (values is List) {
      buffer.write("=");

      values?.forEach((value) {
        buffer.write('$value;');
      });
    }
    buffer.write('\n');

    file.writeAsStringSync(buffer.toString(), mode: FileMode.writeOnlyAppend);
    // Write the localised elements, with their comments above
    modifiers.forEach((modifier, entryForModifier) {
      // Write the comments associated with the primary elements (if any)
      for (var comment in entryForModifier.comments) {
        if (comment.trim().isNotEmpty) {
          file.writeAsStringSync(buildComment(comment),
              mode: FileMode.writeOnlyAppend);
        }
      }

      file.writeAsStringSync(
          buildListLine('$key[$modifiers]', entryForModifier.values ?? []),
          mode: FileMode.writeOnlyAppend);
    });
  }

  // From
  factory UnrecognisedEntry.fromMap(Map<String, dynamic> map) {
    return UnrecognisedEntry(
        key: wrapKeyWithPrefix(map[fieldKey]),
        modifiers: map[SupportsModifiersMixin.fieldModifiers],
        values: map[fieldValue],
        comments: map[CommentsMixin.fieldComments]);
  }

  @override
  int get hashCode =>
      key.hashCode ^ values.hashCode ^ comments.hashCode ^ modifiers.hashCode;

  @override
  bool operator ==(Object other) {
    return other is UnrecognisedEntry &&
        key == other.key &&
        const ListEquality().equals(values, other.values) &&
        const ListEquality().equals(comments, other.comments) &&
        mapEquals(modifiers, other.modifiers);
  }

  @override
  toString() {
    return 'UnrecognisedEntry{ '
        '$fieldKey: $key, '
        '$fieldValue: $values, '
        '${CommentsMixin.fieldComments}: $comments, '
        '${SupportsModifiersMixin.fieldModifiers} $modifiers '
        '}';
  }
}
