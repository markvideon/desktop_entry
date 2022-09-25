import 'specification_types.dart';

mixin DesktopSpecificationSharedMixin {
  ///  Specific name of the application, for example "Mozilla".
  ///  Must be present on Types 1, 2, 3.
  late localestring name;
  static const fieldName = 'Name';
  Map<String, localestring>? namesByLocale;

  ///  Icon to display in file manager, menus, etc.
  ///  If the name is an absolute path, the given file will be used.
  ///  If the name is not an absolute path, the algorithm described in the
  ///  Icon Theme Specification will be used to locate the icon.
  ///  May be present on Types 1, 2, 3.
  iconstring? icon;
  static const fieldIcon = 'Icon';

  ///  Program to execute, possibly with arguments.
  ///  See the Exec key for details on how this key works.
  ///  The Exec key is required if DBusActivatable is not set to true.
  ///  Even if DBusActivatable is true, Exec should be specified for
  ///  compatibility with implementations that do not understand
  ///  DBusActivatable.
  ///  May be present on Type 1.
  string? exec;
  static const fieldExec = 'Exec';
}

mixin SupportsLocalisationMixin<T> {
  late Map<String, T> localisedValues;
}