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
  // MotConnection._();
  // factory MotConnection() => _singleton;
  // static final MotConnection _singleton = MotConnection._();
  // static MotConnection get main => _singleton;

  static final SerialLink serialLink = SerialLink();
  // final BluetoothLink bluetoothLink = BluetoothLink();
  static final Protocol protocol = Protocol(serialLink, const MotPacketInterface());
  static final MotProtocolSocket general = MotProtocolSocket(protocol);
  static final MotProtocolSocket stop = MotProtocolSocket(protocol);
  static final MotProtocolSocket varRead = MotProtocolSocket(protocol);
  static final MotProtocolSocket varWrite = MotProtocolSocket(protocol);
  // static final MotProtocolSocket events = MotProtocolSocket(protocol);

  static Link get activeLink => protocol.link;
  static bool get isConnected => protocol.link.isConnected;

  static bool begin({Enum? linkType, String? name, int? baudRate}) {
    serialLink.connect(name: name, baudRate: baudRate);

    //todo connect and begin
    if (isConnected) protocol.begin();
    return isConnected;
  }
}
