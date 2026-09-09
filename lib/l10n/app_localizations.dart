import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'UTHME2'**
  String get appTitle;

  /// No description provided for @browseDiningMenus.
  ///
  /// In en, this message translates to:
  /// **'Browse dining menus'**
  String get browseDiningMenus;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnection;

  /// No description provided for @couldNotLoadMenu.
  ///
  /// In en, this message translates to:
  /// **'Could not load menu: {error}'**
  String couldNotLoadMenu(Object error);

  /// No description provided for @couldNotLoadRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Could not load restaurants: {error}'**
  String couldNotLoadRestaurants(Object error);

  /// No description provided for @couldNotReachPortal.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the grade portal'**
  String get couldNotReachPortal;

  /// No description provided for @ectsEarned.
  ///
  /// In en, this message translates to:
  /// **'ECTS earned'**
  String get ectsEarned;

  /// No description provided for @enterBothCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter both username and password.'**
  String get enterBothCredentials;

  /// No description provided for @fetchingGrades.
  ///
  /// In en, this message translates to:
  /// **'Fetching your latest grades...'**
  String get fetchingGrades;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @lastGrade.
  ///
  /// In en, this message translates to:
  /// **'last grade'**
  String get lastGrade;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// No description provided for @loginHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your UTH account. We keep you logged in on this device.'**
  String get loginHeroSubtitle;

  /// No description provided for @loginHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Grades and menu,\nin one tap.'**
  String get loginHeroTitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @myGrades.
  ///
  /// In en, this message translates to:
  /// **'My Grades'**
  String get myGrades;

  /// No description provided for @noGradesYet.
  ///
  /// In en, this message translates to:
  /// **'No grades yet'**
  String get noGradesYet;

  /// No description provided for @noGradesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They\'ll show up here once your professors post them.'**
  String get noGradesYetSubtitle;

  /// No description provided for @noMenuForDay.
  ///
  /// In en, this message translates to:
  /// **'No menu for this day'**
  String get noMenuForDay;

  /// No description provided for @noMenuForDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the arrows to check another date.'**
  String get noMenuForDaySubtitle;

  /// No description provided for @noRestaurantsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No restaurants are available at the moment.'**
  String get noRestaurantsAvailable;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSeparator;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get passed;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pickYourRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Pick your restaurant'**
  String get pickYourRestaurant;

  /// No description provided for @preferenceSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Preference saved locally. Server sync failed: {error}'**
  String preferenceSyncFailed(Object error);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'REFRESHING…'**
  String get refreshing;

  /// No description provided for @rememberRestaurant.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remember it for next time.'**
  String get rememberRestaurant;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester {number}'**
  String semester(int number);

  /// No description provided for @servingNow.
  ///
  /// In en, this message translates to:
  /// **'SERVING NOW'**
  String get servingNow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @subjectCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} subject} other{{count} subjects}}'**
  String subjectCount(int count);

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @universityMenus.
  ///
  /// In en, this message translates to:
  /// **'University Menus'**
  String get universityMenus;

  /// No description provided for @unweightedAverage.
  ///
  /// In en, this message translates to:
  /// **'UNWEIGHTED AVERAGE'**
  String get unweightedAverage;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'UTH Username'**
  String get usernameLabel;

  /// No description provided for @weightedAverage.
  ///
  /// In en, this message translates to:
  /// **'WEIGHTED AVERAGE'**
  String get weightedAverage;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
