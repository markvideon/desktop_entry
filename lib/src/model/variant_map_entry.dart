class VariantMapEntry<T> {
  VariantMapEntry(this.key, this.value, {this.modifier});

  final String key;
  final String? modifier;
  final T value;
}
