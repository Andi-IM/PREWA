import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/sample_record_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/app_config_provider.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';

class SampleRecordScreen extends StatefulWidget {
  const SampleRecordScreen({super.key});

  @override
  State<SampleRecordScreen> createState() => _SampleRecordScreenState();
}

class _SampleRecordScreenState extends State<SampleRecordScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  bool _isCameraInitializing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'sample_record');
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isWfa = context.read<AppConfigProvider>().isWfa;
      context.read<SampleRecordProvider>().init(isWfa);
      _initializeCamera();
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

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with safety checks
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

    // If there is an existing controller, dispose it first
    if (_controller != null) {
      await _controller!.dispose();
    }

    // Create a new controller
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
    } catch (e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            if (mounted) {
              _showPermissionDeniedDialog(context, openSettings: true);
            }
            break;
          default:
            debugPrint('Camera Error: ${e.code} ${e.description}');
            break;
        }
      }
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SampleRecordProvider>(
      builder: (context, provider, child) {
        // Navigation logic based on status
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
                                const SizedBox(height: 40),

                                // Title Section (Only show when not capturing to save space, or keep it consistent?)
                                // Keeping consistent for now based on previous layout, maybe smaller?
                                if (provider.status == SampleRecordStatus.idle)
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
                                        minHeight: 200,
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
                                          const SizedBox(height: 20),
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
                                          const SizedBox(height: 20),
                                          const Text(
                                            'Data Sampel Wajah akan diambil sebanyak 10 kali.\nHarap posisi wajah digerakkan sedikit setiap kali pengambilan.',
                                            style: TextStyle(
                                              fontFamily: 'Acme',
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

                                // Camera Preview Section
                                if (provider.status ==
                                        SampleRecordStatus.readyToCapture ||
                                    provider.status ==
                                        SampleRecordStatus.processingImage ||
                                    provider.status ==
                                        SampleRecordStatus.uploading)
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        width: 300,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: _buildCameraPreview(),
                                        ),
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                // Controls
                                if (provider.status == SampleRecordStatus.idle)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40.0),
                                    child: _buildCustomButton(
                                      'Mulai Rekam',
                                      'assets/green_bar.png',
                                      () {
                                        AnalyticsService().logEvent(
                                          name: 'button_click',
                                          parameters: {'button': 'mulai_rekam'},
                                        );
                                        if (_isCameraInitialized) {
                                          context
                                              .read<SampleRecordProvider>()
                                              .startRecording();
                                        } else {
                                          _initializeCamera().then((_) {
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            if (_isCameraInitialized) {
                                              context
                                                  .read<SampleRecordProvider>()
                                                  .startRecording();
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                if (provider.status ==
                                        SampleRecordStatus.readyToCapture ||
                                    provider.status ==
                                        SampleRecordStatus.uploading)
                                  Column(
                                    children: [
                                      Text(
                                        provider.status ==
                                                SampleRecordStatus.uploading
                                            ? "Mengirim ${provider.currentPhotoIndex}/${provider.totalSamples}..."
                                            : provider.message,
                                        style: const TextStyle(
                                          fontFamily: 'Acme',
                                          fontSize: 20,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      if (provider.status ==
                                          SampleRecordStatus.readyToCapture)
                                        _buildCustomButton(
                                          'Ambil Foto',
                                          'assets/green_bar.png',
                                          () async {
                                            AnalyticsService().logEvent(
                                              name: 'take_photo',
                                              parameters: {
                                                'index':
                                                    provider.currentPhotoIndex,
                                              },
                                            );
                                            await _takePicture(context);
                                          },
                                        ),
                                    ],
                                  ),

                                const SizedBox(height: 15),

                                // Back/Exit Button (Always show unless uploading/training?)
                                if (provider.status !=
                                        SampleRecordStatus.uploading &&
                                    provider.status !=
                                        SampleRecordStatus.training)
                                  _buildCustomButton(
                                    'Keluar',
                                    'assets/orange_bar.png',
                                    () {
                                      AnalyticsService().logEvent(
                                        name: 'button_click',
                                        parameters: {
                                          'button': 'sample_keluar',
                                          'photos_taken':
                                              provider.successUploads,
                                        },
                                      );
                                      StorageService.instance.exitApp();
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

            // Loading / Progress Overlay - compact (only for processing & training)
            if (provider.status == SampleRecordStatus.processingImage ||
                provider.status == SampleRecordStatus.training)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          provider.status == SampleRecordStatus.processingImage
                              ? "Memproses..."
                              : "Training...",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Error Overlay - compact toast style
            if (provider.status == SampleRecordStatus.error)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => StorageService.instance.exitApp(),
                            child: const Text(
                              "Keluar",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              context
                                  .read<SampleRecordProvider>()
                                  .retryCapture();
                            },
                            child: const Text("Coba Lagi"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: 1, // Force square container
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

  Future<void> _takePicture(BuildContext context) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        if (!context.mounted) return;
        context.read<SampleRecordProvider>().processImage(image);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
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
              ? "Aplikasi memerlukan izin kamera untuk merekam data sampel wajah. Mohon izinkan akses kamera di pengaturan."
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
