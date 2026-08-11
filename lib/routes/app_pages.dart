import 'package:field_survey/screens/auth/login_page.dart';
import 'package:field_survey/routes/app_routes.dart';
import 'package:field_survey/screens/auth/register_page.dart';
import 'package:field_survey/screens/dashboard/dashboard.dart';
import 'package:field_survey/screens/splash/splash_screen.dart';
import 'package:field_survey/screens/dashboard/home_page.dart';
import 'package:go_router/go_router.dart';

class AppPages {
  static final router = GoRouter(

    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state)=>const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state)=>const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state)=>const Dashboard(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}