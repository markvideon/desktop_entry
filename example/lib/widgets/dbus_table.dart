import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../service/dbus_service.dart';

class DBusTable extends StatefulWidget {
  const DBusTable({super.key});

  @override
  State<StatefulWidget> createState() => _DBusTableState();
}

class _DBusTableState extends State<DBusTable> {
  onDbusEvent() {
    setState(() {
      //
    });
  }

  @override
  void initState() {
    DbusService().setCallback(onDbusEvent);
    super.initState();
  }

  @override
  dispose() {
    DbusService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'D-Bus Response',
          style: Theme.of(context).textTheme.headline6,
        ),
        Row(
          children: [
            Expanded(
              child: DataTable(columns: const [
                DataColumn(label: Text('Key')),
                DataColumn(label: Text('Value')),
              ], rows: [
                DataRow(cells: [
                  const DataCell(Text('DBus Name Request Response')),
                  DataCell(Text(DbusService().requestNameReply.toString()))
                ]),
                if (DbusService().lastResponse is DateTime)
                  DataRow(cells: [
                    const DataCell(Text('Platform Data')),
                    DataCell(Text(
                        DateFormat.yMMMd().format(DbusService().lastResponse!)))
                  ]),
                DataRow(cells: [
                  const DataCell(Text('Platform Data')),
                  DataCell(DbusService().latestPlatformData.isEmpty
                      ? const Text('No arguments provided.')
                      : DataTable(
                          columns: const [
                              DataColumn(label: Text('Key')),
                              DataColumn(label: Text('Value')),
                            ],
                          rows: DbusService()
                              .latestPlatformData
                              .keys
                              .map((e) => DataRow(cells: [
                                    DataCell(Text(e)),
                                    DataCell(Text(DbusService()
                                        .latestPlatformData[e]!
                                        .toString())),
                                  ]))
                              .toList(growable: false)))
                ]),
                if (DbusService().latestUris is List<String> &&
                    DbusService().latestUris!.isNotEmpty)
                  DataRow(cells: [
                    const DataCell(Text('URIs')),
                    DataCell(DbusService().latestUris!.isEmpty
                        ? const Text('No arguments provided.')
                        : DataTable(
                            columns: const [
                                DataColumn(label: Text('Index')),
                                DataColumn(label: Text('Value')),
                              ],
                            rows: DbusService()
                                .latestUris!
                                .mapIndexed((idx, e) => DataRow(cells: [
                                      DataCell(Text('$idx')),
                                      DataCell(Text(e)),
                                    ]))
                                .toList(growable: false)))
                  ]),
                if (DbusService().latestActionName is String)
                  DataRow(cells: [
                    const DataCell(Text('Action Name')),
                    DataCell(Text(DbusService().latestActionName!)),
                  ]),
                if (DbusService().latestActionParams is List<String> &&
                    DbusService().latestActionParams!.isNotEmpty)
                  DataRow(cells: [
                    const DataCell(Text('Action Parameters')),
                    DataCell(DbusService().latestActionParams!.isEmpty
                        ? const Text('No arguments provided.')
                        : DataTable(
                            columns: const [
                                DataColumn(label: Text('Index')),
                                DataColumn(label: Text('Value')),
                              ],
                            rows: DbusService()
                                .latestActionParams!
                                .mapIndexed((idx, e) => DataRow(cells: [
                                      DataCell(Text('$idx')),
                                      DataCell(Text(e)),
                                    ]))
                                .toList(growable: false)))
                  ]),
              ]),
            ),
          ],
        )
      ],
    );
  }
}
