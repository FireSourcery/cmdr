import 'dart:ffi';
import 'dart:typed_data';

import 'byte_struct.dart';

/// Effectively ByteData with a length of 8 bytes.
/// can be compile time constant
class Word {
  const Word(this.value);
  // assign with parameters in little endian order for byteLength
  const Word.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
      : this.of16s((lsb1 << 8) | (lsb & _mask8), (lsb3 << 8) | (lsb2 & _mask8), (msb2 << 8) | (msb3 & _mask8), (msb << 8) | (msb1 & _mask8));
  const Word.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0]) : this.of32s((upperLs16 << 16) | (ls16 & _mask16), (ms16 << 16) | (lowerMs16 & _mask16));
  const Word.of32s(int ls32, [int ms32 = 0]) : value = (ms32 << 32) | (ls32 & _mask32);
  const Word.byteSwap(int value) : this.of8s(value >> 56, value >> 48, value >> 40, value >> 32, value >> 24, value >> 16, value >> 8, value);

  const Word.msb32(int msb, int lmsb, int mlsb, int lsb)
      : assert(msb < 256 && lmsb < 256 && mlsb < 256 && lsb < 256),
        value = msb << 24 | lmsb << 16 | mlsb << 8 | lsb;
  // const Word.msb16(int msb,  int lsb)
  // const Word.msb64(int msb,  int lsb)

  // ByteBuffer, at least 8 bytes, in typed data format can skip copying to buffer
  Word.bytes(TypedData bytes, [Endian endian = Endian.little]) : value = bytes.toInt(endian);
  // Word.byteBuffer(ByteBuffer bytes, [int offset = 0, Endian endian = Endian.little]) : value = bytes.toInt(offset, endian);
  // Runes, take first 8 bytes
  Word.chars(Iterable<int> bytes, [Endian endian = _stringEndian]) : value = bytes.toBytes().toInt(endian);
  Word.string(String string) : this.chars(string.runes, _stringEndian);
  Word.cast(Word word) : value = word.value;

  final int value; // Using int as base. this is the only way to allow a const constructor. e.g. use in Enums. not possible with TypedData

  int get byteLength => value.byteLength;
  bool get isSet => (value != 0);

  static const int _mask8 = 0xFF;
  static const int _mask16 = 0xFFFF;
  static const int _mask32 = 0xFFFFFFFF;
  static const Endian _stringEndian = Endian.little; // Must maintain consistency between fromString and toString. Select little endian to simplify discarding remainder

  /// Entity view
  ByteData toByteData([Endian endian = Endian.little]) => value.toByteData(endian);
  // bytes.length always returns 8 from new buffer
  Uint8List toBytes([Endian endian = Endian.little]) => value.toBytes(endian);
  // trimmed view, configurable length. sublist for copy.
  Uint8List toBytesAs(Endian endian, [int? length]) => value.toBytes(endian).trim(length ?? byteLength, endian);
  // Uint8List asBytes([Endian endian = Endian.little]) => toBytes(endian).asUnmodifiableView();

  // auto trim length
  // Uint8List get bytes => toBytes(Endian.little);
  Uint8List get bytesLE => toBytes(Endian.little).trim(byteLength, Endian.little);
  Uint8List get bytesBE => toBytes(Endian.big).trim(byteLength, Endian.big);

  /// Element view
  int valueSizedAt(int offset, int size) => value.valueSizedAt(offset, size);
  int valueTypedAt<T extends NativeType>(int offset) => value.valueTypedAt<T>(offset);

  /// String
  // asString, as encoded, a copy is made but immutable
  Uint8List get _bytesString => toBytes(_stringEndian);
  String get asString => _bytesString.toStringAsEncoded(0, byteLength);

  // toString as description
  @override
  String toString() => _bytesString.toString();

  /// copyWithChar
  int modifyByte(int index, int value, [Endian endian = Endian.little]) => toBytes(endian).modify(index, value).toInt(endian);

  // String inputs as literal of binary value
  String charAsValue(int index, [bool isSigned = false]) => _bytesString.charAsValue(index); // 1 => '1'
  int modifyAsValue(int index, String value) => modifyByte(index, int.parse(value)); // '1' => 1

  String charAsCode(int index) => _bytesString.charAsCode(index); // 0x31 => '1'
  int modifyAsCode(int index, String value) => modifyByte(index, value.runes.single); // '1' => 0x31

  // static (int index, int byteValue) fieldAsValue(int index, String value) => (index, int.parse(value));
  // static (int index, int byteValue) fieldAsCode(int index, String value) => (index, value.runes.single);

  // @override
  // bool operator ==(covariant Word other) {
  //   if (identical(this, other)) return true;
  //   return other.value == value;
  // }

  // @override
  // int get hashCode => value.hashCode;
}

extension BytesOfInt on int {
  // fixed size buffer then wrap view with length likely better performance than iterative build with flex size BytesBuilder
  static ByteData byteDataOf(int value, [Endian endian = Endian.big]) => ByteData(8)..setInt64(0, value, endian);
  // static Uint8List bytesOf(int value, [Endian endian = Endian.big]) => byteDataOf(value, endian).buffer.asUint8List();

  // returns as 8 bytes
  ByteData toByteData([Endian endian = Endian.big]) => byteDataOf(this, endian);
  Uint8List toBytes([Endian endian = Endian.big]) => byteDataOf(this, endian).buffer.asUint8List();

  /// skip ByteData buffer for a known segment
  int valueSizedAt(int offset, int size) => (this >> (offset * 8)) & ((1 << (size * 8)) - 1);
  int valueTypedAt<T extends NativeType>(int offset) => valueSizedAt(offset, sizeOf<T>());
  // Uint8List modify(int index, int value) => Uint8List.sublistView(this)..[index] = value;

  int get byteLength => (bitLength / 8).ceil();

  Word toWord() => Word(this);
}

extension IntOfByteBuffer on ByteBuffer {
  int toInt([int byteOffset = 0, Endian endian = Endian.little]) => asByteData().getInt64(byteOffset, endian);
}

extension IntOfBytes on TypedData {
  // defaults to little endian for an arbitrary list of bytes, assume external
  // big endian will set first item as msb of 64-bits, fill missing bytes with 0
  //   e.g. for a value of 1, big endian, user must input <int>[0, 0, 0, 0, 0, 0, 0, 1], <int>[1] would be treated as 0x0100'0000'0000'0000
  // static int valueOf(TypedData bytes, [Endian endian = Endian.little]) => bytes.buffer.asByteData().getInt64(bytes.offsetInBytes, endian);
  // equivalent to ByteData.sublistView(this).getInt64(0, endian)
  int toInt([Endian endian = Endian.little]) => buffer.asByteData().getInt64(offsetInBytes, endian);

  // following bytesOfInt
  // trimmed view sublist for copy
  // big endian trim leading. little endian trim trailing
  Uint8List trim(int wordLength, Endian endian) => switch (endian) { Endian.big => trimAsBE(wordLength), Endian.little => trimAsLE(wordLength), Endian() => throw UnsupportedError('Endian') };
  // constructing trimAsBE back to Word will change value, as offset has change, alternatively parameterize with size/type
  Uint8List trimAsBE(int wordLength) => Uint8List.sublistView(this, lengthInBytes - wordLength);
  // constructing trimAsLE back to Word preserves value
  Uint8List trimAsLE(int wordLength) => Uint8List.sublistView(this, 0, wordLength);

  Uint8List modify(int index, int value) => Uint8List.sublistView(this)..[index] = value;
}

extension BytesOfIterable on Iterable<int> {
  static Uint8List bytesOf(Iterable<int> bytes, [int? count]) => Uint8List(8)..setAll(0, bytes.take(8));
  Uint8List toBytes([int? length]) => bytesOf(this);
}

extension StringOfBytes on Uint8List {
  String toStringAsEncoded([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
  // String toStringAsEncodedTrimNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  // String toStringAsEncodedNonNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(String.fromCharCode(0), '');
  // String toStringAsEncodedAlphaNumeric([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  // Chars use array index
  // from User I/O as int literal
  String charAsValue(int index) => this[index].toString(); // 1 => '1'
  Uint8List modifyAsValue(int index, String value) => this..[index] = int.parse(value); // '1' => 1

  String charAsCode(int index) => String.fromCharCode(this[index]); // 0x31 => '1'
  Uint8List modifyAsCode(int index, String value) => this..[index] = value.runes.single; // '1' => 0x31
}
