import 'dart:developer';
import 'dart:io' show Process, ProcessResult;

import 'package:collection/collection.dart';
import 'package:desktop_entry/src/model/variant_map_entry.dart';

import '../model/specification_types.dart';

// Lifted from 'package:flutter/foundation.dart' - Pinched to avoid depending
// on Flutter.
bool mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (final T key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}

Future<Process> adminProcess(String processName, List<String> processArguments) async {
  return Process.start(
    processName,
    processArguments,
    runInShell: true
  );
}

logProcessStdOut(ProcessResult processResult) {
  if (processResult.stdout is List<int>) {
    final messageBytes = processResult.stdout as List<int>;
    if (messageBytes.isNotEmpty) {
      log(String.fromCharCodes(messageBytes));
    }
  } else if (processResult.stdout is String) {
    log(processResult.stdout);
  }
}

checkProcessStdErr(ProcessResult processResult) {
  if (processResult.stderr is List<int>) {
    final errorMessageBytes = processResult.stderr as List<int>;
    if (errorMessageBytes.isNotEmpty) {
      throw Exception(String.fromCharCodes(errorMessageBytes));
    }
  } else if (processResult.stderr is String) {
    final errorMessageString = processResult.stderr.toString().trim();

    if (errorMessageString.isNotEmpty) {
      throw Exception(processResult.stderr);
    }
  }
}

bool stringToBool(String candidate) {
  return candidate.trim().toLowerCase() == 'true';
}

// Line may be of the forms:
// - `Name=AppName`
// - `Name[otherLang]=OtherLangAppName`
extractLocalisedMap(String input) {
  final regExp = RegExp(r'^(\w+)\[?([\w\d\s@*-]+)?]?=(.*)$', dotAll: true);

  final match = regExp.firstMatch(input);
  final groups = <String>[];

  if (match == null) return groups;

  for (int i = 1; i < match.groupCount; i++) {
    if (match.group(i) is String) {
      groups.add(match.group(i)!);
    } else {
      print('Warning: group $i was null.');
    }
  }

  return groups;
}

List<String> extractContents(String input, String startChar, String endChar) {
  final regExp = RegExp(r'\' + startChar + r'(.*?)' + r'\' + endChar);

  final matches = regExp.allMatches(input)
      .map((result) => input.substring(result.start + 1, result.end - 1))
      .toList(growable: false);

  return matches;
}

handleLocalisableList<T extends SpecificationType>(
    Map map, String relevantKey, VariantMapEntry entry, List<String> relevantComments, T Function(dynamic) processValues) {
  bool objectExists = map[relevantKey] != null;

  if (!objectExists) {
    map[relevantKey] = LocalisableSpecificationTypeList<T>(<T>[]);
  }

  final existingName = map[relevantKey] as LocalisableSpecificationTypeList<T>;
  // Check if the map key exists
  if (entry.modifier is String) {
    // if the map entry exists, copy the value currently at the key, adding the new localised value
    // otherwise create a SpecificationLocaleString with an empty value?
    final updatedLocalisation = Map.of(existingName.modifiers)..addEntries([
      MapEntry(entry.modifier!,
          LocalisableSpecificationTypeList<T>(
            (entry.value as Iterable).map((e) => processValues(e)).toList(growable: false)
          )
      )
    ]);

    map[relevantKey] = existingName.copyWith(
        localisedValues: updatedLocalisation,
        comments: relevantComments
    );
  } else {
    // As before
    map[relevantKey] = existingName.copyWith(
        primitiveList: (entry.value as Iterable).map((e) => processValues(e)).toList(growable: false),
        comments: relevantComments
    );
  }

  relevantComments = <String>[];
}

handleLocalisableString(Map map, String relevantKey, VariantMapEntry entry, List<String> relevantComments) {
  // Due to a bug, let's copy the list to be safe.
  final applicableList = List.of(relevantComments);

  bool objectExists = map[relevantKey] != null;

  if (!objectExists) {
    map[relevantKey] = SpecificationLocaleString('');
  }

  final existingName = map[relevantKey] as SpecificationLocaleString;
  // Check if the map key exists
  if (entry.modifier is String) {
    // if the map entry exists, copy the value currently at the key, adding the new localised value
    // otherwise create a SpecificationLocaleString with an empty value?
    final updatedLocalisation = Map.of(existingName.modifiers)..addEntries([
      MapEntry(entry.modifier!, SpecificationLocaleString(entry.value))
    ]);

    map[relevantKey] = existingName.copyWith(
      localisedValues: updatedLocalisation,
      comments: applicableList
    );
  } else {
    // As before
    map[relevantKey] = existingName.copyWith(
      value: entry.value,
      comments: applicableList
    );
  }
  relevantComments = <String>[];
}

bool compareMaps(Map<String, dynamic> mapA, Map<String, dynamic> mapB) {
  List<String> keysExclusiveToA = mapA.keys.where((key) => !mapB.containsKey(key)).toList(growable: false);
  List<String> keysExclusiveToB = mapB.keys.where((key) => !mapA.containsKey(key)).toList(growable: false);
  List<String> differentValues = <String>[];

  mapA.forEach((key, value) {
    bool equalityTestResult = true;

    if (mapB.containsKey(key)) {
      if (value is List) {
        final mapAList = value;
        final mapBList = mapB[key] as List;
        mapAList.forEachIndexed((idx, listAElement) {
          final listBElement = mapBList.elementAt(idx);

          if (listAElement is Map) {
            if (!mapEquals(listAElement, listBElement)) {
              listAElement.forEach((mapKey, listAValue) {
                final listBValue = listBElement[mapKey];
                if (listAValue is List && !const ListEquality().equals(listAValue, listBValue)) {
                  print('At $key $mapKey, $listAValue (hashCode: ${listAValue.hashCode}, runtimeType: ${listAValue.runtimeType}) != $listBValue (hashCode: ${listBValue.hashCode}, runtimeType: ${listBValue.runtimeType})');
                  listAValue.forEachIndexed((listIdx, listElement) {
                    if (listBValue.elementAt(listIdx) != listAValue.elementAt(listIdx)) {
                      print('List element unequal at $key $mapKey $listIdx, ${listAValue.elementAt(listIdx)} (hashCode: ${listAValue.elementAt(listIdx).hashCode}, runtimeType: ${listAValue.elementAt(listIdx).runtimeType}) != ${listBValue.elementAt(listIdx)} (hashCode: ${listBValue.elementAt(listIdx).hashCode}, runtimeType: ${listBValue.elementAt(listIdx).runtimeType})');
                    }
                  });
                } else if (listAValue is Map && !mapEquals(listAValue, listBValue)) {
                  print('At $key $mapKey, $listAValue (hashCode: ${listAValue.hashCode}, runtimeType: ${listAValue.runtimeType}) != $listBValue (hashCode: ${listBValue.hashCode}, runtimeType: ${listBValue.runtimeType})');
                } else {
                  if (listAValue != listBValue) {
                    print('At $key $mapKey, $listAValue (hashCode: ${listAValue.hashCode}, runtimeType: ${listAValue.runtimeType}) != $listBValue (hashCode: ${listBValue.hashCode}, runtimeType: ${listBValue.runtimeType})');
                  }
                }
              });
              print('$key $idx: $listAElement != $listBElement');
              print('${listAElement.toString().length} ... ${listBElement.toString().length}');

            }
          } else if (listAElement is List) {
            if (!const ListEquality().equals(listAElement, listBElement)) {
              print('$key $idx: $listAElement != $listBElement');
              print('${listAElement.toString().length} ... ${listBElement.toString().length}');

            }
          } else {
            if (listAElement!= listBElement) {
              print('$key $idx: $listAElement != $listBElement');
              print('${listAElement.toString().length} ... ${listBElement.toString().length}');
            }
          }
        });
        equalityTestResult = const ListEquality().equals(value, mapB[key]);
      } else if (value is Map) {
        final mapX = value;
        final mapY = mapB[key] as Map;

        mapX.forEach((key, value) {
          if (mapX[key] != mapY[key]) {
            print('mapX[$key] != mapY[$key]. ${mapX[key]} != ${mapY[key]}');
            print('${mapX[key].toString().length} ... ${mapY[key].toString().length}');
          }
        });
        equalityTestResult = mapEquals(value, mapB[key]);
      } else {
        print('value is not list or map for key $key');
        equalityTestResult = value == mapB[key];
      }

      if (!equalityTestResult) {
        differentValues.add(key);
      }
    }
  });

  print('keysExclusiveToA: $keysExclusiveToA\n\n');
  print('keysExclusiveToB: $keysExclusiveToB\n\n');
  for (var key in differentValues) {
    print('differentValues for $key. mapA: ${mapA[key]} mapB: ${mapB[key]}\n\n');
  }

  return keysExclusiveToA.isEmpty && keysExclusiveToB.isEmpty && differentValues.isEmpty;
}