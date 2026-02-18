import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/sample_record_provider.dart';

class SampleRecordScreen extends StatelessWidget {
  const SampleRecordScreen({super.key});

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
                          'Rekam Data Sampel',
                          style: TextStyle(
                            fontFamily: 'Acme',
                            fontSize: 24,
                            color: Color(0xFF8B0000), // Dark Red
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'Presensi Wajah',
                          style: TextStyle(
                            fontFamily: 'Acme',
                            fontSize: 24,
                            color: Color(0xFF8B0000), // Dark Red
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        const Text(
                          'Anda belum merekam\nData Sampel Wajah',
                          style: TextStyle(
                            fontFamily: 'Acme',
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Data Sampel Wajah akan diambil sebanyak 10 kali. Harap posisi wajah digerakkan selayang setiap kali pengambilan data.',
                          style: TextStyle(
                            fontFamily: 'Acme', // Using consistent font
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                _buildCustomButton('Rekam', 'assets/green_bar.png', () {
                  context.read<SampleRecordProvider>().startRecording();
                }),
                const SizedBox(height: 15),
                _buildCustomButton('Keluar', 'assets/orange_bar.png', () {
                  context.go('/');
                }, textColor: Colors.white),

                const SizedBox(height: 40),

                // Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
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
        width: 250, // Wider buttons as per image
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
