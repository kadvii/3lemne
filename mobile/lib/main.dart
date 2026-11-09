import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/writing/writing_screen.dart';
import 'features/reading/reading_screen.dart';
import 'features/listening/listening_screen.dart';
import 'features/speaking/speaking_screen.dart';
import 'features/phonics/phonics_screen.dart';
import 'features/words/words_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/writing', builder: (context, state) => const WritingScreen()),
    GoRoute(path: '/reading', builder: (context, state) => const ReadingScreen()),
    GoRoute(path: '/listening', builder: (context, state) => const ListeningScreen()),
    GoRoute(path: '/speaking', builder: (context, state) => const SpeakingScreen()),
    GoRoute(path: '/phonics', builder: (context, state) => const PhonicsScreen()),
    GoRoute(path: '/words', builder: (context, state) => const WordsScreen()),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlemniApp());
}

class AlemniApp extends StatelessWidget {
  const AlemniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'عَلِّمني — 3lemne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Container(
          color: const Color(0xFF090D16),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}

