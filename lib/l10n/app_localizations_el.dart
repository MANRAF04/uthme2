// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'UTHME2';

  @override
  String get browseDiningMenus => 'Περιήγηση στα μενού εστιατορίων';

  @override
  String get change => 'Αλλαγή';

  @override
  String get checkConnection => 'Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';

  @override
  String couldNotLoadMenu(Object error) {
    return 'Δεν ήταν δυνατή η φόρτωση του μενού: $error';
  }

  @override
  String couldNotLoadRestaurants(Object error) {
    return 'Δεν ήταν δυνατή η φόρτωση των εστιατορίων: $error';
  }

  @override
  String get couldNotReachPortal =>
      'Δεν ήταν δυνατή η σύνδεση με την πύλη βαθμών';

  @override
  String get ectsEarned => 'Μονάδες ECTS';

  @override
  String get enterBothCredentials => 'Συμπληρώστε όνομα χρήστη και κωδικό.';

  @override
  String get fetchingGrades => 'Λήψη των τελευταίων βαθμών σας...';

  @override
  String get languageLabel => 'Γλώσσα';

  @override
  String get lastGrade => 'τελευταίος βαθμός';

  @override
  String get logIn => 'Σύνδεση';

  @override
  String loginFailed(Object error) {
    return 'Η σύνδεση απέτυχε: $error';
  }

  @override
  String get loginHeroSubtitle =>
      'Συνδεθείτε με τον λογαριασμό του UTH. Θα παραμείνετε συνδεδεμένοι σε αυτή τη συσκευή.';

  @override
  String get loginHeroTitle => 'Βαθμοί και μενού λέσχης,\nμε ένα άγγιγμα.';

  @override
  String get logOut => 'Αποσύνδεση';

  @override
  String get myGrades => 'Οι βαθμοί μου';

  @override
  String get noGradesYet => 'Δεν υπάρχουν βαθμοί ακόμη';

  @override
  String get noGradesYetSubtitle =>
      'Θα εμφανιστούν εδώ μόλις οι καθηγητές σας τους καταχωρίσουν.';

  @override
  String get noMenuForDay => 'Δεν υπάρχει μενού για αυτή την ημέρα';

  @override
  String get noMenuForDaySubtitle =>
      'Χρησιμοποιήστε τα βέλη για να δείτε άλλη ημερομηνία.';

  @override
  String get noRestaurantsAvailable =>
      'Δεν υπάρχουν διαθέσιμα εστιατόρια αυτή τη στιγμή.';

  @override
  String get orSeparator => 'ή';

  @override
  String get passed => 'περάστηκαν';

  @override
  String get password => 'Κωδικός';

  @override
  String get pickYourRestaurant => 'Επιλέξτε εστιατόριο';

  @override
  String preferenceSyncFailed(Object error) {
    return 'Η προτίμηση αποθηκεύτηκε τοπικά. Ο συγχρονισμός με τον διακομιστή απέτυχε: $error';
  }

  @override
  String get refresh => 'Ανανέωση';

  @override
  String get refreshing => 'ΑΝΑΝΕΩΣΗ…';

  @override
  String get rememberRestaurant => 'Θα το θυμόμαστε για την επόμενη φορά.';

  @override
  String get restaurant => 'Εστιατόριο';

  @override
  String get retry => 'Δοκιμάστε ξανά';

  @override
  String semester(int number) {
    return 'Εξάμηνο $number';
  }

  @override
  String get servingNow => 'ΣΕΡΒΙΡΕΤΑΙ ΤΩΡΑ';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String subjectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count μαθήματα',
      one: '$count μάθημα',
    );
    return '$_temp0';
  }

  @override
  String get systemDefault => 'Προεπιλογή συστήματος';

  @override
  String get today => 'Σήμερα';

  @override
  String get tomorrow => 'Αύριο';

  @override
  String get tryAgain => 'Δοκιμάστε ξανά';

  @override
  String get universityMenus => 'Μενού εστιατορίων';

  @override
  String get unweightedAverage => 'ΜΗ ΣΤΑΘΜΙΣΜΕΝΟΣ ΜΕΣΟΣ ΟΡΟΣ';

  @override
  String get usernameLabel => 'Όνομα χρήστη UTH';

  @override
  String get weightedAverage => 'ΣΤΑΘΜΙΣΜΕΝΟΣ ΜΕΣΟΣ ΟΡΟΣ';

  @override
  String get yesterday => 'Χθες';
}
