import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../screens/home_screen.dart';
import '../screens/wfo_screen.dart';
import '../screens/wfa_screen.dart';
import '../screens/login_screen.dart';
import '../screens/sample_record_screen.dart';
import '../screens/presensi_screen.dart';
import '../screens/resample_screen.dart';
import '../screens/record_success_screen.dart';

class PresensiExtra {
  final String? ceklok;
  final String? tglKerja;
  const PresensiExtra({this.ceklok, this.tglKerja});
}

class ResampleExtra {
  final String? ceklok;
  final String? tglKerja;
  const ResampleExtra({this.ceklok, this.tglKerja});
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
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
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PresensiScreen(
          ceklok: extra?['ceklok'],
          tglKerja: extra?['tgl_kerja'],
        );
      },
    ),
    GoRoute(
      path: '/resample',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResampleScreen(
          ceklok: extra?['ceklok'],
          tglKerja: extra?['tgl_kerja'],
        );
      },
    ),
    GoRoute(
      path: '/record_success',
      builder: (context, state) => const RecordSuccessScreen(),
    ),
    GoRoute(path: '/ui/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/ui/wfo', builder: (context, state) => const WfoScreen()),
    GoRoute(path: '/ui/wfa', builder: (context, state) => const WfaScreen()),
    GoRoute(
      path: '/ui/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/ui/sample_record',
      builder: (context, state) => const SampleRecordScreen(),
    ),
    GoRoute(
      path: '/ui/presensi',
      builder: (context, state) => const PresensiScreen(),
    ),
    GoRoute(
      path: '/ui/resample',
      builder: (context, state) => const ResampleScreen(),
    ),
    GoRoute(
      path: '/ui/record_success',
      builder: (context, state) => const RecordSuccessScreen(),
    ),
  ],
);
