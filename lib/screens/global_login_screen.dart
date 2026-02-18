import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/storage_provider.dart';

class GlobalLoginScreen extends StatefulWidget {
  const GlobalLoginScreen({super.key});

  @override
  State<GlobalLoginScreen> createState() => _GlobalLoginScreenState();
}

class _GlobalLoginScreenState extends State<GlobalLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final storage = context.read<StorageProvider>();
    if (storage.userId != null) {
      _usernameController.text = storage.userId!;
    }
    if (storage.password != null) {
      _passwordController.text = storage.password!;
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password harus diisi')),
      );
      return;
    }

    try {
      final storage = context.read<StorageProvider>();
      debugPrint('=== LOGIN REQUEST (GLOBAL) ===');
      debugPrint('URL: https://prewa.pnp.ac.id/login_global.php');
      debugPrint('Payload: username=$username&password=****');

      final response = await http.post(
        Uri.parse('https://prewa.pnp.ac.id/login_global.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'username=$username&password=$password',
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('==============================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logData = Map<String, dynamic>.from(data);
        if (logData.containsKey('token')) {
          logData['token'] = '****';
        }
        debugPrint('Parsed Data: $logData');

        if (data['status'] == 'OK') {
          // Save credentials and user data
          // Point 3: Save user_id as username input, password as password input
          await storage.saveCredentials(
            userId: username, // User input username
            password: password, // User input password
          );
          await storage.saveToken(data['token'] ?? '');
          await storage.saveUserData(
            namaUser: data['nama_user'] ?? '',
            // Ensure sampleId is treated as String
            sampleId: data['sample_id']?.toString() ?? '',
          );

          if (mounted) {
            // Point 4: Check status_training
            final statusTraining = data['status_training'];
            final ceklok = data['ceklok']?.toString();
            final tglKerja = data['tgl_kerja']?.toString();

            // Point 5, 6, 7: Navigation logic
            // Handle statusTraining as int or String for robustness
            int? statusTrainingInt;
            if (statusTraining is int) {
              statusTrainingInt = statusTraining;
            } else if (statusTraining is String) {
              statusTrainingInt = int.tryParse(statusTraining);
            }

            if (statusTrainingInt == 0) {
              // Point 5
              context.go('/sample_record');
            } else if (statusTrainingInt == 1) {
              // Point 6
              context.go(
                '/presensi',
                extra: {'ceklok': ceklok, 'tgl_kerja': tglKerja},
              );
            } else {
              // Point 7 (status_training != 0 && != 1)
              context.go(
                '/resample',
                extra: {'ceklok': ceklok, 'tgl_kerja': tglKerja},
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Login Gagal.\nPeriksa Username dan Password Anda.',
                ),
              ),
            );
          }
        }
      } else if (response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maaf,\nAkses Jaringan Invalid')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maaf,\nKoneksi Server bermasalah.')),
          );
        }
      }
    } catch (e) {
      debugPrint('=== LOGIN ERROR (GLOBAL) ===');
      debugPrint('Error: $e');
      debugPrint('============================');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maaf,\nKoneksi Server bermasalah.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFFFFFFF)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Silakan Login Ke',
                          style: TextStyle(
                            color: Color(0xFF800000),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'P R E W A',
                          style: TextStyle(
                            color: Color(0xFF800000),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '(Global)',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'Username',
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildCustomButton(
                    text: 'Masuk',
                    assetPath: 'assets/green_bar.png',
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 16),
                  _buildCustomButton(
                    text: 'Keluar',
                    assetPath: 'assets/orange_bar.png',
                    onPressed: () {
                      context.pop();
                    },
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Your Bridge to the Future',
                    style: TextStyle(
                      fontFamily: 'Hurricane',
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black87, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black87, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomButton({
    required String text,
    required String assetPath,
    required VoidCallback onPressed,
  }) {
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
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
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
        ),
      ),
    );
  }
}
