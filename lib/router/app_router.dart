import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/wfo_screen.dart';
import '../screens/wfa_screen.dart';
import '../screens/login_screen.dart';
import '../screens/sample_record_screen.dart';
import '../screens/presensi_screen.dart';
import '../screens/resample_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/wfo', builder: (context, state) => const WfoScreen()),
    GoRoute(path: '/wfa', builder: (context, state) => const WfaScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/sample_record',
      builder: (context, state) => const SampleRecordScreen(),
    ),
    GoRoute(
      path: '/presensi',
      builder: (context, state) => const PresensiScreen(),
    ),
    GoRoute(
      path: '/resample',
      builder: (context, state) => const ResampleScreen(),
    ),
  ],
);
