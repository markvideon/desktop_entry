// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object model/dbus-interface.xml

import 'package:dbus/dbus.dart';

class DevMarkvideonDesktopEntryExampleObject extends DBusObject {
  DevMarkvideonDesktopEntryExampleObject({this.callback}) : super(DBusObjectPath('/dev/markvideon/DesktopEntryExample/Object'));

  DateTime? lastCalledAt;
  Function? callback;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    print('Handling methodCall baby!!!: ${methodCall.name}');
    if (methodCall.interface == 'dev.markvideon.DesktopEntryExample') {
      // todo: Validate signatures
      switch (methodCall.name) {
        case 'Activate':
          if (methodCall.signature != DBusSignature('a{sv}')) {
            return DBusMethodErrorResponse.invalidArgs();
          }

          break;
        case 'Open':
          if (methodCall.signature != DBusSignature('asa{sv}')) {
            return DBusMethodErrorResponse.invalidArgs();
          }

          break;
        case 'ActivateAction':
          if (methodCall.signature != DBusSignature('sava{sv}')) {
            return DBusMethodErrorResponse.invalidArgs();
          }
          break;
        default:
          return DBusMethodErrorResponse.unknownMethod();
      }

      lastCalledAt = DateTime.now();
      callback?.call();
      return DBusMethodSuccessResponse([DBusString(lastCalledAt.toString())]);
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }
}
