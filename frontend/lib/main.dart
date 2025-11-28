import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/note_provider.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/auth/register_screen.dart';
// import 'screens/home/home_screen.dart';
// import 'screens/library/library_screen.dart';
// import 'screens/notes/notes_screen.dart';
// import 'screens/review/review_screen.dart';
// import 'screens/social/social_screen.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const TramDocApp());
}

class TramDocApp extends StatelessWidget {
  const TramDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => BookProvider()),
        ChangeNotifierProvider(create: (context) => NoteProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp.router(
          title: 'Trạm Đọc',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          routerConfig: _router,
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return HomeScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/library',
          name: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/notes',
          name: 'notes',
          builder: (context, state) => const NotesScreen(),
        ),
        GoRoute(
          path: '/review',
          name: 'review',
          builder: (context, state) => const ReviewScreen(),
        ),
        GoRoute(
          path: '/social',
          name: 'social',
          builder: (context, state) => const SocialScreen(),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final isAuthenticated = ApiService.isAuthenticated;
    final isAuthRoute =
        state.fullPath?.startsWith('/login') == true ||
        state.fullPath?.startsWith('/register') == true;

    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    if (isAuthenticated && isAuthRoute) {
      return '/library';
    }

    return null;
  },
);
