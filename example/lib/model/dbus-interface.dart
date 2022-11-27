// This file was generated using the following command and may be overwritten.
// dart-dbus generate-object lib/model/dbus-interface.xml

import 'package:dbus/dbus.dart';

class DevMarkvideonDesktopEntryExampleObject extends DBusObject {
  Function(Map<String, dynamic> data)? callback;

  /// Creates a new object to expose on [path].
  DevMarkvideonDesktopEntryExampleObject({this.callback,
    DBusObjectPath path = const DBusObjectPath.unchecked('/dev/markvideon/DesktopEntryExample/Object'
  )}) : super(path);

  /// Implementation of org.freedesktop.Application.Activate()
  Future<DBusMethodResponse> doActivate(Map<String, DBusValue> platform_data) async {
    callback?.call(platform_data);
    return DBusMethodSuccessResponse();
  }

  /// Implementation of org.freedesktop.Application.Open()
  Future<DBusMethodResponse> doOpen(List<String> uris, Map<String, DBusValue> platform_data) async {
    callback?.call(platform_data);
    return DBusMethodErrorResponse.failed('org.freedesktop.Application.Open() not implemented');
  }

  /// Implementation of org.freedesktop.Application.ActivateAction()
  Future<DBusMethodResponse> doActivateAction(String action_name, List<DBusValue> parameter, Map<String, DBusValue> platform_data) async {
    callback?.call(platform_data);
    return DBusMethodErrorResponse.failed('org.freedesktop.Application.ActivateAction() not implemented');
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [DBusIntrospectInterface('org.freedesktop.Application', methods: [DBusIntrospectMethod('Activate', args: [DBusIntrospectArgument(DBusSignature('a{sv}'), DBusArgumentDirection.in_, name: 'platform_data')]), DBusIntrospectMethod('Open', args: [DBusIntrospectArgument(DBusSignature('as'), DBusArgumentDirection.in_, name: 'uris'), DBusIntrospectArgument(DBusSignature('a{sv}'), DBusArgumentDirection.in_, name: 'platform_data')]), DBusIntrospectMethod('ActivateAction', args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'action_name'), DBusIntrospectArgument(DBusSignature('av'), DBusArgumentDirection.in_, name: 'parameter'), DBusIntrospectArgument(DBusSignature('a{sv}'), DBusArgumentDirection.in_, name: 'platform_data')])])];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.freedesktop.Application') {
      if (methodCall.name == 'Activate') {
        if (methodCall.signature != DBusSignature('a{sv}')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doActivate(methodCall.values[0].asStringVariantDict());
      } else if (methodCall.name == 'Open') {
        if (methodCall.signature != DBusSignature('asa{sv}')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doOpen(methodCall.values[0].asStringArray().toList(), methodCall.values[1].asStringVariantDict());
      } else if (methodCall.name == 'ActivateAction') {
        if (methodCall.signature != DBusSignature('sava{sv}')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doActivateAction(methodCall.values[0].asString(), methodCall.values[1].asVariantArray().toList(), methodCall.values[2].asStringVariantDict());
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.freedesktop.Application') {
      return DBusMethodErrorResponse.unknownProperty();
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> setProperty(String interface, String name, DBusValue value) async {
    if (interface == 'org.freedesktop.Application') {
      return DBusMethodErrorResponse.unknownProperty();
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }
}
