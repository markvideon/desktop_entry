import 'dart:collection';
import 'dart:io' if (dart.library.html) 'dart:html' show File, FileMode;

import 'package:collection/collection.dart';
import 'package:desktop_entry/desktop_entry.dart';
import '../util/build_line.dart';
import 'desktop_entry.dart';
import 'interface/write_to_file.dart';
import 'mixin/comments_mixin.dart';
import 'mixin/supports_modifiers_mixin.dart';

/// Dart [String]s are encoded in UTF-16 as per
/// https://api.dart.dev/stable/2.18.1/dart-core/String-class.html
const _escapeSequences = [
  '\n', // ASCII newline
  '\t', // ASCII tab
  '\r', // ASCII carriage return
  '\\', // ASCII backslash
  '\b', // ASCII backspace
  '\v', // ASCII vertical tab
  '\f', // ASCII form feed
];

///  Values of type [SpecificationString] may contain all ASCII characters except for
///  control characters.
class SpecificationString extends DesktopEntryType<String> implements FileWritable {
  SpecificationString(super.value, {
    List<String>? comments,
  }) {
    for (var escapeCharacter in _escapeSequences) {
      if (value.contains(escapeCharacter)) {
        throw Exception('Unexpected escape character.');
      }
    }
    this.comments = comments ?? <String>[];
  }

  SpecificationString copyWith({String? value, List<String>? comments}) {
    return SpecificationString(value ?? this.value, comments: comments ?? List.of(this.comments));
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationString &&
      value == other.value &&
      const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode => value.hashCode ^ comments.hashCode;

  @override
  writeToFile(File file, String? key) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }
    file.writeAsStringSync(buildLine(key!, value), mode: FileMode.writeOnlyAppend);
  }

  @override
  toString() {
    return 'SpecificationString{ '
      'value: $value, '
      'comments: $comments, '
    '}';
  }
}

///  Values of type [SpecificationLocaleString] are user displayable, and are encoded in
///  UTF-8.
class SpecificationLocaleString extends DesktopEntryType<String>
  with SupportsModifiersMixin<SpecificationLocaleString> implements FileWritable {
  SpecificationLocaleString(super.value, {
    List<String>? comments,
    Map<String, SpecificationLocaleString>? localisedValues}) {
    this.modifiers = localisedValues ?? <String, SpecificationLocaleString>{};
    this.comments = comments ?? <String>[];
  }

  SpecificationLocaleString copyWith({
    String? value,
    List<String>? comments,
    Map<String, SpecificationLocaleString>? localisedValues
  }) {
    return SpecificationLocaleString(
      value ?? this.value,
      localisedValues: localisedValues ?? Map.of(this.modifiers),
      comments: comments ?? List.of(this.comments)
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationLocaleString &&
      value == other.value &&
      const ListEquality().equals(comments, other.comments) &&
      mapEquals(modifiers, other.modifiers);
  }

  @override
  int get hashCode => value.hashCode ^ modifiers.hashCode ^ comments.hashCode;

  @override
  writeToFile(File file, String? key) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }
    file.writeAsStringSync(buildLine(key!, value.toString()), mode: FileMode.writeOnlyAppend);
    modifiers.forEach((localisedKey, localisedValue) {
      file.writeAsStringSync(buildLine('$key[$localisedKey]', localisedValue.value), mode: FileMode.writeOnlyAppend);
    });
  }

  @override
  toString() {
    return 'SpecificationLocaleString{ '
      'value: $value, '
      'comments: $comments (${comments.length}: ${comments.map((e) => e)}), '
      'localisedValues: $modifiers (${modifiers.length}: ${modifiers.values.map((e) => e.value)}) '
    '}';
  }
}

///  Values of type iconstring are the names of icons;
///  these may be absolute paths, or symbolic names for icons located using
///  the algorithm described in the Icon Theme Specification.
///  Such values are not user-displayable, and are encoded in UTF-8.
class SpecificationIconString extends DesktopEntryType<String>
    with SupportsModifiersMixin<SpecificationIconString> implements FileWritable {
  SpecificationIconString(super.value, {Map<String, SpecificationIconString>? localisedValues, List<String>? comments}) {
    this.modifiers = localisedValues ?? <String, SpecificationIconString>{};
    this.comments = comments ?? <String>[];
  }

  SpecificationIconString copyWith({
    String? value,
    Map<String, SpecificationIconString>? localisedValues,
    List<String>? comments
  }) {
    return SpecificationIconString(
      value ?? this.value,
      localisedValues: localisedValues ?? Map.of(modifiers),
      comments: comments ?? List.of(this.comments)
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationIconString &&
        value == other.value &&
        mapEquals(modifiers, other.modifiers) &&
        const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode => value.hashCode ^
  modifiers.hashCode ^
    comments.hashCode;

  @override
  writeToFile(File file, String? key) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }
    file.writeAsStringSync(buildLine(key!, value.toString()), mode: FileMode.writeOnlyAppend);
    modifiers.forEach((localisedKey, localisedValue) {
      file.writeAsStringSync(buildLine('$key[$localisedKey]', value.toString()), mode: FileMode.writeOnlyAppend);
    });
  }

  @override
  toString() {
    return 'SpecificationIconString{ '
      'value: $value, '
      'comments: $comments, '
      'localisedValues: $modifiers '
    '}';
  }
}

/// Values of type boolean must either be the string true or false.
class SpecificationBoolean extends DesktopEntryType<bool> implements FileWritable {
  SpecificationBoolean(super.value, {List<String>? comments}) {
    this.comments = comments ?? <String>[];
  }

  SpecificationBoolean copyWith({
    bool? value,
    List<String>? comments
  }) {
    return SpecificationBoolean(
      value ?? this.value,
      comments: comments ?? this.comments
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationBoolean &&
      value == other.value &&
      const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode => value.hashCode ^ comments.hashCode;

  @override
  writeToFile(File file, String? key) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }
    file.writeAsStringSync(buildLine(key!, value.toString()), mode: FileMode.writeOnlyAppend);
  }

  @override
  toString() {
    return 'SpecificationBoolean{ '
      'value: $value, '
      'comments: $comments, '
    '}';
  }
}

///  Values of type [SpecificationNumeric] must be a valid floating point number as recognized
///  by the %f specifier for scanf in the C locale.
///  Not used according to the specification table.
class SpecificationNumeric extends DesktopEntryType<double> implements FileWritable {
  SpecificationNumeric(super.value, {List<String>? comments}) {
    this.comments = comments ?? <String>[];
  }

  SpecificationNumeric copyWith({
    double? value,
    List<String>? comments
  }) {
    return SpecificationNumeric(
      value ?? this.value,
      comments: comments ?? this.comments
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationNumeric &&
        value == other.value &&
      const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode => value.hashCode ^ comments.hashCode;

  @override
  writeToFile(File file, String? key) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment));
    }
    file.writeAsStringSync(buildLine(key!, value.toString()), mode: FileMode.writeOnlyAppend);
  }

  @override
  toString() {
    return 'SpecificationNumeric{ '
      'value: $value, '
      'comments: $comments, '
    '}';
  }
}

abstract class DesktopEntryType<T> with CommentsMixin {
  DesktopEntryType(this.value);

  T value;

  @override
  toString() {
    return value.toString();
  }
}

class SpecificationTypeList<T extends DesktopEntryType> extends ListBase<T> with CommentsMixin, FileWritable {
  SpecificationTypeList(List<T> primitiveList, {
    List<String>? comments,
  }) {
    _internalList = List.of(primitiveList);
    this.comments = comments ?? <String>[];
  }

  late List<T> _internalList;

  @override
  int get length => _internalList.length;

  @override
  T operator [](int index) {
    return _internalList[index];
  }

  @override
  void operator []=(int index, T value) {
    _internalList[index] = value;
  }

  @override
  set length(int newLength) => throw UnimplementedError();

  SpecificationTypeList<T> copyWith({
    List<T>? primitiveList,
    List<String>? comments,
  }) {
    return SpecificationTypeList<T>(
      primitiveList ?? List.of(this),
      comments: comments ?? List.of(this.comments),
    );
  }

  @override
  writeToFile(File file, String? key) {
    // Write the comments associated with the [KeywordList] first.
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }

    // Write the comments associated with the primary elements (if any)
    forEach((value) {
      for (var valueComment in value.comments) {
        if (valueComment.trim().isNotEmpty) {
          file.writeAsStringSync(buildComment(valueComment), mode: FileMode.writeOnlyAppend);
        }
      }
    });

    // Write the primary elements
    final primaryValues = map((keyword) => keyword.value.toString()).toList(growable: false);
    file.writeAsStringSync(buildListLine(key!, primaryValues), mode: FileMode.writeOnlyAppend);
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationTypeList<T> &&
      const ListEquality().equals(this, other) &&
      const ListEquality().equals(_internalList, other._internalList) &&
      const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode =>
    super.hashCode ^
    _internalList.hashCode ^
    comments.hashCode;

  @override
  toString() {
    return 'SpecificationTypeList{ '
      'externalList: ${map((element) => element.toString())}, '
      'internalList: ${_internalList.map((e) => e.toString())}, '
      'comments: $comments, '
    '}';
  }
}

class LocalisableSpecificationTypeList<T extends DesktopEntryType>
    extends SpecificationTypeList<T> with SupportsModifiersMixin<List<T>> {
  LocalisableSpecificationTypeList(super.primitiveList, {
    super.comments,
    Map<String, List<T>>? localisedValues
  }) {
    modifiers = localisedValues ?? {};
  }

  @override
  LocalisableSpecificationTypeList<T> copyWith({
    List<T>? primitiveList,
    List<String>? comments,
    Map<String, List<T>>? localisedValues
  }) {
    return LocalisableSpecificationTypeList<T>(
      primitiveList ?? List.of(this),
      comments: comments ?? List.of(this.comments),
      localisedValues: localisedValues ?? Map.of(modifiers)
    );
  }

  @override
  writeToFile(File file, String? key) {
    // Write the comments associated with the [KeywordList] first.
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment), mode: FileMode.writeOnlyAppend);
    }

    // Write the comments associated with the primary elements (if any)
    forEach((value) {
      for (var valueComment in value.comments) {
        if (valueComment.trim().isNotEmpty) {
          file.writeAsStringSync(buildComment(valueComment), mode: FileMode.writeOnlyAppend);
        }
      }
    });

    // Write the primary elements
    final primaryValues = map((keyword) => keyword.value.toString()).toList(growable: false);
    file.writeAsStringSync(buildListLine(key!, primaryValues), mode: FileMode.writeOnlyAppend);

    // Write the localised elements, with their comments above
    modifiers.forEach((languageModifier, languageSpecificListOfKeywords) {
      // Write the comments associated with the primary elements (if any)
      for (var languageSpecificKeyword in languageSpecificListOfKeywords) {
        for (var keywordComment in languageSpecificKeyword.comments) {
          if (keywordComment.trim().isNotEmpty) {
            file.writeAsStringSync(buildComment(keywordComment), mode: FileMode.writeOnlyAppend);
          }
        }
      }

      final languageSpecificValues = languageSpecificListOfKeywords.map((e) => e.value.toString()).toList(growable: false);
      file.writeAsStringSync(buildListLine('$key[$languageModifier]', languageSpecificValues), mode: FileMode.writeOnlyAppend);
    });
  }

  @override
  operator ==(Object other) =>
      other is LocalisableSpecificationTypeList<T> &&
      const ListEquality().equals(_internalList, other._internalList) &&
      const ListEquality().equals(comments, other.comments) &&
      mapEquals(modifiers, other.modifiers);

  @override
  int get hashCode => _internalList.hashCode ^
    comments.hashCode ^
  modifiers.hashCode;

  @override
  toString() {
    return 'LocalisableSpecificationTypeList{ '
        'internalList: ${_internalList.map((e) => e.toString())}, '
        'localisedValues: ${modifiers.toString()}, '
        'comments: $comments, '
    '}';
  }
}

// Can't extend MapEntry, as per this PR:
// https://github.com/dart-lang/sdk/issues/25874
class SpecificationMapEntry<K, V> implements MapEntry<K, V> {
  SpecificationMapEntry(this._key, this._value, {
    this.modifier
  });

  final String? modifier;
  late final K _key;
  late final V _value;

  @override
  K get key => _key;

  @override
  V get value => _value;

  @override
  bool operator ==(Object other) {
    return other is SpecificationMapEntry<K, V> &&
      key == other.key &&
      value == other.value &&
      modifier == other.modifier;
  }

  @override
  int get hashCode => key.hashCode ^ value.hashCode ^ modifier.hashCode;
}