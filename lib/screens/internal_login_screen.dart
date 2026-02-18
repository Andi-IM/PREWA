import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/storage_provider.dart';

class InternalLoginScreen extends StatefulWidget {
  const InternalLoginScreen({super.key});

  @override
  State<InternalLoginScreen> createState() => _InternalLoginScreenState();
}

class _InternalLoginScreenState extends State<InternalLoginScreen> {
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
      debugPrint('=== LOGIN REQUEST ===');
      debugPrint('URL: https://prewa.pnp.ac.id/login.php');
      debugPrint('Payload: username=$username&password=****');

      final response = await http.post(
        Uri.parse('https://prewa.pnp.ac.id/login.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'username=$username&password=$password',
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('====================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logData = Map<String, dynamic>.from(data);
        if (logData.containsKey('token')) {
          logData['token'] = '****';
        }
        debugPrint('Parsed Data: $logData');

        if (data['status'] == 'OK') {
          await storage.saveCredentials(
            userId: data['user_id'] ?? username,
            password: password,
          );
          await storage.saveToken(data['token'] ?? '');
          await storage.saveUserData(
            namaUser: data['nama_user'] ?? '',
            sampleId: data['sample_id'] ?? '',
          );

          if (mounted) {
            final statusTraining = data['status_training'];
            final ceklok = data['ceklok'];
            final tglKerja = data['tgl_kerja'];

            if (statusTraining == 0) {
              context.go('/sample_record');
            } else if (statusTraining == 1) {
              context.go(
                '/presensi',
                extra: {'ceklok': ceklok, 'tgl_kerja': tglKerja},
              );
            } else {
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
      debugPrint('=== LOGIN ERROR ===');
      debugPrint('Error: $e');
      debugPrint('===================');
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
            colors: [
              Color(0xFFFFF3E0), // Light peach
              Color(0xFFFFE0B2), // Light orange
              Color(0xFFFFFFFF), // White
            ],
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
                  // Login Card
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
                            color: Color(0xFF800000), // Maroon
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'P R E W A',
                          style: TextStyle(
                            color: Color(0xFF800000), // Maroon
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '(Internal)',
                          style: TextStyle(
                            color: Color(0xFF1A237E), // Dark Navy
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Username Field
                        _buildTextField(
                          label: 'Username',
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 32),
                        // Password Field
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
                  // Buttons
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
                  // Footer
                  const Text(
                    'Your Bridge to the Future',
                    style: TextStyle(
                      fontFamily: 'Hurricane', // Script font
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
            color: Color(0xFF1A237E), // Dark Navy
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
        width:
            200, // Adjusted to match previous button width roughly, or keep 150 from home? Let's use 200 to fit "Masuk"/"Keluar" nicely or stick to Home design. Home used 150. Let's use 200 to span better or 150. Existing buttons were 200. I'll use 200 to be safe for text length, or matches Home's 150. Home has "WFO" "WFA" "Check In". "Masuk" is short. "Keluar" is short. 150 might be fine but 200 fits the card better. I'll stick to 200 effectively or maybe 180. Home used 150. Let's try 180 for a bit wider action button. Actually, let's copy Home exactly first, then adjust width if needed. Home = 150.
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
            fontFamily:
                'Acme', // Using App's font potentially or just standard if Acme not loaded, but Home used Acme so I assume it's there.
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
