import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bt_screen.dart';

class TopTrapezoid extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.75, size.height);
    path.lineTo(size.width * 0.25, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomTrapezoid extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(size.width * 0.15, 0);
    path.lineTo(size.width * 0.85, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ControlScreen extends StatefulWidget {
  final BluetoothDevice? device;

  const ControlScreen({super.key, this.device});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String dpadState = "X";
  String buttonState = "X";
  String deviceName = "Sin dispositivo";
  String connectionStatus = "Desconectado";
  bool isConnected = false;
  BluetoothDevice? device;
  BluetoothCharacteristic? txCharacteristic;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();

    device = widget.device;
    //_startStream();

    if (device != null) {
      deviceName = device!.platformName.isNotEmpty
          ? device!.platformName
          : "ESP32";
      connectionStatus = "Conectando...";
      _listenConnection();
    }
  }

  void _listenConnection() {
    device!.connectionState.listen((state) async {
      if (!mounted) return;

      if (state == BluetoothConnectionState.connected) {
        setState(() {
          isConnected = true;
          connectionStatus = "Conectado";
        });

        await _setupBle(); // ✅ fuera de setState
        _startStream();

        return;
      }

      if (state == BluetoothConnectionState.connecting) {
        setState(() {
          isConnected = false;
          connectionStatus = "Conectando...";
        });
        return;
      }

      if (state == BluetoothConnectionState.disconnected) {
        setState(() {
          isConnected = false;
          connectionStatus = "Desconectado";
        });

        _streamTimer?.cancel();
        return;
      }
    });
  }

  void _printState() {
    debugPrint("DPAD: $dpadState | BTN: $buttonState");
  }

  void _startStream() {
    _streamTimer?.cancel();

    _streamTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!isConnected) return;
      if (txCharacteristic == null) return;

      final msg = "$dpadState,$buttonState#";

      send(msg);
      //debugPrint("BLE -> $msg");
    });
  }

  Future<void> _setupBle() async {
    try {
      final services = await device!.discoverServices();

      for (final service in services) {
        if (service.uuid.toString() != "12345678-1234-1234-1234-1234567890ab") {
          continue;
        }

        for (final c in service.characteristics) {
          final uuid = c.uuid.toString();

          debugPrint("CHAR FOUND: $uuid");

          if (uuid == "abcdefab-1234-1234-1234-abcdefabcdef") {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              txCharacteristic = c;

              debugPrint("✔ TX OK: $uuid");
              return;
            }
          }
        }
      }

      debugPrint("❌ TX characteristic no encontrada");
    } catch (e) {
      debugPrint("BLE SETUP ERROR: $e");
    }
  }

  Future<void> send(String msg) async {
    if (txCharacteristic == null) return;

    try {
      await txCharacteristic!.write(msg.codeUnits, withoutResponse: true);
    } catch (e) {
      debugPrint("BLE SEND ERROR: $e");
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  Widget button(Color color, IconData icon) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black26, offset: Offset(2, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 34),
    );
  }

  Color getStatusColor() {
    if (connectionStatus == "Conectado")
      return const Color.fromARGB(255, 1, 145, 6);
    if (connectionStatus == "Conectando...") return Colors.orange;
    return const Color.fromARGB(255, 184, 12, 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          /// 🔺 TRAPECIO SUPERIOR (BT CONFIG)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BTConfigScreen(),
                    ),
                  );

                  if (result != null && result is BluetoothDevice) {
                    setState(() {
                      device = result;
                      deviceName = result.platformName.isNotEmpty
                          ? result.platformName
                          : "ESP32";
                      connectionStatus = "Conectando...";
                    });

                    _listenConnection();
                  }
                },
                child: ClipPath(
                  clipper: TopTrapezoid(),
                  child: Container(
                    width: 110,
                    height: 60,
                    color: Colors.grey[400],
                    child: const Center(child: Icon(Icons.bluetooth, size: 36)),
                  ),
                ),
              ),
            ),
          ),

          /// 🔻 TRAPECIO INFERIOR (STATUS)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ClipPath(
                clipper: BottomTrapezoid(),
                child: Container(
                  width: 220,
                  height: 60,
                  color: Colors.grey[350],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          deviceName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          connectionStatus,
                          style: TextStyle(
                            fontSize: 13,
                            color: getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// ⬅️ DPAD
          Positioned(
            left: size.width * 0.08,
            top: size.height * 0.5 - 140,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Listener(
                      onPointerDown: (_) {
                        dpadState = "1";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        dpadState = "X";
                        //_printState();
                      },
                      child: button(Colors.black, Icons.keyboard_arrow_up),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Listener(
                      onPointerDown: (_) {
                        dpadState = "3";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        dpadState = "X";
                        //_printState();
                      },
                      child: button(Colors.black, Icons.keyboard_arrow_left),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Listener(
                      onPointerDown: (_) {
                        dpadState = "4";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        dpadState = "X";
                        //_printState();
                      },
                      child: button(Colors.black, Icons.keyboard_arrow_right),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Listener(
                      onPointerDown: (_) {
                        dpadState = "2";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        dpadState = "X";
                        //_printState();
                      },
                      child: button(Colors.black, Icons.keyboard_arrow_down),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ➡️ BOTONES DERECHA
          Positioned(
            right: size.width * 0.08,
            top: size.height * 0.5 - 140,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Listener(
                      onPointerDown: (_) {
                        buttonState = "A";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        buttonState = "X";
                        //_printState();
                      },
                      child: button(
                        const Color.fromARGB(255, 221, 188, 0),
                        Icons.change_history,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Listener(
                      onPointerDown: (_) {
                        buttonState = "C";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        buttonState = "X";
                        //_printState();
                      },
                      child: button(
                        const Color.fromARGB(255, 58, 160, 61),
                        Icons.stop,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Listener(
                      onPointerDown: (_) {
                        buttonState = "D";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        buttonState = "X";
                        //_printState();
                      },
                      child: button(Colors.blue, Icons.circle),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Listener(
                      onPointerDown: (_) {
                        buttonState = "B";
                        //_printState();
                      },
                      onPointerUp: (_) {
                        buttonState = "X";
                        //_printState();
                      },

                      child: button(Colors.red, Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
