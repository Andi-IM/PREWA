import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // API Message Section
                Consumer<HomeProvider>(
                  builder: (context, provider, child) {
                    if (provider.apiMessage.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          provider.apiMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                // Title Section
                GestureDetector(
                  onTap: () {
                    context.read<HomeProvider>().handleTitleTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Image.asset(
                      'assets/app_title.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // App Version
                Consumer<HomeProvider>(
                  builder: (context, provider, child) {
                    if (provider.appVersion.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        provider.appVersion,
                        style: const TextStyle(
                          fontFamily: 'Acme',
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Logo
                GestureDetector(
                  onTap: () {
                    context.read<HomeProvider>().handleLogoTap();
                  },
                  child: Image.asset('assets/logo-pnp.png', height: 180),
                ),

                const SizedBox(height: 40),

                // Buttons
                _buildCustomButton('WFO', 'assets/green_bar.png', () {
                  context.push('/wfo');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('WFA', 'assets/yellow_bar.png', () {
                  context.push('/wfa');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('Sample', 'assets/green_bar.png', () {
                  context.push('/sample_record');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('Presensi', 'assets/green_bar.png', () {
                  context.push('/presensi');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('Resample', 'assets/green_bar.png', () {
                  context.push('/resample');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('Exit', 'assets/orange_bar.png', () {
                  // Exit app
                }),

                const SizedBox(height: 40),

                // Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Your Bridge to the Future',
                    style: TextStyle(
                      fontFamily: 'Hurricane', // Script font
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton(
    String text,
    String assetPath,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        height: 60,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: text.isNotEmpty
            ? Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Acme',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      color: Colors.black26,
                      blurRadius: 2,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
