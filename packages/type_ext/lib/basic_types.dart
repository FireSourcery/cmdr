/// Mixin for methods
/// Instantiate temporary object for type checking
// TypeCarrier, TypeHost, TypeKey
mixin class TypeKey<T> {
  const TypeKey();

  Type get type => T;
  bool isSubtype<S>() => this is TypeKey<S>;
  bool isSupertype<S>() => TypeKey<S>() is TypeKey<T>;
  bool isExactType<S>() => S == T;
  bool get isNullable => null is T;

  bool compareType(Object? object) => object is T;

  // call passing type
  R call<R>(R Function<G>() callback) => callback<T>();
  // callGeneric, callTyped
  R callWithType<R>(R Function<G>() callback) => callback<T>();
  // R callAsKey<R>(R Function<G>(TypeKey key) callback) => callback<T>(this);
}

// workaround for calling generic methods with type restrictions
mixin class TypeRestrictedKey<T extends S, S> {
  const TypeRestrictedKey();
  R callWithRestrictedType<R>(R Function<G extends S>() callback) => callback<T>();
}

/// Union of generic types
// A primitive union type key
// boundary depending on type
// DataKey
abstract mixin class UnionValueKey<V> implements TypeKey<V> {
  const UnionValueKey();

  List<Enum>? get valueEnumRange; // EnumSubtype.values must be non-null for Enum types
  // Iterable<V>? get valueRange;
  // Limits as the values the num can take, compare with >= and <=
  ({num min, num max})? get valueNumLimits; // must be null for non-num types
  V? get valueDefault;

  V get value;
  set value(V newValue);

  // num get valueAsNum;

  // set valueAsNum(num newValue) {
  //   // assert(V == int || V == double, 'Only num types are supported');
  //   if (valueNumLimits != null) {
  //     value = newValue.clamp(valueNumLimits!.min, valueNumLimits!.max) as V;
  //   }
  // }

  // set valueAsEnum(Enum newValue) {
  //   if (valueEnumRange != null) {
  //     if (valueEnumRange!.contains(newValue)) value = newValue as V;
  //   }
  // }

  // move check limits here
}

typedef NumRange = ({num min, num max});
typedef EnumRange = List<Enum>;

// ServiceKey for retrieving data of dynamic type from external source and casting
// IdKey, EntityKey, DataKey, FieldKey, VarKey,
// abstract mixin class ServiceKey<K, V> implements UnionValueKey<V> {
//   // VarKey
//   K get key;
//   String get label;
//   // Stringifier? get valueStringifier;

//   // a serviceKey can directly access the value with a provided reference to service
//   // ServiceIO? get service;
//   // V? get value => service?.get(keyValue);
//   // alternatively as V always return a cached value
//   V? get value;
//   set value(V? newValue);

//   Future<V?> loadValue();
//   Future<bool> updateValue(V value);
//   String get valueString;

//   void setValueAsNum(num newValue) {
//     if (valueNumLimits != null) {
//       // assert(V == int || V == double, 'Only num types are supported');
//       value = newValue.clamp(valueNumLimits!.min, valueNumLimits!.max) as V;
//     }
//   }

//   void setValueAsEnum(Enum newValue) {
//     if (valueEnumRange != null) {
//       value = valueEnumRange!.contains(newValue) ? newValue as V : valueDefault;
//     }
//   }

//   // Type get type;
//   // TypeKey<V> get valueType => TypeKey<V>();
// }

/// a type of status where non-zero is an error
/// todo with enum factory
// does not implement Enum, as it can be a union of Enums
abstract mixin class Status implements Exception {
  int get code;
  String get message;
  bool get isSuccess => code == 0;
  bool get isError => code != 0;
  Enum get enumId;
}

/// [PropertyFilter]
// encapsulated for selection
// implements Enum for List
// PropertyOf<T>
abstract mixin class PropertyFilter<T> {
  const PropertyFilter();

  ValueTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);
  Iterable<T> Function(Iterable<T> input) get asIterableFilter => call;
}

typedef ValueTest<T> = bool Function(T input);

extension WhereFilter<T> on Iterable<T> {
  Iterable<T> filter(Iterable<T> Function(Iterable<T> input)? filter) => filter?.call(this) ?? this;
  Iterable<T> havingProperty(PropertyFilter<T>? property) => property?.call(this) ?? this;
  // Iterable<T> havingTyped<P extends PropertyFilter<T>>(Iterable<List<PropertyFilter<T>>> allProperties, P filter) {
  Iterable<T> havingTyped<P extends PropertyFilter<T>>(Iterable<List<PropertyFilter<T>>> allProperties) {
    return allProperties.whereType<List<P>>().whereType<P>().singleOrNull?.call(this) ?? this;
  }
}

/// [Stringifier]
///
typedef Stringifier<T> = String Function(T input);
typedef GenericStringifier = String Function<T>(T input);
// typedef Stringifier<T> = String Function(T? input);
// typedef GenericStringifier = String Function<T>(T? input);
typedef NullableStringifier<T> = String Function(T? input); // defining non-nullable type allows null input, cases where T is used for selection

/// [Slicer]
abstract mixin class Sliceable<T extends Sliceable<dynamic>> {
  // int get start => 0;
  int get totalLength;
  T slice(int start, int end);

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < totalLength; index += sliceLength) {
      yield slice(index, (totalLength - index).clamp(0, totalLength));
    }
  }
}

class Slicer<T> {
  const Slicer(this.slicer, this.length);
  final T Function(int start, int end) slicer;
  final int length;
  // final int start;

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < length; index += sliceLength) {
      yield slicer(index, (length - index).clamp(0, length));
    }
  }
}

// naming convention notes
// For classes and types -
// Module/Most descriptive noun first, then adjective descriptions
// this way Aligns characters
// allows the first word to be the module/group name
// unlike objects types are not called with dot notation, so placing the most descriptive noun last is less meaningful
