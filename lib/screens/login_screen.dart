import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/login_provider.dart';
import '../providers/app_config_provider.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'login');
    _loadCredentials();
  }

  void _loadCredentials() {
    final provider = context.read<LoginProvider>();
    if (provider.userId != null) {
      _usernameController.text = provider.userId!;
    }
    if (provider.password != null) {
      _passwordController.text = provider.password!;
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    AnalyticsService().logEvent(
      name: 'login_attempt',
      parameters: {
        'mode': context.read<AppConfigProvider>().isWfa ? 'wfa' : 'wfo',
      },
    );

    final result = await context.read<LoginProvider>().login(
      username,
      password,
    );

    if (!mounted) return;

    if (result.status == LoginStatus.success) {
      AnalyticsService().logLogin(
        method: context.read<AppConfigProvider>().isWfa ? 'wfa' : 'wfo',
      );
      _navigateToTarget(result);
    } else if (result.status == LoginStatus.error &&
        result.errorMessage != null) {
      AnalyticsService().logEvent(
        name: 'login_failed',
        parameters: {'error': result.errorMessage ?? 'unknown'},
      );
      _showError(result.errorMessage!);
    }
  }

  void _navigateToTarget(LoginResult result) {
    final target = result.navigationTarget;
    final extra = {'ceklok': result.ceklok, 'tgl_kerja': result.tglKerja};

    switch (target) {
      case LoginNavigationTarget.sampleRecord:
        context.go('/sample_record');
        break;
      case LoginNavigationTarget.presensi:
        context.go('/presensi', extra: extra);
        break;
      case LoginNavigationTarget.resample:
        context.go('/resample', extra: extra);
        break;
      default:
        break;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigProvider>();
    final loginProvider = context.watch<LoginProvider>();
    final isLoading = loginProvider.status == LoginStatus.loading;
    final modeTitle = config.isWfa ? '(Global)' : '(Internal)';

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
                  _buildLoginCard(modeTitle, isLoading),
                  const SizedBox(height: 48),
                  _buildButtons(isLoading),
                  const SizedBox(height: 40),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(String modeTitle, bool isLoading) {
    return Container(
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
              fontFamily: 'OpenSans',
              color: Color(0xFF800000),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PREWA',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Color(0xFF800000),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            modeTitle,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            label: 'Username',
            controller: _usernameController,
            enabled: !isLoading,
          ),
          const SizedBox(height: 32),
          _buildTextField(
            label: 'Password',
            controller: _passwordController,
            obscureText: true,
            enabled: !isLoading,
          ),
          if (isLoading) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.deepOrange),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildButtons(bool isLoading) {
    return Column(
      children: [
        _buildCustomButton(
          text: 'Masuk',
          assetPath: 'assets/green_bar.png',
          onPressed: isLoading ? null : _handleLogin,
        ),
        const SizedBox(height: 16),
        _buildCustomButton(
          text: 'Keluar',
          assetPath: 'assets/orange_bar.png',
          onPressed: isLoading
              ? null
              : () {
                  AnalyticsService().logEvent(
                    name: 'button_click',
                    parameters: {'button': 'login_keluar'},
                  );
                  StorageService.instance.exitApp();
                },
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Text(
      'Your Bridge to the Future',
      style: TextStyle(
        fontFamily: 'Hurricane',
        fontSize: 24,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            color: Color(0xFF1A237E),
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
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
    VoidCallback? onPressed,
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
            colorFilter: onPressed == null
                ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : null,
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
