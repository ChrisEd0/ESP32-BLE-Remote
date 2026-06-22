import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BTConfigScreen extends StatefulWidget {
  const BTConfigScreen({super.key});

  @override
  State<BTConfigScreen> createState() => _BTConfigScreenState();
}

class _BTConfigScreenState extends State<BTConfigScreen> {
  List<ScanResult> devices = [];
  StreamSubscription? scanSub;

  bool isScanning = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startScan();
    });
  }

  // ---------------- SCAN SIMPLE Y ESTABLE ----------------
  Future<void> startScan() async {
    try {
      setState(() {
        devices.clear();
        isScanning = true;
      });

      await FlutterBluePlus.stopScan();

      scanSub?.cancel();
      scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;

        setState(() {
          devices = results;
        });
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );

      setState(() {
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      debugPrint("❌ BLE ERROR: $e");
    }
  }

  @override
  void dispose() {
    scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("BLE Devices"),
        backgroundColor: Colors.grey[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: startScan,
          )
        ],
      ),

      body: Column(
        children: [
          /// STATUS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.grey[300],
            child: Row(
              children: [
                isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth),

                const SizedBox(width: 10),

                Text(
                  isScanning ? "Scanning..." : "Select device",
                ),
              ],
            ),
          ),

          /// LISTA
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final r = devices[index];

                final name = r.device.platformName.isEmpty
                    ? "Unknown"
                    : r.device.platformName;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),

                    title: Text(name),
                    subtitle: Text(r.device.remoteId.str),

                    onTap: () async {
                      try {
                        await r.device.connect();

                        if (!context.mounted) return;

                        Navigator.pop(context, r.device);
                      } catch (e) {
                        debugPrint("❌ CONNECT ERROR: $e");
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}