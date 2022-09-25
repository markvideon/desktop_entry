import 'specification_types.dart';
import 'shared_mixin.dart';

class DesktopAction with DesktopSpecificationSharedMixin {
  DesktopAction({
    required localestring actionName,
    required this.entryKey,
    iconstring? icon,
    string? exec
  }) {
    name = actionName;
    this.icon = icon;
    this.exec = exec;
  }

  /// Key of type [string] used in the `Actions` field on a Desktop Entry
  /// as well as the header for a [DesktopAction]
  final string entryKey;

  static const fieldEntryKey = 'entryKey';

  static String buildHeader(String entryKey) {
    return '[Desktop Action $entryKey]';
  }

  String get header {
    return buildHeader(name.value);
  }

  static Map<String, dynamic> toMap(DesktopAction action) {
    return <String, dynamic> {
      DesktopSpecificationSharedMixin.fieldName: action.name.copyWith(),
      DesktopAction.fieldEntryKey: action.entryKey.copyWith(),
      if (action.icon is iconstring) DesktopSpecificationSharedMixin.fieldIcon: action.icon!.copyWith(),
      if (action.exec is string) DesktopSpecificationSharedMixin.fieldExec: action.exec!.copyWith()
    };
  }

  factory DesktopAction.fromMap(Map<String, dynamic> map) {
    return DesktopAction(
        actionName: map[DesktopSpecificationSharedMixin.fieldName],
        entryKey: map[fieldEntryKey],
        icon: map[DesktopSpecificationSharedMixin.fieldIcon],
        exec: map[DesktopSpecificationSharedMixin.fieldExec]
    );
  }

  DesktopAction copyWith({
    localestring? actionName,
    string? entryKey,
    iconstring? icon,
    string? exec
  }) {
    return DesktopAction(
        actionName: actionName ?? name,
        entryKey: entryKey?? this.entryKey,
        icon: icon ?? this.icon,
        exec: exec ?? this.exec
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopAction &&
        name == other.name &&
        entryKey == other.entryKey &&
        icon == other.icon &&
        exec == other.exec;
  }

  @override
  int get hashCode => name.hashCode ^
  entryKey.hashCode ^
  icon.hashCode ^
  exec.hashCode;
}