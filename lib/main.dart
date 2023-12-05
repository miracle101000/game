import 'package:flutter/material.dart';
import 'package:game/game.dart';
import 'package:game/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().initNotification();
    tz.initializeTimeZones();
  await MobileAds.instance.initialize();
  await Hive.initFlutter();
  await Hive.openBox(Preferences.boxName);
  await Preferences.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Game(),
    );
  }
}
