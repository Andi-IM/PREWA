import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/analytics_service.dart';

class RecordSuccessScreen extends StatefulWidget {
  const RecordSuccessScreen({super.key});

  @override
  State<RecordSuccessScreen> createState() => _RecordSuccessScreenState();
}

class _RecordSuccessScreenState extends State<RecordSuccessScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'record_success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Message Box
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Rekam Data Sampel',
                        style: TextStyle(
                          fontFamily: 'Acme',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF800000),
                        ),
                      ),
                      const Text(
                        'Presensi Wajah',
                        style: TextStyle(
                          fontFamily: 'Acme',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF800000),
                        ),
                      ),
                      const SizedBox(height: 60),
                      const Text(
                        'Anda telah merekam',
                        style: TextStyle(
                          fontFamily: 'Acme',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const Text(
                        'Data Sampel Wajah',
                        style: TextStyle(
                          fontFamily: 'Acme',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Data Sampel Presensi Wajah sudah dikirim dan diproses. Silakan login kembali untuk mengisi presensi Anda. Terima Kasih.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Acme',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Buttons Box
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        context,
                        'Lanjut',
                        'assets/green_bar.png',
                        () => context.go('/login'),
                      ),
                      const SizedBox(height: 10),
                      _buildButton(
                        context,
                        'Keluar',
                        'assets/orange_bar.png',
                        () => context.go('/'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Footer Box
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                child: const Text(
                  'Your Bridge to the Future',
                  style: TextStyle(
                    fontFamily: 'Hurricane',
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    String assetPath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        height: 40,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Acme',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
