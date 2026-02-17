import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wfo_provider.dart';

class WfoScreen extends StatefulWidget {
  const WfoScreen({super.key});

  @override
  State<WfoScreen> createState() => _WfoScreenState();
}

class _WfoScreenState extends State<WfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WfoProvider>().startWfoProcess();
    });
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

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Image.asset('assets/app_title.png', fit: BoxFit.contain),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Consumer<WfoProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildContent(context, provider)],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              Image.asset('assets/logo-pnp.png', height: 80),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WfoProvider provider) {
    switch (provider.status) {
      case WfoStatus.idle:
      case WfoStatus.checkingInfrastructure:
      case WfoStatus.validatingSecurity:
      case WfoStatus.checkingRestrictions:
      case WfoStatus.processing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text(
              provider.message.isEmpty ? "Memulai..." : provider.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        );

      case WfoStatus.infrastructureError:
      case WfoStatus.securityError:
      case WfoStatus.restrictionError:
      case WfoStatus.submissionError:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              "Akses Ditolak",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => provider.startWfoProcess(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text(
                "Coba Lagi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );

      case WfoStatus.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              "Berhasil!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Kembali ke Dashboard",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
    }
  }
}
