import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/wfa_provider.dart';
import '../providers/app_config_provider.dart';
import '../models/app_mode.dart';

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
    // Set mode early to ensure ApiService uses correct endpoints
    context.read<AppConfigProvider>().setMode(AppMode.wfa);

    final provider = context.read<WfaProvider>();
    final success = await provider.checkConnection();

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.pushReplacement('/login');
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
              // Batal Button
              GestureDetector(
                onTap: () => context.pop(),
                child: Image.asset(
                  'assets/buttonExit.png',
                  height: 60, // approximate height matching previous button
                  fit: BoxFit.contain,
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
