import 'package:flutter/material.dart';

class WfaScreen extends StatelessWidget {
  const WfaScreen({super.key});

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
              const SizedBox(height: 20),
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Title Image
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Image.asset('assets/app_title.png', fit: BoxFit.contain),
              ),

              const Spacer(),

              Image.asset('assets/logo-pnp.png', height: 180),

              const Spacer(),

              // Screen Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'WFA Screen',
                  style: TextStyle(
                    fontFamily: 'Acme',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),

              const Spacer(),

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
    );
  }
}
