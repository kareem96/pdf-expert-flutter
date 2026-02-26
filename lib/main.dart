import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Expert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),       // violet accent
          onPrimary: Colors.white,
          secondary: Color(0xFF03DAC6),     // teal accent
          surface: Color(0xFF1E1E2E),       // dark surface
          onSurface: Color(0xFFE0E0E0),
          surfaceContainerHigh: Color(0xFF2A2A3E),
          outline: Color(0xFF44475A),
        ),
        scaffoldBackgroundColor: const Color(0xFF13131F),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E2E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFAAAAAA)),
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2A2A3E),
          contentTextStyle: GoogleFonts.inter(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14, color: Color(0xFFAAAAAA),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF6C63FF),
          thumbColor: Color(0xFF6C63FF),
          inactiveTrackColor: Color(0xFF44475A),
          overlayColor: Color(0x226C63FF),
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF2A2A3E),
          labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          side: const BorderSide(color: Color(0xFF44475A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF44475A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF44475A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          labelStyle: GoogleFonts.inter(color: const Color(0xFF8888AA)),
          hintStyle: GoogleFonts.inter(color: const Color(0xFF66667A)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : const Color(0xFF666688)),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? const Color(0xFF6C63FF) : const Color(0xFF2A2A3E)),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
