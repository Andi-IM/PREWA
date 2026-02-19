import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache images to reduce jank
    precacheImage(const AssetImage('assets/bg.png'), context);
    precacheImage(const AssetImage('assets/logo-pnp.png'), context);
    precacheImage(const AssetImage('assets/app_title.png'), context);
    precacheImage(const AssetImage('assets/green_bar.png'), context);
    precacheImage(const AssetImage('assets/yellow_bar.png'), context);
    precacheImage(const AssetImage('assets/orange_bar.png'), context);
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
                  AnalyticsService().logEvent(
                    name: 'button_click',
                    parameters: {'button': 'wfo'},
                  );
                  context.push('/wfo');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('WFA', 'assets/yellow_bar.png', () {
                  AnalyticsService().logEvent(
                    name: 'button_click',
                    parameters: {'button': 'wfa'},
                  );
                  context.push('/wfa');
                }),
                const SizedBox(height: 15),
                _buildCustomButton('Exit', 'assets/orange_bar.png', () {
                  AnalyticsService().logEvent(
                    name: 'button_click',
                    parameters: {'button': 'exit'},
                  );
                  StorageService.instance.exitApp();
                }),

                const SizedBox(height: 20),

                // UI Preview Button
                TextButton(
                  onPressed: () => _showUiPreviewDialog(context),
                  child: const Text(
                    'UI Preview',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

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

  void _showUiPreviewDialog(BuildContext context) {
    final screens = [
      {'name': 'Home', 'path': '/ui/home'},
      {'name': 'WFO', 'path': '/ui/wfo'},
      {'name': 'WFA', 'path': '/ui/wfa'},
      {'name': 'Login', 'path': '/ui/login'},
      {'name': 'Sample Record', 'path': '/ui/sample_record'},
      {'name': 'Presensi', 'path': '/ui/presensi'},
      {'name': 'Resample', 'path': '/ui/resample'},
      {'name': 'Record Success', 'path': '/ui/record_success'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UI Preview'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: screens.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(screens[index]['name']!),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push(screens[index]['path']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
