import 'dart:developer';
import 'package:collection/collection.dart';

bool stringToBool(String candidate) {
  return candidate.trim().toLowerCase() == 'true';
}

List<String> extractContents(String input, String startChar, String endChar) {
  final regExp = RegExp(r'\' + startChar + r'(.*?)' + r'\' + endChar);

  final matches = regExp.allMatches(input)
      .map((result) => input.substring(result.start + 1, result.end - 1))
      .toList(growable: false);

  return matches;
}

bool compareMaps(Map<String, dynamic> mapA, Map<String, dynamic> mapB) {
  List<String> keysExclusiveToA = mapA.keys.where((key) => !mapB.containsKey(key)).toList(growable: false);
  List<String> keysExclusiveToB = mapB.keys.where((key) => !mapA.containsKey(key)).toList(growable: false);
  List<String> differentValues = <String>[];

  mapA.forEach((key, value) {
    bool equalityTestResult = true;

    if (mapB.containsKey(key)) {
      if (value is List) {
        equalityTestResult = const ListEquality().equals(value, mapB[key]);
      } else if (value is Map) {
        equalityTestResult = const MapEquality().equals(value, mapB[key]);
      } else {
        equalityTestResult = value == mapB[key];
      }

      if (!equalityTestResult) {
        differentValues.add(key);
      }
    }
  });

  log('keysExclusiveToA: $keysExclusiveToA');
  log('keysExclusiveToB: $keysExclusiveToB');
  for (var key in differentValues) {
    log('differentValues for $key. mapA: ${mapA[key]} mapB: ${mapB[key]}');
  }

  return keysExclusiveToA.isEmpty && keysExclusiveToB.isEmpty && differentValues.isEmpty;
}