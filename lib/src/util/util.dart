import 'dart:developer';
import 'dart:io' show Process, ProcessResult;
import 'package:collection/collection.dart';

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
        final mapX = value;
        final mapY = mapB[key] as Map;

        mapX.forEach((key, value) {
          if (mapX[key] != mapY[key]) {
            print('mapX[$key] != mapY[$key]. ${value} != ${value}');
            print(mapX[key]?.elementConstructor() == mapY[key]?.elementConstructor());
          }
        });
        print('Map hashcodes: ${value.hashCode}, ${mapB.hashCode}');
        equalityTestResult = const MapEquality().equals(value, mapB[key]);
      } else {
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