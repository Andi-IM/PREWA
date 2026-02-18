import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/wfo_screen.dart';
import '../screens/wfa_screen.dart';
import '../screens/login_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/wfo', builder: (context, state) => const WfoScreen()),
    GoRoute(path: '/wfa', builder: (context, state) => const WfaScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  ],
);
