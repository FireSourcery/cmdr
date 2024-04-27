import 'protocol/base/protocol.dart';
import 'protocol/mot_packet.dart';
import 'protocol/mot_protocol.dart';
import 'protocol/serial_link.dart';

// Baud Rate | Byte Time | 24 byte time | 40 byte time
// 19200 bauds | 520.833 µs | 12.499992 ms | 20.83332 ms
// 115200 bauds | 86.806 µs | 2.083344 ms | 3.47224 ms

class MotConnection {
  static final SerialLink serialLink = SerialLink();
  // final BluetoothLink bluetoothLink = BluetoothLink();

  static final Protocol protocol = Protocol(serialLink, MotPacketHeaderHandler());

  static final MotProtocolSocket general = MotProtocolSocket(protocol);
  static final MotProtocolSocket stop = MotProtocolSocket(protocol);
  static final MotProtocolSocket varRead = MotProtocolSocket(protocol);
  static final MotProtocolSocket varWrite = MotProtocolSocket(protocol);

  static bool get isConnected => protocol.link.isConnected;

  static bool begin() {
    if (isConnected) protocol.begin();
    return isConnected;
  }
}
