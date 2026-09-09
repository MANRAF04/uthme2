// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'UTHME2';

  @override
  String get browseDiningMenus => 'Browse dining menus';

  @override
  String get change => 'Change';

  @override
  String get checkConnection => 'Check your connection and try again.';

  @override
  String couldNotLoadMenu(Object error) {
    return 'Could not load menu: $error';
  }

  @override
  String couldNotLoadRestaurants(Object error) {
    return 'Could not load restaurants: $error';
  }

  @override
  String get couldNotReachPortal => 'Couldn\'t reach the grade portal';

  @override
  String get ectsEarned => 'ECTS earned';

  @override
  String get enterBothCredentials => 'Please enter both username and password.';

  @override
  String get fetchingGrades => 'Fetching your latest grades...';

  @override
  String get languageLabel => 'Language';

  @override
  String get lastGrade => 'last grade';

  @override
  String get logIn => 'Log in';

  @override
  String loginFailed(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get loginHeroSubtitle =>
      'Sign in with your UTH account. We keep you logged in on this device.';

  @override
  String get loginHeroTitle => 'Grades and menu,\nin one tap.';

  @override
  String get logOut => 'Log Out';

  @override
  String get myGrades => 'My Grades';

  @override
  String get noGradesYet => 'No grades yet';

  @override
  String get noGradesYetSubtitle =>
      'They\'ll show up here once your professors post them.';

  @override
  String get noMenuForDay => 'No menu for this day';

  @override
  String get noMenuForDaySubtitle => 'Use the arrows to check another date.';

  @override
  String get noRestaurantsAvailable =>
      'No restaurants are available at the moment.';

  @override
  String get orSeparator => 'or';

  @override
  String get passed => 'passed';

  @override
  String get password => 'Password';

  @override
  String get pickYourRestaurant => 'Pick your restaurant';

  @override
  String preferenceSyncFailed(Object error) {
    return 'Preference saved locally. Server sync failed: $error';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshing => 'REFRESHING…';

  @override
  String get rememberRestaurant => 'We\'ll remember it for next time.';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get retry => 'Retry';

  @override
  String semester(int number) {
    return 'Semester $number';
  }

  @override
  String get servingNow => 'SERVING NOW';

  @override
  String get settings => 'Settings';

  @override
  String subjectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subjects',
      one: '$count subject',
    );
    return '$_temp0';
  }

  @override
  String get systemDefault => 'System default';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get universityMenus => 'University Menus';

  @override
  String get unweightedAverage => 'UNWEIGHTED AVERAGE';

  @override
  String get usernameLabel => 'UTH Username';

  @override
  String get weightedAverage => 'WEIGHTED AVERAGE';

  @override
  String get yesterday => 'Yesterday';
}
