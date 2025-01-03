import 'dart:collection';

import 'basic_types.dart';

extension CallOnNullAsNull on Function {
  // callIfNotNull
  // R? callOrNull<T, R>(T? arg) => switch (arg) { T value => this(value), null => null };
  R? callOrNull<R>(Object? input, [R Function()? onNull]) => (input != null) ? this(input) : null;
}

extension IsThen<T extends Object?> on T? {
  /// Executes the given function if the value is non-null.
  ///
  /// This method allows you to perform an operation on a value only if it is non-null.
  ///
  /// Example:
  /// ```dart
  /// int? value = 42;
  /// value.ifNonNull((v) => print(v)); // Prints: 42
  /// ```
  ///
  // analogous to synchronous Future.then
  R? ifNonNull<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) { T value => fn(value), null => onNull?.call() };
  R? ifNull<R>(R Function() fn) => (this == null) ? fn() : null;
  bool isAnd(ValueTest test) => switch (this) { T value => test(value), null => false };
}

extension NumTo on num {
  R to<R extends num>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), const (num) => this, _ => throw StateError(' ') } as R;
}

extension TrimString on String {
  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

extension IterableIntExtensions on Iterable<int> {
  /// Match a sequence of integers in the iterable
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
}

extension RecordSlices<T extends Record> on T {
  Iterable<T> slices(T Function(int start, int end) slicer, int totalLength, int sliceLength) => Slicer(slicer, totalLength).slices(sliceLength);
}

extension MapExt<K, V extends Object> on Map<K, V> {
  Iterable<V> eachOf(Iterable<K> keys) => keys.map<V?>((e) => this[e]).nonNulls;
  Iterable<V> having(PropertyFilter<K>? property) => eachOf(keys.havingProperty(property));
}

extension ReverseMap<T> on Iterable<T> {
  Map<V, T> asReverseMap<V>(V Function(T) mappedValueOf) {
    return Map.unmodifiable(<V, T>{for (var value in this) mappedValueOf(value): value});
  }
}
