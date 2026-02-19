import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/presensi_provider.dart';
import '../providers/storage_provider.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../services/crashlytics_service.dart';

class PresensiScreen extends StatefulWidget {
  final String? ceklok;
  final String? tglKerja;

  const PresensiScreen({super.key, this.ceklok, this.tglKerja});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'presensi');
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresensiProvider>().setData(
        ceklok: widget.ceklok,
        tglKerja: widget.tglKerja,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;

    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog(context, openSettings: true);
        setState(() {
          _isCameraInitializing = false;
        });
      }
      return;
    }

    if (status.isDenied) {
      if (mounted) {
        _showPermissionDeniedDialog(context, openSettings: false);
        setState(() {
          _isCameraInitializing = false;
        });
      }
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada kamera ditemukan')),
        );
        setState(() {
          _isCameraInitializing = false;
        });
      }
      return;
    }

    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    if (_controller != null) {
      await _controller!.dispose();
    }

    final newController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await newController.initialize();
      await newController.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) return;

      setState(() {
        _controller = newController;
        _isCameraInitialized = true;
        _isCameraInitializing = false;
      });
    } catch (e, stack) {
      CrashlyticsService().recordError(
        e,
        stack,
        reason: 'Camera Initialization Error',
      );
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _handleCeklok() async {
    final provider = context.read<PresensiProvider>();

    if (provider.ceklok == '1' || provider.ceklok == '2') {
      return;
    }

    if (provider.ceklok == null) {
      _showErrorDialog('Maaf. Ada masalah koneksi Server.');
      return;
    }

    AnalyticsService().logEvent(
      name: 'button_click',
      parameters: {'button': 'ceklok'},
    );

    setState(() {
      _showCamera = true;
    });

    await _initializeCamera();
  }

  Future<void> _takePictureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _controller!.takePicture();

      if (!mounted) return;

      final provider = context.read<PresensiProvider>();
      final processedFile = await provider.preprocessImage(image);

      if (processedFile != null) {
        await provider.processFaceRecognition(processedFile);

        if (!mounted) return;

        _handlePresensiResult(provider);
      } else {
        _showErrorDialog('Gagal memproses gambar. Coba lagi.');
      }
    } catch (e, stack) {
      debugPrint('Error capturing image: $e');
      CrashlyticsService().recordError(e, stack, reason: 'Take Picture Error');
      _showErrorDialog('Gagal mengambil foto. Coba lagi.');
    }
  }

  void _handlePresensiResult(PresensiProvider provider) {
    switch (provider.status) {
      case PresensiStatus.success:
        _showSuccessDialog();
        break;
      case PresensiStatus.failed:
        if (provider.numTry >= 5) {
          _showFailureDialog();
        }
        break;
      case PresensiStatus.unauthorized:
        _showUnauthorizedDialog();
        break;
      case PresensiStatus.error:
        _showErrorDialog('Koneksi Server Terganggu.');
        break;
      default:
        break;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Pengisian Presensi Sukses"),
        content: const Text('Pencocokan wajah Sukses.\nStatus Anda Hadir.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _scheduleExit();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Pengisian Presensi Gagal"),
        content: const Text(
          'Pencocokan wajah gagal.\nSilakan coba beberapa saat lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _scheduleExit();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sesi Habis"),
        content: const Text("Sesi habis. Login Ulang."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(
    BuildContext context, {
    required bool openSettings,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Izin Kamera Diperlukan"),
        content: Text(
          openSettings
              ? "Aplikasi memerlukan izin kamera untuk mengisi presensi. Mohon izinkan akses kamera di pengaturan."
              : "Aplikasi memerlukan izin kamera untuk melanjutkan. Mohon izinkan akses kamera.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (openSettings) {
                openAppSettings();
              } else {
                _initializeCamera();
              }
            },
            child: Text(openSettings ? "Buka Pengaturan" : "Coba Lagi"),
          ),
        ],
      ),
    );
  }

  void _scheduleExit() {
    Timer(const Duration(seconds: 3), () {
      StorageService.instance.exitApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PresensiProvider>(
      builder: (context, provider, child) {
        if (_showCamera) {
          return _buildCameraView(provider);
        }

        return Scaffold(
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

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: AssetImage('assets/bg_content.png'),
                                    fit: BoxFit.fill,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 300,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Status Presensi',
                                      style: TextStyle(
                                        fontFamily: 'Acme',
                                        fontSize: 24,
                                        color: Color(0xFF8B0000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const Text(
                                      'Hari Ini',
                                      style: TextStyle(
                                        fontFamily: 'Acme',
                                        fontSize: 24,
                                        color: Color(0xFF8B0000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    if (provider.tglKerja != null)
                                      Text(
                                        provider.tglKerja!,
                                        style: const TextStyle(
                                          fontFamily: 'Acme',
                                          fontSize: 18,
                                          color: Color(0xFF08206F),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    const SizedBox(height: 10),
                                    Consumer<StorageProvider>(
                                      builder: (context, storage, child) {
                                        final namaUser = storage.namaUser;
                                        if (namaUser != null &&
                                            namaUser.isNotEmpty) {
                                          return Text(
                                            '$namaUser,',
                                            style: const TextStyle(
                                              fontFamily: 'Acme',
                                              fontSize: 18,
                                              color: Color(0xFF08206F),
                                            ),
                                            textAlign: TextAlign.center,
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      provider.statusMessage,
                                      style: const TextStyle(
                                        fontFamily: 'Acme',
                                        fontSize: 18,
                                        color: Color(0xFF0000FF),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 80),

                            if (provider.isCeklokButtonVisible)
                              _buildCustomButton(
                                'Ceklok',
                                'assets/green_bar.png',
                                _handleCeklok,
                              ),
                            const SizedBox(height: 15),
                            _buildCustomButton(
                              'Keluar',
                              'assets/orange_bar.png',
                              () {
                                AnalyticsService().logEvent(
                                  name: 'button_click',
                                  parameters: {'button': 'presensi_keluar'},
                                );
                                StorageService.instance.exitApp();
                              },
                              textColor: Colors.white,
                            ),

                            const Spacer(),

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
        );
      },
    );
  }

  Widget _buildCameraView(PresensiProvider provider) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  const Text(
                    'Ambil Foto Presensi',
                    style: TextStyle(
                      fontFamily: 'Acme',
                      fontSize: 24,
                      color: Color(0xFF8B0000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildCameraPreview(),
                        ),
                      ),
                    ),
                  ),
                  if (provider.status == PresensiStatus.processing)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Memproses...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (provider.status == PresensiStatus.failed &&
                      provider.numTry < 5)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                            ),
                            onPressed: _takePictureAndProcess,
                            child: const Text("Coba Lagi"),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildCustomButton(
                      'Ambil Foto',
                      'assets/green_bar.png',
                      _takePictureAndProcess,
                    ),
                  const SizedBox(height: 15),
                  _buildCustomButton('Batal', 'assets/orange_bar.png', () {
                    setState(() {
                      _showCamera = false;
                      _controller?.dispose();
                      _controller = null;
                      _isCameraInitialized = false;
                    });
                  }, textColor: Colors.white),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: 1,
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize!.height,
            height: _controller!.value.previewSize!.width,
            child: CameraPreview(_controller!),
          ),
        ),
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
        width: 250,
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
