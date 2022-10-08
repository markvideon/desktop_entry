import 'dart:collection';
import 'dart:io' if (dart.library.html) 'dart:html' show File, FileMode;

import 'package:collection/collection.dart';

import '../util/build_line.dart';
import 'desktop_entry.dart';
import 'interface/write_to_file.dart';
import 'mixin/comments.dart';
import 'mixin/supports_localisation.dart';

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
class SpecificationString extends _DesktopEntryType<String> implements FileWritable {
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

  SpecificationString copyWith({String? value}) {
    return SpecificationString(value ?? this.value);
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationString &&
        value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  writeToFile(File file, {String? key}) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment));
    }
    file.writeAsStringSync(buildLine(key!, value));
  }
}

///  Values of type [SpecificationLocaleString] are user displayable, and are encoded in
///  UTF-8.
class SpecificationLocaleString extends _DesktopEntryType<String>
  with SupportsLocalisationMixin<SpecificationLocaleString> implements FileWritable {
  SpecificationLocaleString(super.value, {
    List<String>? comments,
    Map<String, SpecificationLocaleString>? localisedValues}) {
    this.localisedValues = localisedValues ?? <String, SpecificationLocaleString>{};
    this.comments = comments ?? <String>[];
  }

  SpecificationLocaleString copyWith({
    String? value,
    Map<String, SpecificationLocaleString>? localisedValues
  }) {
    return SpecificationLocaleString(value ?? this.value, localisedValues: localisedValues);
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationLocaleString &&
        value == other.value &&
        localisedValues == other.localisedValues;
  }

  @override
  int get hashCode => value.hashCode ^ localisedValues.hashCode;

  @override
  writeToFile(File file, {String? key}) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment));
    }
    file.writeAsStringSync(buildLine(key!, value.toString()));
    localisedValues.forEach((localisedKey, localisedValue) {
      file.writeAsStringSync(buildLine('$key[$localisedKey]', value.toString()));
    });
  }
}

///  Values of type iconstring are the names of icons;
///  these may be absolute paths, or symbolic names for icons located using
///  the algorithm described in the Icon Theme Specification.
///  Such values are not user-displayable, and are encoded in UTF-8.
class SpecificationIconString extends _DesktopEntryType<String>
    with SupportsLocalisationMixin<SpecificationIconString> implements FileWritable {
  SpecificationIconString(super.value, {Map<String, SpecificationIconString>? localisedValues, List<String>? comments}) {
    this.localisedValues = localisedValues ?? <String, SpecificationIconString>{};
    this.comments = comments ?? <String>[];
  }

  SpecificationIconString copyWith({
    String? value,
    Map<String, SpecificationIconString>? localisedValues,
    List<String>? comments
  }) {
    return SpecificationIconString(
      value ?? this.value,
      localisedValues: localisedValues,
      comments: comments ?? this.comments
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpecificationIconString &&
        value == other.value &&
        const MapEquality().equals(localisedValues, other.localisedValues) &&
        const ListEquality().equals(comments, other.comments);
  }

  @override
  int get hashCode => value.hashCode ^
    localisedValues.hashCode ^
    comments.hashCode;

  @override
  writeToFile(File file, {String? key}) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment));
    }
    file.writeAsStringSync(buildLine(key!, value.toString()));
    localisedValues.forEach((localisedKey, localisedValue) {
      file.writeAsStringSync(buildLine('$key[$localisedKey]', value.toString()));
    });
  }
}

/// Values of type boolean must either be the string true or false.
class SpecificationBoolean extends _DesktopEntryType<bool> implements FileWritable {
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
  writeToFile(File file, {String? key}) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment));
    }
    file.writeAsStringSync(buildLine(key!, value.toString()));
  }
}

///  Values of type [SpecificationNumeric] must be a valid floating point number as recognized
///  by the %f specifier for scanf in the C locale.
///  Not used according to the specification table.
class SpecificationNumeric extends _DesktopEntryType<double> implements FileWritable {
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
  writeToFile(File file, {String? key}) {
    for (var comment in comments) {
      file.writeAsStringSync(buildComment(comment));
    }
    file.writeAsStringSync(buildLine(key!, value.toString()));
  }
}

abstract class _DesktopEntryType<T> with CommentsMixin {
  _DesktopEntryType(this.value);

  T value;

  @override
  toString() {
    return value.toString();
  }
}

class SpecificationTypeList<T extends _DesktopEntryType> extends ListBase<T> with CommentsMixin, FileWritable {
  SpecificationTypeList(List<T> primitiveList, {
    required this.elementConstructor,
    List<String>? comments,
  }) {
    _internalList = List.of(primitiveList);
    this.comments = comments ?? <String>[];
  }

  late List<T> _internalList;
  final T Function() elementConstructor;

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
  set length(int newLength) {
    if (newLength > _internalList.length) {
      _internalList = [
        ..._internalList,
        ...List.generate(newLength - _internalList.length, (index) => elementConstructor())
      ];
    } else if (newLength < _internalList.length) {
      _internalList = _internalList.sublist(0, newLength);
    }
  }

  @override
  writeToFile(File file) {
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
    file.writeAsStringSync(buildListLine(DesktopEntry.fieldKeywords, primaryValues), mode: FileMode.writeOnlyAppend);
  }
}

class LocalisableSpecificationTypeList<T extends _DesktopEntryType>
    extends SpecificationTypeList<T> with SupportsLocalisationMixin<List<T>> {
  LocalisableSpecificationTypeList(super.primitiveList, {
    required super.elementConstructor,
    super.comments,
    Map<String, List<T>>? localisedValues
  }) {
    this.localisedValues = localisedValues ?? {};
  }

  LocalisableSpecificationTypeList<T> copyWith({
    List<T>? primitiveList,
    T Function()? elementConstructor,
    List<String>? comments,
    Map<String, List<T>>? localisedValues
  }) {
    return LocalisableSpecificationTypeList<T>(
      primitiveList ?? List.of(this),
      elementConstructor: elementConstructor ?? this.elementConstructor,
      comments: comments ?? List.of(this.comments),
      localisedValues: localisedValues ?? Map.of(this.localisedValues)
    );
  }

  @override
  writeToFile(File file) {
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
    file.writeAsStringSync(buildListLine(DesktopEntry.fieldKeywords, primaryValues), mode: FileMode.writeOnlyAppend);

    // Write the localised elements, with their comments above
    localisedValues.forEach((languageModifier, languageSpecificListOfKeywords) {
      // Write the comments associated with the primary elements (if any)
      for (var languageSpecificKeyword in languageSpecificListOfKeywords) {
        for (var keywordComment in languageSpecificKeyword.comments) {
          if (keywordComment.trim().isNotEmpty) {
            file.writeAsStringSync(buildComment(keywordComment), mode: FileMode.writeOnlyAppend);
          }
        }
      }

      final languageSpecificValues = languageSpecificListOfKeywords.map((e) => e.value.toString()).toList(growable: false);
      file.writeAsStringSync(buildListLine('${DesktopEntry.fieldKeywords}[$languageModifier]', languageSpecificValues), mode: FileMode.writeOnlyAppend);
    });
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
}