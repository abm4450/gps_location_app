import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    runApp(const MyApp());
  }, (error, stack) {
    runApp(_ErrorApp(error: error, stack: stack));
  });
}

/// عرض خطأ بدل الإغلاق الفوري (لتشخيص المشكلة على iOS)
class _ErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stack;

  const _ErrorApp({required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حدث خطأ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('$error', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Expanded(child: SingleChildScrollView(child: Text('$stack', style: const TextStyle(fontSize: 10)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كفشة كبشة',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ar', 'SA'),

      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.light,

      home: const SplashScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    const Color primary = Color(0xFF0D9488);
    const Color surface = Color(0xFFF8FAFC);
    const Color onSurface = Color(0xFF0F172A);
    const Color surfaceVariant = Color(0xFFF1F5F9);
    final String? fontFamily = _safeTajawalFontFamily();
    final TextTheme baseTextTheme = const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontWeight: FontWeight.w500),
      labelLarge: TextStyle(fontWeight: FontWeight.w700),
    );
    TextTheme textTheme = baseTextTheme;
    if (fontFamily != null) {
      try {
        textTheme = GoogleFonts.tajawalTextTheme(baseTextTheme);
      } catch (_) {}
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        outline: const Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: surface,
      fontFamily: fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  /// تجنب تعطل iOS عند تحميل خط Tajawal
  static String? _safeTajawalFontFamily() {
    try {
      return GoogleFonts.tajawal().fontFamily;
    } catch (_) {
      return null;
    }
  }

  ThemeData _buildDarkTheme() {
    const Color primary = Color(0xFF2DD4BF);
    const Color surface = Color(0xFF0F172A);
    const Color onSurface = Color(0xFFF8FAFC);
    const Color surfaceVariant = Color(0xFF1E293B);
    final String? fontFamily = _safeTajawalFontFamily();
    final TextTheme baseTextTheme = ThemeData.dark().textTheme.copyWith(
      titleLarge: const TextStyle(fontWeight: FontWeight.w800),
      titleMedium: const TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(fontWeight: FontWeight.w500),
      bodyMedium: const TextStyle(fontWeight: FontWeight.w500),
      labelLarge: const TextStyle(fontWeight: FontWeight.w700),
    );
    TextTheme textTheme = baseTextTheme;
    if (fontFamily != null) {
      try {
        textTheme = GoogleFonts.tajawalTextTheme(baseTextTheme);
      } catch (_) {}
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: const Color(0xFF0F172A),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        outline: const Color(0xFF334155),
      ),
      scaffoldBackgroundColor: surface,
      fontFamily: fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: surfaceVariant,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF334155), thickness: 1),
    );
  }
}
