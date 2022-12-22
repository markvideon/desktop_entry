import 'dart:core';

class MapComparison {
  MapComparison(Map<String, dynamic> mapA, Map<String, dynamic> mapB) {
    _keysExclusiveToA = mapA.keys
        .where((key) => !mapB.containsKey(key))
        .toList(growable: false);
    _keysExclusiveToA = mapB.keys
        .where((key) => !mapA.containsKey(key))
        .toList(growable: false);

    final differentValues = <String>[];
    mapA.forEach((key, value) {
      if (mapB.containsKey(key) && value != mapB[key]) {
        _differentValues.add(key);
      }
    });
    _differentValues = differentValues.toList(growable: false);
  }

  late final List<String> _keysExclusiveToA;
  late final List<String> _keysExclusiveToB;
  late final List<String> _differentValues;

  List<String> get keysExclusiveToA => _keysExclusiveToA;
  List<String> get keysExclusiveToB => _keysExclusiveToB;
  List<String> get differentValues => _differentValues;

  @override
  toString() {
    return 'MapComparison{ '
        'keysExclusiveToA: $_keysExclusiveToA, '
        'keysExclusiveToB: $_keysExclusiveToB, '
        'differentValues: $_differentValues '
        '}';
  }
}
