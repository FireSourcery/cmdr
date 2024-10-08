import 'package:cmdr/binary_data/typed_data_ext.dart';

import 'typed_field.dart';

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
// typedef StructConstructor<T> = T Function([TypedData typedData]);
typedef ByteStructCaster<T> = T Function(TypedData typedData);
typedef ByteStructCreator<T> = T Function([TypedData typedData]);

// packet without header/payload context

// effectively TypedData, with a constructor
// cannot extended TypedData, need to add constructor to extension on TypedData
// not a mixin to pass parent constructors, on non ffi.Struct type
class ByteStructBase {
  const ByteStructBase._(this.bytes);
  ByteStructBase(TypedData bytes, [int offset = 0, int? length]) : bytes = Uint8List.sublistView(bytes, offset, length);
  ByteStructBase.origin(ByteBuffer bytesBuffer, [int offset = 0, int? length]) : bytes = Uint8List.view(bytesBuffer, offset, length ?? bytesBuffer.lengthInBytes - offset);

  final Uint8List bytes;

  int get length => bytes.length;

  // wrapping TypedData extensions... this class is still needed to enforce constructor type

  Uint8List range(int offset, [int? length]) => Uint8List.sublistView(bytes, offset, length);
  TypedData rangeAs<T extends TypedData>(int offset, [int? length]) => bytes.asTypedList<T>(offset, length);
  List<int> rangeAsIntList<T extends TypedData>(int byteOffset) => bytes.asIntList<T>(byteOffset);

  // field names need code gen
  ByteData get byteData => ByteData.sublistView(bytes);

  int? fieldValue<V extends NativeType>(int offset) => byteData.wordAt<V>(offset);
  void setFieldValue<V extends NativeType>(int offset, int value) => byteData.setWordAt<V>(offset, value);
  int? fieldValueOrNull<V extends NativeType>(int offset) => byteData.wordOrNullAt<V>(offset);

  // operator [] (TypedField<T> field)=> field.callTyped();

  // dynamic setAs<T extends ByteStructBase, V>(ByteStructCaster<T> caster, V values) => caster(bytes).build(values, this);
  // V getAs<R extends ByteStructBase, V>(ByteStructCaster<R> caster, [dynamic  stateMeta]) => caster(bytes).parse(this, stateMeta);
}

// extension type const Bytes._(TypedData bytes) implements TypedData {
//   // const ByteStruct._(this.bytes);
//   Bytes(TypedData bytes, [int offset = 0, int? length]) : bytes = Uint8List.sublistView(bytes, offset, length);
//   Bytes.origin(ByteBuffer bytesBuffer, [int offset = 0, int? length]) : bytes = Uint8List.view(bytesBuffer, offset, length ?? bytesBuffer.lengthInBytes - offset);

//   // final Uint8List bytes;
//   int get length => bytes.lengthInBytes;

//   // wrapping TypedData extensions... this class is still needed to enforce constructor type
//   Uint8List range(int offset, [int? length]) => Uint8List.sublistView(bytes, offset, length);
//   TypedData rangeAs<T extends TypedData>(int offset, [int? length]) => bytes.asTypedList<T>(offset, length);
//   List<int> rangeAsIntList<T extends TypedData>(int byteOffset) => bytes.asIntList<T>(byteOffset);

//   // field names need code gen
//   ByteData get byteData => ByteData.sublistView(bytes);

//   int? fieldValue<V extends NativeType>(int offset) => byteData.wordAt<V>(offset);
//   void setFieldValue<V extends NativeType>(int offset, int value) => byteData.setWordAt<V>(offset, value);
//   int? fieldValueOrNull<V extends NativeType>(int offset) => byteData.wordOrNullAt<V>(offset);

//   // dynamic setAs<T extends ByteStructBase, V>(ByteStructCaster<T> caster, V values) => caster(bytes).build(values, this);
//   // V getAs<R extends ByteStructBase, V>(ByteStructCaster<R> caster, [dynamic  stateMeta]) => caster(bytes).parse(this, stateMeta);
// }

// Abstract Factory
abstract interface class ByteStructInterface {
  int get lengthMax;
  // Endian get endian;
  ByteStructBase cast(TypedData typedData);
}

/// update with packet
// abstract mixin class ByteStructMutable<T> {
//   late Uint8List _bytes;
//   late T _struct;

//   Uint8List get bytes => _bytes;
//   @protected
//   set bytes(Uint8List value) => _bytes = value;

//   // Uint8List get _byteBuffer; //alternatively use length value
//   set length(int value) => bytes = Uint8List.view(bytes.buffer, bytes.offsetInBytes, value);
// }

// // wrapper around ffi.Struct or  extend ByteStructBase
// class ByteStructBuffer<T> with ByteStructMutable {
//   // ByteStruct._(this._struct, this.bytes) : bytes = _struct.asTypedList;
//   // ByteStruct(StructConstructor<T> structConstructor) : this._(structConstructor());
//   ByteStructBuffer._(this._struct, this._byteBuffer) : _bytes = _byteBuffer;
//   ByteStructBuffer(StructConstructor<T> structConstructor, Uint8List buffer) : this._(structConstructor(buffer), buffer);
//   ByteStructBuffer.size(StructConstructor<T> structConstructor, int size) : this(structConstructor, Uint8List(size));

//   final Uint8List _byteBuffer; // internal buffer of known struct size
//   final T _struct; // holds full view, max length buffer, with named fields
//   Uint8List _bytes; // holds truncated view, mutable length

//   // @override
//   // Uint8List get bytes => _bytes;

//   // @override
//   // @protected
//   // set bytes(Uint8List value) => _bytes = value;
//   T get struct => _struct; // struct view is always full length, including out of set view range

//   // update view length via new view
//   // Uint8List.`view` on buffer to exceed struct view length. sublistView will not exceed current length
//   int get length => bytes.length;
//   set length(int totalLength) => _bytes = Uint8List.view(bytes.buffer, bytes.offsetInBytes, totalLength);

//   void clear() => length = 0;

//   void copyBytes(Uint8List dataIn) {
//     assert(dataIn.length <= bytes.buffer.lengthInBytes - bytes.offsetInBytes); // minus offset if view does not start at buffer 0, in inheritance case
//     length = dataIn.length;
//     bytes.setAll(0, dataIn);
//   }

//   void addBytes(Uint8List dataIn) {
//     // assert(dataIn.length <= bytes.buffer.lengthInBytes - bytes.offsetInBytes); // minus offset if view does not start at buffer 0, in inheritance case
//     final currentLength = bytes.length;
//     length = currentLength + dataIn.length;
//     bytes.setAll(currentLength, dataIn);
//   }
// }
