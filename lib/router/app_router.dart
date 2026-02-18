import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/wfo_screen.dart';
import '../screens/wfa_screen.dart';
import '../screens/internal_login_screen.dart';
import '../screens/global_login_screen.dart';
import '../screens/sample_record_screen.dart';
import '../screens/presensi_screen.dart';
import '../screens/resample_screen.dart';

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
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/wfo', builder: (context, state) => const WfoScreen()),
    GoRoute(path: '/wfa', builder: (context, state) => const WfaScreen()),
    GoRoute(
      path: '/internal_login',
      builder: (context, state) => const InternalLoginScreen(),
    ),
    GoRoute(
      path: '/global_login',
      builder: (context, state) => const GlobalLoginScreen(),
    ),
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
  ],
);
