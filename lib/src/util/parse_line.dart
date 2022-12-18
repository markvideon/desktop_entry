import '../model/variant_map_entry.dart';

List<String> parseRow(String input, String delimiter) {
  final nonEscapedMatches = delimiter.allMatches(input)
      .where((match) => input[match.start - 1] != r'\');

  List<String> parts = [];

  if (nonEscapedMatches.isEmpty) {
    return [input];
  } else {
    StringBuffer candidate = StringBuffer();
    candidate.write(input.substring(0, nonEscapedMatches.first.start));

    if (candidate.toString().isNotEmpty) {
      parts.add(candidate.toString());
      candidate.clear();
    }

    for (int i = 1; i < nonEscapedMatches.length; i++) {
      candidate.write(input.substring(nonEscapedMatches.elementAt(i-1).end, nonEscapedMatches.elementAt(i).start));
      if (candidate.toString().isNotEmpty) {
        parts.add(candidate.toString());
        candidate.clear();
      }
    }

    candidate.write(input.substring(nonEscapedMatches.last.end));
    if (candidate.toString().isNotEmpty) {
      parts.add(candidate.toString());
      candidate.clear();
    }

  }

  return parts;
}

// The good one!
final _parseKeyValueRegExp = RegExp(r'^([\w-]+)\[?([\w\d\s@*-]+)?\]?=(.*)$');

VariantMapEntry<dynamic>? parseLine(String line) {
  String effectiveLine = line.trim();
  final match = _parseKeyValueRegExp.firstMatch(effectiveLine);

  if (match == null || match.group(1) == null || match.group(3) == null) {
    return null;
  }

  final possibleMultipleValues = parseRow(match.group(3)!, ';');

  return VariantMapEntry(
      match.group(1)!,
      possibleMultipleValues.length == 1 ?
      possibleMultipleValues.first :
      possibleMultipleValues,
    modifier: match.group(2)
  );
}