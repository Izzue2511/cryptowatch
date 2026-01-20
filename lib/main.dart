import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'providers/crypto_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CryptoProvider(prefs),
      child: MaterialApp(
        title: 'Crypto Watch',
        darkTheme: buildDarkTheme(),
        theme: buildLightTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const Banner(
          message: 'FlexZ',
          location: BannerLocation.topEnd,
          color: Colors.deepPurpleAccent,
          child: SplashScreen(),
        ),
      ),
    );
  }
}
