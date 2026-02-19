import 'package:flutter/material.dart';
import 'package:prewa/firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/home_provider.dart';
import 'providers/wfa_provider.dart';
import 'providers/wfo_provider.dart';
import 'providers/sample_record_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/resample_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/app_config_provider.dart';
import 'providers/login_provider.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'package:prewa/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'services/performance_service.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Defer PerformanceService - non-critical for first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PerformanceService().initialize();
  });

  runApp(const MyApp());
}

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
        ProxyProvider<AppConfigProvider, ApiService>(
          update: (_, config, _) => ApiService(config),
        ),
        ChangeNotifierProxyProvider2<
          StorageProvider,
          ApiService,
          LoginProvider
        >(
          create: (context) => LoginProvider(
            context.read<StorageProvider>(),
            context.read<ApiService>(),
          ),
          update: (_, storage, api, previous) =>
              previous!..update(storage, api),
        ),
        ChangeNotifierProxyProvider<ApiService, HomeProvider>(
          create: (context) => HomeProvider(context.read<ApiService>()),
          update: (_, api, previous) => previous!..update(api),
        ),
        ChangeNotifierProvider(create: (_) => WfoProvider()),
        ChangeNotifierProxyProvider<ApiService, WfaProvider>(
          create: (context) => WfaProvider(context.read<ApiService>()),
          update: (_, api, previous) => previous!..updateApi(api),
        ),
        ChangeNotifierProvider(create: (_) => SampleRecordProvider()),
        ChangeNotifierProvider(create: (_) => PresensiProvider()),
        ChangeNotifierProvider(create: (_) => ResampleProvider()),
      ],
      child: MaterialApp.router(
        title: 'Prewa - Presensi Wajah',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
