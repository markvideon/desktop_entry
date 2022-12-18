import 'dart:io';

import 'package:flutter/material.dart';

class EnvironmentTable extends StatelessWidget {
  const EnvironmentTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Environment Variables',
          style: Theme.of(context).textTheme.headline6,
        ),
        Row(
          children: [
            Expanded(
              child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Key')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    if (Platform.environment.isEmpty) const DataRow(
                        cells: [
                          DataCell(Text('-')),
                          DataCell(Text('No arguments provided.'))
                        ])
                    else ...Platform.environment.keys.map((e) => DataRow(
                        cells: [
                          DataCell(Text(e)),
                          DataCell(Text('${Platform.environment[e]}', softWrap: true))
                        ])
                    )
                  ]
              ),
            ),
          ],
        )
      ],
    );
  }
}