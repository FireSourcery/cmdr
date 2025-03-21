import 'package:meta/meta.dart';

import 'package:type_ext/index_map.dart';
import 'package:type_ext/struct.dart';
import 'package:type_ext/basic_ext.dart';

import 'bit_field.dart';
export 'bit_field.dart';
import 'bits_map.dart';
export 'bits_map.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] with key access
/// [] Map operators, returning [int]
///
/// [BitStruct] Interface for extending with Subtypes
///   cannot be built directly, extend with Keys or use [BitConstruct]
///   Struct must be extended with Keys
///   Partial Map implementation with [Bits] as source
///
/// [BitsMap] - a version of Map with [Bits] as source. Does not need to be extended in most cases
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitStruct<K extends BitField> implements BitsBase, BitsMap<K, int> {
  // defined by child class
  List<K> get keys;
  Bits get bits;
  set bits(Bits value);

  @override
  int get width => keys.bitmasks.totalWidth;

  // Map operators
  int operator [](covariant K key);
  void operator []=(covariant K key, int value);
  // Map operators
  void clear();
  int remove(K key);

  // Unconstrained type keys
  @protected
  int get(BitField key) => bits.getBits(key.bitmask);
  @protected
  void set(BitField key, int value) => setBits(key.bitmask, value);
  @protected
  bool testBounds(BitField key) => key.bitmask.shift + key.bitmask.width <= width;
  @protected
  int? getOrNull(BitField key) => testBounds(key) ? bits.getBits(key.bitmask) : null;
  @protected
  bool setOrNot(BitField key, int value) {
    if (testBounds(key)) {
      bits = bits.withBits(key.bitmask, value);
      return true;
    }
    return false;
  }

  int field(K key) => get(key);
  void setField(K key, int value) => set(key, value);
  int? fieldOrNull(K key) => getOrNull(key);
  bool setFieldOrNot(K key, int value) => setOrNot(key, value);

  Iterable<({K key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: (this[e] != 0)));
  Iterable<({K key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e]));

  BitStruct<K> copyWithBits(Bits value) => BitConstruct<BitStruct<K>, K>(keys, value);
  // @override
  // BitStruct<K> copyWith() => copyWithBits(bits);

  @override
  BitStruct<K> withField(K key, int value) => copyWithBits(bits.withBits(key.bitmask, value));
  @override
  BitStruct<K> withEntries(Iterable<MapEntry<K, int>> entries) => copyWithBits(bits.withEach(entries.map((e) => (e.key.bitmask, e.value))));
  @override
  BitStruct<K> withMap(Map<K, int> map) => withEntries(map.entries);

  @override
  String toString() => toStringAsMap();

  String toStringAsMap() => MapBase.mapToString(this); // {key: value, key: value}
  String toStringAsValues() => values.toString(); // (0, 0, 0)

  // String toStringAs(String Function(MapEntry<K, int> entry) stringifier) => entries.fold('', (previousValue, element) => previousValue + stringifier(element));

  // MapEntry<String, int> toMapEntry() => MapEntry<String, int>(runtimeType.toString(), bits); // {name: value}
}

////////////////////////////////////////////////////////////////////////////////
/// Struct abstract keys
/// extendable, with Enum.values
////////////////////////////////////////////////////////////////////////////////
// abstract class BitStructBase<K extends BitField> extends BitsBase with MapBase<K, int>, BitFieldMap<K>, BitStruct<K> {
//   BitStructBase(Bits bits);
//   BitStructBase.castInitializer(Map<K, int> initializer) : this(Bits.ofEntries(initializer.bitsEntries));
//   BitStructBase.castBase(Bits bits);
// }

abstract class MutableBitStruct<K extends BitField> extends MutableBits with MapBase<K, int>, BitFieldMap<K>, BitStruct<K> {
  MutableBitStruct([super.bits]);
  MutableBitStruct.castInitializer(Map<K, int> initializer) : super(Bits.ofEntries(initializer.bitsEntries));
  MutableBitStruct.castBase(super.bits) : super.castBase();
}

abstract class ConstBitStruct<K extends BitField> extends ConstBits with MapBase<K, int>, BitFieldMap<K>, BitStruct<K> {
  const ConstBitStruct(super.bits);
  ConstBitStruct.castInitializer(Map<K, int> initializer) : super(Bits.ofEntries(initializer.bitsEntries));
  ConstBitStruct.castBase(super.bits) : super.castBase();
}

/// Subtype considerations:
/// to return a subtype of [BitStruct], :
///   provide the constructor of the subtype
///   use a prototype object .copyWithBits()
mixin BitStructAsSubtype<S extends BitStruct<K>, K extends BitField> on BitStruct<K> {
  // S copyWith();
  @mustBeOverridden
  S copyWithBits(Bits value);

  @override
  S withField(K key, int value) => super.withField(key, value) as S;
  @override
  S withEntries(Iterable<MapEntry<K, int>> entries) => super.withEntries(entries) as S;
  @override
  S withMap(Map<K, int> map) => super.withMap(map) as S;
}

////////////////////////////////////////////////////////////////////////////////
/// Wrapper with all interfaces
////////////////////////////////////////////////////////////////////////////////
class BitConstruct<S extends BitStruct<K>, K extends BitField> extends ConstBitStruct<K> implements BitStruct<K> {
  const BitConstruct(this.keys, super.bits);

  BitConstruct.initWith(this.keys, Map<K, int> initializer) : super(initializer.bits);

  BitConstruct.castBase(BitStruct<K> super.struct)
      : keys = struct.keys,
        super.castBase();

  // const BitConstruct.typed({this.keys, S Function(value) constructor = BitConstruct.generic, super.bits});
  // BitConstruct.generic(bitsKeys ?? const <BitField>[], value as Bits);
  // const BitConstruct.generic(super.bits) : keys = const [];

  @override
  final List<K> keys;
  // final S Function(Bits) constructor;
  // S constructor(Bits bits) => BitConstruct<S, K>(keys, bits);

  // final S struct;

  @override
  BitStruct<K> copyWithBits(Bits value) => BitConstruct<BitStruct<K>, K>(keys, value);
  @override
  BitConstruct<S, K> copyWith() => BitConstruct<S, K>(keys, bits);

  // @override
  // BitConstruct<S, K> withField(K key, int value);
  // @override
  // BitConstruct<S, K> withEntries(Iterable<MapEntry<K, int>> entries) =>
  // @override
  // BitConstruct<S, K> withAll(Map<K, int> map) =>
}

// or equivalently
// Keys list effectively define type and act as factory
// Separates subtype `class variables` from instance
// extension type const BitStructClass<S extends BitStruct, T extends BitField>(List<T> keys) { as subtype
// extension type const BitStructClass<T extends BitField>(List<T> keys) {
//   // BitStruct<T> castBase(BitsBase base) {
//   //   return switch (base) {
//   //     MutableBitFieldsBase() => MutableBitStructWithKeys(keys, base.bits),
//   //     ConstBitFieldsBase() => ConstBitStructWithKeys(keys, base.bits),
//   //     BitsBase() => throw StateError(''),
//   //   };
//   // }

//   // BitStruct<T> castBits(int value) => ConstBitStructWithKeys(keys, Bits(value));

//   // alternatively default constructors can return partial implementation without Keys/MapOperator
//   BitStruct<T> create([int value = 0, bool mutable = true]) {
//     return switch (mutable) {
//       true => MutableBitStructWithKeys(keys, Bits(value)),
//       false => ConstBitStructWithKeys(keys, Bits(value)),
//     };
//   }

//   // Alternatively subclass directly call Bits constructors to derive Bits value
//   // enum map by default copies into an array
//   BitStruct<T> fromValues(Iterable<int> values, [bool mutable = true]) {
//     return create(Bits.ofIterables(keys.bitmasks, values), mutable);
//   }

//   BitStruct<T> fromMap(Map<T, int> map, [bool mutable = true]) {
//     return create(Bits.ofEntries(map.bitsEntries), mutable);
//   }
// }

/// can be implemented on Enum to give each const Bits an Enum Id and String name
/// optionally use BitsInitializer to simplfiy compile time const
abstract mixin class EnumBits<K extends BitField> implements Enum {
  // per instance
  BitsInitializer<K> get initializer; // define as const using initializer
  Bits get bits => initializer.bits;
  // Bits get bits;

  // or build lookup map

  List<K> get keys; // per class
  // List<K> get bitFields; // per class
  BitStruct<K> asBitStruct() => BitConstruct<BitStruct<K>, K>(keys, bits);
}
