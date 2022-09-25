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

MapEntry<String, dynamic>? parseLine(String line) {
  String effectiveLine = line.trim();

  final equalsIdx = effectiveLine.indexOf('=');
  if (equalsIdx.isNegative) {
    return null;
  }

  final value = effectiveLine.substring(equalsIdx + 1);
  if (value.isEmpty) {
    return null;
  }
  final key = effectiveLine.substring(0, equalsIdx).trim();

  final effectiveValue = parseRow(value, ';');

  // Note that fields that support multiple values contain `;` even when only
  // one value is specified.
  return MapEntry(key, value.contains(';') ? effectiveValue : effectiveValue.first);
}