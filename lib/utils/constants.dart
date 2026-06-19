import 'package:flutter/material.dart';

class AppColors {
  // Background utama
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color card = Color(0xFF1C2333);
  static const Color cardLight = Color(0xFF222D3D);

  // Aksen
  static const Color primary = Color(0xFF58A6FF);
  static const Color secondary = Color(0xFF3DDAB4);
  static const Color accent = Color(0xFF79C0FF);

  // Status
  static const Color success = Color(0xFF3DDAB4);
  static const Color warning = Color(0xFFF0B429);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Teks
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // Border
  static const Color border = Color(0xFF30363D);
  static const Color borderLight = Color(0xFF21262D);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF58A6FF), Color(0xFF3DDAB4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;
}
