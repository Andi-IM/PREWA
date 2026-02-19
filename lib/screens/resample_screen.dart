import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/resample_provider.dart';
import '../services/analytics_service.dart';

class ResampleScreen extends StatefulWidget {
  final String? ceklok;
  final String? tglKerja;

  const ResampleScreen({super.key, this.ceklok, this.tglKerja});

  @override
  State<ResampleScreen> createState() => _ResampleScreenState();
}

class _ResampleScreenState extends State<ResampleScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'resample');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResampleProvider>().setData(
        ceklok: widget.ceklok,
        tglKerja: widget.tglKerja,
      );
    });
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Content Area
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/bg_content.png'),
                                fit: BoxFit.fill,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minHeight: 300),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Permintaan Rekam Ulang',
                                  style: TextStyle(
                                    fontFamily: 'Acme',
                                    fontSize: 24,
                                    color: Color(0xFF8B0000), // Dark Red
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Text(
                                  'Sampel Presensi Wajah',
                                  style: TextStyle(
                                    fontFamily: 'Acme',
                                    fontSize: 24,
                                    color: Color(0xFF8B0000), // Dark Red
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Berdasarkan Log Data Presensi ditemukan bahwa tingkat akurasi pencocokan wajah Anda kurang optimal. Anda disarankan melakukan perekaman ulang data sampel.',
                                  style: TextStyle(
                                    fontFamily: 'Acme',
                                    fontSize: 16,
                                    color: Color(0xFF00008B), // Dark Blue
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Buttons
                        _buildCustomButton(
                          'Lanjut',
                          'assets/green_bar.png',
                          () {
                            AnalyticsService().logEvent(
                              name: 'button_click',
                              parameters: {'button': 'resample_lanjut'},
                            );
                            context.read<ResampleProvider>().onProceed();
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildCustomButton(
                          'Tunda',
                          'assets/yellow_bar.png',
                          () {
                            AnalyticsService().logEvent(
                              name: 'button_click',
                              parameters: {'button': 'resample_tunda'},
                            );
                            context.read<ResampleProvider>().onPostpone();
                          },
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 15),
                        _buildCustomButton(
                          'Keluar',
                          'assets/orange_bar.png',
                          () {
                            AnalyticsService().logEvent(
                              name: 'button_click',
                              parameters: {'button': 'resample_keluar'},
                            );
                            context.go('/');
                          },
                          textColor: Colors.white,
                        ),

                        const Spacer(),

                        // Footer
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            'Your Bridge to the Future',
                            style: TextStyle(
                              fontFamily: 'Hurricane',
                              fontSize: 24,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton(
    String text,
    String assetPath,
    VoidCallback onPressed, {
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 250,
        height: 50,
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
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Acme',
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                offset: Offset(1, 1),
                color: Colors.black26,
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
