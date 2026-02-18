import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/sample_record_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/app_config_provider.dart';

class SampleRecordScreen extends StatefulWidget {
  const SampleRecordScreen({super.key});

  @override
  State<SampleRecordScreen> createState() => _SampleRecordScreenState();
}

class _SampleRecordScreenState extends State<SampleRecordScreen> {
  bool _isCapturing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isWfa = context.read<AppConfigProvider>().isWfa;
      context.read<SampleRecordProvider>().init(isWfa);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SampleRecordProvider>(
      builder: (context, provider, child) {
        if (provider.status == SampleRecordStatus.readyToCapture &&
            !_isCapturing) {
          _isCapturing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final recordProvider = context.read<SampleRecordProvider>();
            final XFile? image = await _picker.pickImage(
              source: ImageSource.camera,
              preferredCameraDevice: CameraDevice.front,
              maxWidth: 600,
              maxHeight: 600,
            );
            _isCapturing = false;

            if (image != null && mounted) {
              recordProvider.processImage(image);
            }
          });
        }

        if (provider.status == SampleRecordStatus.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/record_success');
          });
        }

        if (provider.status == SampleRecordStatus.unauthorized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUnauthorizedDialog(context);
          });
        }

        return Stack(
          children: [
            Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                const SizedBox(height: 60),

                                // Content Area
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage(
                                          'assets/bg_content.png',
                                        ),
                                        fit: BoxFit.fill,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minHeight: 300,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Rekam Data Sampel',
                                          style: TextStyle(
                                            fontFamily: 'Acme',
                                            fontSize: 24,
                                            color: Color(
                                              0xFF8B0000,
                                            ), // Dark Red
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const Text(
                                          'Presensi Wajah',
                                          style: TextStyle(
                                            fontFamily: 'Acme',
                                            fontSize: 24,
                                            color: Color(
                                              0xFF8B0000,
                                            ), // Dark Red
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 60),

                                        Text(
                                          'Halo, ${context.watch<StorageProvider>().namaUser ?? 'User'}',
                                          style: const TextStyle(
                                            fontFamily: 'Acme',
                                            fontSize: 20,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),

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
                                            fontFamily:
                                                'Acme', // Using consistent font
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

                                const SizedBox(height: 80),

                                // Buttons
                                _buildCustomButton(
                                  'Rekam',
                                  'assets/green_bar.png',
                                  () {
                                    context
                                        .read<SampleRecordProvider>()
                                        .startRecording();
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildCustomButton(
                                  'Keluar',
                                  'assets/orange_bar.png',
                                  () {
                                    context.go('/');
                                  },
                                  textColor: Colors.white,
                                ),

                                const Spacer(),

                                // Footer
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
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
                    },
                  ),
                ),
              ),
            ),

            // Progress Overlay
            if (provider.status != SampleRecordStatus.idle &&
                provider.status != SampleRecordStatus.success &&
                provider.status != SampleRecordStatus.unauthorized &&
                provider.status != SampleRecordStatus.readyToCapture &&
                provider.status != SampleRecordStatus.error)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          provider.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Error Overlay (if we want to show it here instead of separate dialog)
            if (provider.status == SampleRecordStatus.error)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 20),
                        Text(
                          provider.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SampleRecordProvider>().reset();
                          },
                          child: const Text("Tutup"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Helper for ReadyToCapture just to show a momentary message if needed
            if (provider.status == SampleRecordStatus.readyToCapture &&
                _isCapturing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      provider.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showUnauthorizedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sesi Habis"),
        content: const Text("Sesi Habis. Login Ulang."),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text("OK"),
          ),
        ],
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
