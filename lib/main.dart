import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/utils/service_locator.dart';
import 'features/home/home_screen.dart';
import 'services/sms_integration_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Initialize dependency injection
  setupLocator();
  
  // Initialize SMS listener
  await locator<SmsIntegrationService>().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Interceptor',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6200EA),
              brightness: Brightness.light,
              surface: const Color(0xFFF5F5F5),
            ),
            fontFamily: 'Inter',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6200EA),
              brightness: Brightness.dark,
              surface: const Color(0xFF121212),
            ),
            fontFamily: 'Inter',
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
