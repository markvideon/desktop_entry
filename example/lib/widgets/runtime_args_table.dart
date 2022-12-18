import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class RuntimeArgsTable extends StatelessWidget {
  const RuntimeArgsTable({required this.arguments, super.key});

  final List<String> arguments;

  @override
  Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Runtime Arguments',
            style: Theme.of(context).textTheme.headline6,
          ),
          Row(
            children: [
              Expanded(
                child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Index')),
                      DataColumn(label: Text('Value')),
                    ],
                    rows: [
                      if (arguments.isEmpty) const DataRow(
                          cells: [
                            DataCell(Text('-')), DataCell(Text('No arguments provided.'))
                          ]
                      )
                      else ...arguments.mapIndexed((index, e) => DataRow(
                          cells: [
                            DataCell(Text('$index')), DataCell(Text(e,))
                          ]
                      ))
                    ]
                ),
              )
            ],
          ),
        ],
      );
  }
}