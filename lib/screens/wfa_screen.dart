import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wfa_provider.dart';
import 'login_screen.dart';

class WfaScreen extends StatefulWidget {
  const WfaScreen({super.key});

  @override
  State<WfaScreen> createState() => _WfaScreenState();
}

class _WfaScreenState extends State<WfaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    final provider = context.read<WfaProvider>();
    final success = await provider.checkConnection();

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
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

              // Status Display
              Consumer<WfaProvider>(
                builder: (context, provider, child) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        if (provider.status == WfaStatus.loading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 15.0),
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          ),
                        Text(
                          provider.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Acme',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: provider.status == WfaStatus.error
                                ? Colors.red
                                : (provider.status == WfaStatus.success
                                      ? Colors.green
                                      : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Only show Batal button if there is an issue or loading,
              // but if success we are navigating away.
              // Logic check: "Batal" allows user to exit if stuck.
              _buildGradientButton(
                text: 'Batal',
                colors: [const Color(0xFFD32F2F), const Color(0xFFB71C1C)],
                onPressed: () => Navigator.pop(context),
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

  Widget _buildGradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
