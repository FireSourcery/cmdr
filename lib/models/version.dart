import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cmdr/byte_struct.dart';
import 'package:cmdr/binary_data/byte_struct.dart';
import 'package:cmdr/binary_data/typed_data_ext.dart';
import 'package:recase/recase.dart';

import '../binary_data/word_fields.dart';
import '../binary_data/typed_field.dart';
import '../binary_data/word.dart';
import '../common/enum_map.dart';

/// standard [optional, major, minor, fix] version
// class Version<T extends VersionField> extends WordFields<VersionField> {
class Version extends WordFields<VersionFieldStandard> {
  const Version(super.optional, super.major, super.minor, super.fix, [this.name]) : super.msb32();
  const Version.value(super.value, [this.name]) : super(); // e.g. a stored value
  // Version.cast(super.word, [this.name]) : super.cast();
  const Version.name(this.name) : super(0); // init for updateFrom

  Version.initWith(Map<VersionFieldStandard, int> newValue, [String? name])
      : this(
          newValue[VersionFieldStandard.optional]!,
          newValue[VersionFieldStandard.major]!,
          newValue[VersionFieldStandard.minor]!,
          newValue[VersionFieldStandard.fix]!,
          name,
        );

  Version updateWithMap(Map<VersionFieldStandard, int> newValue) => Version.initWith(newValue, name);

  @override
  final String? name;

  @override
  int get byteLength => (super.byteLength > 4) ? 8 : 4;

  @override
  List<VersionFieldStandard<NativeType>> get keys => VersionFieldStandard.values;

  @override
  (String, String) get asLabelPair => (name ?? '', toStringAsVersion());

  // int get fix => bytesLE[0];
  // int get minor => bytesLE[1];
  // int get major => bytesLE[2];
  // int get optional => bytesLE[3];
  int get fix => this[VersionFieldStandard.fix];
  int get minor => this[VersionFieldStandard.minor];
  int get major => this[VersionFieldStandard.major];
  int get optional => this[VersionFieldStandard.optional];

  Version updateNumber(int index, int value) => Version.value(modifyByte(index, value), name);

  ///
  //todo use as interface, .fromWord size
  //change for copywith? no need to handle swap endian?
  Version.from(int? value, [Endian endian = Endian.little, this.name]) : super(value ?? 0); // e.g. a network value
  Version updateFrom(int? value, [Endian endian = Endian.little]) => Version.from(value, endian, name);
  // new buffer
  // [optional, major, minor, fix][0,0,0,0]
  Uint8List get version => toBytesAs(Endian.big); // trimmed view on new buffer big endian 8 bytes
  // use for passing the same buffer
  Version updateVersion(Uint8List bytes) => Version.value(bytes.toInt(Endian.big), name);

  List<int> get numbers => toBytesAs(Endian.big);
  Version updateNumbers(List<int> numbers) => (numbers is Uint8List) ? updateVersion(version) : Version.value(numbers.toBytes().toInt(Endian.big), name);

  ///

  // msb first with dot separator
  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          ..writeAll(version, separator)
          ..write(right))
        .toString();
  }

  // check datamap gen
  Version copyWith({int? optional, int? major, int? minor, int? fix, String? name}) {
    return Version(optional ?? this.optional, major ?? this.major, minor ?? this.minor, fix ?? this.fix, name ?? this.name);
  }

  /// Json
  factory Version.fromJson(Map<String, dynamic> json) {
    return Version.value(
      json['value'] as int,
      json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
      'description': toStringAsVersion(),
    };
  }

  factory Version.fromMapEntry(MapEntry<dynamic, dynamic> entry) {
    if (entry case MapEntry<String, int>()) {
      return Version.ofMapEntry(entry);
    } else {
      throw UnsupportedError('Unsupported type');
    }
  }

  factory Version.ofMapEntry(MapEntry<String, int> entry) => Version.value(entry.value, entry.key);

  MapEntry<String, int> toMapEntry() => MapEntry<String, int>(name ?? '', value);

  @override
  bool operator ==(covariant Version other) {
    if (identical(this, other)) return true;

    return other.name == name && other.value == value;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}

enum VersionFieldStandard<T extends NativeType> with TypedField<T> implements WordField<T> {
  fix<Uint8>(0),
  minor<Uint8>(1),
  major<Uint8>(2),
  optional<Uint8>(3),
  ;

  const VersionFieldStandard(this.offset);
  @override
  final int offset;
}
