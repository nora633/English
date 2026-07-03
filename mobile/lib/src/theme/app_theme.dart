import 'package:flutter/material.dart';

class AppColors {
  static const page = Color(0xFFF6F7F9);
  static const text = Color(0xFF101318);
  static const muted = Color(0xFF8A8F98);
  static const teal = Color(0xFF12BFC6);
  static const indigo = Color(0xFF5B65F4);
  static const orange = Color(0xFFFF8A2B);
  static const subtle = Color(0xFFEFF8F8);
  static const line = Color(0xFFE2E5EA);
}

class AppText {
  static const pageTitle = TextStyle(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );
  static const hero = TextStyle(fontSize: 28, fontWeight: FontWeight.w900);
  static const heroSub = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);
  static const heroMuted = TextStyle(fontSize: 15, color: Colors.white70);
  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );
  static const sectionBig = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );
  static const bodyLarge = TextStyle(fontSize: 16, height: 1.5);
  static const muted = TextStyle(color: AppColors.muted, height: 1.45);
  static const emphasis = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
  static const accent = TextStyle(
    color: AppColors.teal,
    fontWeight: FontWeight.w800,
  );
  static const stage = TextStyle(
    color: AppColors.indigo,
    fontWeight: FontWeight.w800,
  );
  static const chip = TextStyle(
    color: AppColors.teal,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const metric = TextStyle(fontSize: 24, fontWeight: FontWeight.w900);
}
