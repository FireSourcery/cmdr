import 'package:meta/meta.dart';

import 'enum_map.dart';
import 'index_map.dart';
export 'enum_map.dart';
export 'index_map.dart';

/// [StructView]
/// Similar to a [Map]
///   fixed set of keys
///   getOrNull/setOrNot
///
///
/// interface and implementation
///
// extension type cannot include abstract methods, or implement interfaces
// cannot define copyWith without context of Keys
extension type StructView<K extends Field, V>(Object _this) {
  @protected
  V get(Field key) => key.getIn(_this); // valueOf(Field key);
  @protected
  void set(Field key, V value) => key.setIn(_this, value);

  @protected
  bool testBounds(Field key) => key.testBoundsOf(_this);

  @protected
  V? getOrNull(Field key) => testBounds(key) ? get(key) : null;
  @protected
  bool setOrNot(Field key, V value) {
    if (testBounds(key)) {
      set(key, value);
      return true;
    }
    return false;
  }

  V operator [](K key) => get(key);
  void operator []=(K key, V value) => set(key, value);

  // `field` referring to the field value
  V field(K key) => get(key);
  void setField(K key, V value) => set(key, value);
  V? fieldOrNull(K key) => getOrNull(key);
  bool setFieldOrNot(K key, V value) => setOrNot(key, value);

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: field(key));

  Iterable<V> fieldValues(Iterable<K> keys) => keys.map((key) => field(key));
  Iterable<FieldEntry<K, V>> fieldEntries(Iterable<K> keys) => keys.map((key) => fieldEntry(key));

  // Construct< K, V> withKeys(List<K> keys) => Construct< K, V>(struct: this, keys: keys);
  Construct<K, V> asConstruct(List<K> keys, {dynamic meta}) => Construct<K, V>(structData: this, keys: keys);

  //  copy operations need context of keys
  // @protected
  // StructView<T, V> newWith(  Field key, V value);
}

//
extension type MapStruct<K extends Field, V>(FixedMap<K, V> _this) implements StructView<K, V> {
  MapStruct.cast(List<K> keys, StructView<K, V> struct) : _this = IndexMap.of(keys, struct.fieldValues(keys));
  // MapStruct.of(List<K> keys, Iterable<V> values) : _this = IndexMap.of(keys, values);

  @protected
  V get(Field key) => _this[key as K]; // valueOf(Field key); // by map[index]
  @protected
  void set(Field key, V value) => _this[key as K] = value;

  // V? getOrNull(Field key);
  // bool setOrNot(Field key, V value);

  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance
  StructView<K, V> withField(K key, V value) => (ProxyIndexMap<K, V>(_this)..[key] = value) as StructView<K, V>;
  //
  StructView<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => (ProxyIndexMap<K, V>(_this)..addEntries(newEntries)) as StructView<K, V>;
  // A general values map representing external input, may be a partial map
  StructView<K, V> withAll(Map<K, V> map) => (ProxyIndexMap<K, V>(_this)..addAll(map)) as StructView<K, V>;
}

// abstract mixin class StructView<K extends Field<V>, V> {}

/// [Field] - key to a value in a [StructView], with type
/// define accessors on the struct within key, to keep type withing local scope
/// although implementation of operators may be preferable in the containing class
/// with full context of relationships between fields
/// the key maintains scope of V

/// may implement on enum
///
/// effectively allows StructView to be abstract
abstract mixin class Field<V> {
  int get index;

  @protected
  V getIn(covariant Object struct); // valueOf(covariant Object struct);
  @protected
  void setIn(covariant Object struct, V value);

  // not yet replaceable
  // @protected
  bool testBoundsOf(covariant Object struct);

  @protected
  V? getInOrNull(covariant Object struct) {
    return testBoundsOf(struct) ? getIn(struct) : null;
  }

  @protected
  bool setInOrNot(covariant Object struct, V value) {
    if (testBoundsOf(struct)) {
      setIn(struct, value);
      return true;
    }
    return false;
  }

  V? get defaultValue => null; // allows additional handling of Map<K, V?>
}

typedef FieldEntry<K, V> = ({K key, V value});

abstract interface class EnumField<V> implements Enum, Field<V> {}

/// [Construct]
// handler with class variables,
// struct view with Map and handler
//
// potentially implement the map interface directly
//  - Map interface
//    - Enum keys auto implement EnumMap and
//  - Factory
//  - StructView interface
//  - withX copy methods
// class Construct<T extends StructView<K, V>, K extends Field<V>, V> with MapBase<K, V>, TypedMap<K, V> {
class Construct<K extends Field, V> with MapBase<K, V>, FixedMap<K, V> {
  Construct({
    required this.structData,
    required this.keys,
    // required this.lengthMax,
  });

  // a signature for user override
  // Construct.castBase(Construct<K, V> base) : this(struct: base, keys: const []);

  Construct.castBase(FixedMap<K, V> base)
      : this(
          structData: MapStruct(base),
          keys: base.keys,
        );

  // factory Construct.fromJson(List<K> keys, Map<String, Object?> json) {
  //   // if (keys is List<EnumField<V>>) {
  //   //   return Construct<K, V>(
  //   //     keys: keys,
  //   //     struct: MapStruct(EnumMap<K, V>.fromJson(keys, json)),
  //   //   );
  //   // }
  //   // throw UnsupportedError('Only EnumField is supported');
  // }

  // Construct.fromEntries

  final List<K> keys;
  final StructView<K, V> structData; // or object
  // final T Function(StructView) caster;
  // final T Function( ) constructor;
  // final int lengthMax;

  @override
  String toString() => MapBase.mapToString(this);

  @override
  void operator []=(K key, V value) => structData[key] = value;
  @override
  V operator [](K key) => structData[key];

  @override
  void clear() {
    throw UnimplementedError();
  }

  @override
  V remove(K key) {
    throw UnimplementedError();
  }

  Iterable<FieldEntry<K, V>> get fieldEntries => keys.map((e) => (key: e, value: this[e]));

  // analogous to operator []=, but returns a new instance
  Construct<K, V> withField(K key, V value) => Construct<K, V>.castBase(ProxyIndexMap<K, V>(this)..[key] = value);
  //
  Construct<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => Construct<K, V>.castBase(ProxyIndexMap<K, V>(this)..addEntries(newEntries));
  // A general values map representing external input, may be a partial map
  Construct<K, V> withAll(Map<K, V> map) => Construct<K, V>.castBase(ProxyIndexMap<K, V>(this)..addAll(map));

  // Map<K, V> toMap() {
  //   assert(keys.first.index == keys.first.index); // ensure if index does not throw
  //   return IndexMap.of(keys, keys.map((key) => key.getIn(struct._this)));
  // }
}

mixin ConstructAsSubtype<S extends Construct<K, V>, K extends Field<V>, V> on Construct<K, V> {
  // Overridden the in child class
  //  calls the child class constructor
  //  return an instance of the child class type
  //  passing empty parameters always copies all values
  @override
  @mustBeOverridden
  S copyWith();

  @override
  S withField(K key, V value) => (super.withField(key, value) as ConstructAsSubtype<S, K, V>).copyWith();
  @override
  S withEntries(Iterable<MapEntry<K, V>> entries) => (super.withEntries(entries) as ConstructAsSubtype<S, K, V>).copyWith();
  @override
  S withAll(Map<K, V> map) => (super.withAll(map) as ConstructAsSubtype<S, K, V>).copyWith();
}