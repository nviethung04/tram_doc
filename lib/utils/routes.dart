import 'package:go_router/go_router.dart';
import 'package:tram_doc/screens/home_screen.dart';
import 'package:tram_doc/screens/auth/login_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

