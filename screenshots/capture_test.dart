// Headless screenshot capture. Not part of the CI test suite.
//
//   flutter test screenshots/capture_test.dart --update-goldens --dart-define=SHOTS=after
//
// PNGs land in screenshots/<SHOTS>/.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:uthme2/l10n/app_localizations.dart';
import 'package:uthme2/l10n/locale_controller.dart';
import 'package:uthme2/models/grade_stats.dart';
import 'package:uthme2/models/grades_snapshot.dart';
import 'package:uthme2/providers/average_mode_controller.dart';
import 'package:uthme2/providers/grades_provider.dart';
import 'package:uthme2/providers/menu_notifications_controller.dart';
import 'package:uthme2/screens/home_shell.dart';
import 'package:uthme2/screens/login_screen.dart';
import 'package:uthme2/theme/app_theme.dart';
import 'package:uthme2/widgets/widget_card.dart';

import 'fake_data.dart';

const String _set = String.fromEnvironment('SHOTS', defaultValue: 'after');
const Size _phone = Size(393, 852);

class _FakeGrades extends GradesNotifier {
  _FakeGrades(this._result);

  final Future<GradesSnapshot> Function() _result;

  @override
  Future<GradesSnapshot> build() => _result();

  @override
  Future<void> refreshGrades() async {}
}

Future<void> _loadFonts() async {
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/flutter';
  final material = '$sdk/bin/cache/artifacts/material_fonts';

  final robotoFiles = Directory(material)
      .listSync()
      .map((f) => f.path)
      .where(
        (p) => p.split('/').last.startsWith('Roboto-') && p.endsWith('.ttf'),
      )
      .toList();

  // Roboto also stands in for the default test font, which renders boxes.
  const families = ['Roboto', 'FlutterTest'];
  for (final family in families) {
    final loader = FontLoader(family);
    for (final path in robotoFiles) {
      loader.addFont(_bytes(path));
    }
    await loader.load();
  }

  await (FontLoader(
    'MaterialIcons',
  )..addFont(_bytes('$material/MaterialIcons-Regular.otf'))).load();

  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final cupertino = Directory(
    '$pubCache/hosted/pub.dev',
  ).listSync().firstWhere((d) => d.path.contains('cupertino_icons-'));
  await (FontLoader(
    'packages/cupertino_icons/CupertinoIcons',
  )..addFont(_bytes('${cupertino.path}/assets/CupertinoIcons.ttf'))).load();
}

Future<ByteData> _bytes(String path) async =>
    ByteData.sublistView(File(path).readAsBytesSync());

List<Override> _baseOverrides({List<Override> extra = const []}) => [
  initialLocaleProvider.overrideWithValue(const Locale('en')),
  initialWeightedModeProvider.overrideWithValue(true),
  initialMenuNotificationsProvider.overrideWithValue(true),
  ...extra,
];

Future<void> _shot(
  WidgetTester tester, {
  required String name,
  required Widget home,
  List<Override> overrides = const [],
  http.Client? client,
  Map<String, String> storage = const {
    'username': 'demo',
    'password': 'secret',
  },
  Future<void> Function(WidgetTester tester)? interact,
}) async {
  for (final dark in [false, true]) {
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues(Map.of(storage));
    tester.view.physicalSize = _phone * 3;
    tester.view.devicePixelRatio = 3;

    await http.runWithClient(() async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: _baseOverrides(extra: overrides),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            scrollBehavior: const AppScrollBehavior(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await _settle(tester);
      if (interact != null) {
        await interact(tester);
        await _settle(tester);
      }
      await _decodeImages(tester);
    }, () => client ?? fakeBackend());

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_set/${name}_${dark ? 'dark' : 'light'}.png'),
    );
  }
}

/// Asset images decode on a real event loop, which fake async never runs.
Future<void> _decodeImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}

/// Fixed-step pumping: infinite spinners never let pumpAndSettle finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Override _grades(Future<GradesSnapshot> Function() result) =>
    gradesProvider.overrideWith(() => _FakeGrades(result));

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadFonts();
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('login', (tester) async {
    await _shot(
      tester,
      name: '01_login',
      home: const LoginScreen(),
      storage: const {},
    );
  });

  testWidgets('grades', (tester) async {
    await _shot(
      tester,
      name: '02_grades',
      home: const HomeShell(),
      overrides: [
        _grades(
          () async =>
              GradesSnapshot(grades: demoGrades, fetchedAt: DateTime.now()),
        ),
      ],
    );
  });

  testWidgets('grades scrolled', (tester) async {
    await _shot(
      tester,
      name: '03_grades_scrolled',
      home: const HomeShell(),
      overrides: [
        _grades(
          () async =>
              GradesSnapshot(grades: demoGrades, fetchedAt: DateTime.now()),
        ),
      ],
      interact: (tester) async {
        await tester.tap(find.text('Semester 3'));
        await _settle(tester);
        final scrollable = find.byType(CustomScrollView).first;
        await tester.timedDrag(
          scrollable,
          const Offset(0, -420),
          const Duration(milliseconds: 600),
        );
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  testWidgets('grades offline', (tester) async {
    await _shot(
      tester,
      name: '04_grades_offline',
      home: const HomeShell(),
      overrides: [
        _grades(
          () async => GradesSnapshot(
            grades: demoGrades,
            fetchedAt: DateTime.now().subtract(const Duration(hours: 5)),
            refreshError: 'offline',
          ),
        ),
      ],
    );
  });

  testWidgets('grades loading', (tester) async {
    await _shot(
      tester,
      name: '05_grades_loading',
      home: const HomeShell(),
      overrides: [_grades(() => Completer<GradesSnapshot>().future)],
    );
  });

  testWidgets('grades error', (tester) async {
    await _shot(
      tester,
      name: '06_grades_error',
      home: const HomeShell(),
      overrides: [_grades(() async => throw Exception('portal down'))],
    );
  });

  testWidgets('grades empty', (tester) async {
    await _shot(
      tester,
      name: '07_grades_empty',
      home: const HomeShell(),
      overrides: [_grades(() async => const GradesSnapshot(grades: []))],
    );
  });

  testWidgets('menu picker', (tester) async {
    await _shot(
      tester,
      name: '08_menu_picker',
      home: const HomeShell(initialTab: HomeTab.menu),
    );
  });

  testWidgets('menu', (tester) async {
    await _shot(
      tester,
      name: '09_menu',
      home: const HomeShell(initialTab: HomeTab.menu),
      storage: const {
        'username': 'demo',
        'password': 'secret',
        'preferred_restaurant_id_demo': 'volos',
      },
    );
  });

  testWidgets('menu empty', (tester) async {
    await _shot(
      tester,
      name: '10_menu_empty',
      home: const HomeShell(initialTab: HomeTab.menu),
      client: fakeBackend(emptyMenu: true),
      storage: const {
        'username': 'demo',
        'password': 'secret',
        'preferred_restaurant_id_demo': 'volos',
      },
    );
  });

  testWidgets('menu error', (tester) async {
    await _shot(
      tester,
      name: '11_menu_error',
      home: const HomeShell(initialTab: HomeTab.menu),
      client: fakeBackend(menuFails: true),
      storage: const {
        'username': 'demo',
        'password': 'secret',
        'preferred_restaurant_id_demo': 'volos',
      },
    );
  });

  testWidgets('settings', (tester) async {
    await _shot(
      tester,
      name: '12_settings',
      home: const HomeShell(initialTab: HomeTab.settings),
    );
  });

  testWidgets('logout confirm', (tester) async {
    await _shot(
      tester,
      name: '15_logout_confirm',
      home: const HomeShell(initialTab: HomeTab.settings),
      interact: (tester) async {
        await tester.tap(find.text('Log Out'));
      },
    );
  });

  testWidgets('restaurant sheet', (tester) async {
    await _shot(
      tester,
      name: '16_restaurant_sheet',
      home: const HomeShell(initialTab: HomeTab.menu),
      storage: const {
        'username': 'demo',
        'password': 'secret',
        'preferred_restaurant_id_demo': 'volos',
      },
      interact: (tester) async {
        await tester.tap(find.text('Λέσχη Βόλου').first);
      },
    );
  });

  testWidgets('menu next day', (tester) async {
    await _shot(
      tester,
      name: '17_menu_swiped',
      home: const HomeShell(initialTab: HomeTab.menu),
      storage: const {
        'username': 'demo',
        'password': 'secret',
        'preferred_restaurant_id_demo': 'volos',
      },
      interact: (tester) async {
        await tester.fling(
          find.byType(CustomScrollView).last,
          const Offset(-300, 0),
          1000,
        );
      },
    );
  });

  testWidgets('menu standalone', (tester) async {
    await _shot(
      tester,
      name: '18_menu_signed_out',
      home: const LoginScreen(),
      storage: const {'preferred_restaurant_id': 'larisa'},
      interact: (tester) async {
        await tester.tap(find.text('Browse dining menus'));
      },
    );
  });

  testWidgets('home widget', (tester) async {
    await _shot(
      tester,
      name: '13_home_widget',
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: WidgetCard(
              stats: GradeStats.from(demoGrades),
              l10n: AppLocalizations.of(context),
            ),
          ),
        ),
      ),
    );
  });
}
