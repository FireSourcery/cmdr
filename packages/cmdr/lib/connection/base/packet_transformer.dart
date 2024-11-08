import 'dart:async';

import 'package:binary_data/models/packet.dart';
import 'package:meta/meta.dart';

import 'protocol.dart'; // or move status

/// Packet Rx Meta Parser
class HeaderParser extends PacketBuffer {
  HeaderParser(super.packetCaster, super.size) : super.size();
  HeaderParser.interface(super.packetInterface, super.size) : super();

  Uint8List trailing = Uint8List(0);
  HeaderStatus get status => HeaderStatus(this);

  /// todo track length before parsing: RangeError (typedData.lengthInBytes): The typed list is not large enough: Not greater than or equal to 8: 3

  // cannot cast struct without full length
  // always copy, double buffers, but does not need to handle remainder
  // sets view length to bound validity checks
  void recvBytes(Uint8List bytesIn) {
    if (length == 0) {
      if (bytesIn.seekViewOfChar(packet.startId) case Uint8List result) copyBytes(result);
    } else {
      addBytes(bytesIn);
    }
  }

  void seekStart() => switch (bytes.seekViewOfChar(packet.startId)) { Uint8List view => copyBytes(view), null => clear() };
  void seekTrailing() => copyBytes(trailing);

  // trim trailing before checking checksum
  // effectively sets pointers to (packetStart, packetEnd/trailingStart, trailingEnd)
  void completePacket() {
    assert(status.isPacketComplete == true);
    final completePacketLength = packet.packetLengthOrNull!; // only valid when status.isPacketComplete
    trailing = Uint8List.sublistView(bytes, completePacketLength);
    length = completePacketLength;
  }

  // alternatively as caster
  // headerParser need caster to shift view packet.cast
}

/// determine complete, error, or wait for more data
class HeaderStatus {
  HeaderStatus(this.buffer);
  @protected
  final HeaderParser buffer;

  /// is full length packet or greater, caller `ensure field are valid` before calling
  bool get isPacketComplete {
    assert(isStartValid == true);
    assert(isIdValid != false);
    // assert(isLengthValid != false); buffer.packet.isLengthValid
    return buffer.packet.isPacketComplete;
  }

  bool? get isStartValid => buffer.packet.isStartFieldValid; // nullable when StartField is multiple bytes
  bool? get isIdValid => buffer.packet.isIdFieldValid;
  // non-sync only
  bool? get isLengthValid => buffer.packet.isLengthFieldValid;
  // packet must be complete and length set
  bool? get isChecksumValid => buffer.packet.isChecksumFieldValid; // (isPacketComplete == true), buffer.length == buffer.lengthFieldOrNull
}

/// combine partial/fragmented packets
/// emitted [Packet] is a reference to the buffer, not a copy. handling must be synchronous, before returning control to the transformer
class PacketTransformer extends StreamTransformerBase<Uint8List, Packet> implements EventSink<Uint8List> {
  PacketTransformer({required this.parserBuffer});

  late final EventSink<Packet> _outputSink;
  final HeaderParser parserBuffer;

  @override
  void add(Uint8List bytesIn) {
    // assert(() {
    //   print('');
    //   print('---');
    //   print('remainder: ${parserBuffer.bytes}');
    // print('bytesIn: $bytesIn');
    //   return true;
    // }());

    parserBuffer.recvBytes(bytesIn);

    try {
      // while - potentially 1+ packets queued, do while HeaderStatus(isPacketComplete: false)
      while (parserBuffer.bytes.isNotEmpty) {
        // print('- parseHeader Loop Start: ${parserBuffer.bytes}');

        switch (parserBuffer.status) {
          case HeaderStatus(isStartValid: false):
            parserBuffer.seekStart();
          // print('parserBuffer seekStart(): ${parserBuffer.bytes}');

          case HeaderStatus(isIdValid: false):
            throw ProtocolException.meta;

          case HeaderStatus(isPacketComplete: true):
            parserBuffer.completePacket(); // set length for checksum operation
            // print('parserBuffer completePacket() ${parserBuffer.bytes} trailing ${parserBuffer.trailing}');
            switch (parserBuffer.status.isChecksumValid) {
              case true || null: // null when no checksum implemented
                /// pass on the packet, full buffer including
                _outputSink.add(parserBuffer.packet); // data pointer is either from Link, or remainderBuffer
                /// transformed stream handles using same headerView before continuing
                parserBuffer.seekTrailing(); // if excess packets queued, this loops recursively.. todo

              case false:
                parserBuffer.seekTrailing();
                throw ProtocolException.checksum;
            }

          /// in case of [sync][sync]
          case HeaderStatus(isLengthValid: false):
            throw ProtocolException.meta;

          /// no recognizable id, or recognized as incomplete
          case HeaderStatus(isPacketComplete: false):
            assert(parserBuffer.length < parserBuffer.packet.lengthMax); // should be caught by isLengthValid
            return;
        }
      }
    } on ProtocolException catch (e) {
      // unparsable error
      switch (e) {
        case ProtocolException.meta:
          parserBuffer.clear(); // ensure remainder buffer is cleared this way
        case ProtocolException.checksum:
      }
      print('PacketTransformer: ${e.message}');
      _outputSink.addError(e);
    } catch (e) {
      parserBuffer.clear();
      print(e);
    } finally {
      //  parserBuffer.seekTrailing(); alternatively, always start with 0 trailing, and seek after packet complete
      // print('- finally');
      // print('parserBuffer bytes ${parserBuffer.bytes}');
    }
  }

  @override
  void addError(Object e, [StackTrace? st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();

  EventSink<Uint8List> _mapSink(EventSink<Packet> sink) => this.._outputSink = sink;

  @override
  Stream<Packet> bind(Stream<Uint8List> stream) => Stream<Packet>.eventTransformed(stream, _mapSink);
}
