import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                        const SizedBox(height: 48),
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
                    onPressed: () {
                      // Login logic
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCustomButton(
                    text: 'Keluar',
                    assetPath: 'assets/orange_bar.png',
                    onPressed: () {
                      // Exit logic
                    },
                  ),
                  const SizedBox(height: 40),
                  // Footer
                  const Text(
                    'Your Bridge to the Future',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                      fontSize: 14,
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
