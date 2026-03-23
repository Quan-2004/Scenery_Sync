import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'theme/colors.dart';
import 'services/theme_provider.dart';
import 'services/audio_player_service.dart';
import 'services/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';

// HTTP Override để bypass SSL certificate validation (chỉ dùng cho development)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox<Map>('downloads');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize audio player service
  await AudioPlayerService.instance.init();

  // Áp dụng HTTP override để fix lỗi SSL certificate
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('vi'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('vi'),
      startLocale: const Locale('vi'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseService()),
      ],
      child: const MyAppContent(),
    );
  }
}

class MyAppContent extends StatefulWidget {
  const MyAppContent({super.key});

  @override
  State<MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  @override
  void initState() {
    super.initState();
    // Request all permissions on app startup
    _requestAllPermissions();
    // Kết nối AudioPlayerService với FirebaseService để tự động lưu lịch sử nghe
    // cho MỌI nguồn nhạc (Deezer, Firebase, ChatBot, Album, Artist...)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firebaseService = context.read<FirebaseService>();
      AudioPlayerService.instance.onTrackChanged = (track) {
        if (firebaseService.isLoggedIn && track.id.isNotEmpty) {
          firebaseService.saveRecentlyPlayed({
            'id': track.id,
            'title': track.name,
            'artist': track.artistName,
            'imageUrl': track.imageUrl,
            'previewUrl': track.previewUrl ?? '',
            'durationMs': track.durationMs,
          });
        }
      };
    });
  }

  Future<void> _requestAllPermissions() async {
    // Request Camera
    await Permission.camera.request();
    // Request Microphone
    await Permission.microphone.request();
    // Request Notification
    await Permission.notification.request();
    // Request Photos / Storage (platform-dependent)
    if (Platform.isAndroid) {
      final androidInfo = await Permission.photos.request();
      if (androidInfo.isDenied) {
        // Fallback for older Android
        await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      await Permission.photos.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Scenery Sync Music',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.light().textTheme,
        ),
        cardColor: AppColors.surfaceLight,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardColor: AppColors.cardDark,
      ),
      // Define named routes
      initialRoute: '/main',
      routes: {
        '/': (context) => const MainScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

