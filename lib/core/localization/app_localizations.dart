// App Localizations - Simple implementation for development
// This is a placeholder until I10n is fully set up

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Example strings - expand as needed
  String get appTitle => locale.languageCode == 'id' ? 'Skilloka' : 'Skilloka';
  String get home => locale.languageCode == 'id' ? 'Beranda' : 'Home';
  String get search => locale.languageCode == 'id' ? 'Cari' : 'Search';
  String get profile => locale.languageCode == 'id' ? 'Profil' : 'Profile';
  String get bookings => locale.languageCode == 'id' ? 'Pesanan' : 'Bookings';
  String get login => locale.languageCode == 'id' ? 'Masuk' : 'Login';
  String get register => locale.languageCode == 'id' ? 'Daftar' : 'Register';
  String get welcome =>
      locale.languageCode == 'id' ? 'Selamat Datang' : 'Welcome';
  String get loading =>
      locale.languageCode == 'id' ? 'Memuat...' : 'Loading...';
  String get error =>
      locale.languageCode == 'id' ? 'Terjadi kesalahan' : 'An error occurred';
  String get retry => locale.languageCode == 'id' ? 'Coba Lagi' : 'Retry';
  String get cancel => locale.languageCode == 'id' ? 'Batal' : 'Cancel';
  String get confirm => locale.languageCode == 'id' ? 'Konfirmasi' : 'Confirm';
  String get save => locale.languageCode == 'id' ? 'Simpan' : 'Save';
  String get delete => locale.languageCode == 'id' ? 'Hapus' : 'Delete';
  String get edit => locale.languageCode == 'id' ? 'Edit' : 'Edit';
  String get viewAll =>
      locale.languageCode == 'id' ? 'Lihat Semua' : 'View All';
  String get noData =>
      locale.languageCode == 'id' ? 'Tidak ada data' : 'No data';
  String get courses => locale.languageCode == 'id' ? 'Kursus' : 'Courses';
  String get lpk => 'LPK';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['id', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
