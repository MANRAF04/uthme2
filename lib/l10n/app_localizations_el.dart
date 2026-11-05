// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get academicIdNumber => 'Αριθμός ακαδημαϊκής ταυτότητας';

  @override
  String get account => 'Λογαριασμός';

  @override
  String get appTitle => 'UTHME2';

  @override
  String get averageSimple => 'Απλός';

  @override
  String get averageWeighted => 'Σταθμισμένος';

  @override
  String get browseDiningMenus => 'Περιήγηση στα μενού εστιατορίων';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get change => 'Αλλαγή';

  @override
  String get checkConnection => 'Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';

  @override
  String get copied => 'Αντιγράφηκε';

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
  String get diningCard => 'Κάρτα σίτισης';

  @override
  String get diningCardActive => 'Ενεργή';

  @override
  String get diningCardInactive => 'Ανενεργή';

  @override
  String diningCardValidity(Object from, Object to) {
    return 'Ισχύει από $from έως $to';
  }

  @override
  String get ectsEarned => 'Μονάδες ECTS';

  @override
  String get enterBothCredentials => 'Συμπληρώστε όνομα χρήστη και κωδικό.';

  @override
  String get fetchingGrades => 'Λήψη των τελευταίων βαθμών σας...';

  @override
  String get freeMealsUnavailable => 'Η δωρεάν σίτιση δεν ισχύει σήμερα';

  @override
  String get languageLabel => 'Γλώσσα';

  @override
  String get lastGrade => 'τελευταίος βαθμός';

  @override
  String lastUpdated(Object timestamp) {
    return 'Τελευταία ενημέρωση $timestamp';
  }

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
  String get logOutConfirmMessage =>
      'Οι αποθηκευμένοι βαθμοί θα διαγραφούν από αυτή τη συσκευή.';

  @override
  String get logOutConfirmTitle => 'Αποσύνδεση;';

  @override
  String get menuNotifications => 'Ειδοποιήσεις γευμάτων';

  @override
  String get menuNotificationsSubtitle =>
      'Τα κυρίως πιάτα του εστιατορίου σου, 2 ώρες πριν από το μεσημεριανό και το βραδινό.';

  @override
  String get myGrades => 'Οι βαθμοί μου';

  @override
  String get noDiningCard => 'Δεν υπάρχει κάρτα σίτισης';

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
  String get noStudentDetails => 'Δεν υπάρχουν ακόμα στοιχεία φοιτητή';

  @override
  String get noStudentDetailsSubtitle =>
      'Θα εμφανιστούν μετά τον επόμενο συγχρονισμό βαθμών. Σύρετε προς τα κάτω για συγχρονισμό τώρα.';

  @override
  String get notificationsLabel => 'Ειδοποιήσεις';

  @override
  String notificationsSyncFailed(Object error) {
    return 'Δεν ήταν δυνατή η ενημέρωση των ειδοποιήσεων: $error';
  }

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
  String get scanAtRestaurant =>
      'Δείξτε αυτόν τον κωδικό στο ταμείο του εστιατορίου.';

  @override
  String semester(int number) {
    return 'Εξάμηνο $number';
  }

  @override
  String get servingNow => 'Σερβίρεται τώρα';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get showingSavedGrades => 'Εμφανίζονται αποθηκευμένοι βαθμοί';

  @override
  String get showingSavedMenu => 'Εμφανίζεται το αποθηκευμένο μενού';

  @override
  String get studentId => 'Φοιτητική ταυτότητα';

  @override
  String get studentNumber => 'Αριθμός μητρώου (ΑΕΜ)';

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
  String get tabGrades => 'Βαθμοί';

  @override
  String get tabMenu => 'Μενού';

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
