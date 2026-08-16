/// Returns structural equality for the small immutable collections used by the domain.
bool deepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is List<Object?> && right is List<Object?>) {
    if (left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (!deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Set<Object?> && right is Set<Object?>) {
    return left.length == right.length && left.every(right.contains);
  }
  if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
    if (left.length != right.length) return false;
    for (final MapEntry<Object?, Object?> entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}

/// Creates a stable-enough structural hash for immutable domain values.
int deepHash(Object? value) {
  if (value is List<Object?>) {
    return Object.hashAll(value.map(deepHash));
  }
  if (value is Set<Object?>) {
    return Object.hashAllUnordered(value.map(deepHash));
  }
  if (value is Map<Object?, Object?>) {
    return Object.hashAllUnordered(
      value.entries.map(
        (MapEntry<Object?, Object?> entry) =>
            Object.hash(deepHash(entry.key), deepHash(entry.value)),
      ),
    );
  }
  return value.hashCode;
}

/// Returns a defensive, unmodifiable list copy.
List<T> immutableList<T>(Iterable<T> values) => List<T>.unmodifiable(values);

/// Returns a defensive, unmodifiable set copy.
Set<T> immutableSet<T>(Iterable<T> values) => Set<T>.unmodifiable(values);

/// Returns a defensive, unmodifiable map copy.
Map<K, V> immutableMap<K, V>(Map<K, V> values) =>
    Map<K, V>.unmodifiable(values);
