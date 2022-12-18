import 'package:dbus/dbus.dart';

import '../const.dart';
import '../model/dbus_interface.dart';

class DbusService {
  DbusService._internal() {
    client = DBusClient.session();

    requestName().then((_) {
      registerObject();
    });
  }

  factory DbusService() {
    return instance;
  }

  bool hasRegisteredObject = false;
  static final DbusService instance = DbusService._internal();
  late DBusClient client;

  DevMarkvideonDesktopEntryExampleObject? myObject;
  DBusRequestNameReply? requestNameReply;

  Map<String, DBusValue> latestPlatformData = {};
  List<String>? latestUris = [];
  String? latestActionName;
  List<String>? latestActionParams;
  FreeDesktopResponse latestResponse = FreeDesktopResponse.none;
  DateTime? lastResponse;

  Function? callback;

  requestName() async {
    requestNameReply = await client.requestName(dbusName, flags: {
      // Tailor this to the needs of your application.
      DBusRequestNameFlag.replaceExisting,
      DBusRequestNameFlag.allowReplacement,
    });
  }

  setCallback(Function? candidate) async {
    callback = candidate;

    await releaseObject();
    await registerObject();
  }

  registerObject() async {
    myObject = DevMarkvideonDesktopEntryExampleObject(callback: (data, {
      List<String>? uris,
      String? action_name,
      List<String>? parameter,
      FreeDesktopResponse? response
    }) {
        latestPlatformData = data;
        latestUris = uris;
        latestActionName = action_name;
        latestActionParams = parameter;
        latestResponse = response ?? FreeDesktopResponse.none;
        lastResponse = DateTime.now();
        callback?.call();
    });
    
    await client.registerObject(myObject!);

    hasRegisteredObject = true;
  }

  releaseObject() async {
    if (myObject is DBusObject && myObject?.client is DBusClient) {
      await client.unregisterObject(myObject!);
    }
  }

  dispose() {
    client.releaseName(dbusName);
    releaseObject();
    client.close();
  }
}