import '../base/link.dart';
import '../base/protocol.dart';
import '../links/serial_link.dart';
import 'mot_packet.dart';
import 'mot_protocol.dart';

export '../base/link.dart';
export '../base/protocol.dart';
export '../links/serial_link.dart';
export 'mot_packet.dart';
export 'mot_protocol.dart';

// Baud Rate | Byte Time | 24 byte time | 40 byte time
// 19200 bauds | 520.833 µs | 12.499992 ms | 20.83332 ms
// 115200 bauds | 86.806 µs | 2.083344 ms | 3.47224 ms

class MotConnection {
  MotConnection._();
  static final MotConnection _singleton = MotConnection._();
  factory MotConnection() => _singleton;
  // static MotConnection get main => _singleton;

  final SerialLink serialLink = SerialLink();
  // final BluetoothLink bluetoothLink = BluetoothLink();
  late final Protocol protocol = Protocol(serialLink, const MotPacketInterface()); //todo empty link for state, nullcheck/isconnected
  late final MotProtocolSocket general = MotProtocolSocket(protocol);
  late final MotProtocolSocket stop = MotProtocolSocket(protocol);
  late final MotProtocolSocket varRead = MotProtocolSocket(protocol);
  late final MotProtocolSocket varWrite = MotProtocolSocket(protocol);
  //   final MotProtocolSocket events = MotProtocolSocket(protocol);

  Link get activeLink => protocol.link;
  bool get isConnected => protocol.link.isConnected;

  bool begin({Enum? linkType, String? name, int? baudRate}) {
    serialLink.connect(name: name, baudRate: baudRate);

    if (isConnected) protocol.begin();
    return isConnected;
  }
}
