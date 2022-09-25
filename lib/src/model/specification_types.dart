import 'package:desktop_entry/desktop_entry.dart';
import 'package:desktop_entry/src/model/shared_mixin.dart';

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

///  Values of type [string] may contain all ASCII characters except for
///  control characters.
class string extends _DesktopEntryType<String> {
  string(super.value) {

    for (var escapeCharacter in _escapeSequences) {
      if (value.contains(escapeCharacter)) {
        throw Exception('Unexpected escape character.');
      }
    }
  }

  string copyWith({String? value}) {
    return string(value ?? this.value);
  }

  @override
  bool operator ==(Object other) {
    return other is string &&
        value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

///  Values of type [localestring] are user displayable, and are encoded in
///  UTF-8.
class localestring extends _DesktopEntryType<String>
  with SupportsLocalisationMixin<localestring> {
  localestring(super.value, {Map<String, localestring>? localisedValues}) {
    this.localisedValues = localisedValues ?? <String, localestring>{};
  }

  localestring copyWith({
    String? value,
    Map<String, localestring>? localisedValues}) {
    return localestring(value ?? this.value, localisedValues: localisedValues);
  }

  @override
  bool operator ==(Object other) {
    return other is localestring &&
        value == other.value &&
        localisedValues == other.localisedValues;
  }

  @override
  int get hashCode => value.hashCode ^ localisedValues.hashCode;
}

///  Values of type iconstring are the names of icons;
///  these may be absolute paths, or symbolic names for icons located using
///  the algorithm described in the Icon Theme Specification.
///  Such values are not user-displayable, and are encoded in UTF-8.
class iconstring extends _DesktopEntryType<String>
    with SupportsLocalisationMixin<iconstring> {
  iconstring(super.value, {Map<String, iconstring>? localisedValues}) {
    this.localisedValues = localisedValues ?? <String, iconstring>{};
  }

  iconstring copyWith({
    String? value,
    Map<String, iconstring>? localisedValues}) {
    return iconstring(value ?? this.value, localisedValues: localisedValues);
  }

  @override
  bool operator ==(Object other) {
    return other is iconstring &&
        value == other.value &&
        localisedValues == other.localisedValues;
  }

  @override
  int get hashCode => value.hashCode ^
    localisedValues.hashCode;

}

/// Values of type boolean must either be the string true or false.
class boolean extends _DesktopEntryType<bool> {
  boolean(super.value);

  boolean copyWith({bool? value}) {
    return boolean(value ?? this.value);
  }

  @override
  bool operator ==(Object other) {
    return other is boolean &&
        value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

///  Values of type [numeric] must be a valid floating point number as recognized
///  by the %f specifier for scanf in the C locale.
///  Not used according to the specification table.
class numeric extends _DesktopEntryType<double> {
  numeric(super.value);

  numeric copyWith({double? value}) {
    return numeric(value ?? this.value);
  }

  @override
  bool operator ==(Object other) {
    return other is numeric &&
        value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

abstract class _DesktopEntryType<T> {
  _DesktopEntryType(this.value);

  T value;

  @override
  toString() {
    return value.toString();
  }
}