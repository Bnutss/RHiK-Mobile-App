import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// SnackBar hard-codes `Hero(tag: '<SnackBar Hero tag - $content>',
/// transitionOnUserGestures: true)` inside the Flutter SDK, so any visible
/// SnackBar takes part in the Hero flight of *any* route transition
/// (including a plain back navigation). If the transition's "from" and "to"
/// subtrees both still see that SnackBar (e.g. it's mid dismiss-animation),
/// Flutter throws "multiple heroes share the same tag". Proactively removing
/// the current SnackBar the instant any navigation starts guarantees it's
/// never on screen during a transition, regardless of which button/gesture
/// triggered the navigation.
class _DismissSnackBarsOnNavigate extends NavigatorObserver {
  void _dismiss() {
    final messengerContext = navigator?.context;
    if (messengerContext != null) {
      ScaffoldMessenger.maybeOf(messengerContext)?.removeCurrentSnackBar();
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) => _dismiss();

  @override
  void didPop(Route route, Route? previousRoute) => _dismiss();

  @override
  void didRemove(Route route, Route? previousRoute) => _dismiss();

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _dismiss();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RHiK',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      navigatorObservers: [_DismissSnackBarsOnNavigate()],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
