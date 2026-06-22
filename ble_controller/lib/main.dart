import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/control_screen.dart';
import 'screens/bt_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,    
  ]);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE controller',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/control': (context) => const ControlScreen(),
        '/bt': (context) => const BTConfigScreen(),
      },
    );
  }
}