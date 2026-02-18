import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/home_provider.dart';
import 'providers/wfa_provider.dart';
import 'providers/wfo_provider.dart';
import 'providers/sample_record_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/resample_provider.dart';

import 'package:prewa/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WfoProvider()),
        ChangeNotifierProvider(create: (_) => WfaProvider()),
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
