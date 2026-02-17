import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Title Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Image.asset('assets/app_title.png', fit: BoxFit.contain),
              ),

              const Spacer(),

              // Logo
              Image.asset('assets/logo-pnp.png', height: 180),

              const Spacer(),

              // Buttons
              _buildCustomButton('WFO', 'assets/green_bar.png', () {
                // Navigate to WFO
              }),
              const SizedBox(height: 15),
              _buildCustomButton('WFA', 'assets/yellow_bar.png', () {
                // Navigate to WFA
              }),
              const SizedBox(height: 15),
              _buildCustomButton('Exit', 'assets/orange_bar.png', () {
                // Exit app
              }),

              const Spacer(),

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
        width: 200,
        height: 60,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
