import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class Premium120FPSPageTransitionsBuilder extends PageTransitionsBuilder {
  const Premium120FPSPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.fastLinearToSlowEaseIn),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }
}

class AppThemeManager {
  static ThemeData getTheme(int themeIndex) {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();
    
    final PageTransitionsTheme smoothTransitions = const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: Premium120FPSPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), 
      },
    );

    switch (themeIndex) {
      case 0: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: Colors.deepPurple, colorScheme: const ColorScheme.dark(primary: Colors.deepPurple, secondary: Colors.purpleAccent), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 1: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: Colors.deepPurple, scaffoldBackgroundColor: const Color(0xFFF8F9FA), colorScheme: const ColorScheme.light(primary: Colors.deepPurple, secondary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 2: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.blue, primaryColor: Colors.blue[600], scaffoldBackgroundColor: const Color(0xFFE3F2FD), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.blue), appBarTheme: AppBarTheme(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 3: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.teal, primaryColor: Colors.teal[600], scaffoldBackgroundColor: const Color(0xFFE0F2F1), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.teal), appBarTheme: AppBarTheme(backgroundColor: Colors.teal[600], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 4: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.purple, primaryColor: Colors.deepPurpleAccent, scaffoldBackgroundColor: const Color(0xFFEDE7F6), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepPurpleAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 5: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.deepOrange, primaryColor: Colors.deepOrangeAccent, scaffoldBackgroundColor: const Color(0xFFFBE9E7), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.deepOrangeAccent), appBarTheme: const AppBarTheme(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 6: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.pink, primaryColor: Colors.pinkAccent, scaffoldBackgroundColor: const Color(0xFFFCE4EC), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, secondary: Colors.pink), appBarTheme: const AppBarTheme(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 7: return ThemeData(textTheme: baseTextTheme, primarySwatch: Colors.cyan, primaryColor: Colors.cyan[700], scaffoldBackgroundColor: const Color(0xFFE0F7FA), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Colors.cyan, secondary: Colors.cyanAccent), appBarTheme: AppBarTheme(backgroundColor: Colors.cyan[700], foregroundColor: Colors.white, elevation: 0), pageTransitionsTheme: smoothTransitions);
      case 8: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF2C3E50), scaffoldBackgroundColor: const Color(0xFF1E272E), colorScheme: const ColorScheme.dark(primary: Color(0xFF2C3E50), secondary: Color(0xFF546E7A)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 9: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF607D8B), scaffoldBackgroundColor: const Color(0xFFECEFF1), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Color(0xFF607D8B), secondary: Color(0xFF90A4AE)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF607D8B), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 10: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF8D6E63), scaffoldBackgroundColor: const Color(0xFFF4ECD8), cardColor: const Color(0xFFFDFBF7), colorScheme: const ColorScheme.light(primary: Color(0xFF8D6E63), secondary: Color(0xFFA1887F)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF8D6E63), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 11: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF5C6BC0), scaffoldBackgroundColor: const Color(0xFFE8F4F8), cardColor: const Color(0xFFF5FAFD), colorScheme: const ColorScheme.light(primary: Color(0xFF5C6BC0), secondary: Color(0xFF7986CB)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF5C6BC0), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 12: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF9E9D24), scaffoldBackgroundColor: const Color(0xFFF5F5DC), cardColor: const Color(0xFFFCFDF2), colorScheme: const ColorScheme.light(primary: Color(0xFF9E9D24), secondary: Color(0xFFAED581)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF9E9D24), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 13: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF4E342E), scaffoldBackgroundColor: const Color(0xFF3E2723), colorScheme: const ColorScheme.dark(primary: Color(0xFF4E342E), secondary: Color(0xFF8D6E63)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 14: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), primaryColor: const Color(0xFF263238), scaffoldBackgroundColor: const Color(0xFF101416), colorScheme: const ColorScheme.dark(primary: Color(0xFF263238), secondary: Color(0xFF455A64)), appBarTheme: const AppBarTheme(elevation: 0), pageTransitionsTheme: smoothTransitions); 
      case 15: return ThemeData.light().copyWith(textTheme: baseTextTheme, primaryColor: const Color(0xFF33691E), scaffoldBackgroundColor: const Color(0xFFF1F8E9), cardColor: Colors.white, colorScheme: const ColorScheme.light(primary: Color(0xFF33691E), secondary: Color(0xFF558B2F)), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF33691E), elevation: 0), pageTransitionsTheme: smoothTransitions); 
      default: return ThemeData.dark().copyWith(textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme), pageTransitionsTheme: smoothTransitions);
    }
  }
}
